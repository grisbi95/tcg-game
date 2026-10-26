class_name EffectRules
extends RefCounted
## Effets qui passent par la pile (207) : cibles et validité (207.5), application à la
## résolution (207.4), Contrecarrer (207.6). Les Spells (207.1) sont dans SpellRules, qui appelle
## ce module ; celui-ci n'appelle jamais SpellRules. Les effets statiques se lisent dans
## ForceRules (207.2) ; les effets déclenchés attendent et s'ajoutent par TriggerRules.
##
## Une entrée porte ses cibles par genre (`target_piece_ids`, `target_cells`,
## `target_stack_entry_ids`) ; chaque effet lit celles du genre que vise sa TargetSpec.


## 207.5.1a, 207.5.2, 207.5.8, 207.5.10 : raison du refus des cibles que porte `entry` pour
## `spec`, ou NONE. `entry.owner` est le joueur qui choisit. Pur.
static func validate_targets(
	state: DuelState, entry: StackEntry, spec: TargetSpec
) -> IntentRejected.RejectReason:
	var target_count := chosen_count(entry, spec)
	if target_count < spec.count_min or target_count > spec.count_max:
		return IntentRejected.RejectReason.WRONG_TARGET_COUNT
	if not _all_targets_legal(state, entry, spec):
		return IntentRejected.RejectReason.ILLEGAL_TARGET
	return IntentRejected.RejectReason.NONE


## 207.5.1a, 207.5.8, 211.4.1, 211.4.2 : raison du refus des cibles que porte `entry` pour les
## `effects` d'un Spell ou d'un Ordre : chaque effet juge les cibles de son genre, aucune cible en
## trop. Pur.
static func validate_announced_targets(
	state: DuelState, entry: StackEntry, effects: Array[EffectDefinition]
) -> IntentRejected.RejectReason:
	for effect: EffectDefinition in effects:
		if effect.target == null:
			continue
		var reason := validate_targets(state, entry, effect.target)
		if reason != IntentRejected.RejectReason.NONE:
			return reason
	return validate_no_extra_targets(entry, effects)


## 207.5.1 : une entrée ne porte que les cibles qu'exigent ses effets ; tout autre genre de
## cible fait refuser l'annonce. Pur.
static func validate_no_extra_targets(
	entry: StackEntry, effects: Array[EffectDefinition]
) -> IntentRejected.RejectReason:
	var aimed: Array[TargetSpec.TargetWhat] = []
	for effect: EffectDefinition in effects:
		if effect.target != null:
			aimed.append(effect.target.what)
	var extra_pieces := not entry.target_piece_ids.is_empty()
	extra_pieces = extra_pieces and not aimed.has(TargetSpec.TargetWhat.PIECE)
	var extra_cells := not entry.target_cells.is_empty()
	extra_cells = extra_cells and not aimed.has(TargetSpec.TargetWhat.CELL)
	var extra_spells := not entry.target_stack_entry_ids.is_empty()
	extra_spells = extra_spells and not aimed.has(TargetSpec.TargetWhat.SPELL_ON_STACK)
	if extra_pieces or extra_cells or extra_spells:
		return IntentRejected.RejectReason.WRONG_TARGET_COUNT
	return IntentRejected.RejectReason.NONE


## 207.4.7a : un effet « tant que la pièce est en jeu » cesse pour `piece`, qui quitte le
## plateau ; un effet « jusqu'à la fin du tour » attend 207.4.3.
static func end_effects_on_piece(state: DuelState, piece: Piece, events: Array[DuelEvent]) -> void:
	var remaining: Array[ActiveEffect] = []
	for effect: ActiveEffect in state.active_effects:
		var lasting := effect.duration == ActiveEffect.EffectDuration.WHILE_PIECE_IN_PLAY
		if lasting and effect.affected_piece_id == piece.piece_id:
			events.append(ActiveEffectEnded.new(effect.effect_id))
		else:
			remaining.append(effect)
	state.active_effects = remaining


## 207.5.8, 207.5.10 : nombre de cibles légales pour `spec` d'une entrée de `owner`.
static func legal_target_count(
	state: DuelState, owner: DuelState.PlayerSide, spec: TargetSpec
) -> int:
	if spec.what == TargetSpec.TargetWhat.CELL:
		return legal_cells(state, owner, spec).size()
	return legal_target_ids(state, owner, spec, DuelState.NO_ID).size()


## 207.5.1b, 207.5.9 : pièces ou Spells de la pile légaux pour `spec` d'une entrée de `owner`,
## d'identifiant `entry_id` (jamais ciblée par elle-même, 207.5.16). Pur.
static func legal_target_ids(
	state: DuelState, owner: DuelState.PlayerSide, spec: TargetSpec, entry_id: int
) -> Array[int]:
	var ids: Array[int] = []
	if spec.what == TargetSpec.TargetWhat.PIECE:
		for piece: Piece in state.pieces:
			if is_legal_piece(state, owner, spec, piece):
				ids.append(piece.piece_id)
	elif spec.what == TargetSpec.TargetWhat.SPELL_ON_STACK:
		for entry: StackEntry in state.stack:
			if is_legal_spell(spec, entry, entry_id):
				ids.append(entry.stack_entry_id)
	return ids


## 207.5.1b, 207.5.9 : cases légales pour `spec` d'une entrée de `owner`. Pur.
static func legal_cells(
	state: DuelState, owner: DuelState.PlayerSide, spec: TargetSpec
) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell: Vector2i in BoardGeometry.all_cells():
		if is_legal_cell(state, owner, spec, cell):
			cells.append(cell)
	return cells


## 207.5.6, 207.5.11, 207.5.11a, 207.5.11b : `piece` remplit les conditions de `spec` pour une
## entrée de `owner` (côté, type de pièce, Force actuelle au plus `max_force`).
static func is_legal_piece(
	state: DuelState, owner: DuelState.PlayerSide, spec: TargetSpec, piece: Piece
) -> bool:
	if spec.what != TargetSpec.TargetWhat.PIECE or not BoardGeometry.is_on_board(piece.cell):
		return false
	if spec.side == TargetSpec.TargetSide.ALLY and piece.owner != owner:
		return false
	if spec.side == TargetSpec.TargetSide.ENEMY and piece.owner == owner:
		return false
	if not spec.piece_kinds.is_empty() and not spec.piece_kinds.has(piece.kind):
		return false
	var limited := spec.max_force != TargetSpec.NO_FORCE_LIMIT
	return not limited or ForceRules.current_force(state, piece) <= spec.max_force


## 202.4.12, 207.5.11 : une case ciblée est libre, sur la rangée qu'exige `spec`.
static func is_legal_cell(
	state: DuelState, owner: DuelState.PlayerSide, spec: TargetSpec, cell: Vector2i
) -> bool:
	if spec.what != TargetSpec.TargetWhat.CELL or not BoardGeometry.is_on_board(cell):
		return false
	if spec.row == TargetSpec.CellRow.OWN_FIRST and not BoardGeometry.is_in_first_row(owner, cell):
		return false
	return state.piece_at(cell) == null


## 207.5.14, 207.5.15, 207.5.16 : seul un Spell de la pile se cible, jamais l'entrée qui cible.
static func is_legal_spell(spec: TargetSpec, entry: StackEntry, targeting_entry_id: int) -> bool:
	if spec.what != TargetSpec.TargetWhat.SPELL_ON_STACK:
		return false
	if entry.kind != StackEntry.StackEntryKind.SPELL:
		return false
	return entry.stack_entry_id != targeting_entry_id


## 207.5.3 à 207.5.6, 207.4.6 : applique `effect` de `entry` à chacune de ses cibles restées
## valides ; sans aucune, l'effet n'a pas lieu (207.5.5).
static func resolve_effect(
	state: DuelState, entry: StackEntry, effect: EffectDefinition, events: Array[DuelEvent]
) -> void:
	var context := EffectContext.new(state, entry, effect, events)
	var spec := effect.target
	match spec.what:
		TargetSpec.TargetWhat.PIECE:
			var pieces := _valid_pieces(state, entry, spec)
			if pieces.is_empty():
				_lose_all_targets(entry, events)
				return
			for piece: Piece in pieces:
				_apply_to_piece(context, piece)
		TargetSpec.TargetWhat.CELL:
			var cells := _valid_cells(state, entry, spec)
			if cells.is_empty():
				_lose_all_targets(entry, events)
				return
			for cell: Vector2i in cells:
				_create_token(context, cell)
		TargetSpec.TargetWhat.SPELL_ON_STACK:
			var spells := _valid_spells(state, entry, spec)
			if spells.is_empty():
				_lose_all_targets(entry, events)
				return
			for spell: StackEntry in spells:
				counter_spell(state, spell, events)


## 207.4.1, 208.3.2 : applique, dans l'ordre, les effets à la résolution (`RESOLVE`) d'un Spell ou
## d'un Ordre ; s'arrête dès que la partie s'arrête (209.2.2).
static func resolve_all(
	state: DuelState, entry: StackEntry, effects: Array[EffectDefinition], events: Array[DuelEvent]
) -> void:
	for effect: EffectDefinition in effects:
		if effect.timing == EffectDefinition.EffectTiming.RESOLVE:
			resolve_effect(state, entry, effect, events)
		if state.is_ended():
			return


## 207.6.4, 207.6.5, 207.6.6 : le Spell `spell` quitte la pile sans se résoudre ; sa carte va
## dans la défausse de son joueur, son coût reste dépensé.
static func counter_spell(state: DuelState, spell: StackEntry, events: Array[DuelEvent]) -> void:
	state.stack.erase(spell)
	state.get_player(spell.card.owner).discard.append(spell.card)
	events.append(SpellCountered.new(spell.owner, spell.stack_entry_id))
	events.append(CardDiscarded.new(spell.card.owner, spell.card.card_instance_id))


## 207.5.10 : nombre de cibles du genre que vise `spec` portées par `entry`.
static func chosen_count(entry: StackEntry, spec: TargetSpec) -> int:
	match spec.what:
		TargetSpec.TargetWhat.CELL:
			return entry.target_cells.size()
		TargetSpec.TargetWhat.SPELL_ON_STACK:
			return entry.target_stack_entry_ids.size()
	return entry.target_piece_ids.size()


static func _all_targets_legal(state: DuelState, entry: StackEntry, spec: TargetSpec) -> bool:
	var target_count := chosen_count(entry, spec)
	match spec.what:
		TargetSpec.TargetWhat.CELL:
			return _valid_cells(state, entry, spec).size() == target_count
		TargetSpec.TargetWhat.SPELL_ON_STACK:
			return _valid_spells(state, entry, spec).size() == target_count
	return _valid_pieces(state, entry, spec).size() == target_count


# 207.5.3, 207.5.6, 207.5.6a
static func _valid_pieces(state: DuelState, entry: StackEntry, spec: TargetSpec) -> Array[Piece]:
	var pieces: Array[Piece] = []
	for piece_id: int in entry.target_piece_ids:
		var piece := state.find_piece(piece_id)
		if piece != null and is_legal_piece(state, entry.owner, spec, piece):
			pieces.append(piece)
	return pieces


# 202.4.12b
static func _valid_cells(state: DuelState, entry: StackEntry, spec: TargetSpec) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell: Vector2i in entry.target_cells:
		if is_legal_cell(state, entry.owner, spec, cell):
			cells.append(cell)
	return cells


# 207.5.3, 207.5.14 à 207.5.16
static func _valid_spells(
	state: DuelState, entry: StackEntry, spec: TargetSpec
) -> Array[StackEntry]:
	var spells: Array[StackEntry] = []
	for entry_id: int in entry.target_stack_entry_ids:
		var spell := state.find_stack_entry(entry_id)
		if spell != null and is_legal_spell(spec, spell, entry.stack_entry_id):
			spells.append(spell)
	return spells


# 207.5.5, 200.4.1
static func _lose_all_targets(entry: StackEntry, events: Array[DuelEvent]) -> void:
	events.append(EffectLostAllTargets.new(entry.owner, entry.stack_entry_id))


# 207.4.2, 206.5.1 : MODIFY_FORCE à durée ; 206.3.2 par DESTROY.
static func _apply_to_piece(context: EffectContext, piece: Piece) -> void:
	match context.effect.kind:
		EffectDefinition.EffectKind.MODIFY_FORCE:
			_add_force_modifier(context, piece)
		EffectDefinition.EffectKind.DESTROY:
			CombatRules.destroy_piece(context.state, piece, context.events)


# 207.4.2 : le modificateur de Force vit dans l'état avec sa durée.
static func _add_force_modifier(context: EffectContext, piece: Piece) -> void:
	var entry := context.entry
	var effect := context.effect
	var modifier := ActiveEffect.new()
	modifier.effect_id = context.state.allocate_active_effect_id()
	modifier.duration = effect.duration
	modifier.owner = entry.owner
	modifier.source_card_instance_id = (
		entry.card.card_instance_id if entry.card != null else DuelState.NO_ID
	)
	modifier.affected_piece_id = piece.piece_id
	modifier.effect_kind = EffectDefinition.kind_id(effect.kind)
	modifier.amount = effect.amount
	context.state.active_effects.append(modifier)
	context.events.append(
		ForceModified.new(piece.owner, piece.piece_id, effect.amount, modifier.effect_id)
	)


# 202.4.1, 202.4.8, 202.4.9, 202.4.12 ; 201.5.4, 201.5.4a : le jeton appartient au joueur de
# l'entrée qui le crée ; 205.5.4a : il naît endormi (`is_awake` reste faux).
static func _create_token(context: EffectContext, cell: Vector2i) -> void:
	var token := Piece.new()
	token.piece_id = context.state.allocate_piece_id()
	token.kind = context.effect.token_piece_kind
	token.owner = context.entry.owner
	token.cell = cell
	token.token_force = context.effect.token_force
	context.state.pieces.append(token)
	context.events.append(TokenCreated.new(token.owner, token.piece_id, cell))
