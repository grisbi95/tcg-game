class_name ClockReading
extends RefCounted
## Ce qu'un joueur voit de son temps (209.4) : le temps qui compte pour lui, s'il s'écoule, et le
## temps de tour en pause quand la pile n'est pas vide (209.4.8a). Lu sur le moteur, sans règle.

const NO_PAUSED_TURN: int = -1
const MSEC_PER_SECOND: int = 1000

var kind: DuelState.ClockKind = DuelState.ClockKind.TURN
var remaining_msec: int = 0
var is_running: bool = false
## Temps de tour en pause ; NO_PAUSED_TURN s'il ne l'est pas.
var paused_turn_msec: int = NO_PAUSED_TURN


func _init(
	clock_kind: DuelState.ClockKind = DuelState.ClockKind.TURN,
	time_msec: int = 0,
	running: bool = false,
	paused_msec: int = NO_PAUSED_TURN
) -> void:
	kind = clock_kind
	remaining_msec = time_msec
	is_running = running
	paused_turn_msec = paused_msec


func has_paused_turn() -> bool:
	return paused_turn_msec != NO_PAUSED_TURN


## Change quand l'affichage change : le type, les secondes entamées, l'écoulement et la pause.
func display_key() -> String:
	var paused_seconds := NO_PAUSED_TURN
	if has_paused_turn():
		paused_seconds = started_seconds(paused_turn_msec)
	return "%d|%d|%s|%d" % [kind, started_seconds(remaining_msec), is_running, paused_seconds]


## Secondes entamées : une seconde commencée compte pour une seconde pleine.
static func started_seconds(time_msec: int) -> int:
	return ceili(maxi(time_msec, 0) / float(MSEC_PER_SECOND))
