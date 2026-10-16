class_name CardReturnedToHand
extends PlayerEvent
## 205.1.7, 205.1.8 : la carte d'un déploiement revient dans la main du joueur.

var card_instance_id: int = DuelState.NO_ID


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A,
	returned_card_id: int = DuelState.NO_ID
) -> void:
	super(concerned_player)
	card_instance_id = returned_card_id
