class_name TriggerTargets
extends RefCounted
## Cibles d'un effet déclenché en attente (207.5.1b, 207.5.2, 207.5.9, 207.5.10, décisions 0004,
## 0017 et 0056) : pièces et cases légales, choix unique pris par le moteur, attente des cibles.
## Appelé par TriggerRules, qui ajoute l'effet à la pile ; les filtres relatifs à la pièce source
## se lisent par `EffectRules.resolved_spec` (207.3.14).


## 207.5.9, 207.5.10 : nombre de cibles légales de l'effet ; pour un déplacement, une pièce ne
## compte que si une case lui est légale (215.1.1).
static func legal_count(state: DuelState, entry: StackEntry, effect: EffectDefinition) -> int:
	if effect.destination == null:
		var spec := EffectRules.resolved_spec(state, entry, effect.target)
		return EffectRules.legal_target_count(state, entry.owner, spec)
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
	option_count += EffectRules.legal_cells(state, entry.owner, spec).size()
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


# 207.5.9, 215.1.1 : cibles légales de l'effet ; un déplacement ne propose que les pièces qui ont
# au moins une case de destination légale.
static func _candidate_ids(
	state: DuelState, entry: StackEntry, effect: EffectDefinition
) -> Array[int]:
	var spec := EffectRules.resolved_spec(state, entry, effect.target)
	var ids := EffectRules.legal_target_ids(state, entry.owner, spec, entry.stack_entry_id)
	if effect.destination == null:
		return ids
	var destination := EffectRules.resolved_spec(state, entry, effect.destination)
	var movable: Array[int] = []
	for piece_id: int in ids:
		var piece := state.find_piece(piece_id)
		if not EffectRules.legal_cells(state, entry.owner, destination, piece).is_empty():
			movable.append(piece_id)
	return movable


# 207.5.1b, 215.1.1 : cases que l'entrée peut cibler ; pour un déplacement, les cases légales pour
# au moins l'une des pièces `piece_ids`.
static func _candidate_cells(
	state: DuelState, entry: StackEntry, effect: EffectDefinition, piece_ids: Array[int]
) -> Array[Vector2i]:
	if effect.destination == null:
		var spec := EffectRules.resolved_spec(state, entry, effect.target)
		return EffectRules.legal_cells(state, entry.owner, spec)
	var destination := EffectRules.resolved_spec(state, entry, effect.destination)
	var cells: Array[Vector2i] = []
	for piece_id: int in piece_ids:
		var piece := state.find_piece(piece_id)
		for cell: Vector2i in EffectRules.legal_cells(state, entry.owner, destination, piece):
			if not cells.has(cell):
				cells.append(cell)
	return cells
