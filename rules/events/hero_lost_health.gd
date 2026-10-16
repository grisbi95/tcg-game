class_name HeroLostHealth
extends PlayerEvent
## 209.5.3 : le Hero du joueur perd des PV.

var amount: int = 0


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A, lost_health: int = 0
) -> void:
	super(concerned_player)
	amount = lost_health
