class_name DashedOutline
extends RefCounted
## Contour en pointillé d'un emplacement vide (Sources, défausse) : trace les quatre côtés du
## rectangle du Control, de la couleur des lignes de case.

const DASH_LENGTH: float = 6.0


## À appeler depuis le `_draw()` du Control, ou depuis son signal `draw`.
static func draw(canvas: CanvasItem, size: Vector2) -> void:
	var corners := PackedVector2Array(
		[Vector2.ZERO, Vector2(size.x, 0.0), size, Vector2(0.0, size.y)]
	)
	for corner: int in corners.size():
		var next := corners[(corner + 1) % corners.size()]
		canvas.draw_dashed_line(
			corners[corner],
			next,
			DuelPalette.CELL_LINE_COLOR,
			DuelPalette.BORDER_WIDTH,
			DASH_LENGTH
		)
