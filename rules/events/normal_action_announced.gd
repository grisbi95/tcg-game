class_name NormalActionAnnounced
extends PlayerEvent
## 208.1.2, 205.2.5, 205.3.1 : le joueur annonce l'action normale d'une de ses pièces vers une case.

var piece_id: int = DuelState.NO_ID
var cell: Vector2i = BoardGeometry.NO_CELL


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A,
	acting_piece_id: int = DuelState.NO_ID,
	target_cell: Vector2i = BoardGeometry.NO_CELL
) -> void:
	super(concerned_player)
	piece_id = acting_piece_id
	cell = target_cell
