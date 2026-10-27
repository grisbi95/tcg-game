class_name TriggerTargets
extends RefCounted
## Cibles d'un effet déclenché en attente (207.5.1b, 207.5.2, 207.5.9, 207.5.10, décisions 0004,
## 0017 et 0056) : pièces et cases légales, choix unique pris par le moteur, attente des cibles ;
## et cibles d'un Spell ou d'un Ordre à l'annonce (207.5.1a, 207.5.8, 211.4.1, 211.4.2). Appelé
## par TriggerRules, qui ajoute l'effet à la pile, par SpellRules et par OrderRules ; les filtres
## relatifs à la pièce source se lisent par `EffectRules.resolved_spec` (207.3.14).


## 207.5.9, 207.5.10 : nombre de cibles légales de l'effet ; pour un déplacement, une pièce ne
## compte que si une case lui est légale (215.1.1).
static func legal_count(state: DuelState, entry: StackEntry, effect: EffectDefinition) -> int:
	if effect.destination == null:
		var spec := EffectRules.resolved_spec(state, entry, effect.target)
		return legal_target_count(state, entry.owner, spec)
	return _candidate_ids(state, entry, effect).size()


## 207.5.2, 207.5.10, décision 0004 : autant de cibles légales que le minimum exigé, un seul choix
## est possible ; sinon le joueur à qui appartient l'effet choisit ses cibles. Un déplacement n'a
## qu'un choix si une seule pièce est déplaçable, vers une seule case (décision 0056).
static func has_unique_targets(
	state: DuelState, entry: StackEntry, effect: EffectDefinition
) -> bool:
	var spec := EffectRules.resolved_spec(state, entry, effect.target)
	var piece_ids := _candidate_ids(state, entry, effect)
	var option_count := piece_ids.size()
	option_count += legal_cells(state, entry.owner, spec).size()
	if option_count != spec.count_min:
		return false
	if effect.destination == null:
		return true
	return _candidate_cells(state, entry, effect, piece_ids).size() == 1


## 207.5.1b, décision 0004 : le moteur prend toutes les cibles légales, sans demander.
static func assign_unique_targets(
	state: DuelState, entry: StackEntry, effect: EffectDefinition, events: Array[DuelEvent]
) -> void:
	var target_ids := _candidate_ids(state, entry, effect)
	entry.target_cells.assign(_candidate_cells(state, entry, effect, target_ids))
	if effect.target.what == TargetSpec.TargetWhat.SPELL_ON_STACK:
		entry.target_stack_entry_ids.assign(target_ids)
	else:
		entry.target_piece_ids.assign(target_ids)
	var targeting := PendingDecision.DecisionKind.CHOOSE_TARGETS
	events.append(DecisionResolvedAutomatically.new(entry.owner, targeting))


## 207.5.1b, 207.5.2 : le joueur à qui appartient l'effet choisit ses cibles parmi les légales.
static func make_decision(
	state: DuelState, entry: StackEntry, effect: EffectDefinition
) -> PendingDecision:
	var decision := PendingDecision.new()
	decision.kind = PendingDecision.DecisionKind.CHOOSE_TARGETS
	decision.awaited_players.append(entry.owner)
	decision.subject_stack_entry_id = entry.stack_entry_id
	decision.candidate_ids.assign(_candidate_ids(state, entry, effect))
	decision.candidate_cells.assign(_candidate_cells(state, entry, effect, decision.candidate_ids))
	return decision


## 207.5.1b : l'effet reçoit les cibles choisies.
static func assign_chosen(entry: StackEntry, intent: ChooseTargets) -> void:
	entry.target_piece_ids.assign(intent.target_piece_ids)
	entry.target_cells.assign(intent.target_cells)
	entry.target_stack_entry_ids.assign(intent.target_stack_entry_ids)


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
	var reason := EffectRules.validate_targets(state, entry, effect.target)
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
		and EffectRules.has_duplicates(entry, effect.target)
	):
		return IntentRejected.RejectReason.ILLEGAL_TARGET
	if effect.destination == null:
		return IntentRejected.RejectReason.NONE
	var spec := EffectRules.resolved_spec(state, entry, effect.destination)
	var cell_count := EffectRules.chosen_count(entry, spec)
	if cell_count < spec.count_min or cell_count > spec.count_max:
		return IntentRejected.RejectReason.WRONG_TARGET_COUNT
	var anchor := state.find_piece(entry.target_piece_ids[0])
	for cell: Vector2i in entry.target_cells:
		if not EffectRules.is_legal_cell(state, entry.owner, spec, cell, anchor):
			return IntentRejected.RejectReason.ILLEGAL_TARGET
	return IntentRejected.RejectReason.NONE


# 207.5.9, 215.1.1 : cibles légales de l'effet ; un déplacement ne propose que les pièces qui ont
# au moins une case de destination légale.
static func _candidate_ids(
	state: DuelState, entry: StackEntry, effect: EffectDefinition
) -> Array[int]:
	var spec := EffectRules.resolved_spec(state, entry, effect.target)
	var ids := legal_target_ids(state, entry.owner, spec, entry.stack_entry_id)
	if effect.destination == null:
		return ids
	var destination := EffectRules.resolved_spec(state, entry, effect.destination)
	var movable: Array[int] = []
	for piece_id: int in ids:
		var piece := state.find_piece(piece_id)
		if not legal_cells(state, entry.owner, destination, piece).is_empty():
			movable.append(piece_id)
	return movable


# 207.5.1b, 215.1.1 : cases que l'entrée peut cibler ; pour un déplacement, les cases légales pour
# au moins l'une des pièces `piece_ids`.
static func _candidate_cells(
	state: DuelState, entry: StackEntry, effect: EffectDefinition, piece_ids: Array[int]
) -> Array[Vector2i]:
	if effect.destination == null:
		var spec := EffectRules.resolved_spec(state, entry, effect.target)
		return legal_cells(state, entry.owner, spec)
	var destination := EffectRules.resolved_spec(state, entry, effect.destination)
	var cells: Array[Vector2i] = []
	for piece_id: int in piece_ids:
		var piece := state.find_piece(piece_id)
		for cell: Vector2i in legal_cells(state, entry.owner, destination, piece):
			if not cells.has(cell):
				cells.append(cell)
	return cells


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
			if EffectRules.is_legal_piece(state, owner, spec, piece):
				ids.append(piece.piece_id)
	elif spec.what == TargetSpec.TargetWhat.SPELL_ON_STACK:
		for entry: StackEntry in state.stack:
			if EffectRules.is_legal_spell(state, spec, entry, entry_id):
				ids.append(entry.stack_entry_id)
	return ids


## 207.5.1b, 207.5.9 : cases légales pour `spec` d'une entrée de `owner`. Pur.
static func legal_cells(
	state: DuelState, owner: DuelState.PlayerSide, spec: TargetSpec, anchor: Piece = null
) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell: Vector2i in BoardGeometry.all_cells():
		if EffectRules.is_legal_cell(state, owner, spec, cell, anchor):
			cells.append(cell)
	return cells
