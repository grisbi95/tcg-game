class_name FatigueIncreased
extends PlayerEvent
## 209.5.2 : le compteur de fatigue du joueur augmente.

## Nouvelle valeur du compteur.
var fatigue_counter: int = 0


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A, new_fatigue_counter: int = 0
) -> void:
	super(concerned_player)
	fatigue_counter = new_fatigue_counter
