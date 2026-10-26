class_name PiecesSwapped
extends PlayerEvent
## 214.1.1, 214.1.2, 214.2.5 : deux Units du joueur échangent leurs cases en même temps. Distinct
## de PieceMoved : un échange n'est pas un déplacement.

var first_piece_id: int = DuelState.NO_ID
var second_piece_id: int = DuelState.NO_ID
## Case qu'occupait la première pièce avant l'échange (la seconde l'occupe ensuite).
var first_cell: Vector2i = BoardGeometry.NO_CELL
## Case qu'occupait la seconde pièce avant l'échange (la première l'occupe ensuite).
var second_cell: Vector2i = BoardGeometry.NO_CELL


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A,
	first_id: int = DuelState.NO_ID,
	second_id: int = DuelState.NO_ID
) -> void:
	super(concerned_player)
	first_piece_id = first_id
	second_piece_id = second_id
