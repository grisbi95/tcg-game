class_name GearAnnounced
extends PlayerEvent
## 208.1.5, 202.2.22 : le joueur annonce un Gear de sa main et l'Unit qui le recevra.

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
