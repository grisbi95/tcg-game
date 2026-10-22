class_name TimeExpired
extends PlayerEvent
## 209.4.9, 209.4.10 : le temps de tour ou le temps de réponse du joueur atteint 0 seconde ; la
## conséquence (fin du tour, passe, choix abandonné) suit dans les événements.

var kind: DuelState.ClockKind = DuelState.ClockKind.TURN


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A,
	clock_kind: DuelState.ClockKind = DuelState.ClockKind.TURN
) -> void:
	super(concerned_player)
	kind = clock_kind
