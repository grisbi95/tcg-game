class_name PieceView
extends Control
## Pièce sur le plateau (décision 0027, épurée au jalon J2b) : l'illustration carrée de sa carte
## (décision 0051), la même et à la même taille que sur la carte en main
## (`DuelFrames.ART_ZONE_SIZE`),
## ou l'icône du type sur sa teinte tant qu'il n'y en a pas, sur du papier liseré de la couleur
## fixe de son joueur ; Force actuelle (losange) ou PV du Hero (cœur) dans le coin. Ni nom, ni type,
## ni mot-clé : le type se lit à la teinte, le reste à l'aperçu au survol. Le cadre est dessiné
## (DuelFrames) ou remplacé par `cards/frames/piece_<type>.png`. Un Gear attaché dépasse d'une bande
## en haut. Un clic passe à la case (cell_pressed, décision 0030) ; survol, surlignage et choix se
## marquent par des anneaux autour de la mini-carte (DuelMarks), sans cacher le liseré du joueur.
## Les valeurs viennent du parent, qui lit la Force actuelle par `DuelEngine.current_force` : rien
## n'est calculé ici.

signal piece_hovered(piece_id: int)
signal piece_unhovered(piece_id: int)

## Décision 0028, fiche de l'écran de duel : la pièce mesure 125 px ; sa case de 139 px l'entoure
## d'une marge où se tracent les anneaux de marque.
const PIECE_SIZE := Vector2(125, 125)
const CELL_MARGIN: float = 7.0
## Bande visible du Gear attaché, au-dessus de la mini-carte.
const GEAR_PEEK_HEIGHT: float = 23.0
const STAT_BADGE_SIZE: float = 36.0
## Le cœur porte deux chiffres : un peu plus large que le losange.
const HEART_BADGE_SIZE: float = 40.0
const ART_ICON_SIZE: float = 40.0
const GEAR_ICON_SIZE: float = 12.0
## Marge de la pastille de Force contre le coin de la pièce.
const BADGE_INSET: float = 3.0
const GEAR_PADDING: float = 4.0
const GEAR_CUT: int = 4
## Trait d'encre autour de la pièce, hors de son liseré de camp, et ombre en aplat.
const OUTLINE_WIDTH: int = 2
const GRAYSCALE_SHADER: Shader = preload("res://ui/theme/grayscale.gdshader")

var _piece_id: int = DuelState.NO_ID
var _tint: DuelPalette.Tint = DuelPalette.Tint.UNIT
var _is_frame_drawn: bool = true
var _owner_color: Color = DuelPalette.NEUTRAL_COLOR
var _stat: StatBadgeBinding
var _gear_peek: float = 0.0
var _badge_size: float = STAT_BADGE_SIZE
var _marks := ControlMarks.new(self, CELL_MARGIN)
var _grayscale_material := ShaderMaterial.new()

@onready var _gear_panel: PanelContainer = %GearPanel
@onready var _gear_icon: Control = %GearIcon
@onready var _gear_label: Label = %GearLabel
@onready var _mini_card: PanelContainer = %MiniCard
@onready var _stat_badge: Control = %StatBadge
@onready var _stat_label: Label = %StatLabel
@onready var _art: PanelContainer = %Art
@onready var _art_image: TextureRect = %ArtImage
@onready var _art_icon: Control = %ArtIcon


func _ready() -> void:
	_grayscale_material.shader = GRAYSCALE_SHADER
	_marks.hover_changed.connect(_on_hover_changed)
	_mini_card.draw.connect(_on_mini_card_drawn)
	_art.draw.connect(_on_art_drawn)
	_stat = StatBadgeBinding.new(_stat_badge, _stat_label)
	_bind_icons()
	_size_parts()
	_style_fixed_parts()
	_refresh_frame()


func _draw() -> void:
	_draw_outline()
	_marks.draw()


## Unit ou Building d'une carte (202.1) ; sa Force suit par `show_force`.
func show_card_piece(piece_id: int, definition: CardDefinition, side: DuelState.PlayerSide) -> void:
	_show(piece_id, side, DuelPalette.tint_of(definition.card_type))
	DuelAssets.show_card_art(_art_image, _art_icon, definition.id)


## Jeton (202.4) Unit ou Building, sans illustration ; sa Force suit par `show_force`.
func show_token(
	piece_id: int, card_type: CardDefinition.CardType, side: DuelState.PlayerSide
) -> void:
	_show(piece_id, side, DuelPalette.tint_of(card_type))
	DuelAssets.show_no_art(_art_image, _art_icon)


## Hero (202.3) ; ses PV suivent par `show_health`.
func show_hero(piece_id: int, hero: HeroDefinition, side: DuelState.PlayerSide) -> void:
	_show(piece_id, side, DuelPalette.Tint.HERO)
	DuelAssets.show_card_art(_art_image, _art_icon, hero.id)


## Décision 0027 : `force` actuelle (209.1, lue par `DuelEngine.current_force`) sur un losange ;
## le chiffre est sombre si elle égale `printed_force`, vert au-dessus, orange en dessous.
func show_force(force: int, printed_force: int) -> void:
	_stat.show_force(force, printed_force)
	_place_stat_badge(STAT_BADGE_SIZE)


## PV du Hero (202.3.7), sur un cœur, à la place de la Force.
func show_health(health: int) -> void:
	_stat.show_health(health)
	_place_stat_badge(HEART_BADGE_SIZE)


## Nom du Gear attaché (202.2.10, un seul au plus) ; vide sans Gear.
func show_gear(gear_name: String) -> void:
	var has_gear := not gear_name.is_empty()
	_gear_panel.visible = has_gear
	_gear_label.text = gear_name
	_gear_peek = GEAR_PEEK_HEIGHT if has_gear else 0.0
	_mini_card.offset_top = _gear_peek
	_place_stat_badge(_badge_size)
	queue_redraw()


## 201.4.11 : une pièce endormie montre son illustration (ou l'icône du type) en gris ; liseré,
## pastille restent en couleur. Un Building n'est jamais montré endormi.
func show_asleep(is_asleep: bool) -> void:
	var art_material: ShaderMaterial = _grayscale_material if is_asleep else null
	_art_image.material = art_material
	_art_icon.material = art_material


func set_marks(is_highlighted: bool, is_selected: bool) -> void:
	_marks.set_marks(is_highlighted, is_selected)


func _show(piece_id: int, side: DuelState.PlayerSide, tint: DuelPalette.Tint) -> void:
	_piece_id = piece_id
	_owner_color = DuelPalette.player_color(side)
	_tint = tint
	_art_icon.queue_redraw()
	_refresh_frame()


# Pastille dans le coin haut droit de la mini-carte, sous la bande du Gear s'il y en a une.
func _place_stat_badge(badge_size: float) -> void:
	_badge_size = badge_size
	_stat_badge.offset_right = -BADGE_INSET
	_stat_badge.offset_left = -BADGE_INSET - badge_size
	_stat_badge.offset_top = _gear_peek + BADGE_INSET
	_stat_badge.offset_bottom = _gear_peek + BADGE_INSET + badge_size


func _bind_icons() -> void:
	DuelIcons.bind_tinted([_art_icon], func() -> DuelPalette.Tint: return _tint)
	DuelIcons.bind(
		_gear_icon,
		func() -> DuelIcons.Icon: return DuelIcons.Icon.GEAR,
		func() -> Color: return DuelPalette.TINT_INKS[DuelPalette.Tint.GEAR]
	)


func _size_parts() -> void:
	custom_minimum_size = PIECE_SIZE
	_art_icon.custom_minimum_size = Vector2.ONE * ART_ICON_SIZE
	_art.custom_minimum_size = Vector2.ONE * DuelFrames.ART_ZONE_SIZE
	_gear_icon.custom_minimum_size = Vector2.ONE * GEAR_ICON_SIZE
	_place_stat_badge(STAT_BADGE_SIZE)


func _style_fixed_parts() -> void:
	var gear_ink := DuelPalette.TINT_INKS[DuelPalette.Tint.GEAR]
	var gear_style := DuelPalette.fill_style(
		DuelPalette.TINT_BACKGROUNDS[DuelPalette.Tint.GEAR], GEAR_CUT, GEAR_PADDING
	)
	gear_style.border_color = gear_ink
	gear_style.set_border_width_all(DuelPalette.BORDER_WIDTH)
	_gear_panel.add_theme_stylebox_override("panel", gear_style)
	_gear_label.add_theme_color_override("font_color", gear_ink)


func _on_hover_changed(is_hovered: bool) -> void:
	if is_hovered:
		piece_hovered.emit(_piece_id)
	else:
		piece_unhovered.emit(_piece_id)


# Décision 0027 : liseré épais de la couleur fixe du joueur, toujours visible ; l'image
# `piece_<type>.png` remplace le cadre dessiné, que `_on_mini_card_drawn` complète sinon.
func _refresh_frame() -> void:
	var frame := DuelFrames.piece_style(_tint, _owner_color)
	_is_frame_drawn = DuelFrames.is_drawn(frame)
	_mini_card.add_theme_stylebox_override("panel", frame)
	_art.add_theme_stylebox_override("panel", DuelFrames.art_style(_tint, 1.0))
	_mini_card.queue_redraw()
	_art.queue_redraw()


func _on_mini_card_drawn() -> void:
	var rect := Rect2(Vector2.ZERO, _mini_card.size)
	if _is_frame_drawn:
		DuelFrames.draw_piece_face(_mini_card, rect)
	else:
		DuelFrames.draw_piece_ring(_mini_card, rect, _owner_color)


# Trame de points sous l'illustration ; sans effet quand l'image la recouvre.
func _on_art_drawn() -> void:
	if _art_image.visible:
		return
	DuelFrames.draw_art_dots(_art, _art.size, 1.0)


# Bible : trait d'encre autour de la mini-carte et ombre en aplat, sous le liseré du camp.
func _draw_outline() -> void:
	var outline := DuelPalette.framed_style(
		DuelPalette.INK_COLOR, DuelPalette.INK_COLOR, OUTLINE_WIDTH, 0.0
	)
	var rect := _mini_card.get_rect().grow(OUTLINE_WIDTH)
	draw_style_box(DuelPalette.with_shadow(outline, DuelPalette.SHADOW_OFFSET), rect)
