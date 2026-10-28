class_name SelectionTarget
extends RefCounted
## Cible choisie à l'écran (décision 0024) : aucune, une pièce, une case ou une entrée de la pile.

## Genre d'une cible, dans l'ordre où l'assistant d'annonce les propose (décision 0068). Ajouter à
## la fin, sans réordonner.
enum TargetKind {
	PIECE,
	CELL,
	STACK_ENTRY,
}

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


## Nombre de cibles portées, tous genres confondus.
func count() -> int:
	return piece_ids.size() + cells.size() + stack_entry_ids.size()


## Genre de la cible : pièce d'abord, puis case, sinon entrée de la pile (décision 0068).
func kind() -> TargetKind:
	if not piece_ids.is_empty():
		return TargetKind.PIECE
	return TargetKind.CELL if not cells.is_empty() else TargetKind.STACK_ENTRY


## Les mêmes cibles dans le même ordre.
func is_same_as(other: SelectionTarget) -> bool:
	return (
		piece_ids == other.piece_ids
		and cells == other.cells
		and stack_entry_ids == other.stack_entry_ids
	)


## Vrai si l'une des cibles de `other` est déjà portée ici.
func overlaps(other: SelectionTarget) -> bool:
	for piece_id: int in other.piece_ids:
		if piece_ids.has(piece_id):
			return true
	for cell: Vector2i in other.cells:
		if cells.has(cell):
			return true
	for entry_id: int in other.stack_entry_ids:
		if stack_entry_ids.has(entry_id):
			return true
	return false


## Une nouvelle cible qui porte celles-ci puis celles de `other`.
func merged_with(other: SelectionTarget) -> SelectionTarget:
	var merged := SelectionTarget.new()
	merged.piece_ids.assign(piece_ids + other.piece_ids)
	merged.cells.assign(cells + other.cells)
	merged.stack_entry_ids.assign(stack_entry_ids + other.stack_entry_ids)
	return merged


## Renseigne les cibles de `intent`, un CastSpell, un AnnounceOrder ou un ChooseTargets.
func assign_to(intent: DuelIntent) -> void:
	if intent is CastSpell:
		var cast := intent as CastSpell
		cast.target_piece_ids.assign(piece_ids)
		cast.target_cells.assign(cells)
		cast.target_stack_entry_ids.assign(stack_entry_ids)
	elif intent is AnnounceOrder:
		var order := intent as AnnounceOrder
		order.target_piece_ids.assign(piece_ids)
		order.target_cells.assign(cells)
		order.target_stack_entry_ids.assign(stack_entry_ids)
	elif intent is ChooseTargets:
		var choice := intent as ChooseTargets
		choice.target_piece_ids.assign(piece_ids)
		choice.target_cells.assign(cells)
		choice.target_stack_entry_ids.assign(stack_entry_ids)
