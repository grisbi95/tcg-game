class_name OpponentHandView
extends HBoxContainer
## Main adverse (201.4.2 ; décision 0030) : un dos réduit de 50×70 par carte, sans chiffre,
## bordé de la couleur de son joueur, centré dans sa zone.

## Décision 0030 : écart de 8 px entre les dos.
const BACK_GAP: int = 8

const BACK_SCENE: PackedScene = preload("res://ui/components/card_back_view.tscn")


func _ready() -> void:
	custom_minimum_size.y = CardBackView.HAND_SIZE.y
	add_theme_constant_override("separation", BACK_GAP)


## Montre `card_count` dos de cartes du joueur `side`.
func show_hand(side: DuelState.PlayerSide, card_count: int) -> void:
	ViewNodes.free_children(self)
	for index: int in card_count:
		var back: CardBackView = BACK_SCENE.instantiate()
		add_child(back)
		back.show_back(side, CardBackView.HAND_SIZE)
