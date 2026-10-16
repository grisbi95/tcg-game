class_name CardSetAside
extends PlayerEvent
## 201.3.9, 204.2.10 : une carte passe de la main à l'Écart de son joueur.

var card_instance_id: int = DuelState.NO_ID


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A,
	set_aside_card_instance_id: int = DuelState.NO_ID
) -> void:
	super(concerned_player)
	card_instance_id = set_aside_card_instance_id
