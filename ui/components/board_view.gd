class_name BoardView
extends GridContainer
## Plateau 5×5 (201.2 ; décision 0030) : 25 CellView, la rangée 1 en bas et la rangée 5 en haut, les
## colonnes A à E de gauche à droite : le joueur A en bas (201.2.5). Décision 0050 : vu du joueur B,
## le plateau est tourné d'un demi-tour, rangée 5 en bas et colonne E à gauche. Les repères « A » à
## « E » sont sous la grille, « 1 » à « 5 » à gauche. Le parent pose la grille au pixel : le coin
## haut-gauche de la grille est à `GRID_OFFSET` du coin du plateau. Les pièces viennent du parent ;
## un clic sur une case, pièce comprise, devient `cell_pressed`.

signal cell_pressed(cell: Vector2i)

## Décision 0030 : cases de 143 px, écart de 4 px, soit 731×731.
const CELL_GAP: int = 4
const GRID_SIZE := (
	CellView.CELL_SIZE * float(BoardGeometry.COLUMN_COUNT)
	+ Vector2.ONE * float(CELL_GAP * (BoardGeometry.COLUMN_COUNT - 1))
)
## Côté des repères, écart avec la grille compris : marge prise à gauche et en dessous.
const COORDINATE_SIZE: float = 20.0
const COORDINATE_MARGIN: float = COORDINATE_SIZE + CELL_GAP
## Position de la grille dans le plateau ; le plateau mesure `GRID_SIZE + COORDINATE_MARGIN`
## en largeur et en hauteur.
const GRID_OFFSET := Vector2(COORDINATE_MARGIN, 0.0)

const CELL_SCENE: PackedScene = preload("res://ui/components/cell_view.tscn")

var _cell_views: Dictionary[Vector2i, CellView] = {}


func _ready() -> void:
	add_theme_constant_override("h_separation", CELL_GAP)
	add_theme_constant_override("v_separation", CELL_GAP)
	_build(DuelState.PlayerSide.A)


## Décision 0050 : redessine la grille vue du côté de `bottom_side`, avant de poser les pièces.
func show_from_side(bottom_side: DuelState.PlayerSide) -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_cell_views.clear()
	_build(bottom_side)


## Place `piece_view` sur la case `cell`, à la place de sa pièce précédente.
func put_piece(cell: Vector2i, piece_view: PieceView) -> void:
	_cell_views[cell].put_piece(piece_view)


## Retire les pièces de toutes les cases, avant un recalage sur l'état.
func clear_pieces() -> void:
	for cell_view: CellView in _cell_views.values():
		cell_view.clear_piece()


## Surligne les cases de `cells` (proposées par la sélection), pas les autres.
func show_highlighted_cells(cells: Array[Vector2i]) -> void:
	for cell: Vector2i in _cell_views:
		_cell_views[cell].set_highlighted(cells.has(cell))


# Rangées de haut en bas, chacune précédée de son repère, puis la ligne des lettres.
func _build(bottom_side: DuelState.PlayerSide) -> void:
	var rows := range(BoardGeometry.ROW_COUNT - 1, -1, -1)
	var column_indexes := range(BoardGeometry.COLUMN_COUNT)
	if bottom_side != DuelState.PlayerSide.A:
		rows.reverse()
		column_indexes.reverse()
	for row: int in rows:
		add_child(_make_coordinate(str(row + 1), true))
		for column: int in column_indexes:
			_add_cell(Vector2i(column, row))
	add_child(Control.new())
	for column: int in column_indexes:
		var letter := BoardGeometry.cell_name(Vector2i(column, 0)).left(1)
		add_child(_make_coordinate(letter, false))


func _add_cell(cell: Vector2i) -> void:
	var cell_view: CellView = CELL_SCENE.instantiate()
	add_child(cell_view)
	cell_view.show_cell(cell)
	cell_view.cell_pressed.connect(cell_pressed.emit)
	_cell_views[cell] = cell_view


func _make_coordinate(text: String, is_row: bool) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"BoardCoordinateLabel"
	label.add_theme_color_override("font_color", DuelPalette.MUTED_COLOR)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if is_row:
		label.custom_minimum_size.x = COORDINATE_SIZE
	else:
		label.custom_minimum_size.y = COORDINATE_SIZE
	return label
