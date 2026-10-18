class_name SelectionTarget
extends RefCounted
## Cible choisie à l'écran (décision 0024) : aucune, une pièce, une case ou une entrée de la pile.

var piece_ids: Array[int] = []
var cells: Array[Vector2i] = []
var stack_entry_ids: Array[int] = []


static func of_piece(piece_id: int) -> SelectionTarget:
	var target := SelectionTarget.new()
	target.piece_ids.append(piece_id)
	return target


static func of_cell(cell: Vector2i) -> SelectionTarget:
	var target := SelectionTarget.new()
	target.cells.append(cell)
	return target


static func of_stack_entry(stack_entry_id: int) -> SelectionTarget:
	var target := SelectionTarget.new()
	target.stack_entry_ids.append(stack_entry_id)
	return target


## Chaque cible possible de `state`, une par pièce, par case et par entrée de la pile ; le moteur
## dit ensuite lesquelles sont légales.
static func all_in(state: DuelState) -> Array[SelectionTarget]:
	var targets: Array[SelectionTarget] = []
	for piece: Piece in state.pieces:
		targets.append(of_piece(piece.piece_id))
	for cell: Vector2i in BoardGeometry.all_cells():
		targets.append(of_cell(cell))
	for entry: StackEntry in state.stack:
		targets.append(of_stack_entry(entry.stack_entry_id))
	return targets


## Renseigne les cibles de `intent`, un CastSpell, un UseHeroPower ou un ChooseTargets.
func assign_to(intent: DuelIntent) -> void:
	if intent is CastSpell:
		var cast := intent as CastSpell
		cast.target_piece_ids.assign(piece_ids)
		cast.target_cells.assign(cells)
		cast.target_stack_entry_ids.assign(stack_entry_ids)
	elif intent is UseHeroPower:
		var power := intent as UseHeroPower
		power.target_piece_ids.assign(piece_ids)
		power.target_cells.assign(cells)
		power.target_stack_entry_ids.assign(stack_entry_ids)
	elif intent is ChooseTargets:
		var choice := intent as ChooseTargets
		choice.target_piece_ids.assign(piece_ids)
		choice.target_cells.assign(cells)
		choice.target_stack_entry_ids.assign(stack_entry_ids)
