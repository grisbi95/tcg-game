class_name CellView
extends PanelContainer
## Case du plateau (201.2 ; décision 0028 : 143 px, coordonnées écrites hors du plateau) : la pièce
## qui l'occupe, et un surlignage quand la sélection la propose : bordure jaune, et un point au
## centre d'une case libre, pour ne pas dépendre de la seule couleur. Fond plus clair au survol. Sa
## notation reste en infobulle.

signal cell_pressed(cell: Vector2i)

## Décision 0028 : une case de 143 px, la pièce au centre à `PieceView.CELL_MARGIN` du bord.
const CELL_SIZE := PieceView.PIECE_SIZE + Vector2.ONE * PieceView.CELL_MARGIN * 2.0
const LINE_WIDTH: int = 1
const HIGHLIGHT_WIDTH: int = 4
const LEGAL_DOT_RADIUS: float = 8.0

var _cell: Vector2i = BoardGeometry.NO_CELL
var _is_highlighted: bool = false
var _is_hovered: bool = false

@onready var _piece_slot: CenterContainer = %PieceSlot


func _ready() -> void:
	custom_minimum_size = CELL_SIZE
	mouse_entered.connect(_on_hover_changed.bind(true))
	mouse_exited.connect(func() -> void: _on_hover_changed(_is_pointer_inside()))
	_refresh_frame()


func _draw() -> void:
	if _is_highlighted and _piece_slot.get_child_count() == 0:
		draw_circle(size / 2.0, LEGAL_DOT_RADIUS, DuelPalette.HIGHLIGHT_COLOR)


func _gui_input(event: InputEvent) -> void:
	if ViewInput.is_left_click(event):
		cell_pressed.emit(_cell)
		accept_event()


## 201.2.4 : la case `cell`, nommée de A1 à E5.
func show_cell(cell: Vector2i) -> void:
	_cell = cell
	tooltip_text = BoardGeometry.cell_name(cell)


## Place `piece_view` sur la case, à la place de la pièce précédente.
func put_piece(piece_view: PieceView) -> void:
	clear_piece()
	_piece_slot.add_child(piece_view)
	queue_redraw()


func clear_piece() -> void:
	ViewNodes.free_children(_piece_slot)
	queue_redraw()


func set_highlighted(is_highlighted: bool) -> void:
	_is_highlighted = is_highlighted
	_refresh_frame()


func _on_hover_changed(is_hovered: bool) -> void:
	_is_hovered = is_hovered
	_refresh_frame()


# Godot signale la sortie quand le pointeur passe sur la pièce : rester survolée tant qu'il est
# dans la case.
func _is_pointer_inside() -> bool:
	return Rect2(Vector2.ZERO, size).has_point(get_local_mouse_position())


func _refresh_frame() -> void:
	var background := DuelPalette.CELL_HOVER_COLOR if _is_hovered else DuelPalette.CELL_COLOR
	var style := DuelPalette.fill_style(
		background, DuelPalette.CORNER_RADIUS, PieceView.CELL_MARGIN
	)
	style.border_color = (
		DuelPalette.HIGHLIGHT_COLOR if _is_highlighted else DuelPalette.CELL_LINE_COLOR
	)
	style.set_border_width_all(HIGHLIGHT_WIDTH if _is_highlighted else LINE_WIDTH)
	add_theme_stylebox_override("panel", style)
	queue_redraw()
