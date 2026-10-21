class_name PreviewSpy
extends HoverPreview
## Aperçu d'essai : enregistre ce qu'on lui demande de montrer, sans scène ni arbre (le script
## n'est jamais prêt, ses `@onready` restent vides). Sert aux suites de `DuelPreviewer`.

## Noms des appels reçus, dans l'ordre : `show_card`, `show_hero`, `show_token`, `hide_preview`.
var calls: Array[String] = []
var shown_card: CardDefinition = null
var shown_hero: HeroDefinition = null
var shown_gear: CardDefinition = null
var shown_token_type: CardDefinition.CardType = CardDefinition.CardType.UNIT
var shown_token_force: int = 0


func show_card(definition: CardDefinition, gear: CardDefinition = null) -> void:
	calls.append("show_card")
	shown_card = definition
	shown_gear = gear


func show_hero(hero: HeroDefinition, gear: CardDefinition = null) -> void:
	calls.append("show_hero")
	shown_hero = hero
	shown_gear = gear


func show_token(
	card_type: CardDefinition.CardType, force: int, gear: CardDefinition = null
) -> void:
	calls.append("show_token")
	shown_token_type = card_type
	shown_token_force = force
	shown_gear = gear


func hide_preview() -> void:
	calls.append("hide_preview")
