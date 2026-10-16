class_name PieceEnteredAttacking
extends PlayerEvent
## 205.1.6 : une Unit du joueur entre en jeu en attaquant la pièce ennemie de sa case.

var piece_id: int = DuelState.NO_ID
var cell: Vector2i = BoardGeometry.NO_CELL


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A,
	deployed_piece_id: int = DuelState.NO_ID,
	target_cell: Vector2i = BoardGeometry.NO_CELL
) -> void:
	super(concerned_player)
	piece_id = deployed_piece_id
	cell = target_cell
