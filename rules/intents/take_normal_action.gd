class_name TakeNormalAction
extends DuelIntent
## 204.4.5, 208.1.2 : le joueur actif annonce l'action normale d'une de ses pièces vers une case
## adjacente ; elle ne coûte aucune Essence (205.2.4).

var piece_id: int = DuelState.NO_ID
var cell: Vector2i = BoardGeometry.NO_CELL


func _init(
	author: DuelState.PlayerSide = DuelState.PlayerSide.A,
	acting_piece_id: int = DuelState.NO_ID,
	target_cell: Vector2i = BoardGeometry.NO_CELL
) -> void:
	super(author)
	piece_id = acting_piece_id
	cell = target_cell
