extends Control
## Essai de ClockView (décision 0028) : la pendule de B arrêtée (4 min 12 s), celle de A qui
## tourne (5 min 3 s), dans la largeur de la colonne de duel.

const CLOCK_SCENE: PackedScene = preload("res://ui/components/clock_view.tscn")
const DURATION_MSEC: int = 600_000  # 209.4.3
const B_REMAINING_MSEC: int = 252_000
const A_REMAINING_MSEC: int = 303_000
const COLUMN_WIDTH: float = 200.0


func _ready() -> void:
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = COLUMN_WIDTH
	column.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	TrySamples.frame(self, column)
	_add_clock(column, DuelState.PlayerSide.B).show_clock(B_REMAINING_MSEC, false)
	_add_clock(column, DuelState.PlayerSide.A).show_clock(A_REMAINING_MSEC, true)


func _add_clock(column: VBoxContainer, owner: DuelState.PlayerSide) -> ClockView:
	var clock: ClockView = CLOCK_SCENE.instantiate()
	column.add_child(clock)
	clock.setup(owner, "Joueur %s" % DuelState.PlayerSide.keys()[owner], DURATION_MSEC)
	return clock
