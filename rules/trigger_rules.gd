class_name TriggerRules
extends RefCounted
## Effets déclenchés (207.3, 208.4 ; décisions 0004 et 0017) : attente, ordre d'ajout, cibles,
## « une fois par tour », résolution.
##
## Un effet survenu attend dans `DuelState.waiting_triggers` ; `add_waiting_triggers` l'ajoute à
## la pile, joueur actif d'abord, et s'arrête quand un choix est attendu. DuelEngine l'appelle
## après chaque intention, puis rend la main par `StackRules.return_priority_to_active_player`.

## 208.4.6, 208.4.7 : à partir de deux effets d'un même joueur, l'ordre est un choix.
const MIN_EFFECTS_TO_ORDER: int = 2


## 207.3.1, 207.3.3, 207.3.4, 208.4.2 : les effets de `piece` déclenchés par `trigger_event`
## attendent leur ajout à la pile. Un Hero n'en porte aucun, un jeton non plus (202.4.5).
static func trigger(
	state: DuelState,
	piece: Piece,
	trigger_event: EffectDefinition.TriggerEvent,
	events: Array[DuelEvent]
) -> void:
	if piece.kind == Piece.PieceKind.HERO or piece.is_token():
		return
	var definition := state.catalog.get_card(piece.card.definition_id)
	for index: int in definition.effects.size():
		var effect := definition.effects[index]
		var is_triggered := effect.timing == EffectDefinition.EffectTiming.TRIGGERED
		if is_triggered and effect.trigger == trigger_event:
			_wait(state, piece, index, events)


## 205.6.3, 205.6.5, 205.6.6, 208.7.14 : `combat` attend la fin de la résolution qui l'a fait
## naître, comme un effet déclenché du joueur à qui appartient l'attaquant. Il reçoit un identifiant
## d'entrée dès maintenant (décision 0017) et peut recevoir une réponse.
static func wait_pending_combat(
	state: DuelState, combat: StackEntry, events: Array[DuelEvent]
) -> void:
	combat.stack_entry_id = state.allocate_stack_entry_id()
	combat.kind = StackEntry.StackEntryKind.PENDING_COMBAT
	combat.allows_response = true
	state.waiting_triggers.append(combat)
	var held := CombatPutOnHold.new(
		combat.owner, combat.stack_entry_id, combat.source_piece_id, combat.target_cells[0]
	)
	if combat.card != null:
		held.card_instance_id = combat.card.card_instance_id
	events.append(held)


## 204.5.3 : quand le joueur actif termine son tour, chaque pièce en jeu réagit à la fin du tour.
static func trigger_end_of_turn(state: DuelState, events: Array[DuelEvent]) -> void:
	for piece: Piece in state.pieces:
		if BoardGeometry.is_on_board(piece.cell):
			trigger(state, piece, EffectDefinition.TriggerEvent.END_OF_TURN, events)


## Décision 0017 ; 208.4.3, 208.4.6, 208.4.7 : ajoute à la pile les effets en attente, ceux du
## joueur actif d'abord ; s'arrête sur une attente d'ordre ou de cibles.
static func add_waiting_triggers(state: DuelState, events: Array[DuelEvent]) -> void:
	while state.pending_decision == null:
		if not state.triggers_to_add.is_empty():
			_add_next(state, events)
		elif not state.waiting_triggers.is_empty():
			_order_next_group(state, events)
		else:
			return


## 208.4.6, 208.4.7, décision 0017 : raison du refus de `intent`, ou NONE. Pur.
static func validate_order(state: DuelState, intent: OrderTriggers) -> IntentRejected.RejectReason:
	var reason := PendingDecision.validate_answer(
		state.pending_decision, PendingDecision.DecisionKind.ORDER_TRIGGERS, intent.player
	)
	if reason != IntentRejected.RejectReason.NONE:
		return reason
	var awaited_ids := state.pending_decision.candidate_ids
	var ordered_ids := intent.ordered_stack_entry_ids
	if ordered_ids.size() != awaited_ids.size():
		return IntentRejected.RejectReason.WRONG_TRIGGER_ORDER
	for entry_id: int in awaited_ids:
		if ordered_ids.count(entry_id) != 1:
			return IntentRejected.RejectReason.WRONG_TRIGGER_ORDER
	return IntentRejected.RejectReason.NONE


## 208.4.6, 208.4.7 : les effets du joueur passent dans l'ordre choisi ; l'ajout reprend par
## DuelEngine.
## Suppose l'intention validée.
static func apply_order(state: DuelState, intent: OrderTriggers, events: Array[DuelEvent]) -> void:
	state.pending_decision = null
	events.append(TriggersOrdered.new(intent.player))
	for entry_id: int in intent.ordered_stack_entry_ids:
		var entry := _find_waiting(state, entry_id)
		state.waiting_triggers.erase(entry)
		state.triggers_to_add.append(entry)


## 207.5.1b, 207.5.2, 207.5.10, décision 0017 : raison du refus de `intent`, ou NONE. Pur.
static func validate_targets_choice(
	state: DuelState, intent: ChooseTargets
) -> IntentRejected.RejectReason:
	var reason := PendingDecision.validate_answer(
		state.pending_decision, PendingDecision.DecisionKind.CHOOSE_TARGETS, intent.player
	)
	if reason != IntentRejected.RejectReason.NONE:
		return reason
	var entry := _targeted_entry(state).clone()
	_assign_targets(entry, intent)
	var effect := effect_of(state, entry)
	reason = EffectRules.validate_targets(state, entry, effect.target)
	if reason != IntentRejected.RejectReason.NONE:
		return reason
	var effects: Array[EffectDefinition] = [effect]
	return EffectRules.validate_no_extra_targets(entry, effects)


## 207.5.1b : l'effet reçoit ses cibles ; son ajout à la pile, puis celui des suivants, reprend
## par DuelEngine. Suppose l'intention validée.
static func apply_targets_choice(
	state: DuelState, intent: ChooseTargets, events: Array[DuelEvent]
) -> void:
	var entry := _targeted_entry(state)
	state.pending_decision = null
	_assign_targets(entry, intent)
	events.append(TargetsChosen.new(intent.player, entry.stack_entry_id))


## 209.4.11a, Q-110 : vrai si l'expiration du temps pendant le choix des cibles de l'effet
## attendu peut l'abandonner : aucun autre effet n'attend et il n'est pas « une fois par tour »,
## cas que le ruleset ne tranche pas. Pur.
static func can_abandon_targets_choice(state: DuelState) -> bool:
	var entry := _targeted_entry(state)
	if entry == null:
		return false
	var only_one_waiting := state.triggers_to_add.size() == 1 and state.waiting_triggers.is_empty()
	return only_one_waiting and not effect_of(state, entry).once_per_turn


## 209.4.11a : l'effet dont le joueur choisissait les cibles ne s'ajoute pas à la pile.
## Suppose `can_abandon_targets_choice`.
static func abandon_targets_choice(state: DuelState, events: Array[DuelEvent]) -> void:
	var entry := _targeted_entry(state)
	state.pending_decision = null
	_skip(state.triggers_to_add, entry, events)


## 208.4.6, 208.4.7, 209.4.12 : ordre des effets déclenchés à l'expiration du temps, celui où ils
## se sont déclenchés. Suppose l'attente ORDER_TRIGGERS.
static func order_as_triggered(state: DuelState, events: Array[DuelEvent]) -> void:
	var decision := state.pending_decision
	var ordered_ids: Array[int] = []
	for entry: StackEntry in state.waiting_triggers:
		if decision.candidate_ids.has(entry.stack_entry_id):
			ordered_ids.append(entry.stack_entry_id)
	apply_order(state, OrderTriggers.new(decision.awaited_players[0], ordered_ids), events)


## 208.3.2a, 207.3.3, 207.5.3 à 207.5.5 : l'effet a lieu même si sa pièce a quitté le plateau.
static func resolve_triggered(
	state: DuelState, entry: StackEntry, events: Array[DuelEvent]
) -> void:
	EffectRules.resolve_effect(state, entry, effect_of(state, entry), events)


## Définition de l'effet que porte `entry`.
static func effect_of(state: DuelState, entry: StackEntry) -> EffectDefinition:
	return state.catalog.get_card(entry.source_definition_id).effects[entry.effect_index]


# 207.3.4 : l'effet appartient au joueur à qui appartient la carte ; son identifiant d'entrée
# lui est donné dès maintenant (décision 0017).
static func _wait(
	state: DuelState, piece: Piece, effect_index: int, events: Array[DuelEvent]
) -> void:
	var entry := StackEntry.new()
	entry.stack_entry_id = state.allocate_stack_entry_id()
	entry.kind = StackEntry.StackEntryKind.TRIGGERED_EFFECT
	entry.owner = piece.card.owner
	entry.source_piece_id = piece.piece_id
	entry.source_card_instance_id = piece.card.card_instance_id
	entry.source_definition_id = piece.card.definition_id
	entry.effect_index = effect_index
	entry.allows_response = state.triggers_allow_response  # 208.7.8 à 208.7.11
	state.waiting_triggers.append(entry)
	events.append(EffectTriggered.new(entry.owner, entry.stack_entry_id, piece.piece_id))


# 208.4.6, 208.4.7 : les effets du joueur actif, sinon ceux de son adversaire ; un seul effet
# s'ordonne sans demander (décision 0004).
static func _order_next_group(state: DuelState, events: Array[DuelEvent]) -> void:
	var addable: Array[StackEntry] = []
	for entry: StackEntry in _next_group(state):
		if _can_be_added(state, entry):
			addable.append(entry)
		else:
			_skip(state.waiting_triggers, entry, events)
	if addable.size() >= MIN_EFFECTS_TO_ORDER:
		_request(state, _make_order_decision(addable), events)
		return
	for entry: StackEntry in addable:
		var ordering := PendingDecision.DecisionKind.ORDER_TRIGGERS
		events.append(DecisionResolvedAutomatically.new(entry.owner, ordering))
		state.waiting_triggers.erase(entry)
		state.triggers_to_add.append(entry)


# 208.4.6, 208.4.7 : les effets en attente du joueur actif, sinon ceux de son adversaire.
static func _next_group(state: DuelState) -> Array[StackEntry]:
	var active := state.active_player
	var has_active_effects := state.waiting_triggers.any(
		func(entry: StackEntry) -> bool: return entry.owner == active
	)
	var side := active if has_active_effects else DuelState.opponent_of(active)
	var group: Array[StackEntry] = []
	group.assign(
		state.waiting_triggers.filter(func(entry: StackEntry) -> bool: return entry.owner == side)
	)
	return group


# 207.5.1b, 207.3.6, 208.4.1 : les cibles d'abord, puis l'ajout au sommet de la pile, qui
# décompte la mention « une fois par tour ».
static func _add_next(state: DuelState, events: Array[DuelEvent]) -> void:
	var entry := state.triggers_to_add[0]
	if entry.kind == StackEntry.StackEntryKind.PENDING_COMBAT:
		state.triggers_to_add.pop_front()
		StackRules.add_to_stack(state, entry, events)
		return
	if not _can_be_added(state, entry):
		_skip(state.triggers_to_add, entry, events)
		return
	var effect := effect_of(state, entry)
	if EffectRules.chosen_count(entry, effect.target) == 0:
		if not _has_unique_targets(state, entry, effect.target):
			_request(state, _make_targets_decision(state, entry, effect.target), events)
			return
		_assign_unique_targets(state, entry, effect.target, events)
	state.triggers_to_add.pop_front()
	if effect.once_per_turn:
		state.once_per_turn_card_ids.append(entry.source_card_instance_id)
	StackRules.add_to_stack(state, entry, events)


# 207.3.5a, 207.3.7, 207.3.10 ; 207.5.9, 207.5.10
static func _can_be_added(state: DuelState, entry: StackEntry) -> bool:
	if entry.kind == StackEntry.StackEntryKind.PENDING_COMBAT:
		return true
	var effect := effect_of(state, entry)
	if effect.once_per_turn and state.once_per_turn_card_ids.has(entry.source_card_instance_id):
		return false
	var legal_count := EffectRules.legal_target_count(state, entry.owner, effect.target)
	return legal_count >= effect.target.count_min


# 207.5.2, 207.5.10, décision 0004 : autant de cibles légales que le minimum exigé, un seul
# choix est possible ; sinon le joueur à qui appartient l'effet choisit.
static func _has_unique_targets(state: DuelState, entry: StackEntry, spec: TargetSpec) -> bool:
	var legal_count := _legal_ids(state, entry, spec).size()
	legal_count += EffectRules.legal_cells(state, entry.owner, spec).size()
	return legal_count == spec.count_min


# 207.5.1b, décision 0004 : le moteur prend toutes les cibles légales, sans demander.
static func _assign_unique_targets(
	state: DuelState, entry: StackEntry, spec: TargetSpec, events: Array[DuelEvent]
) -> void:
	entry.target_cells.assign(EffectRules.legal_cells(state, entry.owner, spec))
	if spec.what == TargetSpec.TargetWhat.SPELL_ON_STACK:
		entry.target_stack_entry_ids.assign(_legal_ids(state, entry, spec))
	else:
		entry.target_piece_ids.assign(_legal_ids(state, entry, spec))
	var targeting := PendingDecision.DecisionKind.CHOOSE_TARGETS
	events.append(DecisionResolvedAutomatically.new(entry.owner, targeting))


# 207.3.5a, 207.5.9, 207.5.10 : l'effet est retiré sans avoir lieu, et l'événement le dit.
static func _skip(list: Array[StackEntry], entry: StackEntry, events: Array[DuelEvent]) -> void:
	list.erase(entry)
	events.append(TriggerSkipped.new(entry.owner, entry.stack_entry_id))


# 207.5.2, 208.4.6, 208.4.7 : le moteur attend le choix du joueur (décisions 0009 et 0017).
static func _request(state: DuelState, decision: PendingDecision, events: Array[DuelEvent]) -> void:
	state.pending_decision = decision
	for side: DuelState.PlayerSide in decision.awaited_players:
		state.get_player(side).response_time_remaining_msec = state.config.response_time_msec
	events.append(DecisionRequested.new(decision.awaited_players[0], decision.kind))


# 208.4.6, 208.4.7 : le joueur à qui appartiennent les effets choisit leur ordre.
static func _make_order_decision(entries: Array[StackEntry]) -> PendingDecision:
	var decision := PendingDecision.new()
	decision.kind = PendingDecision.DecisionKind.ORDER_TRIGGERS
	decision.awaited_players.append(entries[0].owner)
	for entry: StackEntry in entries:
		decision.candidate_ids.append(entry.stack_entry_id)
	return decision


# 207.5.1b, 207.5.2 : le joueur à qui appartient l'effet choisit ses cibles parmi les légales.
static func _make_targets_decision(
	state: DuelState, entry: StackEntry, spec: TargetSpec
) -> PendingDecision:
	var decision := PendingDecision.new()
	decision.kind = PendingDecision.DecisionKind.CHOOSE_TARGETS
	decision.awaited_players.append(entry.owner)
	decision.subject_stack_entry_id = entry.stack_entry_id
	decision.candidate_ids.assign(_legal_ids(state, entry, spec))
	decision.candidate_cells.assign(EffectRules.legal_cells(state, entry.owner, spec))
	return decision


static func _legal_ids(state: DuelState, entry: StackEntry, spec: TargetSpec) -> Array[int]:
	return EffectRules.legal_target_ids(state, entry.owner, spec, entry.stack_entry_id)


# 207.5.1b : l'effet reçoit les cibles choisies.
static func _assign_targets(entry: StackEntry, intent: ChooseTargets) -> void:
	entry.target_piece_ids.assign(intent.target_piece_ids)
	entry.target_cells.assign(intent.target_cells)
	entry.target_stack_entry_ids.assign(intent.target_stack_entry_ids)


# 208.4.6, 208.4.7 : l'effet en attente que désigne `entry_id`.
static func _find_waiting(state: DuelState, entry_id: int) -> StackEntry:
	return _find_entry(state.waiting_triggers, entry_id)


# 207.5.1b : l'effet dont l'attente CHOOSE_TARGETS demande les cibles.
static func _targeted_entry(state: DuelState) -> StackEntry:
	return _find_entry(state.triggers_to_add, state.pending_decision.subject_stack_entry_id)


static func _find_entry(entries: Array[StackEntry], entry_id: int) -> StackEntry:
	for entry: StackEntry in entries:
		if entry.stack_entry_id == entry_id:
			return entry
	return null
