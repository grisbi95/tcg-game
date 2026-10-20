class_name BadgeLook
extends RefCounted
## Couleurs d'une forme pleine portant un chiffre (`DuelIcons.draw_badge`) : remplissage, contour
## et encre du chiffre. Coût, Force (chiffre neutre, vert ou orange) et PV du Hero.

var fill: Color
var outline: Color
var ink: Color


func _init(fill_color: Color, outline_color: Color, ink_color: Color) -> void:
	fill = fill_color
	outline = outline_color
	ink = ink_color


## Goutte du coût en Essence.
static func cost() -> BadgeLook:
	return BadgeLook.new(
		DuelPalette.COST_FILL_COLOR, DuelPalette.COST_OUTLINE_COLOR, DuelPalette.COST_INK_COLOR
	)


## Losange de la Force `force_value`, le même dans tous les cas ; seul le chiffre change : sombre
## si égale à `printed_force`, vert au-dessus, orange foncé en dessous.
static func force(force_value: int, printed_force: int) -> BadgeLook:
	var ink := DuelPalette.CARD_TEXT_COLOR
	if force_value > printed_force:
		ink = DuelPalette.FORCE_UP_INK
	elif force_value < printed_force:
		ink = DuelPalette.FORCE_DOWN_INK
	return BadgeLook.new(DuelPalette.FORCE_FILL_COLOR, DuelPalette.FORCE_OUTLINE_COLOR, ink)


## Cœur des PV du Hero.
static func health() -> BadgeLook:
	return BadgeLook.new(
		DuelPalette.HEALTH_FILL_COLOR,
		DuelPalette.HEALTH_OUTLINE_COLOR,
		DuelPalette.HEALTH_INK_COLOR
	)
