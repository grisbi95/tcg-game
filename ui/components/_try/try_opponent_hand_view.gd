extends Control
## Essai de OpponentHandView (décision 0030) : cinq dos de la main du joueur B.

const HAND_SCENE: PackedScene = preload("res://ui/components/opponent_hand_view.tscn")
const CARD_COUNT: int = 5


func _ready() -> void:
	var column := VBoxContainer.new()
	TrySamples.frame(self, column)
	var hand: OpponentHandView = HAND_SCENE.instantiate()
	column.add_child(hand)
	hand.show_hand(DuelState.PlayerSide.B, CARD_COUNT)
