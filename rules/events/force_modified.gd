class_name ForceModified
extends PlayerEvent
## 207.4.2, 206.5.1 : un effet à durée modifie la Force d'une pièce du joueur.

var piece_id: int = DuelState.NO_ID
var amount: int = 0
var effect_id: int = DuelState.NO_ID


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A,
	modified_piece_id: int = DuelState.NO_ID,
	force_change: int = 0,
	active_effect_id: int = DuelState.NO_ID
) -> void:
	super(concerned_player)
	piece_id = modified_piece_id
	amount = force_change
	effect_id = active_effect_id
