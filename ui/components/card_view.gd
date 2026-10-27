class_name CardView
extends PanelContainer
## Carte de la main ou de l'aperçu (décision 0027, habillage « Vestiaire » des décisions 0070 et
## 0071) : l'illustration carrée (décision 0051 : `assets/cards/art/<id>.webp`), en entier,
## remplacée
## par l'icône du type sur la teinte tant qu'il n'y en a pas, prend toute la largeur ; par-dessus,
## le coût (goutte) en haut à gauche, la Force (losange) ou les PV du Hero (cœur) en haut à droite
## et le nom sur un bandeau de papier en bas. Dessous, le texte de règles, précédé de ses
## étiquettes : vitesse d'un Spell et mots-clés avec leur icône. Pas de bande de type : le cadre,
## de la teinte du type, le dit. Il est dessiné (DuelFrames) ou remplacé par
## `cards/frames/card_<type>.png` ; les marques de survol, de surlignage et de choix sont des
## anneaux (DuelMarks). Le dos d'une carte est une CardBackView. La carte garde toujours sa taille :
## un nom ou un texte trop long pour la place restante est mis à une taille de police plus petite,
## de cette carte seulement, jusqu'à un minimum, puis coupé.

signal card_pressed(card_instance_id: int)
signal card_hovered(card_instance_id: int)
signal card_unhovered(card_instance_id: int)

## Décision 0028 : carte de la main et de la défausse, au format 63:88 ; l'aperçu l'agrandit.
const CARD_SIZE := Vector2(158, 220)
## 213.1 : un coût X s'écrit « X » sur la carte, pas 0.
const X_COST_TEXT: String = "X"
## Taille de police la plus petite d'un nom, à l'échelle 1 : au-dessous, il est coupé.
const NAME_MIN_FONT_SIZE: int = 10
## Côté de l'icône d'une étiquette de texte, à l'échelle 1.
const CHIP_ICON_SIZE: float = 11.0

var _card_instance_id: int = DuelState.NO_ID
var _tint: DuelPalette.Tint = DuelPalette.Tint.UNIT
var _scale: float = 1.0
var _is_frame_drawn: bool = true
var _chips: Array[CardText.Chip] = []
var _body: String = ""
var _fitted_name_width: float = -1.0
var _stat: StatBadgeBinding
var _marks := ControlMarks.new(self, 0.0)
var _scaler := CardScaler.new()

@onready var _layout: VBoxContainer = %Layout
@onready var _art_frame: Control = %ArtFrame
@onready var _art: PanelContainer = %Art
@onready var _art_image: TextureRect = %ArtImage
@onready var _art_icon: Control = %ArtIcon
@onready var _name_banner: PanelContainer = %NameBanner
@onready var _name_label: Label = %NameLabel
@onready var _cost_badge: Control = %CostBadge
@onready var _cost_label: Label = %CostLabel
@onready var _stat_badge: Control = %StatBadge
@onready var _stat_label: Label = %StatLabel
@onready var _text_panel: PanelContainer = %TextPanel
@onready var _text_label: RichTextLabel = %TextLabel


func _ready() -> void:
	_marks.hover_changed.connect(_on_hover_changed)
	_art.draw.connect(_on_art_drawn)
	_name_label.resized.connect(_on_name_resized)
	_scaler.setup(self, _scale_parts(), CARD_SIZE)
	DuelIcons.bind_tinted([_art_icon], func() -> DuelPalette.Tint: return _tint)
	_stat = StatBadgeBinding.new(_stat_badge, _stat_label)
	_bind_cost_badge()
	_text_label.add_theme_color_override("default_color", DuelPalette.CARD_TEXT_COLOR)
	_apply_scale()


func _draw() -> void:
	if _is_frame_drawn:
		DuelFrames.draw_card_face(self, Rect2(Vector2.ZERO, size), _scale)
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
	_show_text(CardText.chips(definition), CardText.body_bbcode(definition))


## Carte d'un Hero (202.3) : ses PV sur un cœur à la place de la Force, sans coût.
func show_hero(hero: HeroDefinition) -> void:
	_card_instance_id = DuelState.NO_ID
	_show_face(DuelPalette.Tint.HERO, hero.hero_name)
	DuelAssets.show_card_art(_art_image, _art_icon, hero.id)
	_cost_badge.visible = false
	_show_health(hero.health)
	_show_text([], CardText.hero_body_bbcode(hero))


## Jeton (202.4) sans carte, de type `card_type` et de Force `force` : nommé « Jeton », sans texte ;
## son type se lit à la teinte.
func show_token(card_type: CardDefinition.CardType, force: int) -> void:
	_card_instance_id = DuelState.NO_ID
	_show_face(DuelPalette.tint_of(card_type), CardText.TOKEN_NAME)
	DuelAssets.show_no_art(_art_image, _art_icon)
	_cost_badge.visible = false
	_show_force(force)
	_show_text([], "")


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
	_name_label.add_theme_color_override("font_color", DuelPalette.TINT_INKS[tint])
	_fit_name()
	_art_icon.queue_redraw()
	_refresh_frame()


# Texte de règles : les étiquettes `chips` en tête, sur le fond d'encre, puis `body`, en BBCode.
func _show_text(chips: Array[CardText.Chip], body: String) -> void:
	_text_label.clear()
	for chip: CardText.Chip in chips:
		_text_label.push_bgcolor(DuelPalette.KEYWORD_BACKGROUND)
		_text_label.push_color(DuelPalette.KEYWORD_INK)
		if chip.has_icon:
			var icon_pixels := roundi(CHIP_ICON_SIZE * _scale)
			_text_label.add_image(
				DuelIcons.chip_texture(
					chip.icon, icon_pixels, DuelPalette.KEYWORD_BACKGROUND, DuelPalette.KEYWORD_INK
				),
				icon_pixels,
				icon_pixels
			)
		_text_label.add_text(" %s " % chip.label)
		_text_label.pop()
		_text_label.pop()
		_text_label.add_text(" ")
	_text_label.append_text(body)
	_chips = chips
	_body = body


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
	_refresh_frame()
	_scaler.apply_scale(_scale)
	_fit_name()
	_show_text(_chips, _body)


func _scale_parts() -> CardScaler.Parts:
	var parts := CardScaler.Parts.new()
	parts.layout = _layout
	parts.art_frame = _art_frame
	parts.art = _art
	parts.art_icon = _art_icon
	parts.name_banner = _name_banner
	parts.cost_badge = _cost_badge
	parts.stat_badge = _stat_badge
	parts.text_panel = _text_panel
	parts.text_label = _text_label
	parts.cost_label = _cost_label
	parts.stat_label = _stat_label
	parts.name_label = _name_label
	return parts


func _on_hover_changed(is_hovered: bool) -> void:
	if is_hovered:
		card_hovered.emit(_card_instance_id)
	else:
		card_unhovered.emit(_card_instance_id)


# Cadre de la carte, bandeau du nom, illustration et marge du texte, à la teinte et à l'échelle
# courantes ; l'image `card_<type>.png` remplace le cadre dessiné, que `_draw` complète sinon.
func _refresh_frame() -> void:
	var frame := DuelFrames.card_style(_tint, _scale)
	_is_frame_drawn = DuelFrames.is_drawn(frame)
	add_theme_stylebox_override("panel", frame)
	_name_banner.add_theme_stylebox_override("panel", DuelFrames.banner_style(_scale))
	_art.add_theme_stylebox_override("panel", DuelFrames.art_style(_tint, _scale))
	_text_panel.add_theme_stylebox_override(
		"panel", DuelPalette.fill_style(Color.TRANSPARENT, 0, CardScaler.TEXT_MARGIN * _scale)
	)
	queue_redraw()
	_art.queue_redraw()


func _fit_name() -> void:
	_fitted_name_width = _name_label.size.x
	LabelFit.fit_to_width(_name_label, _scale, NAME_MIN_FONT_SIZE)


# Seule une autre largeur change la taille d'un nom : la refaire à chaque `resized` bouclerait.
func _on_name_resized() -> void:
	if not is_equal_approx(_name_label.size.x, _fitted_name_width):
		_fit_name()


# Trame de points sous l'illustration ; sans effet quand l'image la recouvre.
func _on_art_drawn() -> void:
	if _art_image.visible:
		return
	DuelFrames.draw_art_dots(_art, _art.size, _scale)
