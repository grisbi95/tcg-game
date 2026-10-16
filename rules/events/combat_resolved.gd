class_name CombatResolved
extends DuelEvent
## 206.2.1, 206.2.2 : un combat compare la Force de l'attaquant et celle du défenseur, lues avant
## tout déplacement (206.5.2).

var attacker_piece_id: int = DuelState.NO_ID
var defender_piece_id: int = DuelState.NO_ID
var attacker_force: int = 0
var defender_force: int = 0


func _init(
	attacker_id: int = DuelState.NO_ID,
	defender_id: int = DuelState.NO_ID,
	attacker_force_value: int = 0,
	defender_force_value: int = 0
) -> void:
	attacker_piece_id = attacker_id
	defender_piece_id = defender_id
	attacker_force = attacker_force_value
	defender_force = defender_force_value
