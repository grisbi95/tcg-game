class_name DuelEngine
extends RefCounted
## Façade du moteur (décisions 0001 et 0012) : démarrage, validation, soumission, lecture.
##
## Médiateur sans règle propre : chaque intention est aiguillée vers le module de son chapitre,
## `_resolve_stack` aiguille chaque entrée de pile vers le module de son genre, puis `_settle`
## enchaîne les étapes qui suivent toute intention. Une intention illégale produit un unique
## IntentRejected et ne change rien.

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
	PreparationRules.start_preparation(_state, setup, events)
	return events


## Reprend un état construit à la main, pour les tests.
func start_from_state(state: DuelState) -> void:
	_state = state


## État courant en lecture seule ; null avant le démarrage.
func get_state() -> DuelState:
	return _state


## Décisions 0018 et 0045 ; 209.4 : l'hôte signale `elapsed_msec` de temps réel écoulé, hors de
## tout `submit()`. Renvoie les événements de l'expiration d'un temps (fin du tour, passe, choix
## abandonné, défaite par inactivité) ; vide si aucun temps ne s'écoule ou avant le démarrage. Le
## temps qui reste après une expiration s'écoule dans l'état qui la suit.
func advance_clock(elapsed_msec: int) -> Array[DuelEvent]:
	var events: Array[DuelEvent] = []
	if _state == null:
		return events
	var remaining_msec := elapsed_msec
	while remaining_msec > 0 and not _state.is_ended():
		remaining_msec -= StateCheckRules.spend_time(_state, remaining_msec)
		var expired := StateCheckRules.expired_owners(_state)
		if expired.is_empty() or not _expire(expired[0], events):
			break
		_settle(events)
	return events


## 209.4.4, 204.2.2 : joueurs dont une décision est attendue, les deux pendant le mulligan ;
## vide avant le démarrage, après la fin de la partie ou quand aucune décision n'est attendue.
## Pur.
func awaited_players() -> Array[DuelState.PlayerSide]:
	var awaited: Array[DuelState.PlayerSide] = []
	if _state != null:
		awaited = StateCheckRules.awaited_players(_state)
	return awaited


## 209.4.2, 209.4.2d, 209.4.4 : joueurs dont un temps s'écoule, aucun pendant le mulligan ; vide
## avant le démarrage, après la fin de la partie ou quand aucune décision n'est attendue. Pur.
func clock_owners() -> Array[DuelState.PlayerSide]:
	var owners: Array[DuelState.PlayerSide] = []
	if _state != null:
		owners = StateCheckRules.clock_owners(_state)
	return owners


## 209.4.4, 209.4.7 : temps de tour ou temps de réponse qui s'écoule pour `side`. Pur.
func clock_kind(side: DuelState.PlayerSide) -> DuelState.ClockKind:
	if _state == null:
		return DuelState.ClockKind.TURN
	return StateCheckRules.clock_kind(_state, side)


## 209.4.3, 209.4.6 : temps restant du compteur qui s'écoule (ou s'écoulerait) pour `side`. Pur.
func running_time_remaining_msec(side: DuelState.PlayerSide) -> int:
	if _state == null:
		return 0
	return StateCheckRules.running_time_remaining_msec(_state, side)


## 209.4.8, 209.4.8a : vrai si le temps de tour de `side` attend que la pile se vide. Pur.
func is_turn_time_paused(side: DuelState.PlayerSide) -> bool:
	return _state != null and StateCheckRules.is_turn_time_paused(_state, side)


## 209.1 : Force actuelle de la pièce `piece_id`, auras et effets compris, pour la vue ;
## CardDefinition.NO_FORCE si la pièce n'est pas sur le plateau. Pur.
func current_force(piece_id: int) -> int:
	var piece := _state.find_piece(piece_id) if _state != null else null
	if piece == null:
		return CardDefinition.NO_FORCE
	return ForceRules.current_force(_state, piece)


## 203.2.1, 203.2.2 : Sources redressées de `side` une fois `payment` appliqué, pour la vue ;
## 0 avant le premier duel. Pur.
func upright_sources_after_payment(side: DuelState.PlayerSide, payment: EssencePayment) -> int:
	if _state == null:
		return 0
	return EssenceRules.upright_sources_after_payment(_state.get_player(side), payment)


## 203.2.1, 203.2.2 : Sources inclinées de `side` une fois `payment` appliqué, pour la vue ;
## 0 avant le premier duel. Pur.
func tilted_sources_after_payment(side: DuelState.PlayerSide, payment: EssencePayment) -> int:
	if _state == null:
		return 0
	return EssenceRules.tilted_sources_after_payment(_state.get_player(side), payment)


## 203.5.3 : Sources de la Fonte de `side` une fois `payment` appliqué, pour la vue ; 0 avant le
## premier duel. Pur.
func fonte_after_payment(side: DuelState.PlayerSide, payment: EssencePayment) -> int:
	if _state == null:
		return 0
	return EssenceRules.fonte_after_payment(_state.get_player(side), payment)


## 202.2.22, 207.5.1a, 205.1.5 : la carte `card_id` s'annonce avec une cible (Spell, Gear)
## plutôt qu'avec une case ; faux avant le premier duel ou si aucune main ne la contient, seule
## zone d'où la vue annonce. Pur.
func announces_with_target(card_id: int) -> bool:
	var card := _find_card_in_hands(card_id)
	if card == null:
		return false
	var definition := _state.catalog.get_card(card.definition_id)
	return definition != null and CardRules.is_announced_with_target(definition)


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


func _find_card_in_hands(card_id: int) -> CardInstance:
	if _state == null:
		return null
	for player: PlayerState in _state.players:
		var card := player.find_card_in_hand(card_id)
		if card != null:
			return card
	return null


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
	if _is_decision_answer(intent):
		return _validate_answer(intent)
	if _state.pending_decision != null:
		return IntentRejected.RejectReason.DECISION_PENDING
	return _route_play_validation(intent)


func _is_decision_answer(intent: DuelIntent) -> bool:
	return _answer_scripts().has(intent.get_script())


# Intentions qui répondent à une attente (décisions 0009 et 0057) ; `_validate_answer` les aiguille.
func _answer_scripts() -> Array[Script]:
	return [ChooseMulligan, OrderTriggers, ChooseTargets, ChooseDiscard, ChooseTopCardPlace]


# Réponses aux attentes : mulligan, ordre des effets, cibles, et les deux choix d'une résolution
# (décision 0057).
func _validate_answer(intent: DuelIntent) -> IntentRejected.RejectReason:
	if intent is ChooseMulligan:
		return PreparationRules.validate_mulligan(_state, intent as ChooseMulligan)
	if intent is OrderTriggers:
		return TriggerRules.validate_order(_state, intent as OrderTriggers)
	if intent is ChooseTargets:
		return TriggerRules.validate_targets_choice(_state, intent as ChooseTargets)
	if intent is ChooseDiscard:
		return DiscardRules.validate_choice(_state, intent as ChooseDiscard)
	if intent is ChooseTopCardPlace:
		return LookRules.validate_choice(_state, intent as ChooseTopCardPlace)
	return IntentRejected.RejectReason.UNKNOWN_INTENT


# Intentions de jeu, hors attente.
func _route_play_validation(intent: DuelIntent) -> IntentRejected.RejectReason:
	if intent is EndTurn:
		return TurnRules.validate_end_turn(_state, intent as EndTurn)
	if intent is PassPriority:
		return StackRules.validate_pass(_state, intent as PassPriority)
	if intent is ProduceEssence:
		return EssenceRules.validate_production(_state, intent as ProduceEssence)
	return _route_announcement_validation(intent)


# 208.1 : annonces qui s'ajoutent à la pile.
func _route_announcement_validation(intent: DuelIntent) -> IntentRejected.RejectReason:
	if intent is AttachGear:
		return CardRules.validate_attach_gear(_state, intent as AttachGear)
	if intent is DeployCard:
		return ActionRules.validate_deploy(_state, intent as DeployCard)
	if intent is TakeNormalAction:
		return ActionRules.validate_normal_action(_state, intent as TakeNormalAction)
	if intent is CastSpell:
		return SpellRules.validate_cast(_state, intent as CastSpell)
	if intent is AnnounceOrder:
		return OrderRules.validate_announce(_state, intent as AnnounceOrder)
	return IntentRejected.RejectReason.UNKNOWN_INTENT


# 208.4.3, 208.5.1, 208.5.1a, 208.7.13, 204.5.6, 204.5.7 : après chaque intention, les effets en
# attente s'ajoutent à la pile ; une pile qui contient une entrée sans réponse se résout aussitôt,
# sans que personne puisse répondre, tant qu'aucun choix n'est attendu ; une fin du tour dont la
# pile est vide se poursuit jusqu'au tour suivant, dont les effets en attente s'ajoutent à leur
# tour (208.4.11).
func _settle(events: Array[DuelEvent]) -> void:
	while not _state.is_ended():
		TriggerRules.add_waiting_triggers(_state, events)
		if _state.pending_decision == null and StackRules.resolves_at_once(_state):
			_resolve_stack(events)
			continue
		StackRules.return_priority_to_active_player(_state)
		if not TurnRules.is_end_of_turn_ready(_state):
			return
		TurnRules.finish_end_of_turn(_state, events)


# 208.3.1, 208.3.2, 208.3.3 ; 209.2.1, 209.2.3 : toute la pile se résout d'un bloc, du sommet à
# la base ; la victoire se vérifie après chaque entrée, et une partie arrêtée laisse le reste.
# Décision 0057 : un effet qui attend un choix (212.1.3, 217.1.2) suspend le bloc, l'entrée restant
# `resolving_entry` ; la réponse rappelle cette boucle, qui reprend cette entrée à son prochain
# effet puis le reste du bloc. Une entrée est annoncée résolue une seule fois, à sa fin.
func _resolve_stack(events: Array[DuelEvent]) -> void:
	while _state.resolving_entry != null or not _state.stack.is_empty():
		var entry := _state.resolving_entry
		if entry == null:
			entry = StackRules.take_top_entry(_state)
			_state.triggers_allow_response = entry.allows_response  # 208.7.9, 208.7.11
		_resolve_entry(entry, events)
		if _state.pending_decision != null:
			return
		if _state.is_ended():
			return  # 209.2.2 : la pile et l'entrée en cours restent en l'état
		StackRules.end_resolution(_state)
		StackRules.announce_entry_resolved(_state, entry, events)
		if StateCheckRules.check_victory(_state, events, DuelState.EndReason.HERO_HEALTH_ZERO):
			return


# 208.3.2 : chaque genre d'entrée se résout par le module de son chapitre.
func _resolve_entry(entry: StackEntry, events: Array[DuelEvent]) -> void:
	match entry.kind:
		StackEntry.StackEntryKind.DEPLOY:
			ActionRules.resolve_deploy(_state, entry, events)
		StackEntry.StackEntryKind.NORMAL_ACTION:
			ActionRules.resolve_normal_action(_state, entry, events)
		StackEntry.StackEntryKind.SPELL:
			SpellRules.resolve_spell(_state, entry, events)
		StackEntry.StackEntryKind.ATTACH_GEAR:
			CardRules.resolve_attach_gear(_state, entry, events)
		StackEntry.StackEntryKind.TRIGGERED_EFFECT:
			TriggerRules.resolve_triggered(_state, entry, events)
		StackEntry.StackEntryKind.PENDING_COMBAT:
			ActionRules.resolve_pending_combat(_state, entry, events)
		StackEntry.StackEntryKind.ORDER:
			OrderRules.resolve_order(_state, entry, events)


# 209.4.9, 209.4.10, 209.4.11a, 209.4.12 à 209.4.14 : le temps de `side` est écoulé. Le tour se
# termine, le joueur passe, les effets déclenchés s'ordonnent comme ils se sont déclenchés, l'effet
# dont il choisissait les cibles est abandonné, ou le choix d'une résolution est tiré au sort et la
# résolution reprend. Renvoie faux, sans rien changer, quand le ruleset ne
# tranche pas (Q-110).
func _expire(side: DuelState.PlayerSide, events: Array[DuelEvent]) -> bool:
	var decision := _state.pending_decision
	var is_targets_choice := (
		decision != null and decision.kind == PendingDecision.DecisionKind.CHOOSE_TARGETS
	)
	if is_targets_choice and not TriggerRules.can_abandon_targets_choice(_state):
		return false
	var consequence := _expiry_consequence(decision)
	events.append(TimeExpired.new(side, StateCheckRules.clock_kind(_state, side), consequence))
	match consequence:
		TimeExpired.Consequence.TURN_ENDED:
			TurnRules.apply_end_turn(_state, EndTurn.new(side), events)
			StateCheckRules.record_turn_expired(_state, side, events)
		TimeExpired.Consequence.PRIORITY_PASSED:
			_apply(PassPriority.new(side), events)
		TimeExpired.Consequence.TARGETS_ABANDONED:
			TriggerRules.abandon_targets_choice(_state, events)
		TimeExpired.Consequence.TRIGGERS_ORDERED:
			TriggerRules.order_as_triggered(_state, events)
		TimeExpired.Consequence.CARDS_DISCARDED_AT_RANDOM:
			DiscardRules.discard_at_random(_state, events)
			_resolve_stack(events)
		TimeExpired.Consequence.TOP_CARD_PLACE_DRAWN_AT_RANDOM:
			LookRules.place_at_random(_state, events)
			_resolve_stack(events)
	return true


func _expiry_consequence(decision: PendingDecision) -> TimeExpired.Consequence:
	if decision != null:
		match decision.kind:
			PendingDecision.DecisionKind.CHOOSE_TARGETS:
				return TimeExpired.Consequence.TARGETS_ABANDONED
			PendingDecision.DecisionKind.CHOOSE_DISCARD:
				return TimeExpired.Consequence.CARDS_DISCARDED_AT_RANDOM
			PendingDecision.DecisionKind.CHOOSE_TOP_CARD_PLACE:
				return TimeExpired.Consequence.TOP_CARD_PLACE_DRAWN_AT_RANDOM
		return TimeExpired.Consequence.TRIGGERS_ORDERED
	if _state.stack.is_empty():
		return TimeExpired.Consequence.TURN_ENDED
	return TimeExpired.Consequence.PRIORITY_PASSED


func _apply(intent: DuelIntent, events: Array[DuelEvent]) -> void:
	if intent is Concede:
		StateCheckRules.apply_concede(_state, intent as Concede, events)
	elif intent is ChooseMulligan:
		PreparationRules.apply_mulligan(_state, intent as ChooseMulligan, events)
	elif intent is OrderTriggers:
		TriggerRules.apply_order(_state, intent as OrderTriggers, events)
	elif intent is ChooseTargets:
		TriggerRules.apply_targets_choice(_state, intent as ChooseTargets, events)
	elif intent is ChooseDiscard:
		DiscardRules.apply_choice(_state, intent as ChooseDiscard, events)
		_resolve_stack(events)
	elif intent is ChooseTopCardPlace:
		LookRules.apply_choice(_state, intent as ChooseTopCardPlace, events)
		_resolve_stack(events)
	elif intent is EndTurn:
		TurnRules.apply_end_turn(_state, intent as EndTurn, events)
		StateCheckRules.record_turn_ended_by_player(_state, (intent as EndTurn).player)
	elif intent is PassPriority:
		StackRules.apply_pass(_state, intent as PassPriority, events)
		_resolve_stack(events)
	elif intent is ProduceEssence:
		EssenceRules.apply_production(_state, intent as ProduceEssence, events)
	elif intent is DeployCard:
		ActionRules.announce_deploy(_state, intent as DeployCard, events)
	elif intent is TakeNormalAction:
		ActionRules.announce_normal_action(_state, intent as TakeNormalAction, events)
	elif intent is CastSpell:
		SpellRules.announce_spell(_state, intent as CastSpell, events)
	elif intent is AttachGear:
		CardRules.announce_gear(_state, intent as AttachGear, events)
	elif intent is AnnounceOrder:
		OrderRules.apply_announce(_state, intent as AnnounceOrder, events)
