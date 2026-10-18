class_name PieceView
extends Control
## Pièce sur le plateau (décision 0027) : mini-carte carrée qui remplit sa case, teintée par son
## type et liserée de la couleur fixe de son joueur ; nom, Force actuelle ou PV du Hero, icône du
## type, bandeau et mots-clés, aucun coût. Un Gear attaché dépasse d'une bande en haut. Un clic
## passe à la case (cell_pressed) ; survol, surlignage et choix se marquent par des anneaux autour
## de la mini-carte (DuelMarks), sans cacher le liseré du joueur. Les valeurs
## viennent du parent, qui lit la Force actuelle par `DuelEngine.current_force` : rien n'est
## calculé ici.

signal piece_hovered(piece_id: int)
signal piece_unhovered(piece_id: int)

const PIECE_SIZE := Vector2(129, 129)
## Anneaux de marque tracés dans la marge de 7 px entre la pièce et le bord de sa case.
const MARK_OUTSET: float = 7.0
## Bande visible du Gear attaché, au-dessus de la mini-carte.
const GEAR_PEEK_HEIGHT: float = 23.0
const PILL_SIZE: float = 34.0
const ART_ICON_SIZE: float = 30.0
const BAND_ICON_SIZE: float = 12.0
const HEART_ICON_SIZE: float = 11.0
const CARD_PADDING: float = 4.0
const GEAR_PADDING: float = 4.0
const ART_RADIUS: int = 5
const CHIP_RADIUS: int = 4
const CHIP_PADDING: float = 2.0
const STRIKE_WIDTH: float = 1.5

var _piece_id: int = DuelState.NO_ID
var _tint: DuelPalette.Tint = DuelPalette.Tint.UNIT
var _owner_color: Color = DuelPalette.NEUTRAL_COLOR
var _is_hovered: bool = false
var _is_highlighted: bool = false
var _is_selected: bool = false

@onready var _gear_panel: PanelContainer = %GearPanel
@onready var _gear_icon: Control = %GearIcon
@onready var _gear_label: Label = %GearLabel
@onready var _mini_card: PanelContainer = %MiniCard
@onready var _name_label: Label = %NameLabel
@onready var _printed_label: Label = %PrintedLabel
@onready var _stat_pill: PanelContainer = %StatPill
@onready var _heart_icon: Control = %HeartIcon
@onready var _stat_label: Label = %StatLabel
@onready var _art: PanelContainer = %Art
@onready var _art_icon: Control = %ArtIcon
@onready var _band_icon: Control = %BandIcon
@onready var _type_label: Label = %TypeLabel
@onready var _keyword_chip: PanelContainer = %KeywordChip
@onready var _keyword_label: Label = %KeywordLabel


func _ready() -> void:
	mouse_entered.connect(_on_hover_changed.bind(true))
	mouse_exited.connect(_on_hover_changed.bind(false))
	_bind_icons()
	_size_parts()
	_style_fixed_parts()
	_printed_label.draw.connect(_strike_printed_force)
	_refresh_frame()


func _draw() -> void:
	var mark := DuelMarks.mark_of(_is_hovered, _is_highlighted, _is_selected)
	DuelMarks.draw(self, Rect2(Vector2.ZERO, size), mark, MARK_OUTSET)


## Unit ou Building d'une carte (202.1) ; sa Force suit par `show_force`.
func show_card_piece(
	piece_id: int, definition: CardDefinition, owner: DuelState.PlayerSide
) -> void:
	_show(piece_id, owner, DuelPalette.tint_of(definition.card_type), definition.card_name)
	_type_label.text = CardText.type_name(definition.card_type)
	_show_keywords(CardText.keywords_line(definition))


## Jeton (202.4) Unit ou Building, nommé « Jeton », sans mot-clé (décision 0137 du ruleset) ; sa
## Force suit par `show_force`.
func show_token(
	piece_id: int, card_type: CardDefinition.CardType, owner: DuelState.PlayerSide
) -> void:
	_show(piece_id, owner, DuelPalette.tint_of(card_type), CardText.TOKEN_NAME)
	_type_label.text = CardText.token_type_name(card_type)
	_show_keywords("")


## Hero (202.3) ; ses PV suivent par `show_health`.
func show_hero(piece_id: int, hero: HeroDefinition, owner: DuelState.PlayerSide) -> void:
	_show(piece_id, owner, DuelPalette.Tint.HERO, hero.hero_name)
	_type_label.text = CardText.HERO_TYPE_NAME
	_show_keywords("")


## Décision 0027 : `force` actuelle (209.1, lue par `DuelEngine.current_force`) dans une pastille
## neutre si elle égale `printed_force`, verte au-dessus, orange en dessous, avec la Force
## imprimée barrée à côté.
func show_force(force: int, printed_force: int) -> void:
	_heart_icon.visible = false
	_stat_label.text = str(force)
	_printed_label.text = str(printed_force)
	_printed_label.visible = force != printed_force
	if force > printed_force:
		_color_pill(DuelPalette.FORCE_UP_BACKGROUND, DuelPalette.FORCE_UP_INK)
	elif force < printed_force:
		_color_pill(DuelPalette.FORCE_DOWN_BACKGROUND, DuelPalette.FORCE_DOWN_INK)
	else:
		_color_pill(DuelPalette.CARD_FACE_COLOR, DuelPalette.CARD_TEXT_COLOR)


## PV du Hero (202.3.7), avec un cœur, à la place de la Force.
func show_health(health: int) -> void:
	_printed_label.visible = false
	_heart_icon.visible = true
	_stat_label.text = str(health)
	_color_pill(DuelPalette.CARD_FACE_COLOR, DuelPalette.CARD_TEXT_COLOR)


## Nom du Gear attaché (202.2.10, un seul au plus) ; vide sans Gear.
func show_gear(gear_name: String) -> void:
	var has_gear := not gear_name.is_empty()
	_gear_panel.visible = has_gear
	_gear_label.text = gear_name
	_mini_card.offset_top = GEAR_PEEK_HEIGHT if has_gear else 0.0


func set_marks(is_highlighted: bool, is_selected: bool) -> void:
	_is_highlighted = is_highlighted
	_is_selected = is_selected
	queue_redraw()


func _show(
	piece_id: int, owner: DuelState.PlayerSide, tint: DuelPalette.Tint, piece_name: String
) -> void:
	_piece_id = piece_id
	_owner_color = DuelPalette.player_color(owner)
	_tint = tint
	_name_label.text = piece_name
	var ink := DuelPalette.TINT_INKS[tint]
	for label: Label in [_name_label, _printed_label, _type_label]:
		label.add_theme_color_override("font_color", ink)
	for icon: Control in [_art_icon, _band_icon, _heart_icon]:
		icon.queue_redraw()
	_refresh_frame()


func _show_keywords(keywords: String) -> void:
	_keyword_label.text = keywords
	_keyword_chip.visible = not keywords.is_empty()


func _color_pill(background: Color, ink: Color) -> void:
	_stat_pill.add_theme_stylebox_override("panel", DuelPalette.pill_style(background))
	_stat_label.add_theme_color_override("font_color", ink)


func _strike_printed_force() -> void:
	var middle := _printed_label.size.y / 2.0
	var ink := DuelPalette.TINT_INKS[_tint]
	_printed_label.draw_line(
		Vector2(0.0, middle), Vector2(_printed_label.size.x, middle), ink, STRIKE_WIDTH
	)


func _bind_icons() -> void:
	var type_icon := func() -> DuelIcons.Icon: return DuelIcons.TINT_ICONS[_tint]
	var ink := func() -> Color: return DuelPalette.TINT_INKS[_tint]
	DuelIcons.bind(_art_icon, type_icon, ink)
	DuelIcons.bind(_band_icon, type_icon, ink)
	DuelIcons.bind(_heart_icon, func() -> DuelIcons.Icon: return DuelIcons.Icon.HEART, ink)
	DuelIcons.bind(
		_gear_icon,
		func() -> DuelIcons.Icon: return DuelIcons.Icon.GEAR,
		func() -> Color: return DuelPalette.TINT_INKS[DuelPalette.Tint.GEAR]
	)


func _size_parts() -> void:
	custom_minimum_size = PIECE_SIZE
	_stat_pill.custom_minimum_size = Vector2.ONE * PILL_SIZE
	_art_icon.custom_minimum_size = Vector2.ONE * ART_ICON_SIZE
	_band_icon.custom_minimum_size = Vector2.ONE * BAND_ICON_SIZE
	_gear_icon.custom_minimum_size = Vector2.ONE * BAND_ICON_SIZE
	_heart_icon.custom_minimum_size = Vector2.ONE * HEART_ICON_SIZE


func _style_fixed_parts() -> void:
	_art.add_theme_stylebox_override(
		"panel", DuelPalette.fill_style(DuelPalette.ART_COLOR, ART_RADIUS, 0.0)
	)
	_keyword_chip.add_theme_stylebox_override(
		"panel", DuelPalette.fill_style(DuelPalette.KEYWORD_BACKGROUND, CHIP_RADIUS, CHIP_PADDING)
	)
	_keyword_label.add_theme_color_override("font_color", DuelPalette.KEYWORD_INK)
	var gear_ink := DuelPalette.TINT_INKS[DuelPalette.Tint.GEAR]
	_gear_panel.add_theme_stylebox_override(
		"panel",
		DuelPalette.tinted_style(
			DuelPalette.Tint.GEAR, gear_ink, DuelPalette.BORDER_WIDTH, GEAR_PADDING
		)
	)
	_gear_label.add_theme_color_override("font_color", gear_ink)


func _on_hover_changed(is_hovered: bool) -> void:
	_is_hovered = is_hovered
	queue_redraw()
	if is_hovered:
		piece_hovered.emit(_piece_id)
	else:
		piece_unhovered.emit(_piece_id)


# Décision 0027 : liseré épais de la couleur fixe du joueur, toujours visible.
func _refresh_frame() -> void:
	var width := DuelPalette.PLAYER_BORDER_WIDTH
	_mini_card.add_theme_stylebox_override(
		"panel", DuelPalette.tinted_style(_tint, _owner_color, width, width + CARD_PADDING)
	)
