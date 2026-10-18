class_name DuelMarks
extends RefCounted
## Marques de sélection des cartes, pièces et entrées de pile (décision 0027) : des anneaux tracés
## autour de l'élément, qui laissent visibles sa teinte et le liseré de son joueur, et se
## distinguent par leur forme autant que par leur couleur. Survolé : un anneau clair ; surligné
## (peut être choisi) : un anneau jaune ; choisi : deux anneaux verts.

## Ajouter à la fin, sans réordonner.
enum Mark {
	NONE,
	HOVERED,
	HIGHLIGHTED,
	SELECTED,
}

const RING_WIDTH: int = 3
const RING_GAP: float = 1.0
const RING_RADIUS: int = 10
const HOVER_COLOR := Color(1.0, 1.0, 1.0, 0.6)


## Marque à montrer : le choix l'emporte sur le surlignage, qui l'emporte sur le survol.
static func mark_of(is_hovered: bool, is_highlighted: bool, is_selected: bool) -> Mark:
	if is_selected:
		return Mark.SELECTED
	if is_highlighted:
		return Mark.HIGHLIGHTED
	return Mark.HOVERED if is_hovered else Mark.NONE


## Trace `mark` autour de `rect` sur `canvas`, le premier anneau s'arrêtant à `outset` pixels hors
## du bord (0 : sur le bord, à l'intérieur) ; le second, s'il y en a un, est tracé en dedans.
static func draw(canvas: CanvasItem, rect: Rect2, mark: Mark, outset: float) -> void:
	match mark:
		Mark.HOVERED:
			_draw_ring(canvas, rect.grow(outset), HOVER_COLOR)
		Mark.HIGHLIGHTED:
			_draw_ring(canvas, rect.grow(outset), DuelPalette.HIGHLIGHT_COLOR)
		Mark.SELECTED:
			_draw_ring(canvas, rect.grow(outset), DuelPalette.SELECTED_COLOR)
			var inner := rect.grow(outset - RING_WIDTH - RING_GAP)
			_draw_ring(canvas, inner, DuelPalette.SELECTED_COLOR)


static func _draw_ring(canvas: CanvasItem, rect: Rect2, color: Color) -> void:
	var ring := StyleBoxFlat.new()
	ring.draw_center = false
	ring.border_color = color
	ring.set_border_width_all(RING_WIDTH)
	ring.set_corner_radius_all(RING_RADIUS)
	ring.anti_aliasing = true
	canvas.draw_style_box(ring, rect)
