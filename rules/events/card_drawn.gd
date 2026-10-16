class_name CardDrawn
extends PlayerEvent
## 201.3.2 : une carte passe du sommet du deck à la main de son joueur.

var card_instance_id: int = DuelState.NO_ID


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A,
	drawn_card_instance_id: int = DuelState.NO_ID
) -> void:
	super(concerned_player)
	card_instance_id = drawn_card_instance_id
