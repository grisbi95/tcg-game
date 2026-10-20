class_name CardView
extends PanelContainer
## Carte de la main ou de l'aperçu (décision 0027) : coût (goutte), nom et Force (losange, ou PV du
## Hero sur un cœur) en haut ; l'illustration, remplacée par l'icône du type tant qu'il n'y en a
## pas ; bandeau de type et vitesse d'un Spell ; texte, mots-clés en étiquettes. Toute la carte
## prend la teinte de son type ; ses marques de survol, de surlignage et de choix sont des anneaux
## (DuelMarks). Le dos d'une carte est une CardBackView. La carte garde toujours sa taille : un
## texte trop long pour la place restante est mis à une taille de police plus petite, de cette
## carte seulement, jusqu'à un minimum, puis coupé.

signal card_pressed(card_instance_id: int)
signal card_hovered(card_instance_id: int)
signal card_unhovered(card_instance_id: int)

## Décision 0028 : carte de la main et de la défausse, au format 63:88 ; l'aperçu l'agrandit.
const CARD_SIZE := Vector2(158, 220)
const COST_BADGE_SIZE: float = 34.0
const STAT_BADGE_SIZE: float = 42.0
const ART_ICON_SIZE: float = 40.0
const BAND_ICON_SIZE: float = 14.0
const TEXT_HEIGHT: float = 84.0
const CARD_MARGIN: float = 7.0
const TEXT_MARGIN: float = 5.0
const ART_RADIUS: int = 6
## Taille de police la plus petite du texte, à l'échelle 1.
const TEXT_MIN_FONT_SIZE: int = 9
const HIGHLIGHT_PADDING_NAMES: Array[StringName] = [
	&"text_highlight_h_padding", &"text_highlight_v_padding"
]
## Le Layout compte quatre rangées : en-tête, illustration, bandeau et texte.
const LAYOUT_GAP_COUNT: int = 3

var _card_instance_id: int = DuelState.NO_ID
var _tint: DuelPalette.Tint = DuelPalette.Tint.UNIT
var _scale: float = 1.0
var _stat_shape: DuelIcons.Badge = DuelIcons.Badge.DIAMOND
var _stat_look: BadgeLook = BadgeLook.force(0, 0)
var _marks := ControlMarks.new(self, 0.0)
var _fitted_text_width: float = -1.0
var _is_text_fit_pending: bool = false

@onready var _layout: VBoxContainer = %Layout
@onready var _header: HBoxContainer = %Header
@onready var _cost_badge: Control = %CostBadge
@onready var _cost_label: Label = %CostLabel
@onready var _name_label: Label = %NameLabel
@onready var _stat_badge: Control = %StatBadge
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
	_marks.hover_changed.connect(_on_hover_changed)
	_text_label.resized.connect(_on_text_label_resized)
	DuelIcons.bind_tinted([_art_icon, _band_icon], func() -> DuelPalette.Tint: return _tint)
	_bind_badges()
	_text_label.add_theme_color_override("default_color", DuelPalette.CARD_TEXT_COLOR)
	_apply_scale()


func _draw() -> void:
	_marks.draw()


func _gui_input(event: InputEvent) -> void:
	if ViewInput.is_left_click(event):
		card_pressed.emit(_card_instance_id)
		accept_event()


## Carte `card_instance_id` de deck (202.1) : la Force n'apparaît que pour une Unit ou un Building.
func show_card(card_instance_id: int, definition: CardDefinition) -> void:
	_card_instance_id = card_instance_id
	_show_face(DuelPalette.tint_of(definition.card_type), definition.card_name)
	_cost_badge.visible = true
	_cost_label.text = str(definition.cost)
	if definition.force != CardDefinition.NO_FORCE:
		_show_force(definition.force)
	else:
		_hide_stat()
	_type_label.text = CardText.type_name(definition.card_type)
	_speed_label.text = CardText.speed_name(definition)
	_text_label.text = CardText.body_bbcode(definition)


## Carte d'un Hero (202.3) : ses PV sur un cœur à la place de la Force, sans coût.
func show_hero(hero: HeroDefinition) -> void:
	_card_instance_id = DuelState.NO_ID
	_show_face(DuelPalette.Tint.HERO, hero.hero_name)
	_cost_badge.visible = false
	_show_health(hero.health)
	_type_label.text = CardText.HERO_TYPE_NAME
	_speed_label.text = ""
	_text_label.text = CardText.hero_body_bbcode(hero)


## Jeton (202.4) sans carte, de type `card_type` et de Force `force` : nommé « Jeton », sans texte.
func show_token(card_type: CardDefinition.CardType, force: int) -> void:
	_card_instance_id = DuelState.NO_ID
	_show_face(DuelPalette.tint_of(card_type), CardText.TOKEN_NAME)
	_cost_badge.visible = false
	_show_force(force)
	_type_label.text = CardText.token_type_name(card_type)
	_speed_label.text = ""
	_text_label.text = ""


## Taille de la carte : 1 en main, plus en aperçu ; textes, formes et marges suivent.
func set_card_scale(card_scale: float) -> void:
	_scale = card_scale
	_apply_scale()


## Surlignée : la carte peut être choisie ; choisie : elle l'est.
func set_marks(is_highlighted: bool, is_selected: bool) -> void:
	_marks.set_marks(is_highlighted, is_selected)


func _show_face(tint: DuelPalette.Tint, card_name: String) -> void:
	_tint = tint
	_name_label.text = card_name
	var ink := DuelPalette.TINT_INKS[tint]
	for label: Label in [_name_label, _type_label, _speed_label]:
		label.add_theme_color_override("font_color", ink)
	for icon: Control in [_art_icon, _band_icon]:
		icon.queue_redraw()
	_refresh_frame()


func _show_force(force: int) -> void:
	_set_stat(DuelIcons.Badge.DIAMOND, BadgeLook.force(force, force), force)


func _show_health(health: int) -> void:
	_set_stat(DuelIcons.Badge.HEART, BadgeLook.health(), health)


func _hide_stat() -> void:
	_stat_badge.visible = false


func _set_stat(badge: DuelIcons.Badge, look: BadgeLook, value: int) -> void:
	_stat_shape = badge
	_stat_look = look
	_stat_badge.visible = true
	_stat_label.text = str(value)
	_stat_label.add_theme_color_override("font_color", look.ink)
	DuelIcons.fit_label(_stat_label, badge)
	_stat_badge.queue_redraw()


func _bind_badges() -> void:
	var cost_look := BadgeLook.cost()
	DuelIcons.bind_badge(
		_cost_badge,
		func() -> DuelIcons.Badge: return DuelIcons.Badge.DROP,
		func() -> BadgeLook: return cost_look
	)
	_cost_label.add_theme_color_override("font_color", cost_look.ink)
	DuelIcons.fit_label(_cost_label, DuelIcons.Badge.DROP)
	DuelIcons.bind_badge(
		_stat_badge,
		func() -> DuelIcons.Badge: return _stat_shape,
		func() -> BadgeLook: return _stat_look
	)


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
	_text_label.theme_type_variation = &"CardBodyText"
	_cost_badge.custom_minimum_size = Vector2.ONE * COST_BADGE_SIZE * _scale
	_header.custom_minimum_size.y = STAT_BADGE_SIZE * _scale
	_stat_badge.custom_minimum_size = Vector2.ONE * STAT_BADGE_SIZE * _scale
	_art_icon.custom_minimum_size = Vector2.ONE * ART_ICON_SIZE * _scale
	_band_icon.custom_minimum_size = Vector2.ONE * BAND_ICON_SIZE * _scale
	_text_panel.custom_minimum_size.y = TEXT_HEIGHT * _scale
	var radius := roundi(ART_RADIUS * _scale)
	_art.add_theme_stylebox_override(
		"panel", DuelPalette.fill_style(DuelPalette.ART_COLOR, radius, 0.0)
	)
	_text_panel.add_theme_stylebox_override(
		"panel", DuelPalette.fill_style(DuelPalette.CARD_FACE_COLOR, radius, TEXT_MARGIN * _scale)
	)
	_refresh_frame()
	_request_text_fit()


func _scale_font(control: Control, variation: StringName, font_size_name: StringName) -> void:
	control.theme_type_variation = variation
	control.remove_theme_font_size_override(font_size_name)
	var base_size := control.get_theme_font_size(font_size_name)
	control.add_theme_font_size_override(font_size_name, roundi(base_size * _scale))


# Le surlignage d'une étiquette déborde de sa ligne de la marge `text_highlight_*_padding`, valable
# pour la taille de police du thème : elle suit la taille effective du texte.
func _follow_highlight_padding(font_size: int, theme_font_size: int) -> void:
	for padding_name: StringName in HIGHLIGHT_PADDING_NAMES:
		_text_label.remove_theme_constant_override(padding_name)
		var base_padding := _text_label.get_theme_constant(padding_name)
		var padding := roundi(base_padding * float(font_size) / theme_font_size)
		_text_label.add_theme_constant_override(padding_name, padding)


func _scale_constant(
	container: Container, variation: StringName, constant_name: StringName
) -> void:
	container.theme_type_variation = variation
	container.remove_theme_constant_override(constant_name)
	var base_value := container.get_theme_constant(constant_name)
	container.add_theme_constant_override(constant_name, roundi(base_value * _scale))


func _on_text_label_resized() -> void:
	if not is_equal_approx(_text_label.size.x, _fitted_text_width):
		_request_text_fit()


# Contournement : la largeur du texte n'est connue qu'après la mise en page des conteneurs, d'où
# l'appel différé, repris par `resized` tant que la largeur n'a pas été donnée.
func _request_text_fit() -> void:
	if _is_text_fit_pending:
		return
	_is_text_fit_pending = true
	_fit_text.call_deferred()


# Seuls le texte, la largeur et l'échelle décident de la taille : la mesure est déterministe.
func _fit_text() -> void:
	_is_text_fit_pending = false
	if _text_label.size.x <= 0.0:
		return
	_fitted_text_width = _text_label.size.x
	var panel_margin := _text_panel.get_theme_stylebox(&"panel").get_minimum_size().y
	var max_text_height := _max_text_panel_height() - panel_margin
	_text_label.remove_theme_font_size_override(&"normal_font_size")
	var theme_font_size := _text_label.get_theme_font_size(&"normal_font_size")
	var font_size := roundi(theme_font_size * _scale)
	var min_font_size := roundi(TEXT_MIN_FONT_SIZE * _scale)
	_text_label.add_theme_font_size_override(&"normal_font_size", font_size)
	while font_size > min_font_size and _text_label.get_content_height() > max_text_height:
		font_size -= 1
		_text_label.add_theme_font_size_override(&"normal_font_size", font_size)
	_follow_highlight_padding(font_size, theme_font_size)
	var text_height := minf(_text_label.get_content_height(), max_text_height)
	_text_panel.custom_minimum_size.y = maxf(TEXT_HEIGHT * _scale, text_height + panel_margin)


# Place laissée au texte : la carte moins le cadre, l'en-tête, l'illustration à sa taille minimale,
# le bandeau et les écarts.
func _max_text_panel_height() -> float:
	var frame_height := get_theme_stylebox(&"panel").get_minimum_size().y
	var rows_height := (
		_header.get_combined_minimum_size().y
		+ _art.get_combined_minimum_size().y
		+ _band.get_combined_minimum_size().y
	)
	var gaps_height := _layout.get_theme_constant(&"separation") * LAYOUT_GAP_COUNT
	return CARD_SIZE.y * _scale - frame_height - rows_height - gaps_height


func _on_hover_changed(is_hovered: bool) -> void:
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
