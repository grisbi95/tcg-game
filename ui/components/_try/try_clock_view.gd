extends Control
## Essai de ClockView : la pendule de A qui tourne (9 min 5 s), celle de B arrêtée (10 min).

const CLOCK_SCENE: PackedScene = preload("res://ui/components/clock_view.tscn")
const RUNNING_MSEC: int = 545_000
const FULL_MSEC: int = 600_000  # 209.4.3


func _ready() -> void:
	var row := HBoxContainer.new()
	TrySamples.frame(self, row)
	_add_clock(row, DuelState.PlayerSide.A).show_clock(RUNNING_MSEC, true)
	_add_clock(row, DuelState.PlayerSide.B).show_clock(FULL_MSEC, false)


func _add_clock(row: HBoxContainer, owner: DuelState.PlayerSide) -> ClockView:
	var clock: ClockView = CLOCK_SCENE.instantiate()
	row.add_child(clock)
	clock.setup(owner)
	return clock
