class_name DuelEngine
extends RefCounted
## Façade du moteur (décisions 0001 et 0012) : démarrage, validation, soumission, lecture.
##
## Médiateur sans règle propre : chaque intention est aiguillée vers le module de son chapitre,
## puis `_settle` enchaîne les étapes qui suivent toute intention. Une intention illégale produit
## un unique IntentRejected et ne change rien.

var _catalog: Catalog
var _config: DuelConfig
var _state: DuelState


func _init(catalog: Catalog, config: DuelConfig = DuelConfig.new()) -> void:
	_catalog = catalog
	_config = config


## Décision 0012 : démarre un duel par sa préparation (204.1.9). Un setup ou une configuration
## invalide produit un unique DuelSetupRejected, et aucun duel ne démarre.
func start_new_duel(setup: DuelSetup) -> Array[DuelEvent]:
	var events: Array[DuelEvent] = []
	var errors := setup.find_errors(_catalog, _config)
	errors.append_array(_config.find_errors())
	if not errors.is_empty():
		events.append(DuelSetupRejected.new(errors))
		return events
	_state = DuelState.create(_config, _catalog)
	_state.rng.seed = setup.rng_seed
	TurnRules.start_preparation(_state, setup, events)
	return events


## Reprend un état construit à la main, pour les tests.
func start_from_state(state: DuelState) -> void:
	_state = state


## État courant en lecture seule ; null avant le démarrage.
func get_state() -> DuelState:
	return _state


## Décision 0018 ; 209.4 : l'hôte signale `elapsed_msec` de temps réel écoulé, hors de tout
## `submit()`. Renvoie les événements (temps écoulé, fin de la partie) ; vide si aucune pendule
## ne tourne ou avant le démarrage.
func advance_clock(elapsed_msec: int) -> Array[DuelEvent]:
	var events: Array[DuelEvent] = []
	if _state != null:
		StateCheckRules.advance_clock(_state, elapsed_msec, events)
	return events


## 209.4.4, 204.2.2 : joueurs dont une décision est attendue, les deux pendant le mulligan ;
## vide avant le démarrage, après la fin de la partie ou quand aucune décision n'est attendue.
## Pur.
func awaited_players() -> Array[DuelState.PlayerSide]:
	var awaited: Array[DuelState.PlayerSide] = []
	if _state != null:
		awaited = StateCheckRules.awaited_players(_state)
	return awaited


## 209.4.2, 209.4.2d, 209.4.4 : joueurs dont la pendule tourne, aucun pendant le mulligan ; vide
## avant le démarrage, après la fin de la partie ou quand aucune décision n'est attendue. Pur.
func clock_owners() -> Array[DuelState.PlayerSide]:
	var owners: Array[DuelState.PlayerSide] = []
	if _state != null:
		owners = StateCheckRules.clock_owners(_state)
	return owners


## Raison du refus de `intent`, ou NONE si elle est légale. Pur.
func validate(intent: DuelIntent) -> IntentRejected.RejectReason:
	var reason := _validate_duel_running()
	if reason != IntentRejected.RejectReason.NONE:
		return reason
	return _route_validation(intent)


## Applique `intent` si elle est légale et renvoie les événements, dans l'ordre.
func submit(intent: DuelIntent) -> Array[DuelEvent]:
	var events: Array[DuelEvent] = []
	var reason := validate(intent)
	if reason != IntentRejected.RejectReason.NONE:
		events.append(IntentRejected.new(intent, reason))
		return events
	_apply(intent, events)
	_settle(events)
	return events


func _validate_duel_running() -> IntentRejected.RejectReason:
	if _state == null or _state.phase == DuelState.DuelPhase.NOT_STARTED:
		return IntentRejected.RejectReason.DUEL_NOT_STARTED
	if _state.is_ended():
		return IntentRejected.RejectReason.DUEL_ENDED
	return IntentRejected.RejectReason.NONE


# Décision 0009 : pendant une attente, seule sa réponse passe, avec Concede (209.2.5).
func _route_validation(intent: DuelIntent) -> IntentRejected.RejectReason:
	if intent is Concede:
		return StateCheckRules.validate_concede(_state, intent as Concede)
	if intent is ChooseMulligan:
		return TurnRules.validate_mulligan(_state, intent as ChooseMulligan)
	if intent is OrderTriggers:
		return TriggerRules.validate_order(_state, intent as OrderTriggers)
	if intent is ChooseTargets:
		return TriggerRules.validate_targets_choice(_state, intent as ChooseTargets)
	if _state.pending_decision != null:
		return IntentRejected.RejectReason.DECISION_PENDING
	return _route_play_validation(intent)


# Intentions de jeu, hors attente.
func _route_play_validation(intent: DuelIntent) -> IntentRejected.RejectReason:
	if intent is EndTurn:
		return TurnRules.validate_end_turn(_state, intent as EndTurn)
	if intent is PassPriority:
		return StackRules.validate_pass(_state, intent as PassPriority)
	return _route_announcement_validation(intent)


# 208.1 : annonces qui s'ajoutent à la pile.
func _route_announcement_validation(intent: DuelIntent) -> IntentRejected.RejectReason:
	if intent is AttachGear:
		return CardRules.validate_attach_gear(_state, intent as AttachGear)
	if intent is UseHeroPower:
		return CardRules.validate_hero_power(_state, intent as UseHeroPower)
	if intent is DeployCard:
		return ActionRules.validate_deploy(_state, intent as DeployCard)
	if intent is TakeNormalAction:
		return ActionRules.validate_normal_action(_state, intent as TakeNormalAction)
	if intent is CastSpell:
		return EffectRules.validate_cast(_state, intent as CastSpell)
	return IntentRejected.RejectReason.UNKNOWN_INTENT


# 208.4.3, 208.5.1, 204.5.6, 204.5.7 : après chaque intention, les effets en attente s'ajoutent
# à la pile ; une fin du tour dont la pile est vide se poursuit jusqu'au tour suivant, dont les
# effets en attente s'ajoutent à leur tour (208.4.11).
func _settle(events: Array[DuelEvent]) -> void:
	while not _state.is_ended():
		StackRules.settle_after_triggers(_state, events)
		if not TurnRules.is_end_of_turn_ready(_state):
			return
		TurnRules.finish_end_of_turn(_state, events)


func _apply(intent: DuelIntent, events: Array[DuelEvent]) -> void:
	if intent is Concede:
		StateCheckRules.apply_concede(_state, intent as Concede, events)
	elif intent is ChooseMulligan:
		TurnRules.apply_mulligan(_state, intent as ChooseMulligan, events)
	elif intent is OrderTriggers:
		TriggerRules.apply_order(_state, intent as OrderTriggers, events)
	elif intent is ChooseTargets:
		TriggerRules.apply_targets_choice(_state, intent as ChooseTargets, events)
	elif intent is EndTurn:
		TurnRules.apply_end_turn(_state, intent as EndTurn, events)
	elif intent is PassPriority:
		StackRules.apply_pass(_state, intent as PassPriority, events)
	elif intent is DeployCard:
		ActionRules.announce_deploy(_state, intent as DeployCard, events)
	elif intent is TakeNormalAction:
		ActionRules.announce_normal_action(_state, intent as TakeNormalAction, events)
	elif intent is CastSpell:
		EffectRules.announce_spell(_state, intent as CastSpell, events)
	elif intent is AttachGear:
		CardRules.announce_gear(_state, intent as AttachGear, events)
	elif intent is UseHeroPower:
		CardRules.announce_hero_power(_state, intent as UseHeroPower, events)
