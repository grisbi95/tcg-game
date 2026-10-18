class_name CardView
extends PanelContainer
## Carte de la main ou de l'aperçu (décision 0025) : nom, coût, type et Force, mots-clés, texte.
## Face cachée pour une carte que le joueur devant l'écran ne doit pas voir (201.4).

signal card_pressed(card_instance_id: int)
signal card_hovered(card_instance_id: int)
signal card_unhovered(card_instance_id: int)

const HIDDEN_TITLE: String = "Carte cachée"

var _card_instance_id: int = DuelState.NO_ID
var _owner_color: Color = DuelPalette.NEUTRAL_COLOR
var _is_highlighted: bool = false
var _is_selected: bool = false

@onready var _name_label: Label = %NameLabel
@onready var _cost_label: Label = %CostLabel
@onready var _type_label: Label = %TypeLabel
@onready var _keywords_label: Label = %KeywordsLabel
@onready var _text_label: Label = %TextLabel


func _ready() -> void:
	mouse_entered.connect(func() -> void: card_hovered.emit(_card_instance_id))
	mouse_exited.connect(func() -> void: card_unhovered.emit(_card_instance_id))
	_refresh_frame()


func _gui_input(event: InputEvent) -> void:
	if ViewInput.is_left_click(event):
		card_pressed.emit(_card_instance_id)
		accept_event()


## Montre `definition` pour la carte `card_instance_id` du joueur `owner`.
func show_card(
	card_instance_id: int, definition: CardDefinition, owner: DuelState.PlayerSide
) -> void:
	_card_instance_id = card_instance_id
	_owner_color = DuelPalette.player_color(owner)
	_name_label.text = definition.card_name
	_cost_label.text = CardText.cost_line(definition)
	_type_label.text = CardText.type_line(definition)
	_keywords_label.text = CardText.keywords_line(definition)
	_keywords_label.visible = not _keywords_label.text.is_empty()
	_text_label.text = definition.text
	_refresh_frame()


## 201.4 : dos de la carte `card_instance_id` du joueur `owner`.
func show_hidden(card_instance_id: int, owner: DuelState.PlayerSide) -> void:
	_card_instance_id = card_instance_id
	_owner_color = DuelPalette.player_color(owner)
	_name_label.text = HIDDEN_TITLE
	for label: Label in [_cost_label, _type_label, _keywords_label, _text_label]:
		label.text = ""
	_keywords_label.visible = false
	_refresh_frame()


## Carte en grand, pour l'aperçu : les variations agrandies du thème unique (décision 0025).
func set_large(is_large: bool) -> void:
	var line_variation := DuelPalette.LARGE_LABEL if is_large else &""
	for label: Label in [_name_label, _cost_label, _type_label, _keywords_label]:
		label.theme_type_variation = line_variation
	_text_label.theme_type_variation = (
		DuelPalette.LARGE_CARD_TEXT_LABEL if is_large else DuelPalette.CARD_TEXT_LABEL
	)


## Surlignée : la carte peut être choisie ; choisie : elle l'est.
func set_marks(is_highlighted: bool, is_selected: bool) -> void:
	_is_highlighted = is_highlighted
	_is_selected = is_selected
	_refresh_frame()


func _refresh_frame() -> void:
	var border := DuelPalette.marked_border(_owner_color, _is_highlighted, _is_selected)
	var style := DuelPalette.panel_style(border, _is_highlighted or _is_selected)
	add_theme_stylebox_override("panel", style)
