class_name HeroAttacked
extends PlayerEvent
## 206.4.1, 206.4.2 : une Unit attaque le Hero du joueur, qui perd autant de PV que sa Force.

var attacker_piece_id: int = DuelState.NO_ID
var attacker_force: int = 0


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A,
	attacker_id: int = DuelState.NO_ID,
	attacker_force_value: int = 0
) -> void:
	super(concerned_player)
	attacker_piece_id = attacker_id
	attacker_force = attacker_force_value
