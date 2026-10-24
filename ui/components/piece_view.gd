class_name PieceView
extends Control
## Pièce sur le plateau (décision 0027) : mini-carte carrée qui remplit sa case, teintée par son
## type et liserée de la couleur fixe de son joueur ; nom, Force actuelle (losange) ou PV du Hero
## (cœur), illustration ou icône du type (décision 0051), bandeau et mots-clés, aucun coût. Un Gear
## attaché dépasse d'une bande en haut. Un clic passe à la case (cell_pressed, décision 0030) ;
## survol, surlignage et choix se marquent par des anneaux autour de la mini-carte (DuelMarks), sans
## cacher le liseré du joueur. Les valeurs viennent du parent, qui lit la Force actuelle par
## `DuelEngine.current_force` : rien n'est calculé ici.

signal piece_hovered(piece_id: int)
signal piece_unhovered(piece_id: int)

## Décision 0028, fiche de l'écran de duel : la pièce mesure 125 px ; sa case de 139 px l'entoure
## d'une marge où se tracent les anneaux de marque.
const PIECE_SIZE := Vector2(125, 125)
const CELL_MARGIN: float = 7.0
## Bande visible du Gear attaché, au-dessus de la mini-carte.
const GEAR_PEEK_HEIGHT: float = 23.0
const STAT_BADGE_SIZE: float = 42.0
## Le cœur porte deux chiffres : un peu plus large que le losange.
const HEART_BADGE_SIZE: float = 46.0
const ART_ICON_SIZE: float = 30.0
const BAND_ICON_SIZE: float = 12.0
const CARD_PADDING: float = 4.0
const GEAR_PADDING: float = 4.0
const ART_RADIUS: int = 5
const CHIP_RADIUS: int = 4
const CHIP_PADDING: float = 2.0
const GRAYSCALE_SHADER: Shader = preload("res://ui/theme/grayscale.gdshader")

var _piece_id: int = DuelState.NO_ID
var _tint: DuelPalette.Tint = DuelPalette.Tint.UNIT
var _owner_color: Color = DuelPalette.NEUTRAL_COLOR
var _stat: StatBadgeBinding
var _marks := ControlMarks.new(self, CELL_MARGIN)
var _grayscale_material := ShaderMaterial.new()

@onready var _gear_panel: PanelContainer = %GearPanel
@onready var _gear_icon: Control = %GearIcon
@onready var _gear_label: Label = %GearLabel
@onready var _mini_card: PanelContainer = %MiniCard
@onready var _name_label: Label = %NameLabel
@onready var _stat_badge: Control = %StatBadge
@onready var _stat_label: Label = %StatLabel
@onready var _art: PanelContainer = %Art
@onready var _art_image: TextureRect = %ArtImage
@onready var _art_icon: Control = %ArtIcon
@onready var _band_icon: Control = %BandIcon
@onready var _type_label: Label = %TypeLabel
@onready var _keyword_chip: PanelContainer = %KeywordChip
@onready var _keyword_label: Label = %KeywordLabel


func _ready() -> void:
	_grayscale_material.shader = GRAYSCALE_SHADER
	_marks.hover_changed.connect(_on_hover_changed)
	_stat = StatBadgeBinding.new(_stat_badge, _stat_label)
	_bind_icons()
	_size_parts()
	_style_fixed_parts()
	_refresh_frame()


func _draw() -> void:
	_marks.draw()


## Unit ou Building d'une carte (202.1) ; sa Force suit par `show_force`.
func show_card_piece(piece_id: int, definition: CardDefinition, side: DuelState.PlayerSide) -> void:
	_show(piece_id, side, DuelPalette.tint_of(definition.card_type), definition.card_name)
	DuelAssets.show_card_art(_art_image, _art_icon, definition.id)
	_type_label.text = CardText.type_name(definition.card_type)
	_show_keywords(CardText.keywords_line(definition))


## Jeton (202.4) Unit ou Building, nommé « Jeton », sans mot-clé (décision 0137 du ruleset) ; sa
## Force suit par `show_force`.
func show_token(
	piece_id: int, card_type: CardDefinition.CardType, side: DuelState.PlayerSide
) -> void:
	_show(piece_id, side, DuelPalette.tint_of(card_type), CardText.TOKEN_NAME)
	DuelAssets.show_no_art(_art_image, _art_icon)
	_type_label.text = CardText.token_type_name(card_type)
	_show_keywords("")


## Hero (202.3) ; ses PV suivent par `show_health`.
func show_hero(piece_id: int, hero: HeroDefinition, side: DuelState.PlayerSide) -> void:
	_show(piece_id, side, DuelPalette.Tint.HERO, hero.hero_name)
	DuelAssets.show_card_art(_art_image, _art_icon, hero.id)
	_type_label.text = CardText.HERO_TYPE_NAME
	_show_keywords("")


## Décision 0027 : `force` actuelle (209.1, lue par `DuelEngine.current_force`) sur un losange ;
## le chiffre est sombre si elle égale `printed_force`, vert au-dessus, orange en dessous.
func show_force(force: int, printed_force: int) -> void:
	_stat.show_force(force, printed_force)
	_stat_badge.custom_minimum_size = Vector2.ONE * STAT_BADGE_SIZE


## PV du Hero (202.3.7), sur un cœur, à la place de la Force.
func show_health(health: int) -> void:
	_stat.show_health(health)
	_stat_badge.custom_minimum_size = Vector2.ONE * HEART_BADGE_SIZE


## Nom du Gear attaché (202.2.10, un seul au plus) ; vide sans Gear.
func show_gear(gear_name: String) -> void:
	var has_gear := not gear_name.is_empty()
	_gear_panel.visible = has_gear
	_gear_label.text = gear_name
	_mini_card.offset_top = GEAR_PEEK_HEIGHT if has_gear else 0.0


## 201.4.11 : une pièce endormie montre son illustration (ou l'icône du type) en gris ; liseré,
## pastilles, nom et bandeau restent en couleur. Un Building n'est jamais montré endormi.
func show_asleep(is_asleep: bool) -> void:
	var art_material: ShaderMaterial = _grayscale_material if is_asleep else null
	_art_image.material = art_material
	_art_icon.material = art_material


func set_marks(is_highlighted: bool, is_selected: bool) -> void:
	_marks.set_marks(is_highlighted, is_selected)


func _show(
	piece_id: int, side: DuelState.PlayerSide, tint: DuelPalette.Tint, piece_name: String
) -> void:
	_piece_id = piece_id
	_owner_color = DuelPalette.player_color(side)
	_tint = tint
	_name_label.text = piece_name
	var ink := DuelPalette.TINT_INKS[tint]
	for label: Label in [_name_label, _type_label]:
		label.add_theme_color_override("font_color", ink)
	for icon: Control in [_art_icon, _band_icon]:
		icon.queue_redraw()
	_refresh_frame()


func _show_keywords(keywords: String) -> void:
	_keyword_label.text = keywords
	_keyword_chip.visible = not keywords.is_empty()


func _bind_icons() -> void:
	DuelIcons.bind_tinted([_art_icon, _band_icon], func() -> DuelPalette.Tint: return _tint)
	DuelIcons.bind(
		_gear_icon,
		func() -> DuelIcons.Icon: return DuelIcons.Icon.GEAR,
		func() -> Color: return DuelPalette.TINT_INKS[DuelPalette.Tint.GEAR]
	)


func _size_parts() -> void:
	custom_minimum_size = PIECE_SIZE
	_art_icon.custom_minimum_size = Vector2.ONE * ART_ICON_SIZE
	_band_icon.custom_minimum_size = Vector2.ONE * BAND_ICON_SIZE
	_gear_icon.custom_minimum_size = Vector2.ONE * BAND_ICON_SIZE


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
