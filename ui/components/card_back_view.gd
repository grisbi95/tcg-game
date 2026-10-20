class_name CardBackView
extends Control
## Dos d'une carte (décision 0027) : rayures sombres et bordure de la couleur fixe de son joueur.
## Deck face cachée avec son nombre de cartes (201.4.1), ou dos réduit sans chiffre d'une carte de
## la main adverse (201.4.2).

## Décision 0028 : deck de la taille d'une carte de main ; main adverse en dos réduits.
const DECK_SIZE := Vector2(158, 220)
const HAND_SIZE := Vector2(50, 70)
const STRIPE_WIDTH: float = 8.0

## Libellé sous le nombre : « carte » au singulier pour 0 et 1, « cartes » au-delà.
const CARD_WORD_SINGULAR: String = "carte"
const CARD_WORD_PLURAL: String = "cartes"

var _player: DuelState.PlayerSide = DuelState.PlayerSide.A

@onready var _count_column: VBoxContainer = %CountColumn
@onready var _count_label: Label = %CountLabel
@onready var _cards_label: Label = %CardsLabel


func _ready() -> void:
	_count_label.add_theme_color_override("font_color", DuelPalette.INK_COLOR)
	_cards_label.add_theme_color_override("font_color", DuelPalette.MUTED_COLOR)


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var back := DuelPalette.framed_style(
		DuelPalette.CARD_BACK_COLOR,
		DuelPalette.player_color(_player),
		DuelPalette.BORDER_WIDTH,
		0.0
	)
	draw_style_box(back, rect)
	_draw_stripes(rect.grow(-DuelPalette.BORDER_WIDTH))


## Dos d'une carte du joueur `player`, de taille `back_size` (DECK_SIZE ou HAND_SIZE).
func show_back(player: DuelState.PlayerSide, back_size: Vector2) -> void:
	_player = player
	custom_minimum_size = back_size
	queue_redraw()


## Nombre de cartes du deck, écrit au centre du dos.
func show_count(card_count: int) -> void:
	_count_label.text = str(card_count)
	_cards_label.text = CARD_WORD_SINGULAR if card_count <= 1 else CARD_WORD_PLURAL
	_count_column.visible = true


# Rayures à 45°, découpées au rectangle intérieur.
func _draw_stripes(inner: Rect2) -> void:
	var frame := PackedVector2Array(
		[
			inner.position,
			Vector2(inner.end.x, inner.position.y),
			inner.end,
			Vector2(inner.position.x, inner.end.y)
		]
	)
	var span := inner.size.x + inner.size.y
	var offset := 0.0
	while offset < span:
		var stripe := PackedVector2Array(
			[
				inner.position + Vector2(offset, 0.0),
				inner.position + Vector2(offset + STRIPE_WIDTH, 0.0),
				inner.position + Vector2(offset + STRIPE_WIDTH - span, span),
				inner.position + Vector2(offset - span, span),
			]
		)
		for piece: PackedVector2Array in Geometry2D.intersect_polygons(stripe, frame):
			draw_colored_polygon(piece, DuelPalette.CARD_BACK_STRIPE_COLOR)
		offset += STRIPE_WIDTH * 2.0
