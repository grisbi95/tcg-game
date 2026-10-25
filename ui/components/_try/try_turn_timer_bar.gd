extends Control
## Essai de TurnTimerBar (décisions 0045 et 0053), dans la largeur de la grille (711 px) : de haut
## en bas, A actif (tour 72 s), B actif sous l'alerte (réponse 8 s), A actif avec un tour de 54 s
## en pause, B inactif, A inactif avec un tour de 54 s en pause, et B inactif sans temps en pause.

const TURN_DURATION_MSEC: int = 90_000  # 209.4.3
const RESPONSE_DURATION_MSEC: int = 30_000
const TURN_REMAINING_MSEC: int = 72_000
const RESPONSE_REMAINING_MSEC: int = 24_000
const ALERT_REMAINING_MSEC: int = 8_000
const PAUSED_TURN_MSEC: int = 54_000
const BAR_WIDTH: float = 711.0
const ROW_SPACING: int = 30
const A := DuelState.PlayerSide.A
const B := DuelState.PlayerSide.B
const KIND := DuelState.ClockKind

var _column: VBoxContainer


func _ready() -> void:
	_column = VBoxContainer.new()
	_column.custom_minimum_size.x = BAR_WIDTH
	_column.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_column.add_theme_constant_override("separation", ROW_SPACING)
	TrySamples.frame(self, _column)
	_add_bar(A, ClockReading.new(KIND.TURN, TURN_REMAINING_MSEC, true))
	_add_bar(B, ClockReading.new(KIND.RESPONSE, ALERT_REMAINING_MSEC, true))
	_add_bar(A, ClockReading.new(KIND.RESPONSE, RESPONSE_REMAINING_MSEC, true, PAUSED_TURN_MSEC))
	_add_bar(B, ClockReading.new(KIND.RESPONSE, RESPONSE_DURATION_MSEC, false))
	_add_bar(A, ClockReading.new(KIND.TURN, TURN_DURATION_MSEC, false, PAUSED_TURN_MSEC))
	_add_bar(B, ClockReading.new(KIND.TURN, TURN_DURATION_MSEC, false))


func _add_bar(side: DuelState.PlayerSide, reading: ClockReading) -> void:
	var bar: TurnTimerBar = preload("res://ui/components/turn_timer_bar.tscn").instantiate()
	_column.add_child(bar)
	bar.setup(side, TURN_DURATION_MSEC, RESPONSE_DURATION_MSEC)
	bar.show_reading(reading)
