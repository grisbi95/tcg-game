class_name OrderAnnounced
extends PlayerEvent
## 208.1.12, 211.2.2 : le joueur annonce un Ordre de son Hero, qui s'endort aussitôt.

var piece_id: int = DuelState.NO_ID
var order_index: int = 0


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A,
	hero_piece_id: int = DuelState.NO_ID,
	rank: int = 0
) -> void:
	super(concerned_player)
	piece_id = hero_piece_id
	order_index = rank
