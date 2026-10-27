class_name FilterAnchor
extends RefCounted
## Point de référence d'un PieceFilter à l'évaluation (décision 0062) : le joueur à qui appartient
## l'effet, la pièce de référence et sa case. La case d'une pièce partie du plateau est sa dernière
## (207.3.14). Construit à chaque évaluation par EffectRules ou ModifierRules, jamais conservé ni
## cloné.

var owner: DuelState.PlayerSide
var piece_id: int
var cell: Vector2i


func _init(
	owner_value: DuelState.PlayerSide = DuelState.PlayerSide.A,
	piece_id_value: int = DuelState.NO_ID,
	cell_value: Vector2i = BoardGeometry.NO_CELL
) -> void:
	owner = owner_value
	piece_id = piece_id_value
	cell = cell_value
