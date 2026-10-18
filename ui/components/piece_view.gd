class_name PieceView
extends PanelContainer
## Pièce sur le plateau (décision 0025) : nom, Force actuelle ou PV du Hero, Gear attaché. Les
## valeurs viennent du parent, qui les lit dans le moteur : rien n'est calculé ici.

signal piece_pressed(piece_id: int)

var _piece_id: int = DuelState.NO_ID
var _owner_color: Color = DuelPalette.NEUTRAL_COLOR
var _is_highlighted: bool = false
var _is_selected: bool = false

@onready var _name_label: Label = %NameLabel
@onready var _stat_label: Label = %StatLabel
@onready var _gear_label: Label = %GearLabel


func _ready() -> void:
	_refresh_frame()


func _gui_input(event: InputEvent) -> void:
	if ViewInput.is_left_click(event):
		piece_pressed.emit(_piece_id)
		accept_event()


## Unit, Building ou jeton : `force` est sa Force actuelle (209.1).
func show_unit(piece_id: int, piece_name: String, owner: DuelState.PlayerSide, force: int) -> void:
	_show(piece_id, piece_name, owner, CardText.force_line(force))


## Hero : `health` est son nombre de PV (202.3.7).
func show_hero(piece_id: int, hero_name: String, owner: DuelState.PlayerSide, health: int) -> void:
	_show(piece_id, hero_name, owner, "PV %d" % health)


## Nom du Gear attaché ; vide sans Gear (202.2.8).
func show_gear(gear_name: String) -> void:
	_gear_label.text = gear_name
	_gear_label.visible = not gear_name.is_empty()


func set_marks(is_highlighted: bool, is_selected: bool) -> void:
	_is_highlighted = is_highlighted
	_is_selected = is_selected
	_refresh_frame()


func _show(piece_id: int, piece_name: String, owner: DuelState.PlayerSide, stat: String) -> void:
	_piece_id = piece_id
	_owner_color = DuelPalette.player_color(owner)
	_name_label.text = piece_name
	_stat_label.text = stat
	_refresh_frame()


func _refresh_frame() -> void:
	var border := DuelPalette.marked_border(_owner_color, _is_highlighted, _is_selected)
	add_theme_stylebox_override(
		"panel", DuelPalette.panel_style(border, _is_highlighted or _is_selected)
	)
