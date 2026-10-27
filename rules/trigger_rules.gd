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


## 207.3.1, 207.3.3, 207.3.4, 207.3.12, 208.4.2 : les effets de `piece` et de son Gear déclenchés
## par `trigger_event` attendent leur ajout à la pile. Un Hero porte les siens (202.3.20), un jeton
## aucun (202.4.5) ; le Gear ne déclenche que tant qu'il est attaché à une Unit en jeu (207.3.12a).
static func trigger(
	state: DuelState,
	piece: Piece,
	trigger_event: EffectDefinition.TriggerEvent,
	events: Array[DuelEvent]
) -> void:
	_trigger_piece(state, piece, TriggerOccurrence.of_event(trigger_event), events)


## 204.3.12, 212.2.4 : chaque pièce en jeu de `side` réagit à `trigger_event` (décision 0060).
static func trigger_for_player(
	state: DuelState,
	side: DuelState.PlayerSide,
	trigger_event: EffectDefinition.TriggerEvent,
	events: Array[DuelEvent]
) -> void:
	_trigger_side(state, side, TriggerOccurrence.of_event(trigger_event), events)


## 208.4.4 : les pièces en jeu du joueur qui annonce `spell` réagissent à son annonce.
static func trigger_spell_announced(
	state: DuelState, spell: StackEntry, events: Array[DuelEvent]
) -> void:
	var announced := EffectDefinition.TriggerEvent.OWN_SPELL_ANNOUNCED
	_trigger_side(state, spell.owner, TriggerOccurrence.of_spell(announced, spell), events)


## 207.3.1, 207.6.4 : toutes les pièces en jeu réagissent au contrecarrage de `spell`.
static func trigger_spell_countered(
	state: DuelState, spell: StackEntry, events: Array[DuelEvent]
) -> void:
	var countered := EffectDefinition.TriggerEvent.SPELL_COUNTERED
	var occurrence := TriggerOccurrence.of_spell(countered, spell)
	for piece: Piece in state.pieces_on_board():
		_trigger_piece(state, piece, occurrence, events)


## 207.3.1, 207.3.15 : les pièces `destroyed` en même temps sont l'objet de « une autre pièce est
## détruite » pour chacune des `reactors`, les pièces en jeu avant la destruction.
static func trigger_other_destroyed(
	state: DuelState, destroyed: Array[Piece], reactors: Array[Piece], events: Array[DuelEvent]
) -> void:
	for piece: Piece in destroyed:
		var occurrence := TriggerOccurrence.of_destruction(piece)
		for reactor: Piece in reactors:
			_trigger_piece(state, reactor, occurrence, events)


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
	TriggerTargets.assign_chosen(entry, intent)
	reason = TriggerTargets.validate_effect_targets(state, entry, targeting_effect_of(state, entry))
	if reason != IntentRejected.RejectReason.NONE:
		return reason
	return TriggerTargets.validate_no_extra_targets(entry, text_of(state, entry).effects)


## 207.5.1b : l'effet reçoit ses cibles ; son ajout à la pile, puis celui des suivants, reprend
## par DuelEngine. Suppose l'intention validée.
static func apply_targets_choice(
	state: DuelState, intent: ChooseTargets, events: Array[DuelEvent]
) -> void:
	var entry := _targeted_entry(state)
	state.pending_decision = null
	TriggerTargets.assign_chosen(entry, intent)
	events.append(TargetsChosen.new(intent.player, entry.stack_entry_id))


## 209.4.11a, Q-110 : vrai si l'expiration du temps pendant le choix des cibles de l'effet
## attendu peut l'abandonner : aucun autre effet n'attend et il n'est pas « une fois par tour »,
## cas que le ruleset ne tranche pas. Pur.
static func can_abandon_targets_choice(state: DuelState) -> bool:
	var entry := _targeted_entry(state)
	if entry == null:
		return false
	var only_one_waiting := state.triggers_to_add.size() == 1 and state.waiting_triggers.is_empty()
	return only_one_waiting and not text_of(state, entry).once_per_turn


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


## 208.3.2a, 207.3.3, 207.5.3 à 207.5.5, 207.7.4 : le texte a lieu même si sa pièce a quitté le
## plateau ; ses effets s'appliquent dans l'ordre du texte (décision 0064). Après une attente qu'un
## effet a posée (décision 0057), la reprise continue au rang suivant.
static func resolve_triggered(
	state: DuelState, entry: StackEntry, events: Array[DuelEvent]
) -> void:
	EffectRules.resolve_text(state, entry, text_of(state, entry), events)


## 207.3.7 à 207.3.7c, 207.3.10 : clé du décompte « une fois par tour » du texte que porte `entry` :
## la carte qui le porte en x (Hero et Gear compris ; un jeton ne porte aucun texte, 202.4.5,
## 207.3.7a n'a donc pas d'objet), le rang du texte sur cette carte en y (décision 0064). Le couple
## (carte, rang) tient dans un `Vector2i` : x = `card_instance_id`, y = rang. Pur.
static func once_per_turn_key(entry: StackEntry) -> Vector2i:
	return Vector2i(entry.source_card_instance_id, entry.text_index)


## Décision 0064 : texte que porte `entry`.
static func text_of(state: DuelState, entry: StackEntry) -> EffectText:
	return state.catalog.triggerable_texts(entry.source_definition_id)[entry.text_index]


## Décision 0064, 207.5.1b : l'effet du texte de `entry` qui porte les cibles ; null si aucun.
static func targeting_effect_of(state: DuelState, entry: StackEntry) -> EffectDefinition:
	return text_of(state, entry).targeting_effect()


# 207.3.12a : le texte de la carte de `piece` et celui de son Gear, tant que la pièce est en jeu.
static func _trigger_piece(
	state: DuelState, piece: Piece, occurrence: TriggerOccurrence, events: Array[DuelEvent]
) -> void:
	if not piece.is_token():
		_trigger_card(state, piece, piece.card, occurrence, events)
	var gear := piece.attached_gear
	if gear != null and state.pieces.has(piece):
		_trigger_card(state, piece, gear, occurrence, events)


static func _trigger_side(
	state: DuelState,
	side: DuelState.PlayerSide,
	occurrence: TriggerOccurrence,
	events: Array[DuelEvent]
) -> void:
	for piece: Piece in state.pieces_on_board():
		if piece.owner == side:
			_trigger_piece(state, piece, occurrence, events)


# 207.3.13 : la condition « si » du texte se lit ici, à l'événement ; fausse, le texte ne se
# déclenche pas et ne compte donc pas pour « une fois par tour » (207.3.6).
static func _trigger_card(
	state: DuelState,
	piece: Piece,
	card: CardInstance,
	occurrence: TriggerOccurrence,
	events: Array[DuelEvent]
) -> void:
	var texts := state.catalog.triggerable_texts(card.definition_id)
	var reading := ValueReading.of_event(card.owner, piece, occurrence.spell)
	for index: int in texts.size():
		var text := texts[index]
		var is_triggered := text.timing == EffectDefinition.EffectTiming.TRIGGERED
		if not is_triggered or text.trigger != occurrence.event:
			continue
		var has_object := _has_object(state, text, piece, card.owner, occurrence)
		if has_object and ValueRules.condition_holds(state, text.condition, reading):
			_wait(state, piece, card, index, events)


# 207.3.1, décision 0065 : l'objet est celui que qualifie le texte pour `carrier`, la pièce qui le
# porte ; « une autre pièce » n'est jamais `carrier`. Dernière case d'une pièce partie : 207.3.14.
static func _has_object(
	state: DuelState,
	text: EffectText,
	carrier: Piece,
	owner: DuelState.PlayerSide,
	occurrence: TriggerOccurrence
) -> bool:
	var object := text.event_object
	match occurrence.event:
		EffectDefinition.TriggerEvent.OTHER_PIECE_DESTROYED:
			var destroyed := occurrence.destroyed_piece
			if destroyed == carrier:
				return false
			if object == null:
				return true
			var anchor := ModifierRules.reference_anchor(
				state, object, owner, carrier.piece_id, carrier.cell
			)
			return ModifierRules.matches_filter(object, anchor, destroyed)
		EffectDefinition.TriggerEvent.SPELL_COUNTERED:
			var side := PieceFilter.SideFilter.ANY if object == null else object.side
			return ModifierRules.is_on_side(side, owner, occurrence.spell.owner)
	return true


# 207.3.4, 207.3.12b : l'effet appartient au joueur à qui appartient la carte qui le porte, Gear
# compris ; son identifiant d'entrée lui est donné dès maintenant (décision 0017).
static func _wait(
	state: DuelState, piece: Piece, card: CardInstance, text_index: int, events: Array[DuelEvent]
) -> void:
	var entry := StackEntry.new()
	entry.stack_entry_id = state.allocate_stack_entry_id()
	entry.kind = StackEntry.StackEntryKind.TRIGGERED_EFFECT
	entry.owner = card.owner
	entry.source_piece_id = piece.piece_id
	entry.source_card_instance_id = card.card_instance_id
	entry.source_definition_id = card.definition_id
	entry.text_index = text_index
	entry.allows_response = state.triggers_allow_response  # 208.7.8 à 208.7.11
	state.waiting_triggers.append(entry)
	events.append(EffectTriggered.new(entry.owner, entry.stack_entry_id, piece.piece_id))


# 208.4.6, 208.4.7 : les effets du joueur actif, sinon ceux de son adversaire ; un seul effet
# s'ordonne sans demander (décision 0004).
static func _order_next_group(state: DuelState, events: Array[DuelEvent]) -> void:
	var addable: Array[StackEntry] = []
	for entry: StackEntry in _next_group(state):
		if _can_be_added(state, entry) and not _repeats_once_per_turn(state, entry, addable):
			addable.append(entry)
		else:
			_skip(state.waiting_triggers, entry, events)
	if addable.size() >= MIN_EFFECTS_TO_ORDER:
		StackRules.request_decision(state, _make_order_decision(addable), events)
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
	var effect := targeting_effect_of(state, entry)
	if effect != null and EffectRules.chosen_effect_count(entry, effect) == 0:
		if not TriggerTargets.has_unique_targets(state, entry, effect):
			StackRules.request_decision(
				state, TriggerTargets.make_decision(state, entry, effect), events
			)
			return
		TriggerTargets.assign_unique_targets(state, entry, effect, events)
	state.triggers_to_add.pop_front()
	if text_of(state, entry).once_per_turn:
		state.once_per_turn_texts.append(once_per_turn_key(entry))
	StackRules.add_to_stack(state, entry, events)


# 207.3.5a, 207.3.7, 207.3.10 ; 207.5.9, 207.5.10
static func _can_be_added(state: DuelState, entry: StackEntry) -> bool:
	if entry.kind == StackEntry.StackEntryKind.PENDING_COMBAT:
		return true
	if (
		text_of(state, entry).once_per_turn
		and state.once_per_turn_texts.has(once_per_turn_key(entry))
	):
		return false
	var effect := targeting_effect_of(state, entry)
	if effect == null:
		return true  # décision 0057 : un texte sans cible n'attend aucune cible légale
	return TriggerTargets.legal_count(state, entry, effect) >= effect.target.count_min


# 207.3.5, 207.3.5a, 207.3.7b, 212.2.5 : un second exemplaire du même texte « une fois par tour »,
# déjà dans `kept`, ne s'ajoutera pas à la pile ; un autre texte de la même carte, si.
static func _repeats_once_per_turn(
	state: DuelState, entry: StackEntry, kept: Array[StackEntry]
) -> bool:
	if entry.kind == StackEntry.StackEntryKind.PENDING_COMBAT:
		return false
	if not text_of(state, entry).once_per_turn:
		return false
	return kept.any(
		func(other: StackEntry) -> bool:
			return (
				other.kind != StackEntry.StackEntryKind.PENDING_COMBAT
				and (once_per_turn_key(other) == once_per_turn_key(entry))
			)
	)


# 207.3.5a, 207.5.9, 207.5.10 : l'effet est retiré sans avoir lieu, et l'événement le dit.
static func _skip(list: Array[StackEntry], entry: StackEntry, events: Array[DuelEvent]) -> void:
	list.erase(entry)
	events.append(TriggerSkipped.new(entry.owner, entry.stack_entry_id))


# 208.4.6, 208.4.7 : le joueur à qui appartiennent les effets choisit leur ordre.
static func _make_order_decision(entries: Array[StackEntry]) -> PendingDecision:
	var decision := PendingDecision.new()
	decision.kind = PendingDecision.DecisionKind.ORDER_TRIGGERS
	decision.awaited_players.append(entries[0].owner)
	for entry: StackEntry in entries:
		decision.candidate_ids.append(entry.stack_entry_id)
	return decision


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
