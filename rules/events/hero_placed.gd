class_name HeroPlaced
extends PlayerEvent
## 204.1.1, 204.1.8 : le Hero du joueur est placé sur sa case de départ avec ses PV.

var piece_id: int = DuelState.NO_ID
var cell: Vector2i = BoardGeometry.NO_CELL


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A,
	placed_piece_id: int = DuelState.NO_ID,
	start_cell: Vector2i = BoardGeometry.NO_CELL
) -> void:
	super(concerned_player)
	piece_id = placed_piece_id
	cell = start_cell
