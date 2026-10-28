class_name CardView
extends PanelContainer
## Carte de la main ou de l'aperçu (décision 0027) : coût (goutte), nom et Force (losange, ou PV du
## Hero sur un cœur) en haut ; l'illustration (décision 0051 : `assets/cards/art/<id>.webp`),
## remplacée par l'icône du type tant qu'il n'y en a pas ; bandeau de type et vitesse d'un Spell ;
## texte, mots-clés en étiquettes. Toute la carte prend la teinte de son type ; ses marques de
## survol, de surlignage et de choix sont des anneaux (DuelMarks). Le dos d'une carte est une
## CardBackView. La carte garde toujours sa taille : un texte trop long pour la place restante est
## mis à une taille de police plus petite, de cette carte seulement, jusqu'à un minimum, puis coupé.

signal card_pressed(card_instance_id: int)
signal card_hovered(card_instance_id: int)
signal card_unhovered(card_instance_id: int)

## Décision 0028 : carte de la main et de la défausse, au format 63:88 ; l'aperçu l'agrandit.
const CARD_SIZE := Vector2(158, 220)
const CARD_MARGIN: float = 7.0
## 213.1 : un coût X s'écrit « X » sur la carte, pas 0.
const X_COST_TEXT: String = "X"

var _card_instance_id: int = DuelState.NO_ID
var _tint: DuelPalette.Tint = DuelPalette.Tint.UNIT
var _scale: float = 1.0
var _stat: StatBadgeBinding
var _marks := ControlMarks.new(self, 0.0)
var _scaler := CardScaler.new()

@onready var _layout: VBoxContainer = %Layout
@onready var _header: HBoxContainer = %Header
@onready var _cost_badge: Control = %CostBadge
@onready var _cost_label: Label = %CostLabel
@onready var _name_label: Label = %NameLabel
@onready var _stat_badge: Control = %StatBadge
@onready var _stat_label: Label = %StatLabel
@onready var _art: PanelContainer = %Art
@onready var _art_image: TextureRect = %ArtImage
@onready var _art_icon: Control = %ArtIcon
@onready var _band: HBoxContainer = %Band
@onready var _band_icon: Control = %BandIcon
@onready var _type_label: Label = %TypeLabel
@onready var _speed_label: Label = %SpeedLabel
@onready var _text_panel: PanelContainer = %TextPanel
@onready var _text_label: RichTextLabel = %TextLabel


func _ready() -> void:
	_marks.hover_changed.connect(_on_hover_changed)
	_scaler.setup(self, _scale_parts(), CARD_SIZE)
	DuelIcons.bind_tinted([_art_icon, _band_icon], func() -> DuelPalette.Tint: return _tint)
	_stat = StatBadgeBinding.new(_stat_badge, _stat_label)
	_bind_cost_badge()
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
	DuelAssets.show_card_art(_art_image, _art_icon, definition.id)
	_cost_badge.visible = true
	_cost_label.text = X_COST_TEXT if definition.has_x_cost else str(definition.cost)
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
	DuelAssets.show_card_art(_art_image, _art_icon, hero.id)
	_cost_badge.visible = false
	_show_health(hero.health)
	_type_label.text = CardText.HERO_TYPE_NAME
	_speed_label.text = ""
	_text_label.text = CardText.hero_body_bbcode(hero)


## Jeton (202.4) sans carte, de type `card_type` et de Force `force` : nommé « Jeton », sans texte.
func show_token(card_type: CardDefinition.CardType, force: int) -> void:
	_card_instance_id = DuelState.NO_ID
	_show_face(DuelPalette.tint_of(card_type), CardText.TOKEN_NAME)
	DuelAssets.show_no_art(_art_image, _art_icon)
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
	_stat_badge.visible = true
	_stat.show_force(force, force)


func _show_health(health: int) -> void:
	_stat_badge.visible = true
	_stat.show_health(health)


func _hide_stat() -> void:
	_stat_badge.visible = false


func _bind_cost_badge() -> void:
	var cost_look := BadgeLook.cost()
	DuelIcons.bind_badge(
		_cost_badge,
		func() -> DuelIcons.Badge: return DuelIcons.Badge.DROP,
		func() -> BadgeLook: return cost_look
	)
	_cost_label.add_theme_color_override("font_color", cost_look.ink)
	DuelIcons.fit_label(_cost_label, DuelIcons.Badge.DROP)


func _apply_scale() -> void:
	_scaler.apply_scale(_scale)
	_refresh_frame()


func _scale_parts() -> CardScaler.Parts:
	var parts := CardScaler.Parts.new()
	parts.layout = _layout
	parts.header = _header
	parts.band = _band
	parts.cost_badge = _cost_badge
	parts.stat_badge = _stat_badge
	parts.art_icon = _art_icon
	parts.band_icon = _band_icon
	parts.art = _art
	parts.text_panel = _text_panel
	parts.text_label = _text_label
	parts.cost_label = _cost_label
	parts.stat_label = _stat_label
	parts.name_label = _name_label
	parts.type_label = _type_label
	parts.speed_label = _speed_label
	return parts


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
