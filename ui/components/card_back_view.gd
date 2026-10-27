class_name CardBackView
extends Control
## Dos d'une carte (décisions 0027, 0070 et 0071) : fond sombre rayé de losanges clairs, liseré de
## la couleur fixe de son joueur et, au centre, un petit plateau de 5 × 5 cases à la case centrale
## jaune ; remplacé par `cards/frames/card_back.png` (deck) ou `card_back_small.png` (main
## adverse), le liseré du joueur restant tracé par-dessus.
## Deck face cachée avec son nombre de cartes (201.4.1), ou dos réduit sans chiffre d'une carte de
## la main adverse (201.4.2).

## Décision 0028 : deck de la taille d'une carte de main ; main adverse en dos réduits.
const DECK_SIZE := Vector2(158, 220)
const HAND_SIZE := Vector2(50, 70)
const SMALL_CUT: int = 4
## Losanges du fond : deux séries de traits à 45°, une ligne de 1,5 px tous les 12 px en travers.
const LATTICE_PERIOD: float = 12.0
const LATTICE_LINE_WIDTH: float = 1.5
const SQRT_TWO: float = 1.41421356
## Emblème central : un papier carré portant la grille 5 × 5 des cases du plateau.
const EMBLEM_RATIO: float = 0.42
const EMBLEM_CUT_RATIO: float = 6.0
const EMBLEM_GRID: int = 5
const EMBLEM_INSET: float = 2.0
const EMBLEM_CELL_ALPHA: float = 0.8
const EMBLEM_LINE_WIDTH: int = 1
## Avec le nombre de cartes dessous, l'emblème monte à cette hauteur de la carte.
const EMBLEM_COUNTED_CENTER_RATIO: float = 0.36

## Libellé sous le nombre : « carte » au singulier pour 0 et 1, « cartes » au-delà.
const CARD_WORD_SINGULAR: String = "carte"
const CARD_WORD_PLURAL: String = "cartes"

var _player: DuelState.PlayerSide = DuelState.PlayerSide.A
var _is_small: bool = false
var _has_count: bool = false

@onready var _count_column: VBoxContainer = %CountColumn
@onready var _count_label: Label = %CountLabel
@onready var _cards_label: Label = %CardsLabel


func _ready() -> void:
	_count_label.add_theme_color_override("font_color", DuelPalette.TEXT_COLOR)
	_cards_label.add_theme_color_override("font_color", DuelPalette.MUTED_COLOR)


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var cut := SMALL_CUT if _is_small else DuelPalette.CUT_SIZE
	var ring_width := DuelPalette.BORDER_WIDTH if _is_small else DuelPalette.PLAYER_BORDER_WIDTH
	var texture := DuelAssets.card_back(_is_small)
	var ring_rect := rect
	var ring_cut := cut
	if texture != null:
		draw_texture_rect(texture, rect, false)
	else:
		_draw_drawn_back(rect, cut)
		ring_rect = rect.grow(-float(DuelPalette.BORDER_WIDTH))
		ring_cut = cut - DuelPalette.BORDER_WIDTH
	var ring := DuelPalette.outline_style(DuelPalette.player_color(_player), ring_width, ring_cut)
	ring.anti_aliasing = true
	draw_style_box(ring, ring_rect)


## Dos d'une carte du joueur `player`, de taille `back_size` (DECK_SIZE ou HAND_SIZE).
func show_back(player: DuelState.PlayerSide, back_size: Vector2) -> void:
	_player = player
	_is_small = back_size.x < DECK_SIZE.x / 2.0
	custom_minimum_size = back_size
	queue_redraw()


## Nombre de cartes du deck, écrit au centre du dos.
func show_count(card_count: int) -> void:
	_count_label.text = str(card_count)
	_cards_label.text = CARD_WORD_SINGULAR if card_count <= 1 else CARD_WORD_PLURAL
	_count_column.visible = true
	_has_count = true
	queue_redraw()


func _draw_drawn_back(rect: Rect2, cut: int) -> void:
	var back := DuelPalette.framed_style(
		DuelPalette.CARD_BACK_COLOR, DuelPalette.INK_COLOR, DuelPalette.BORDER_WIDTH, 0.0
	)
	back.set_corner_radius_all(cut)
	if not _is_small:
		DuelPalette.with_shadow(back, DuelPalette.SHADOW_OFFSET)
	draw_style_box(back, rect)
	_draw_lattice(rect.grow(-float(DuelPalette.BORDER_WIDTH)), cut - DuelPalette.BORDER_WIDTH)
	_draw_emblem(rect)


# Losanges : deux séries de traits à 45°, découpées au rectangle intérieur aux coins coupés.
func _draw_lattice(inner: Rect2, cut: int) -> void:
	var frame := DuelFrames.octagon(inner, cut)
	var span := inner.size.x + inner.size.y
	var step := LATTICE_PERIOD * SQRT_TWO
	var offset := 0.0
	while offset < span:
		var rising := PackedVector2Array(
			[
				inner.position + Vector2(offset, 0.0),
				inner.position + Vector2(offset - inner.size.y, inner.size.y),
			]
		)
		var falling := PackedVector2Array(
			[
				inner.position + Vector2(offset - inner.size.y, 0.0),
				inner.position + Vector2(offset, inner.size.y),
			]
		)
		for line: PackedVector2Array in [rising, falling]:
			for piece: PackedVector2Array in Geometry2D.intersect_polyline_with_polygon(
				line, frame
			):
				draw_polyline(piece, DuelPalette.CARD_BACK_STRIPE_COLOR, LATTICE_LINE_WIDTH)
		offset += step


func _draw_emblem(rect: Rect2) -> void:
	var emblem_size := minf(rect.size.x, rect.size.y) * EMBLEM_RATIO
	var center_y := rect.size.y * EMBLEM_COUNTED_CENTER_RATIO if _has_count else rect.size.y / 2.0
	var emblem := Rect2(
		Vector2(rect.size.x / 2.0, center_y) - Vector2.ONE * emblem_size / 2.0,
		Vector2.ONE * emblem_size
	)
	var paper := DuelPalette.framed_style(
		DuelPalette.PAPER_COLOR, DuelPalette.INK_COLOR, EMBLEM_LINE_WIDTH, 0.0
	)
	paper.set_corner_radius_all(roundi(emblem_size / EMBLEM_CUT_RATIO))
	draw_style_box(paper, emblem)
	var cell := (emblem_size - EMBLEM_INSET * 2.0) / EMBLEM_GRID
	var middle := floori(EMBLEM_GRID * EMBLEM_GRID / 2.0)
	for index: int in EMBLEM_GRID * EMBLEM_GRID:
		var origin := emblem.position + Vector2.ONE * EMBLEM_INSET
		origin += Vector2(index % EMBLEM_GRID, floori(float(index) / EMBLEM_GRID)) * cell
		var color := DuelPalette.ESSENCE_COLOR
		if index != middle:
			color = Color(DuelPalette.INK_COLOR, EMBLEM_CELL_ALPHA)
		draw_rect(Rect2(origin, Vector2.ONE * (cell - 1.0)), color)
