class_name CardView
extends PanelContainer
## Carte de la main ou de l'aperçu (décision 0027) : coût, nom et Force en haut ; l'illustration,
## remplacée par l'icône du type tant qu'il n'y en a pas ; bandeau de type et vitesse d'un Spell ;
## texte, mots-clés en étiquettes. Toute la carte prend la teinte de son type ; ses marques de
## survol, de surlignage et de choix sont des anneaux (DuelMarks). Le dos d'une carte est une
## CardBackView.

signal card_pressed(card_instance_id: int)
signal card_hovered(card_instance_id: int)
signal card_unhovered(card_instance_id: int)

## Décision 0028 : carte de la main et de la défausse, au format 63:88 ; l'aperçu l'agrandit.
const CARD_SIZE := Vector2(158, 220)
const PILL_SIZE: float = 26.0
const ART_ICON_SIZE: float = 40.0
const BAND_ICON_SIZE: float = 14.0
const HEART_ICON_SIZE: float = 11.0
const TEXT_HEIGHT: float = 84.0
const CARD_MARGIN: float = 7.0
const TEXT_MARGIN: float = 5.0
const ART_RADIUS: int = 6

var _card_instance_id: int = DuelState.NO_ID
var _tint: DuelPalette.Tint = DuelPalette.Tint.UNIT
var _is_hovered: bool = false
var _is_highlighted: bool = false
var _is_selected: bool = false
var _scale: float = 1.0

@onready var _layout: VBoxContainer = %Layout
@onready var _header: HBoxContainer = %Header
@onready var _cost_pill: PanelContainer = %CostPill
@onready var _cost_label: Label = %CostLabel
@onready var _name_label: Label = %NameLabel
@onready var _stat_pill: PanelContainer = %StatPill
@onready var _heart_icon: Control = %HeartIcon
@onready var _stat_label: Label = %StatLabel
@onready var _art: PanelContainer = %Art
@onready var _art_icon: Control = %ArtIcon
@onready var _band: HBoxContainer = %Band
@onready var _band_icon: Control = %BandIcon
@onready var _type_label: Label = %TypeLabel
@onready var _speed_label: Label = %SpeedLabel
@onready var _text_panel: PanelContainer = %TextPanel
@onready var _text_label: RichTextLabel = %TextLabel


func _ready() -> void:
	mouse_entered.connect(_on_hover_changed.bind(true))
	mouse_exited.connect(_on_hover_changed.bind(false))
	var type_icon := func() -> DuelIcons.Icon: return DuelIcons.TINT_ICONS[_tint]
	var ink := func() -> Color: return DuelPalette.TINT_INKS[_tint]
	DuelIcons.bind(_art_icon, type_icon, ink)
	DuelIcons.bind(_band_icon, type_icon, ink)
	DuelIcons.bind(_heart_icon, func() -> DuelIcons.Icon: return DuelIcons.Icon.HEART, ink)
	_cost_label.add_theme_color_override("font_color", DuelPalette.COST_INK_COLOR)
	_stat_label.add_theme_color_override("font_color", DuelPalette.CARD_TEXT_COLOR)
	_text_label.add_theme_color_override("default_color", DuelPalette.CARD_TEXT_COLOR)
	_apply_scale()


func _draw() -> void:
	var mark := DuelMarks.mark_of(_is_hovered, _is_highlighted, _is_selected)
	DuelMarks.draw(self, Rect2(Vector2.ZERO, size), mark, 0.0)


func _gui_input(event: InputEvent) -> void:
	if ViewInput.is_left_click(event):
		card_pressed.emit(_card_instance_id)
		accept_event()


## Carte `card_instance_id` de deck (202.1) : la Force n'apparaît que pour une Unit ou un Building.
func show_card(card_instance_id: int, definition: CardDefinition) -> void:
	_card_instance_id = card_instance_id
	_show_face(DuelPalette.tint_of(definition.card_type), definition.card_name)
	_cost_pill.visible = true
	_cost_label.text = str(definition.cost)
	_show_stat(definition.force != CardDefinition.NO_FORCE, definition.force, false)
	_type_label.text = CardText.type_name(definition.card_type)
	_speed_label.text = CardText.speed_name(definition)
	_text_label.text = CardText.body_bbcode(definition)


## Carte d'un Hero (202.3) : ses PV avec un cœur à la place de la Force, sans coût.
func show_hero(hero: HeroDefinition) -> void:
	_card_instance_id = DuelState.NO_ID
	_show_face(DuelPalette.Tint.HERO, hero.hero_name)
	_cost_pill.visible = false
	_show_stat(true, hero.health, true)
	_type_label.text = CardText.HERO_TYPE_NAME
	_speed_label.text = ""
	_text_label.text = CardText.hero_body_bbcode(hero)


## Jeton (202.4) sans carte, de type `card_type` et de Force `force` : nommé « Jeton », sans texte.
func show_token(card_type: CardDefinition.CardType, force: int) -> void:
	_card_instance_id = DuelState.NO_ID
	_show_face(DuelPalette.tint_of(card_type), CardText.TOKEN_NAME)
	_cost_pill.visible = false
	_show_stat(true, force, false)
	_type_label.text = CardText.token_type_name(card_type)
	_speed_label.text = ""
	_text_label.text = ""


## Taille de la carte : 1 en main, plus en aperçu ; textes, pastilles et marges suivent.
func set_card_scale(card_scale: float) -> void:
	_scale = card_scale
	_apply_scale()


## Surlignée : la carte peut être choisie ; choisie : elle l'est.
func set_marks(is_highlighted: bool, is_selected: bool) -> void:
	_is_highlighted = is_highlighted
	_is_selected = is_selected
	queue_redraw()


func _show_face(tint: DuelPalette.Tint, card_name: String) -> void:
	_tint = tint
	_name_label.text = card_name
	var ink := DuelPalette.TINT_INKS[tint]
	for label: Label in [_name_label, _type_label, _speed_label]:
		label.add_theme_color_override("font_color", ink)
	for icon: Control in [_art_icon, _band_icon, _heart_icon]:
		icon.queue_redraw()
	_refresh_frame()


func _show_stat(is_shown: bool, value: int, is_health: bool) -> void:
	_stat_pill.visible = is_shown
	_heart_icon.visible = is_health
	_stat_label.text = str(value)


# Les tailles du thème valent pour l'échelle 1 ; la carte agrandie les multiplie par `_scale`.
func _apply_scale() -> void:
	custom_minimum_size = CARD_SIZE * _scale
	_scale_constant(_layout, &"CardColumn", &"separation")
	for row: HBoxContainer in [_header, _band]:
		_scale_constant(row, &"CardRow", &"separation")
	for label: Label in [_cost_label, _stat_label]:
		_scale_font(label, &"CardPillLabel", &"font_size")
	_scale_font(_name_label, &"CardNameLabel", &"font_size")
	for label: Label in [_type_label, _speed_label]:
		_scale_font(label, &"CardBandLabel", &"font_size")
	_scale_font(_text_label, &"CardBodyText", &"normal_font_size")
	var pill := Vector2.ONE * PILL_SIZE * _scale
	_cost_pill.custom_minimum_size = pill
	_stat_pill.custom_minimum_size = pill
	_art_icon.custom_minimum_size = Vector2.ONE * ART_ICON_SIZE * _scale
	_band_icon.custom_minimum_size = Vector2.ONE * BAND_ICON_SIZE * _scale
	_heart_icon.custom_minimum_size = Vector2.ONE * HEART_ICON_SIZE * _scale
	_text_panel.custom_minimum_size.y = TEXT_HEIGHT * _scale
	var radius := roundi(ART_RADIUS * _scale)
	_art.add_theme_stylebox_override(
		"panel", DuelPalette.fill_style(DuelPalette.ART_COLOR, radius, 0.0)
	)
	_text_panel.add_theme_stylebox_override(
		"panel", DuelPalette.fill_style(DuelPalette.CARD_FACE_COLOR, radius, TEXT_MARGIN * _scale)
	)
	for pill_panel: PanelContainer in [_cost_pill, _stat_pill]:
		pill_panel.add_theme_stylebox_override(
			"panel", DuelPalette.pill_style(DuelPalette.CARD_FACE_COLOR)
		)
	_refresh_frame()


func _scale_font(control: Control, variation: StringName, font_size_name: StringName) -> void:
	control.theme_type_variation = variation
	var base_size := control.get_theme_font_size(font_size_name, variation)
	control.add_theme_font_size_override(font_size_name, roundi(base_size * _scale))


func _scale_constant(
	container: Container, variation: StringName, constant_name: StringName
) -> void:
	container.theme_type_variation = variation
	var base_value := container.get_theme_constant(constant_name, variation)
	container.add_theme_constant_override(constant_name, roundi(base_value * _scale))


func _on_hover_changed(is_hovered: bool) -> void:
	_is_hovered = is_hovered
	queue_redraw()
	if is_hovered:
		card_hovered.emit(_card_instance_id)
	else:
		card_unhovered.emit(_card_instance_id)


func _refresh_frame() -> void:
	var ink := DuelPalette.TINT_INKS[_tint]
	var margin := CARD_MARGIN * _scale
	add_theme_stylebox_override(
		"panel", DuelPalette.tinted_style(_tint, ink, DuelPalette.BORDER_WIDTH, margin)
	)
