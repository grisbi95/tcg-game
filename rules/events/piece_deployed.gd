class_name PieceDeployed
extends PlayerEvent
## 205.1.2, 205.1.3 : une carte du joueur entre en jeu comme pièce sur une case libre.

var piece_id: int = DuelState.NO_ID
var cell: Vector2i = BoardGeometry.NO_CELL


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A,
	deployed_piece_id: int = DuelState.NO_ID,
	deploy_cell: Vector2i = BoardGeometry.NO_CELL
) -> void:
	super(concerned_player)
	piece_id = deployed_piece_id
	cell = deploy_cell
