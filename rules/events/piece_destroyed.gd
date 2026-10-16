class_name PieceDestroyed
extends PlayerEvent
## 206.3.1, 206.3.2 : une pièce du joueur est détruite et quitte le plateau.

var piece_id: int = DuelState.NO_ID


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A,
	destroyed_piece_id: int = DuelState.NO_ID
) -> void:
	super(concerned_player)
	piece_id = destroyed_piece_id
