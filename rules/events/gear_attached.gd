class_name GearAttached
extends PlayerEvent
## 202.2.6, 202.2.10, 207.2.3a : un Gear du joueur s'attache à une Unit ; son effet statique
## commence.

var card_instance_id: int = DuelState.NO_ID
var piece_id: int = DuelState.NO_ID


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A,
	gear_card_id: int = DuelState.NO_ID,
	unit_piece_id: int = DuelState.NO_ID
) -> void:
	super(concerned_player)
	card_instance_id = gear_card_id
	piece_id = unit_piece_id
