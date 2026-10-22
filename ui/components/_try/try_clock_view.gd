extends Control
## Essai de ClockView (décisions 0028 et 0045) : de haut en bas, B qui attend (Réponse 0:24,
## estompé), A dans son temps de tour (Tour 1:12), A qui répond sous l'alerte (Réponse 0:08) et A
## avec son temps de tour en pause, dans la largeur de la colonne de duel.

const CLOCK_SCENE: PackedScene = preload("res://ui/components/clock_view.tscn")
const TURN_DURATION_MSEC: int = 90_000  # 209.4.3
const RESPONSE_DURATION_MSEC: int = 30_000
const TURN_REMAINING_MSEC: int = 72_000
const RESPONSE_REMAINING_MSEC: int = 24_000
const ALERT_REMAINING_MSEC: int = 8_000
const COLUMN_WIDTH: float = 200.0
const A := DuelState.PlayerSide.A
const B := DuelState.PlayerSide.B
const KIND := DuelState.ClockKind


func _ready() -> void:
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = COLUMN_WIDTH
	column.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	TrySamples.frame(self, column)
	_add_clock(column, B, ClockReading.new(KIND.RESPONSE, RESPONSE_REMAINING_MSEC, false))
	_add_clock(column, A, ClockReading.new(KIND.TURN, TURN_REMAINING_MSEC, true))
	_add_clock(column, A, ClockReading.new(KIND.RESPONSE, ALERT_REMAINING_MSEC, true))
	var paused := ClockReading.new(
		KIND.RESPONSE, RESPONSE_REMAINING_MSEC, true, TURN_REMAINING_MSEC
	)
	_add_clock(column, A, paused)


func _add_clock(column: VBoxContainer, side: DuelState.PlayerSide, reading: ClockReading) -> void:
	var clock: ClockView = CLOCK_SCENE.instantiate()
	column.add_child(clock)
	clock.setup(
		side,
		"Joueur %s" % DuelState.PlayerSide.keys()[side],
		TURN_DURATION_MSEC,
		RESPONSE_DURATION_MSEC
	)
	clock.show_clock(reading)
