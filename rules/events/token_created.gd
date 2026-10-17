class_name TokenCreated
extends PlayerEvent
## 202.4.1, 202.4.12, 201.5.4 : un jeton du joueur est créé sur une case.

var piece_id: int = DuelState.NO_ID
var cell: Vector2i = BoardGeometry.NO_CELL


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A,
	token_piece_id: int = DuelState.NO_ID,
	token_cell: Vector2i = BoardGeometry.NO_CELL
) -> void:
	super(concerned_player)
	piece_id = token_piece_id
	cell = token_cell
