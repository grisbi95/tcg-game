extends Control
## Essai de DuelColumnView (décisions 0029, 0030 et 0032) : cinq colonnes côte à côte, une par état
## du centre (Tour, Pile, Mulligan, Choix, Fin), temps de B estompé et temps de A vif,
## « Abandonner » près du temps de A (Tour) puis de B (Pile). Les
## nombres sont factices : un clic ne fait qu'écrire dans la sortie.

const COLUMN_SCENE: PackedScene = preload("res://ui/components/duel_column_view.tscn")
const TURN_DURATION_MSEC: int = 90_000  # 209.4.3
const RESPONSE_DURATION_MSEC: int = 30_000
const B_REMAINING_MSEC: int = 24_000
const A_REMAINING_MSEC: int = 72_000
const TURN_NUMBER: int = 7
const SPACING: int = 16
const STACK_ENTRY_IDS: Array[int] = [11, 12, 13]


func _ready() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", SPACING)
	TrySamples.frame(self, row)
	var turn_column := _add_column(row)
	turn_column.show_turn(TURN_NUMBER, DuelState.PlayerSide.A, true)
	turn_column.show_concede(DuelState.PlayerSide.A)
	var stack_column := _add_column(row)
	stack_column.show_stack(_stack_lines(), [], DuelState.PlayerSide.B, true)
	stack_column.show_response_open()
	stack_column.show_concede(DuelState.PlayerSide.B)
	_add_column(row).show_mulligan(DuelState.PlayerSide.A, false)
	var choice_column := _add_column(row)
	choice_column.show_choice("Héraut : choisis une Unit ennemie à cibler")
	_add_column(row).show_ended("Victoire du joueur A")


func _add_column(row: HBoxContainer) -> DuelColumnView:
	var column: DuelColumnView = COLUMN_SCENE.instantiate()
	row.add_child(column)
	column.setup(TURN_DURATION_MSEC, RESPONSE_DURATION_MSEC)
	var kind := DuelState.ClockKind
	column.show_clock(DuelState.PlayerSide.A, ClockReading.new(kind.TURN, A_REMAINING_MSEC, true))
	column.show_clock(
		DuelState.PlayerSide.B, ClockReading.new(kind.RESPONSE, B_REMAINING_MSEC, false)
	)
	column.end_turn_pressed.connect(func() -> void: print("Terminer le tour pressé"))
	column.pass_pressed.connect(func() -> void: print("Passer pressé"))
	column.confirm_pressed.connect(func() -> void: print("Confirmer pressé"))
	column.concede_pressed.connect(func() -> void: print("Abandonner pressé"))
	column.stack_entry_pressed.connect(func(id: int) -> void: print("Entrée pressée : ", id))
	column.stack_entry_hovered.connect(func(id: int) -> void: print("Entrée survolée : ", id))
	column.stack_entry_unhovered.connect(func(id: int) -> void: print("Entrée quittée : ", id))
	return column


func _stack_lines() -> Array[StackView.StackLine]:
	return [
		StackView.StackLine.new(
			STACK_ENTRY_IDS[0], "Recrue", DuelPalette.Tint.UNIT, DuelState.PlayerSide.A
		),
		StackView.StackLine.new(
			STACK_ENTRY_IDS[1], "Foudre", DuelPalette.Tint.SPELL, DuelState.PlayerSide.B
		),
		StackView.StackLine.new(
			STACK_ENTRY_IDS[2], "Contrecarrer", DuelPalette.Tint.SPELL, DuelState.PlayerSide.A
		),
	]
