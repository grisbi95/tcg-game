class_name CardDiscarded
extends PlayerEvent
## 205.1.10, 201.3.6a : la carte va dans la défausse du joueur, faute de place dans sa main.

var card_instance_id: int = DuelState.NO_ID


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A,
	discarded_card_id: int = DuelState.NO_ID
) -> void:
	super(concerned_player)
	card_instance_id = discarded_card_id
