extends Control
## Essai de BoardView (décision 0030) : le Hero de A en C1 et celui de B en C5, un Soldat de A,
## un Héraut de B, les cases C2 et D1 surlignées. Un clic sur une case écrit sa notation.

const BOARD_SCENE: PackedScene = preload("res://ui/components/board_view.tscn")
const PIECE_SCENE: PackedScene = preload("res://ui/components/piece_view.tscn")
const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const SOLDIER_CELL := Vector2i(1, 0)
const HERALD_CELL := Vector2i(3, 3)
const HIGHLIGHTED_CELLS: Array[Vector2i] = [Vector2i(2, 1), Vector2i(3, 0)]

var _catalog: Catalog
var _next_piece_id: int = 0


func _ready() -> void:
	_catalog = TrySamples.catalog()
	var column := VBoxContainer.new()
	TrySamples.frame(self, column)
	var board: BoardView = BOARD_SCENE.instantiate()
	column.add_child(board)
	_put_hero(board, A)
	_put_hero(board, B)
	_put_card_piece(board, SOLDIER_CELL, &"soldat", A)
	_put_card_piece(board, HERALD_CELL, &"heraut", B)
	board.show_highlighted_cells(HIGHLIGHTED_CELLS)
	board.cell_pressed.connect(
		func(cell: Vector2i) -> void: print("case pressée ", BoardGeometry.cell_name(cell))
	)


func _put_hero(board: BoardView, side: DuelState.PlayerSide) -> void:
	var hero := _catalog.get_hero(TrySamples.HERO_ID)
	var piece := _new_piece(board, BoardGeometry.hero_start_cell(side))
	piece.show_hero(_next_piece_id, hero, side)
	piece.show_health(hero.health)


func _put_card_piece(
	board: BoardView, cell: Vector2i, card_id: StringName, side: DuelState.PlayerSide
) -> void:
	var definition := _catalog.get_card(card_id)
	var piece := _new_piece(board, cell)
	piece.show_card_piece(_next_piece_id, definition, side)
	piece.show_force(definition.force, definition.force)


func _new_piece(board: BoardView, cell: Vector2i) -> PieceView:
	_next_piece_id += 1
	var piece: PieceView = PIECE_SCENE.instantiate()
	board.put_piece(cell, piece)
	return piece
