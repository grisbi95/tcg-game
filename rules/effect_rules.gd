class_name EffectRules
extends RefCounted
## Effets qui passent par la pile (207) : cibles et validité (207.5), application à la
## résolution (207.4), Contrecarrer (207.6) ; filtres de pièce (`matches_filter`). SpellRules les
## appelle, jamais l'inverse ; TriggerRules ajoute les effets déclenchés, TriggerTargets lit les
## cibles légales.
##
## Une entrée porte ses cibles par genre (`target_piece_ids`, `target_cells`,
## `target_stack_entry_ids`) ; chaque effet lit celles du genre que vise sa TargetSpec. Un effet
## de déplacement (215) lit aussi la case de sa `destination` (décision 0056).


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
		var reason := validate_effect_targets(state, entry, effect)
		if reason != IntentRejected.RejectReason.NONE:
			return reason
	return validate_no_extra_targets(entry, effects)


## 207.5.1a, 207.5.10, 214.1.3, 215.1.1 : raison du refus des cibles que porte `entry` pour
## `effect`, destination comprise ; l'échange exige deux pièces distinctes (cartes, Q-098 reste
## ouverte en général). Pur.
static func validate_effect_targets(
	state: DuelState, entry: StackEntry, effect: EffectDefinition
) -> IntentRejected.RejectReason:
	var reason := validate_targets(state, entry, effect.target)
	if reason != IntentRejected.RejectReason.NONE:
		return reason
	return validate_destination_targets(state, entry, effect)


## 207.5.1 : une entrée ne porte que les cibles qu'exigent ses effets ; tout autre genre de
## cible fait refuser l'annonce. Pur.
static func validate_no_extra_targets(
	entry: StackEntry, effects: Array[EffectDefinition]
) -> IntentRejected.RejectReason:
	var aimed: Array[TargetSpec.TargetWhat] = []
	for effect: EffectDefinition in effects:
		if effect.target != null:
			aimed.append(effect.target.what)
		if effect.destination != null:
			aimed.append(effect.destination.what)
	var extra_pieces := not entry.target_piece_ids.is_empty()
	extra_pieces = extra_pieces and not aimed.has(TargetSpec.TargetWhat.PIECE)
	var extra_cells := not entry.target_cells.is_empty()
	extra_cells = extra_cells and not aimed.has(TargetSpec.TargetWhat.CELL)
	var extra_spells := not entry.target_stack_entry_ids.is_empty()
	extra_spells = extra_spells and not aimed.has(TargetSpec.TargetWhat.SPELL_ON_STACK)
	if extra_pieces or extra_cells or extra_spells:
		return IntentRejected.RejectReason.WRONG_TARGET_COUNT
	return IntentRejected.RejectReason.NONE


## 207.5.1, 214.1.3, 215.1.1 : raison du refus de ce que `entry` porte en plus des pièces déjà
## jugées pour `effect` : l'échange veut deux pièces distinctes (contrôle de ce `kind`, Q-098 reste
## ouverte en général), le déplacement une case de destination légale pour la pièce ciblée. Pur.
static func validate_destination_targets(
	state: DuelState, entry: StackEntry, effect: EffectDefinition
) -> IntentRejected.RejectReason:
	if (
		effect.kind == EffectDefinition.EffectKind.SWAP_CELLS
		and _has_duplicates(entry, effect.target)
	):
		return IntentRejected.RejectReason.ILLEGAL_TARGET
	if effect.destination == null:
		return IntentRejected.RejectReason.NONE
	var spec := resolved_spec(state, entry, effect.destination)
	var cell_count := chosen_count(entry, spec)
	if cell_count < spec.count_min or cell_count > spec.count_max:
		return IntentRejected.RejectReason.WRONG_TARGET_COUNT
	var anchor := state.find_piece(entry.target_piece_ids[0])
	for cell: Vector2i in entry.target_cells:
		if not is_legal_cell(state, entry.owner, spec, cell, anchor):
			return IntentRejected.RejectReason.ILLEGAL_TARGET
	return IntentRejected.RejectReason.NONE


## 207.5.6, 207.5.11, 207.5.11a, 207.5.11b : `piece` remplit les conditions de `spec` pour une
## entrée de `owner` (filtre de pièce, Force actuelle au plus `max_force`).
static func is_legal_piece(
	state: DuelState, owner: DuelState.PlayerSide, spec: TargetSpec, piece: Piece
) -> bool:
	if spec.what != TargetSpec.TargetWhat.PIECE or not BoardGeometry.is_on_board(piece.cell):
		return false
	if spec.max_force_is_x:
		return false  # 213.1.10 : une borne « X » non résolue (`TargetSpec.with_x`) n'admet rien
	if not ModifierRules.matches_filter(spec.piece_filter, spec_anchor(state, owner, spec), piece):
		return false
	var limited := spec.max_force != TargetSpec.NO_FORCE_LIMIT
	return not limited or ForceRules.current_force(state, piece) <= spec.max_force


## 207.5.6, 207.3.14, 205.2.5 : point de référence de `spec` pour une entrée de `owner` : le Hero du
## joueur, ou la pièce source de `spec` (`TargetSpec.with_source`).
static func spec_anchor(
	state: DuelState, owner: DuelState.PlayerSide, spec: TargetSpec
) -> FilterAnchor:
	if spec.piece_filter.relative_to == PieceFilter.RelativeTo.OWN_HERO:
		var hero := state.find_hero(owner)
		if hero == null:
			return FilterAnchor.new(owner)
		return FilterAnchor.new(owner, hero.piece_id, hero.cell)
	return FilterAnchor.new(owner, spec.source_piece_id, spec.source_cell)


## 202.4.12, 207.5.11, 215.1.1 : une case ciblée est libre, dans la zone qu'exige `spec` et, si
## `spec` le demande, adjacente à `anchor`, la pièce que cible le même effet.
static func is_legal_cell(
	state: DuelState,
	owner: DuelState.PlayerSide,
	spec: TargetSpec,
	cell: Vector2i,
	anchor: Piece = null
) -> bool:
	if spec.what != TargetSpec.TargetWhat.CELL or not BoardGeometry.is_on_board(cell):
		return false
	if spec.adjacent_to == TargetSpec.AdjacentTo.TARGET_PIECE:
		if anchor == null or not BoardGeometry.are_adjacent(anchor.cell, cell):
			return false
	if spec.adjacent_to == TargetSpec.AdjacentTo.SOURCE_PIECE:
		if not BoardGeometry.are_adjacent(spec.source_cell, cell):
			return false  # 207.3.14
	if not ModifierRules.is_in_row_zone(spec.row, owner, cell):
		return false
	return state.piece_at(cell) == null


## 207.5.14, 207.5.15, 207.5.16, 207.5.6 : seul un Spell de la pile se cible, jamais l'entrée qui
## cible, et seulement s'il remplit les filtres de `spec` : coût actuel, X compris (213.1.6,
## 213.1.7), et vitesse (207.1.2).
static func is_legal_spell(
	state: DuelState, spec: TargetSpec, entry: StackEntry, targeting_entry_id: int
) -> bool:
	if spec.what != TargetSpec.TargetWhat.SPELL_ON_STACK:
		return false
	if entry.kind != StackEntry.StackEntryKind.SPELL:
		return false
	if entry.stack_entry_id == targeting_entry_id:
		return false
	var definition := state.catalog.get_card(entry.card.definition_id)
	if not spec.spell_speeds.is_empty() and not spec.spell_speeds.has(definition.speed):
		return false
	var limited := spec.spell_max_cost != TargetSpec.NO_COST_LIMIT
	return not limited or ValueRules.current_cost(definition, entry) <= spec.spell_max_cost


## 207.5.3 à 207.5.6, 207.4.6 : applique `effect` de `entry` à chacune de ses cibles restées
## valides ; sans aucune, l'effet n'a pas lieu (207.5.5).
static func resolve_effect(
	state: DuelState, entry: StackEntry, effect: EffectDefinition, events: Array[DuelEvent]
) -> void:
	var context := EffectContext.new(state, entry, effect, events)
	match effect.kind:
		EffectDefinition.EffectKind.DRAW_CARDS:
			TurnRules.draw_cards(state, entry.owner, effect.amount, events)
			return
		EffectDefinition.EffectKind.DISCARD_CARDS:
			DiscardRules.resolve(context)
			return
		EffectDefinition.EffectKind.LOOK_AT_TOP_CARD:
			LookRules.resolve(context)
			return
		_ when effect.subject == EffectDefinition.EffectSubject.SOURCE_PIECE:
			_resolve_on_source_piece(context)
			return
		EffectDefinition.EffectKind.SWAP_CELLS:
			SwapRules.resolve(context)
			return
		EffectDefinition.EffectKind.MOVE_UNIT:
			MoveRules.resolve(context)
			return
		EffectDefinition.EffectKind.RETURN_TO_HAND:
			ReturnRules.resolve(context)
			return
	var spec := effect.target
	match spec.what:
		TargetSpec.TargetWhat.PIECE:
			var pieces := valid_pieces(state, entry, spec)
			if pieces.is_empty():
				lose_all_targets(entry, events)
				return
			var amount := ValueRules.read_amount(state, entry, effect, pieces)
			for piece: Piece in pieces:
				_apply_to_piece(context, piece, amount)
		TargetSpec.TargetWhat.CELL:
			var cells := _valid_cells(state, entry, spec)
			if cells.is_empty():
				lose_all_targets(entry, events)
				return
			for cell: Vector2i in cells:
				CardRules.create_token(context, cell)
		TargetSpec.TargetWhat.SPELL_ON_STACK:
			var spells := _valid_spells(state, entry, spec)
			if spells.is_empty():
				lose_all_targets(entry, events)
				return
			for spell: StackEntry in spells:
				counter_spell(state, spell, events)


## 207.4.1, 208.3.2 : applique, dans l'ordre, les effets à la résolution (`RESOLVE`) d'un Spell ou
## d'un Ordre ; s'arrête dès que la partie s'arrête (209.2.2). Décision 0057 : s'arrête aussi quand
## un effet pose une attente (212.1.3, 217.1.2) ; l'appel suivant reprend au rang retenu par
## `DuelState.resolving_effect_index`.
static func resolve_all(
	state: DuelState, entry: StackEntry, effects: Array[EffectDefinition], events: Array[DuelEvent]
) -> void:
	while state.resolving_effect_index < effects.size():
		var effect := effects[state.resolving_effect_index]
		state.resolving_effect_index += 1
		if effect.timing == EffectDefinition.EffectTiming.RESOLVE:
			resolve_effect(state, entry, effect, events)
		if state.is_ended() or state.pending_decision != null:
			return


## 207.6.4, 207.6.5, 207.6.6 : le Spell `spell` quitte la pile sans se résoudre ; sa carte va
## dans la défausse de son joueur, son coût reste dépensé.
static func counter_spell(state: DuelState, spell: StackEntry, events: Array[DuelEvent]) -> void:
	state.stack.erase(spell)
	state.get_player(spell.card.owner).discard.append(spell.card)
	events.append(SpellCountered.new(spell.owner, spell.stack_entry_id))
	events.append(CardDiscarded.new(spell.card.owner, spell.card.card_instance_id))


## 213.1.10, 213.1.11, 207.3.14 : `spec` où « X » vaut celui de `entry` et où la case de la pièce
## source est celle de `entry.source_piece_id`, sur le plateau ou la dernière qu'elle a occupée.
static func resolved_spec(state: DuelState, entry: StackEntry, spec: TargetSpec) -> TargetSpec:
	var cell := state.cell_of_piece(entry.source_piece_id)
	return spec.with_x(entry.x_value).with_source(entry.source_piece_id, cell)


## 207.5.10 : nombre de cibles du genre que vise `spec` portées par `entry`.
static func chosen_count(entry: StackEntry, spec: TargetSpec) -> int:
	match spec.what:
		TargetSpec.TargetWhat.CELL:
			return entry.target_cells.size()
		TargetSpec.TargetWhat.SPELL_ON_STACK:
			return entry.target_stack_entry_ids.size()
	return entry.target_piece_ids.size()


## 207.5.10, 215.1.1 : nombre de cibles que porte `entry` pour `effect`, destination comprise.
static func chosen_effect_count(entry: StackEntry, effect: EffectDefinition) -> int:
	var target_count := 0 if effect.target == null else chosen_count(entry, effect.target)
	if effect.destination != null:
		target_count += chosen_count(entry, effect.destination)
	return target_count


static func _all_targets_legal(state: DuelState, entry: StackEntry, spec: TargetSpec) -> bool:
	var target_count := chosen_count(entry, spec)
	if spec.distinct and _has_duplicates(entry, spec):
		return false
	match spec.what:
		TargetSpec.TargetWhat.CELL:
			return _valid_cells(state, entry, spec).size() == target_count
		TargetSpec.TargetWhat.SPELL_ON_STACK:
			return _valid_spells(state, entry, spec).size() == target_count
	return valid_pieces(state, entry, spec).size() == target_count


# 207.5.10, 214.1.3, Q-098 : deux cibles du même genre ne sont pas la même (« distinctes » écrit
# par la carte ; la règle générale reste ouverte).
static func _has_duplicates(entry: StackEntry, spec: TargetSpec) -> bool:
	if spec.what == TargetSpec.TargetWhat.CELL:
		for cell: Vector2i in entry.target_cells:
			if entry.target_cells.count(cell) > 1:
				return true
		return false
	for piece_id: int in entry.target_piece_ids:
		if entry.target_piece_ids.count(piece_id) > 1:
			return true
	return false


## 207.5.3, 207.5.6, 207.5.6a : pièces ciblées par `entry` restées valides pour `spec`.
static func valid_pieces(state: DuelState, entry: StackEntry, spec: TargetSpec) -> Array[Piece]:
	var pieces: Array[Piece] = []
	var limits := resolved_spec(state, entry, spec)
	for piece_id: int in entry.target_piece_ids:
		var piece := state.find_piece(piece_id)
		if piece != null and is_legal_piece(state, entry.owner, limits, piece):
			pieces.append(piece)
	return pieces


# 202.4.12b
static func _valid_cells(state: DuelState, entry: StackEntry, spec: TargetSpec) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var limits := resolved_spec(state, entry, spec)
	for cell: Vector2i in entry.target_cells:
		if is_legal_cell(state, entry.owner, limits, cell):
			cells.append(cell)
	return cells


# 207.5.3, 207.5.14 à 207.5.16
static func _valid_spells(
	state: DuelState, entry: StackEntry, spec: TargetSpec
) -> Array[StackEntry]:
	var spells: Array[StackEntry] = []
	for entry_id: int in entry.target_stack_entry_ids:
		var spell := state.find_stack_entry(entry_id)
		if spell != null and is_legal_spell(state, spec, spell, entry.stack_entry_id):
			spells.append(spell)
	return spells


## 207.5.5, 200.4.1 : l'effet de `entry` n'a pas lieu faute de cible valide.
static func lose_all_targets(entry: StackEntry, events: Array[DuelEvent]) -> void:
	events.append(EffectLostAllTargets.new(entry.owner, entry.stack_entry_id))


# 200.4.1, 207.3.12, décision 0062 : l'effet a pour sujet la pièce qui le porte (« cette Unit » ;
# pour un Gear, l'Unit qui le porte, 207.3.12) ; partie du plateau à la résolution, il n'a pas lieu
# pour elle, sans événement.
static func _resolve_on_source_piece(context: EffectContext) -> void:
	var source := context.state.find_piece(context.entry.source_piece_id)
	if source == null:
		return
	var pieces: Array[Piece] = [source]
	var amount := ValueRules.read_amount(context.state, context.entry, context.effect, pieces)
	_apply_to_piece(context, source, amount)


# 207.4.2, 206.5.1, 206.3.2, 205.5 : MODIFY_FORCE à durée ; DESTROY ; WAKE ; SLEEP.
static func _apply_to_piece(context: EffectContext, piece: Piece, amount: int) -> void:
	match context.effect.kind:
		EffectDefinition.EffectKind.MODIFY_FORCE:
			ModifierRules.add_force_modifier(context, piece, amount)
		EffectDefinition.EffectKind.GRANT_KEYWORD:
			ModifierRules.grant_keyword(context, piece, amount)
		EffectDefinition.EffectKind.DESTROY:
			CombatRules.destroy_piece(context.state, piece, context.events)
		EffectDefinition.EffectKind.WAKE:
			ActionRules.wake_pieces([piece], context.events)
		EffectDefinition.EffectKind.SLEEP:
			ActionRules.sleep_pieces([piece], context.events)
