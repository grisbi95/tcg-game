class_name TurnStarted
extends PlayerEvent
## 204.3 : le tour du joueur commence.

## Numéro du tour global, commencé à 1.
var turn_number: int = DuelState.NO_TURN


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A,
	started_turn_number: int = DuelState.NO_TURN
) -> void:
	super(concerned_player)
	turn_number = started_turn_number
