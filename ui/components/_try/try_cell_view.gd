extends Control
## Essai de CellView : un plateau 5×5 (201.2), deux pièces posées, la première rangée de A
## surlignée. Un clic sur une case inverse son surlignage.

const CELL_SCENE: PackedScene = preload("res://ui/components/cell_view.tscn")
const PIECE_SCENE: PackedScene = preload("res://ui/components/piece_view.tscn")
const HERO_HEALTH: int = 15
const UNIT_FORCE: int = 3

var _highlighted_cells: Array[Vector2i] = []


func _ready() -> void:
	var grid := GridContainer.new()
	grid.columns = BoardGeometry.COLUMN_COUNT
	TrySamples.frame(self, grid)
	for cell: Vector2i in TrySamples.cells_in_display_order():
		var cell_view: CellView = CELL_SCENE.instantiate()
		grid.add_child(cell_view)
		cell_view.show_cell(cell)
		if BoardGeometry.is_in_first_row(DuelState.PlayerSide.A, cell):
			_highlighted_cells.append(cell)
		cell_view.set_highlighted(_highlighted_cells.has(cell))
		cell_view.cell_pressed.connect(func(pressed: Vector2i) -> void: _toggle(cell_view, pressed))
		_place_sample_piece(cell_view, cell)


func _place_sample_piece(cell_view: CellView, cell: Vector2i) -> void:
	if cell == BoardGeometry.hero_start_cell(DuelState.PlayerSide.A):
		var hero: PieceView = PIECE_SCENE.instantiate()
		cell_view.put_piece(hero)
		hero.show_hero(0, "Capitaine", DuelState.PlayerSide.A, HERO_HEALTH)
	elif cell == BoardGeometry.hero_start_cell(DuelState.PlayerSide.B):
		var unit: PieceView = PIECE_SCENE.instantiate()
		cell_view.put_piece(unit)
		unit.show_unit(1, "Soldat", DuelState.PlayerSide.B, UNIT_FORCE)


func _toggle(cell_view: CellView, cell: Vector2i) -> void:
	if _highlighted_cells.has(cell):
		_highlighted_cells.erase(cell)
	else:
		_highlighted_cells.append(cell)
	cell_view.set_highlighted(_highlighted_cells.has(cell))
	print("case pressée ", BoardGeometry.cell_name(cell))
