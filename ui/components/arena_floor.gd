class_name ArenaFloor
extends Control
## Sol de l'arène (bible « Vestiaire », décision 0071) : une tache ovale, plus claire au centre,
## posée sur la table autour du plateau, et la lumière de l'arène qui tombe d'en haut de l'écran.
## Purement décoratif : aucune souris, aucune règle. Le parent donne le plateau à suivre.

const OVERSHOOT := Vector2(90.0, 70.0)
const EDGE_OFFSET: float = 0.8
const TEXTURE_SIDE: int = 128
const LIGHT_WIDTH_RATIO: float = 0.6
const LIGHT_HEIGHT_RATIO: float = 0.7
const RADIAL_CENTER := Vector2(0.5, 0.5)
const RADIAL_EDGE := Vector2(1.0, 0.5)

var _board: Control
var _floor_texture: GradientTexture2D = _make_radial(
	[
		DuelPalette.ARENA_CENTER_COLOR,
		DuelPalette.ARENA_EDGE_COLOR,
		Color(DuelPalette.ARENA_EDGE_COLOR, 0.0)
	],
	PackedFloat32Array([0.0, EDGE_OFFSET, 1.0]),
	RADIAL_CENTER,
	RADIAL_EDGE
)
var _light_texture: GradientTexture2D = _make_radial(
	[DuelPalette.ARENA_LIGHT_COLOR, Color(DuelPalette.ARENA_LIGHT_COLOR, 0.0)],
	PackedFloat32Array([0.0, 1.0]),
	RADIAL_CENTER,
	RADIAL_EDGE
)


func _draw() -> void:
	var radii := Vector2(size.x * LIGHT_WIDTH_RATIO, size.y * LIGHT_HEIGHT_RATIO)
	var light_rect := Rect2(Vector2(size.x / 2.0 - radii.x, -radii.y), radii * 2.0)
	draw_texture_rect(_light_texture, light_rect, false)
	if _board != null:
		# Le plateau et le sol sont sur deux CanvasLayer : passage par l'écran.
		var to_local := get_screen_transform().affine_inverse() * _board.get_screen_transform()
		var board_rect := to_local * Rect2(Vector2.ZERO, _board.size)
		draw_texture_rect(
			_floor_texture,
			board_rect.grow_individual(OVERSHOOT.x, OVERSHOOT.y, OVERSHOOT.x, OVERSHOOT.y),
			false
		)


## Suit `board`, le plateau dont le sol est dessiné autour.
func setup(board: Control) -> void:
	_board = board
	board.item_rect_changed.connect(queue_redraw)
	queue_redraw()


static func _make_radial(
	colors: Array[Color], offsets: PackedFloat32Array, from: Vector2, to: Vector2
) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = offsets
	gradient.colors = PackedColorArray(colors)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = from
	texture.fill_to = to
	texture.width = TEXTURE_SIDE
	texture.height = TEXTURE_SIDE
	return texture
