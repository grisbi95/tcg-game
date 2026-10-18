class_name HoverPreview
extends HBoxContainer
## Aperçu en grand de la carte survolée, sans libellé (décisions 0027 et 0028) : la carte complète
## d'une carte en main, d'une pièce, de la défausse ou d'une entrée de pile, et celle de son Gear à
## côté s'il y en a un (202.2.10).

## Décision 0028 : environ 348 × 484 pour une carte seule ; avec son Gear, les deux cartes
## rapetissent pour tenir entre la marge et le plateau (conseil de l'agent UI).
const SINGLE_SCALE: float = 2.2
const PAIR_SCALE: float = 1.7

@onready var _card_view: CardView = %CardView
@onready var _gear_view: CardView = %GearView


func _ready() -> void:
	visible = false


## Carte de deck ; `gear`, le Gear attaché à sa pièce, ou null.
func show_card(definition: CardDefinition, gear: CardDefinition = null) -> void:
	_card_view.show_card(DuelState.NO_ID, definition)
	_show_gear(gear)


## Carte du Hero ; `gear`, le Gear attaché, ou null.
func show_hero(hero: HeroDefinition, gear: CardDefinition = null) -> void:
	_card_view.show_hero(hero)
	_show_gear(gear)


## Jeton (202.4) ; `gear`, le Gear attaché, ou null.
func show_token(
	card_type: CardDefinition.CardType, force: int, gear: CardDefinition = null
) -> void:
	_card_view.show_token(card_type, force)
	_show_gear(gear)


func hide_preview() -> void:
	visible = false


func _show_gear(gear: CardDefinition) -> void:
	var has_gear := gear != null
	var card_scale := PAIR_SCALE if has_gear else SINGLE_SCALE
	_card_view.set_card_scale(card_scale)
	_gear_view.visible = has_gear
	if has_gear:
		_gear_view.set_card_scale(card_scale)
		_gear_view.show_card(DuelState.NO_ID, gear)
	visible = true
