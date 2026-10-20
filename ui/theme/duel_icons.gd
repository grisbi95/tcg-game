class_name DuelIcons
extends RefCounted
## Icônes provisoires (décision 0027), en attendant les illustrations : tracés de la maquette
## `docs/maquettes/ecran-de-partie-v1.html` sur une grille de 24 × 24, dessinés en code pour rester
## nets à toute taille. Un composant les dessine dans le signal `draw` d'un Control vide.

## Ajouter à la fin, sans réordonner.
enum Icon {
	UNIT,
	BUILDING,
	SPELL,
	GEAR,
	HERO,
	HEART,
	SOURCE,
}

const GRID_SIZE: float = 24.0
const STROKE_WIDTH: float = 1.8
const HEART_POINT_COUNT: int = 32
## Cœur paramétrique (16 sin³ t, 13 cos t − 5 cos 2t − 2 cos 3t − cos 4t) ramené à la grille.
const HEART_SCALE: float = 0.47
const HEART_OFFSET := Vector2(0.0, 0.8)
const SOURCE_CORE_RADIUS: float = 4.0
const SOURCE_ARC_POINT_COUNT: int = 24
const CENTER := Vector2(12.0, 12.0)

const TINT_ICONS: Dictionary[DuelPalette.Tint, Icon] = {
	DuelPalette.Tint.UNIT: Icon.UNIT,
	DuelPalette.Tint.BUILDING: Icon.BUILDING,
	DuelPalette.Tint.SPELL: Icon.SPELL,
	DuelPalette.Tint.GEAR: Icon.GEAR,
	DuelPalette.Tint.HERO: Icon.HERO,
}

## Tracés de la maquette : x, y de chaque point d'une ligne brisée, sur la grille.
const UNIT_PATH: Array[float] = [14.0, 3.0, 21.0, 10.0, 10.0, 21.0, 6.0, 22.0, 7.0, 18.0, 14.0, 3.0]
const BUILDING_PATH: Array[float] = [
	4.0, 21.0, 4.0, 9.0, 8.0, 6.0, 12.0, 9.0, 16.0, 6.0, 20.0, 9.0, 20.0, 21.0, 4.0, 21.0
]
const SPELL_PATH: Array[float] = [
	12.0,
	2.0,
	14.5,
	8.5,
	21.0,
	11.0,
	14.5,
	13.5,
	12.0,
	20.0,
	9.5,
	13.5,
	3.0,
	11.0,
	9.5,
	8.5,
	12.0,
	2.0
]
const GEAR_HANDLE_PATH: Array[float] = [4.0, 20.0, 13.0, 11.0]
const GEAR_BLADE_PATH: Array[float] = [15.0, 4.0, 20.0, 9.0, 17.0, 12.0, 12.0, 7.0, 15.0, 4.0]
const HERO_PATH: Array[float] = [
	3.0, 18.0, 5.0, 7.0, 10.0, 12.0, 12.0, 5.0, 14.0, 12.0, 19.0, 7.0, 21.0, 18.0, 3.0, 18.0
]

## Lignes brisées de chaque icône, en coordonnées de la grille.
static var _strokes: Dictionary[Icon, Array] = {
	Icon.UNIT: [_path(UNIT_PATH)],
	Icon.BUILDING: [_path(BUILDING_PATH)],
	Icon.SPELL: [_path(SPELL_PATH)],
	Icon.GEAR: [_path(GEAR_HANDLE_PATH), _path(GEAR_BLADE_PATH)],
	Icon.HERO: [_path(HERO_PATH)],
	Icon.HEART: [_heart_path()],
	Icon.SOURCE: _source_paths(),
}


## Dessine `icon` de couleur `color` dans le carré centré sur `rect`, sur le canevas `canvas`.
static func draw(canvas: CanvasItem, icon: Icon, rect: Rect2, color: Color) -> void:
	var side := minf(rect.size.x, rect.size.y)
	var origin := rect.position + (rect.size - Vector2(side, side)) / 2.0
	var ratio := side / GRID_SIZE
	var width := maxf(STROKE_WIDTH * ratio, 1.0)
	for stroke: PackedVector2Array in _strokes[icon]:
		var points := PackedVector2Array()
		for point: Vector2 in stroke:
			points.append(origin + point * ratio)
		canvas.draw_polyline(points, color, width, true)


## Relie un Control vide à `icon`, recalculée par `color_of` à chaque dessin.
static func bind(control: Control, icon_of: Callable, color_of: Callable) -> void:
	control.draw.connect(
		func() -> void:
			var icon: Icon = icon_of.call()
			var color: Color = color_of.call()
			draw(control, icon, Rect2(Vector2.ZERO, control.size), color)
	)


## Relie les icônes de type `type_icons` et le cœur `heart_icon` d'une carte ou d'une pièce à la
## teinte rendue par `tint_of`, recalculée à chaque dessin : icône du type et encre de la teinte.
static func bind_tinted(type_icons: Array[Control], heart_icon: Control, tint_of: Callable) -> void:
	var type_icon := func() -> Icon: return TINT_ICONS[tint_of.call()]
	var ink := func() -> Color: return DuelPalette.TINT_INKS[tint_of.call()]
	for control: Control in type_icons:
		bind(control, type_icon, ink)
	bind(heart_icon, func() -> Icon: return Icon.HEART, ink)


static func _path(coordinates: Array[float]) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index: int in range(0, coordinates.size(), 2):
		points.append(Vector2(coordinates[index], coordinates[index + 1]))
	return points


static func _heart_path() -> PackedVector2Array:
	var points := PackedVector2Array()
	for step: int in HEART_POINT_COUNT + 1:
		var angle := TAU * step / HEART_POINT_COUNT
		var x := 16.0 * pow(sin(angle), 3)
		var y := 13.0 * cos(angle) - 5.0 * cos(2 * angle) - 2.0 * cos(3 * angle) - cos(4 * angle)
		points.append(CENTER + HEART_OFFSET + Vector2(x, -y) * HEART_SCALE)
	return points


# Soleil : un cercle et huit rayons.
static func _source_paths() -> Array[PackedVector2Array]:
	var core := PackedVector2Array()
	for step: int in SOURCE_ARC_POINT_COUNT + 1:
		var angle := TAU * step / SOURCE_ARC_POINT_COUNT
		core.append(CENTER + Vector2(cos(angle), sin(angle)) * SOURCE_CORE_RADIUS)
	var paths: Array[PackedVector2Array] = [core]
	var rays: Array[Array] = [
		[12.0, 2.0, 12.0, 5.0],
		[12.0, 19.0, 12.0, 22.0],
		[2.0, 12.0, 5.0, 12.0],
		[19.0, 12.0, 22.0, 12.0],
		[5.0, 5.0, 7.0, 7.0],
		[17.0, 17.0, 19.0, 19.0],
		[5.0, 19.0, 7.0, 17.0],
		[17.0, 7.0, 19.0, 5.0],
	]
	for ray: Array in rays:
		var coordinates: Array[float] = []
		coordinates.assign(ray)
		paths.append(_path(coordinates))
	return paths
