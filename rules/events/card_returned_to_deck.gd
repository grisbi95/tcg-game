class_name CardReturnedToDeck
extends PlayerEvent
## 204.2.6, 204.2.11 : une carte passe de l'Écart au deck de son joueur.

var card_instance_id: int = DuelState.NO_ID


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A,
	returned_card_instance_id: int = DuelState.NO_ID
) -> void:
	super(concerned_player)
	card_instance_id = returned_card_instance_id
