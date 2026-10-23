extends Control
## Essai de HeroCardView (décision 0032) : les cartes Hero de A et de B.
## Les survols s'écrivent dans la sortie.

const HERO_CARD_SCENE: PackedScene = preload("res://ui/components/hero_card_view.tscn")
const CARD_GAP: int = 60


func _ready() -> void:
	var hero := TrySamples.catalog().get_hero(TrySamples.HERO_ID)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", CARD_GAP)
	TrySamples.frame(self, row)
	_add_hero_card(row, DuelState.PlayerSide.A, hero)
	_add_hero_card(row, DuelState.PlayerSide.B, hero)


func _add_hero_card(
	row: HBoxContainer, player: DuelState.PlayerSide, hero: HeroDefinition
) -> HeroCardView:
	var card: HeroCardView = HERO_CARD_SCENE.instantiate()
	row.add_child(card)
	card.setup(player, hero)
	var side_name := EventText.player_label(player)
	card.hero_card_hovered.connect(func() -> void: print("survol, joueur ", side_name))
	card.hero_card_unhovered.connect(func() -> void: print("fin de survol, joueur ", side_name))
	return card
