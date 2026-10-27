class_name DuelFrames
extends RefCounted
## Cadres dessinés des cartes et des pièces, selon la bible « Vestiaire » (décisions 0070 et 0071) :
## trait d'encre, coins coupés, ombre en aplat, cadre de la teinte du type rayé de hachures et
## papier au centre ; bande de type à plat ; fond d'illustration tramé de points. Chaque cadre
## est cherché d'abord en image (`cards/frames/`, `DuelAssets`) ; sans fichier, il est dessiné ici.
## Tout se règle par l'échelle de la carte (1 en main, 2,2 en aperçu) et ne connaît aucune règle.

## Épaisseur du cadre rayé entre le trait d'encre et le papier, à l'échelle 1.
const HATCH_RING_WIDTH: float = 4.0
## Hachures à 135° (maquette) : un trait sombre de 2 px tous les 5 px, mesurés en travers.
const HATCH_PERIOD: float = 5.0
const HATCH_LINE_WIDTH: float = 2.0
const HATCH_COLOR := Color(0.0, 0.0, 0.0, 0.133)
## Trait fin du papier et de la bande : 1,5 px de la maquette, arrondi à l'échelle.
const THIN_LINE_WIDTH: float = 1.5
const PAPER_CUT: int = 5
const CARD_SHADOW_OFFSET: float = 3.0
## Marge intérieure de la carte : trait, cadre rayé, trait du papier, un pixel d'air.
const CARD_CONTENT_MARGIN: float = 8.0
## Bande de type : marges autour de son contenu.
const BAND_PADDING_HORIZONTAL: float = 4.0
const BAND_PADDING_VERTICAL: float = 1.0
## Trame de points du fond d'illustration : un point tous les 6 px, de rayon proportionnel.
const DOT_STEP: float = 6.0
const DOT_RADIUS_RATIO: float = 0.17
const DOT_COLOR := Color(0.082, 0.071, 0.059, 0.16)
## Zone d'illustration carrée, trait d'encre compris, commune à la carte en main (E11) et à la
## pièce (E06) : un seul fichier `cards/art/<id>.webp` sert aux deux, montré en entier.
const ART_ZONE_SIZE: float = 110.0
const SQRT_TWO: float = 1.41421356

## Hachures déjà calculées : clé « largeur x hauteur x échelle » → bandes à tracer.
static var _hatch_cache: Dictionary[String, Array] = {}
## Trames déjà tracées : pas en pixels → texture.
static var _dot_textures: Dictionary[int, Texture2D] = {}


## Cadre d'une carte de teinte `tint` à l'échelle `card_scale` : `card_<type>.png` s'il existe,
## sinon trait d'encre, fond de la teinte et ombre ; `draw_card_face` y ajoute hachures et papier.
static func card_style(tint: DuelPalette.Tint, card_scale: float) -> StyleBox:
	var drawn := _drawn_card_style(tint, card_scale)
	return DuelAssets.card_frame_style(DuelPalette.tint_name(tint), card_scale, drawn)


## Cadre d'une pièce de teinte `tint` et de camp `owner_color` : `piece_<type>.png` s'il existe,
## sinon le liseré du joueur ; `draw_piece_face` complète l'un et l'autre.
static func piece_style(tint: DuelPalette.Tint, owner_color: Color) -> StyleBox:
	var drawn := DuelPalette.fill_style(owner_color, DuelPalette.CUT_SIZE, piece_margin())
	return DuelAssets.piece_frame_style(DuelPalette.tint_name(tint), drawn)


## Marge intérieure d'une pièce : liseré du joueur, trait du papier, un pixel d'air.
static func piece_margin() -> float:
	return DuelPalette.PLAYER_BORDER_WIDTH + THIN_LINE_WIDTH + 2.0


## Vrai si `style` est le cadre dessiné, que `draw_card_face` et `draw_piece_face` complètent.
static func is_drawn(style: StyleBox) -> bool:
	return style is StyleBoxFlat


## Hachures et papier d'une carte dessinée, sur `canvas`, dans `rect` à l'échelle `card_scale`.
static func draw_card_face(canvas: CanvasItem, rect: Rect2, card_scale: float) -> void:
	var border := border_width(card_scale)
	var cut := DuelPalette.CUT_SIZE * card_scale
	var hatched := octagon(rect.grow(-border), cut - border)
	for stripe: PackedVector2Array in _hatch_stripes(rect.size, hatched, card_scale):
		canvas.draw_colored_polygon(stripe, HATCH_COLOR)
	var ring := (DuelPalette.BORDER_WIDTH + HATCH_RING_WIDTH) * card_scale
	_draw_paper(canvas, rect.grow(-ring), card_scale)


## Papier d'une pièce dessinée, dans le liseré de son joueur.
static func draw_piece_face(canvas: CanvasItem, rect: Rect2) -> void:
	_draw_paper(canvas, rect.grow(-float(DuelPalette.PLAYER_BORDER_WIDTH)), 1.0)


## Liseré du joueur par-dessus une pièce habillée d'une image, qui l'a recouvert.
static func draw_piece_ring(canvas: CanvasItem, rect: Rect2, owner_color: Color) -> void:
	var ring := DuelPalette.outline_style(owner_color, DuelPalette.PLAYER_BORDER_WIDTH)
	ring.anti_aliasing = true
	canvas.draw_style_box(ring, rect)


## Bandeau du nom, posé sur le bas de l'illustration : papier bordé d'encre, coins droits.
static func banner_style(card_scale: float) -> StyleBoxFlat:
	var line := _thin(card_scale)
	var style := DuelPalette.framed_style(DuelPalette.PAPER_COLOR, DuelPalette.INK_COLOR, line, 0.0)
	style.set_corner_radius_all(0)
	style.content_margin_left = BAND_PADDING_HORIZONTAL * card_scale + line
	style.content_margin_right = BAND_PADDING_HORIZONTAL * card_scale + line
	style.content_margin_top = BAND_PADDING_VERTICAL * card_scale + line
	style.content_margin_bottom = BAND_PADDING_VERTICAL * card_scale + line
	return style


## Zone d'illustration : la teinte du type, un trait d'encre autour, coins droits.
static func art_style(tint: DuelPalette.Tint, card_scale: float) -> StyleBoxFlat:
	var border := border_width(card_scale)
	var style := DuelPalette.framed_style(
		DuelPalette.TINT_BACKGROUNDS[tint], DuelPalette.INK_COLOR, border, float(border)
	)
	style.set_corner_radius_all(0)
	return style


## Trame de points du fond d'une zone d'illustration de taille `zone_size`, dans son trait d'encre.
static func draw_art_dots(canvas: CanvasItem, zone_size: Vector2, card_scale: float) -> void:
	var inset := Vector2.ONE * border_width(card_scale)
	var rect := Rect2(inset, zone_size - inset * 2.0)
	canvas.draw_texture_rect(_dot_texture(roundi(DOT_STEP * card_scale)), rect, true)


## Rectangle aux quatre coins coupés de `cut` px : le polygone qui borne les hachures.
static func octagon(rect: Rect2, cut: float) -> PackedVector2Array:
	return PackedVector2Array(
		[
			rect.position + Vector2(cut, 0.0),
			Vector2(rect.end.x - cut, rect.position.y),
			Vector2(rect.end.x, rect.position.y + cut),
			Vector2(rect.end.x, rect.end.y - cut),
			Vector2(rect.end.x - cut, rect.end.y),
			Vector2(rect.position.x + cut, rect.end.y),
			Vector2(rect.position.x, rect.end.y - cut),
			rect.position + Vector2(0.0, cut),
		]
	)


## Épaisseur du trait d'encre d'une carte, d'une pièce ou d'une zone d'illustration à l'échelle.
static func border_width(card_scale: float) -> int:
	return _line_width(DuelPalette.BORDER_WIDTH, card_scale)


static func _drawn_card_style(tint: DuelPalette.Tint, card_scale: float) -> StyleBoxFlat:
	var border := border_width(card_scale)
	var style := DuelPalette.framed_style(
		DuelPalette.TINT_BACKGROUNDS[tint],
		DuelPalette.INK_COLOR,
		border,
		CARD_CONTENT_MARGIN * card_scale
	)
	style.set_corner_radius_all(roundi(DuelPalette.CUT_SIZE * card_scale))
	return DuelPalette.with_shadow(style, CARD_SHADOW_OFFSET * card_scale)


static func _draw_paper(canvas: CanvasItem, rect: Rect2, card_scale: float) -> void:
	var paper := DuelPalette.framed_style(
		DuelPalette.PAPER_COLOR, DuelPalette.INK_COLOR, _thin(card_scale), 0.0
	)
	paper.set_corner_radius_all(roundi(PAPER_CUT * card_scale))
	canvas.draw_style_box(paper, rect)


static func _thin(card_scale: float) -> int:
	return _line_width(THIN_LINE_WIDTH, card_scale)


static func _line_width(base_width: float, card_scale: float) -> int:
	return maxi(1, roundi(base_width * card_scale))


# Bandes sombres le long de x + y = constante, découpées au polygone `bounds`.
static func _hatch_stripes(size: Vector2, bounds: PackedVector2Array, card_scale: float) -> Array:
	var key := "%d x %d x %.2f" % [roundi(size.x), roundi(size.y), card_scale]
	if not _hatch_cache.has(key):
		var stripes: Array[PackedVector2Array] = []
		var period := HATCH_PERIOD * SQRT_TWO * card_scale
		var width := HATCH_LINE_WIDTH * SQRT_TWO * card_scale
		var start := (HATCH_PERIOD - HATCH_LINE_WIDTH) * SQRT_TWO * card_scale
		var offset := start
		while offset < size.x + size.y:
			var slanted := PackedVector2Array(
				[
					Vector2(offset, 0.0),
					Vector2(offset + width, 0.0),
					Vector2(offset + width - size.y, size.y),
					Vector2(offset - size.y, size.y),
				]
			)
			stripes.append_array(Geometry2D.intersect_polygons(slanted, bounds))
			offset += period
		_hatch_cache[key] = stripes
	return _hatch_cache[key]


static func _dot_texture(step: int) -> Texture2D:
	if not _dot_textures.has(step):
		var image := Image.create(step, step, false, Image.FORMAT_RGBA8)
		var center := Vector2.ONE * (step / 2.0)
		var radius := step * DOT_RADIUS_RATIO
		for y: int in step:
			for x: int in step:
				var distance := Vector2(x + 0.5, y + 0.5).distance_to(center)
				var coverage := clampf(radius + 0.5 - distance, 0.0, 1.0)
				image.set_pixel(x, y, Color(DOT_COLOR, DOT_COLOR.a * coverage))
		_dot_textures[step] = ImageTexture.create_from_image(image)
	return _dot_textures[step]
