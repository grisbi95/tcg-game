class_name PieceMoved
extends PlayerEvent
## 205.2.2, 205.3.1, 206.3.3 : une pièce du joueur change de case.

var piece_id: int = DuelState.NO_ID
var from_cell: Vector2i = BoardGeometry.NO_CELL
var to_cell: Vector2i = BoardGeometry.NO_CELL


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A,
	moved_piece_id: int = DuelState.NO_ID,
	previous_cell: Vector2i = BoardGeometry.NO_CELL,
	new_cell: Vector2i = BoardGeometry.NO_CELL
) -> void:
	super(concerned_player)
	piece_id = moved_piece_id
	from_cell = previous_cell
	to_cell = new_cell
