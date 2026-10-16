class_name DuelEngine
extends RefCounted
## Façade du moteur (décisions 0001 et 0012) : démarrage, validation, soumission, lecture.
##
## Aucune règle ici : chaque intention est aiguillée vers le module de son chapitre. Une
## intention illégale produit un unique IntentRejected et ne change rien.

var _catalog: Catalog
var _config: DuelConfig
var _state: DuelState


func _init(catalog: Catalog, config: DuelConfig = DuelConfig.new()) -> void:
	_catalog = catalog
	_config = config


## Décision 0012 : démarre un duel par sa préparation (204.1.9). Un setup invalide produit un
## unique DuelSetupRejected, et aucun duel ne démarre.
func start_new_duel(setup: DuelSetup) -> Array[DuelEvent]:
	var events: Array[DuelEvent] = []
	var errors := setup.find_errors(_catalog, _config)
	if not errors.is_empty():
		events.append(DuelSetupRejected.new(errors))
		return events
	_state = DuelState.create(_config)
	_state.rng.seed = setup.rng_seed
	TurnRules.start_preparation(_state, setup, _catalog, events)
	return events


## Reprend un état construit à la main, pour les tests.
func start_from_state(state: DuelState) -> void:
	_state = state


## État courant en lecture seule ; null avant le démarrage.
func get_state() -> DuelState:
	return _state


## Raison du refus de `intent`, ou NONE si elle est légale. Pur.
func validate(intent: DuelIntent) -> IntentRejected.RejectReason:
	if _state == null or _state.phase == DuelState.DuelPhase.NOT_STARTED:
		return IntentRejected.RejectReason.DUEL_NOT_STARTED
	if _state.phase == DuelState.DuelPhase.ENDED:
		return IntentRejected.RejectReason.DUEL_ENDED
	if intent is ChooseMulligan:
		return TurnRules.validate_mulligan(_state, intent as ChooseMulligan)
	if _state.pending_decision != null:
		return IntentRejected.RejectReason.DECISION_PENDING
	if intent is EndTurn:
		return TurnRules.validate_end_turn(_state, intent as EndTurn)
	return IntentRejected.RejectReason.UNKNOWN_INTENT


## Applique `intent` si elle est légale et renvoie les événements, dans l'ordre.
func submit(intent: DuelIntent) -> Array[DuelEvent]:
	var events: Array[DuelEvent] = []
	var reason := validate(intent)
	if reason != IntentRejected.RejectReason.NONE:
		events.append(IntentRejected.new(intent, reason))
		return events
	_apply(intent, events)
	return events


func _apply(intent: DuelIntent, events: Array[DuelEvent]) -> void:
	if intent is ChooseMulligan:
		TurnRules.apply_mulligan(_state, intent as ChooseMulligan, events)
	elif intent is EndTurn:
		TurnRules.apply_end_turn(_state, intent as EndTurn, events)
