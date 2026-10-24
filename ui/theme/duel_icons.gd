class_name DuelIcons
extends RefCounted
## Icônes provisoires (décision 0027), en attendant les illustrations : tracés de la maquette
## `docs/maquettes/ecran-de-partie-v1.html` sur une grille de 24 × 24, dessinés en code pour rester
## nets à toute taille. Un composant les dessine dans le signal `draw` d'un Control vide.
## Les formes pleines (`Badge`) portent un chiffre : un Label posé sur la forme (`fit_label`).

## Ajouter à la fin, sans réordonner. Les noms, en minuscules, sont aussi ceux des fichiers de
## `assets/icons/` (`asset_name`) : renommer une valeur renomme son fichier.
enum Icon {
	UNIT,
	BUILDING,
	SPELL,
	GEAR,
	HERO,
	HEART,
	SOURCE,
	CONCEDE,
	ESSENCE,
}

## Formes pleines d'un chiffre : goutte du coût, losange de la Force, cœur des PV. Ajouter à la fin.
enum Badge {
	DROP,
	DIAMOND,
	HEART,
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
const BADGE_OUTLINE_WIDTH: float = 1.4
## Goutte : une pointe en haut, un corps rond dont les tangentes partent de la pointe.
const DROP_TIP := Vector2(12.0, 1.0)
const DROP_BODY_CENTER := Vector2(12.0, 14.6)
const DROP_BODY_RADIUS: float = 8.4
const DROP_ARC_POINT_COUNT: int = 28
## Cœur plein : le tracé du cœur, agrandi et recentré (le cœur paramétrique couvre y de −11,9 à 17).
const HEART_BADGE_SCALE: float = 0.7
const HEART_BADGE_OFFSET := Vector2(0.0, -1.78)
## Losange plein : quatre sommets au milieu des côtés de la grille, un peu en retrait du bord.
const DIAMOND_PATH: Array[float] = [12.0, 0.8, 23.2, 12.0, 12.0, 23.2, 0.8, 12.0]

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
## Drapeau : une hampe et une bannière à bord échancré.
const CONCEDE_POLE_PATH: Array[float] = [6.0, 3.0, 6.0, 21.0]
const CONCEDE_FLAG_PATH: Array[float] = [6.0, 4.5, 19.0, 4.5, 15.5, 9.0, 19.0, 13.5, 6.0, 13.5]
## Essence : une gemme taillée, sa ceinture en travers.
const ESSENCE_GEM_PATH: Array[float] = [12.0, 2.0, 20.0, 9.0, 12.0, 22.0, 4.0, 9.0, 12.0, 2.0]
const ESSENCE_BELT_PATH: Array[float] = [4.0, 9.0, 20.0, 9.0]
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
	Icon.HEART: [_heart_path(HEART_SCALE, HEART_OFFSET)],
	Icon.SOURCE: _source_paths(),
	Icon.CONCEDE: [_path(CONCEDE_POLE_PATH), _path(CONCEDE_FLAG_PATH)],
	Icon.ESSENCE: [_path(ESSENCE_GEM_PATH), _path(ESSENCE_BELT_PATH)],
}
## Polygones de chaque forme pleine, du fond au dessus, en coordonnées de la grille.
static var _badge_shapes: Dictionary[Badge, Array] = {
	Badge.DROP: [_drop_path()],
	Badge.DIAMOND: [_path(DIAMOND_PATH)],
	Badge.HEART: [_heart_path(HEART_BADGE_SCALE, HEART_BADGE_OFFSET)],
}
## Centre du chiffre sur la grille : le centre du losange, le corps de la goutte, les lobes du cœur.
static var _badge_text_centers: Dictionary[Badge, Vector2] = {
	Badge.DROP: Vector2(12.0, 15.0),
	Badge.DIAMOND: Vector2(12.0, 12.0),
	Badge.HEART: Vector2(12.0, 11.2),
}


## Dessine `icon` de couleur `color` dans le carré centré sur `rect`, sur le canevas `canvas` :
## le SVG de `assets/icons/` à son nom s'il existe (décision 0051), sinon le tracé de la grille.
static func draw(canvas: CanvasItem, icon: Icon, rect: Rect2, color: Color) -> void:
	var side := minf(rect.size.x, rect.size.y)
	var origin := rect.position + (rect.size - Vector2(side, side)) / 2.0
	var texture := DuelAssets.icon(asset_name(icon))
	if texture != null:
		canvas.draw_texture_rect(texture, Rect2(origin, Vector2(side, side)), false, color)
		return
	var ratio := side / GRID_SIZE
	var width := maxf(STROKE_WIDTH * ratio, 1.0)
	for stroke: PackedVector2Array in _strokes[icon]:
		var points := PackedVector2Array()
		for point: Vector2 in stroke:
			points.append(origin + point * ratio)
		canvas.draw_polyline(points, color, width, true)


## Nom du fichier de `icon` dans `assets/icons/`, sans extension : `unit`, `heart`, `source`…
static func asset_name(icon: Icon) -> String:
	return str(Icon.find_key(icon)).to_lower()


## Dessine la forme `badge` dans le carré centré sur `rect`, remplie et contournée aux couleurs de
## `look`, sur le canevas `canvas`. Le chiffre est un Label posé par `fit_label`.
static func draw_badge(canvas: CanvasItem, badge: Badge, rect: Rect2, look: BadgeLook) -> void:
	var side := minf(rect.size.x, rect.size.y)
	var origin := rect.position + (rect.size - Vector2(side, side)) / 2.0
	var ratio := side / GRID_SIZE
	var width := maxf(BADGE_OUTLINE_WIDTH * ratio, 1.0)
	for shape: PackedVector2Array in _badge_shapes[badge]:
		var points := PackedVector2Array()
		for point: Vector2 in shape:
			points.append(origin + point * ratio)
		canvas.draw_colored_polygon(points, look.fill)
		points.append(points[0])
		canvas.draw_polyline(points, look.outline, width, true)


## Relie un Control vide à une forme pleine, recalculée par `badge_of` et `look_of` à chaque dessin.
static func bind_badge(control: Control, badge_of: Callable, look_of: Callable) -> void:
	control.draw.connect(
		func() -> void:
			var badge: Badge = badge_of.call()
			var look: BadgeLook = look_of.call()
			draw_badge(control, badge, Rect2(Vector2.ZERO, control.size), look)
	)


## Centre `label`, enfant du Control qui dessine `badge`, sur la partie large de la forme.
static func fit_label(label: Label, badge: Badge) -> void:
	var center := _badge_text_centers[badge] / GRID_SIZE
	label.anchor_left = center.x
	label.anchor_right = center.x
	label.anchor_top = center.y
	label.anchor_bottom = center.y
	label.offset_left = 0.0
	label.offset_right = 0.0
	label.offset_top = 0.0
	label.offset_bottom = 0.0
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.grow_vertical = Control.GROW_DIRECTION_BOTH


## Relie un Control vide à `icon`, recalculée par `color_of` à chaque dessin.
static func bind(control: Control, icon_of: Callable, color_of: Callable) -> void:
	control.draw.connect(
		func() -> void:
			var icon: Icon = icon_of.call()
			var color: Color = color_of.call()
			draw(control, icon, Rect2(Vector2.ZERO, control.size), color)
	)


## Relie les icônes de type `type_icons` d'une carte ou d'une pièce à la teinte rendue par
## `tint_of`, recalculée à chaque dessin : icône du type et encre de la teinte.
static func bind_tinted(type_icons: Array[Control], tint_of: Callable) -> void:
	var type_icon := func() -> Icon: return TINT_ICONS[tint_of.call()]
	var ink := func() -> Color: return DuelPalette.TINT_INKS[tint_of.call()]
	for control: Control in type_icons:
		bind(control, type_icon, ink)


static func _path(coordinates: Array[float]) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index: int in range(0, coordinates.size(), 2):
		points.append(Vector2(coordinates[index], coordinates[index + 1]))
	return points


static func _heart_path(heart_scale: float, offset: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for step: int in HEART_POINT_COUNT + 1:
		var angle := TAU * step / HEART_POINT_COUNT
		var x := 16.0 * pow(sin(angle), 3)
		var y := 13.0 * cos(angle) - 5.0 * cos(2 * angle) - 2.0 * cos(3 * angle) - cos(4 * angle)
		points.append(CENTER + offset + Vector2(x, -y) * heart_scale)
	return points


static func _drop_path() -> PackedVector2Array:
	var points := PackedVector2Array([DROP_TIP])
	var tangent_angle := acos(DROP_BODY_RADIUS / DROP_BODY_CENTER.distance_to(DROP_TIP))
	var arc_angle := TAU - 2.0 * tangent_angle
	for step: int in DROP_ARC_POINT_COUNT + 1:
		var angle := tangent_angle + arc_angle * step / DROP_ARC_POINT_COUNT
		points.append(DROP_BODY_CENTER + Vector2(sin(angle), -cos(angle)) * DROP_BODY_RADIUS)
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
