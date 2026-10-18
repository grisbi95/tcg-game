class_name CellView
extends PanelContainer
## Case du plateau (201.2, décision 0025) : sa notation, la pièce qui l'occupe, et un surlignage
## quand la sélection la propose.

signal cell_pressed(cell: Vector2i)

var _cell: Vector2i = BoardGeometry.NO_CELL
var _is_highlighted: bool = false

@onready var _cell_label: Label = %CellLabel
@onready var _piece_slot: CenterContainer = %PieceSlot


func _ready() -> void:
	_refresh_frame()


func _gui_input(event: InputEvent) -> void:
	if ViewInput.is_left_click(event):
		cell_pressed.emit(_cell)
		accept_event()


## 201.2.4 : la case `cell`, nommée de A1 à E5.
func show_cell(cell: Vector2i) -> void:
	_cell = cell
	_cell_label.text = BoardGeometry.cell_name(cell)


## Place `piece_view` sur la case, à la place de la pièce précédente.
func put_piece(piece_view: PieceView) -> void:
	clear_piece()
	_piece_slot.add_child(piece_view)


func clear_piece() -> void:
	ViewNodes.free_children(_piece_slot)


func set_highlighted(is_highlighted: bool) -> void:
	_is_highlighted = is_highlighted
	_refresh_frame()


func _refresh_frame() -> void:
	var border := DuelPalette.marked_border(DuelPalette.NEUTRAL_COLOR, _is_highlighted, false)
	add_theme_stylebox_override("panel", DuelPalette.panel_style(border, _is_highlighted))
