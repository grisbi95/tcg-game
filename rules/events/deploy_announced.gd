class_name DeployAnnounced
extends PlayerEvent
## 208.1.1, 205.1.5 : le joueur annonce le déploiement d'une carte de sa main sur une case.

var card_instance_id: int = DuelState.NO_ID
var cell: Vector2i = BoardGeometry.NO_CELL


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A,
	deployed_card_id: int = DuelState.NO_ID,
	target_cell: Vector2i = BoardGeometry.NO_CELL
) -> void:
	super(concerned_player)
	card_instance_id = deployed_card_id
	cell = target_cell
