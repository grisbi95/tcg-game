class_name BoardView
extends GridContainer
## Plateau 5×5 (201.2 ; décision 0030) : 25 CellView, la rangée 1 en bas et la rangée 5 en haut, les
## colonnes A à E de gauche à droite : le joueur A en bas (201.2.5). Décision 0050 : vu du joueur B,
## le plateau est tourné d'un demi-tour, rangée 5 en bas et colonne E à gauche. Les repères « 1 » à
## « 5 » sont à gauche ; « A » à « E » vivent dans `ColumnLettersView`, sous la barre de temps du
## bas. Le plateau mesure `COORDINATE_MARGIN` de plus que la grille en largeur ; les cases
## s'étendent si le parent donne plus que la taille minimale, la pièce restant centrée à sa taille.
## Les pièces viennent du parent ; un clic sur une case, pièce comprise, devient `cell_pressed`.

signal cell_pressed(cell: Vector2i)

## Fiche de l'écran de duel : cases de 139 px, écart de 4 px, soit 711×711.
const CELL_GAP: int = 4
const GRID_SIZE := (
	CellView.CELL_SIZE * float(BoardGeometry.COLUMN_COUNT)
	+ Vector2.ONE * float(CELL_GAP * (BoardGeometry.COLUMN_COUNT - 1))
)
## Largeur des repères des rangées, écart avec la grille compris : marge prise à gauche.
const COORDINATE_SIZE: float = 20.0
const COORDINATE_MARGIN: float = COORDINATE_SIZE + CELL_GAP

const CELL_SCENE: PackedScene = preload("res://ui/components/cell_view.tscn")

## Cadre de la grille : un fond d'encre à coins coupés et son ombre, sous les cases ; image
## `board_frame.png` (marge de 20 px autour de la grille) quand elle existe (décision 0071).
const FRAME_STYLE: StringName = &"BoardGrid"

var _cell_views: Dictionary[Vector2i, CellView] = {}


func _ready() -> void:
	# Le cadre image déborde de la grille : il passe sous les barres de temps voisines.
	z_index = -1
	sort_children.connect(queue_redraw)
	add_theme_constant_override("h_separation", CELL_GAP)
	add_theme_constant_override("v_separation", CELL_GAP)
	_build(DuelState.PlayerSide.A)


func _draw() -> void:
	if _cell_views.is_empty():
		return
	var grid := Rect2()
	var is_first := true
	for cell_view: CellView in _cell_views.values():
		var cell_rect := cell_view.get_rect()
		grid = cell_rect if is_first else grid.merge(cell_rect)
		is_first = false
	var style := get_theme_stylebox(&"panel", FRAME_STYLE)
	if style is StyleBoxTexture:
		grid = grid.grow(DuelAssets.BOARD_FRAME_IMAGE_MARGIN)
	draw_style_box(style, grid)


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


# Rangées de haut en bas, chacune précédée de son repère.
func _build(bottom_side: DuelState.PlayerSide) -> void:
	var rows := range(BoardGeometry.ROW_COUNT - 1, -1, -1)
	var column_indexes := range(BoardGeometry.COLUMN_COUNT)
	if bottom_side != DuelState.PlayerSide.A:
		rows.reverse()
		column_indexes.reverse()
	for row: int in rows:
		add_child(_make_row_label(str(row + 1)))
		for column: int in column_indexes:
			_add_cell(Vector2i(column, row))


func _add_cell(cell: Vector2i) -> void:
	var cell_view: CellView = CELL_SCENE.instantiate()
	cell_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(cell_view)
	cell_view.show_cell(cell)
	cell_view.cell_pressed.connect(cell_pressed.emit)
	_cell_views[cell] = cell_view


func _make_row_label(text: String) -> Label:
	var label := ColumnLettersView.make_coordinate_label(text)
	label.custom_minimum_size.x = COORDINATE_SIZE
	return label
