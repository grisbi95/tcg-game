extends Control
## Essai de DuelColumnView (décisions 0029, 0030, 0032 et 0053) : six colonnes de 711 de haut côte à
## côte, une par situation : Tour de A (bouton actif, abandon visible), Tour de B vu par A (bouton
## grisé « Tour de B »), Pile à trois entrées (réponse de B, fenêtre ouverte), Mulligan (Confirmer
## grisé), Choix d'une cible et Fin. Le Tour de B est aussi la pile vide, une alvéole creusée. Les
## nombres sont factices : un clic ne fait qu'écrire dans la sortie.

const COLUMN_SCENE: PackedScene = preload("res://ui/components/duel_column_view.tscn")
const TURN_NUMBER: int = 7
const SPACING: int = 16
const COLUMN_HEIGHT: float = 711.0
const STACK_ENTRY_IDS: Array[int] = [11, 12, 13]


func _ready() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", SPACING)
	TrySamples.frame(self, row)
	var turn_column := _add_column(row, DuelState.PlayerSide.A)
	turn_column.show_turn(TURN_NUMBER, DuelState.PlayerSide.A, true)
	turn_column.show_concede()
	_add_column(row, DuelState.PlayerSide.A).show_turn(TURN_NUMBER, DuelState.PlayerSide.B, false)
	var stack_column := _add_column(row, DuelState.PlayerSide.B)
	stack_column.show_stack(_stack_lines(), [STACK_ENTRY_IDS[1]], DuelState.PlayerSide.B, true)
	stack_column.show_response_open()
	stack_column.show_concede()
	_add_column(row, DuelState.PlayerSide.A).show_mulligan(DuelState.PlayerSide.A, false)
	var choice_column := _add_column(row, DuelState.PlayerSide.A)
	choice_column.show_choice("Héraut : choisis une Unit ennemie à cibler", DuelState.PlayerSide.A)
	_add_column(row, DuelState.PlayerSide.A).show_ended("Victoire du joueur A")


func _add_column(row: HBoxContainer, viewer: DuelState.PlayerSide) -> DuelColumnView:
	var column: DuelColumnView = COLUMN_SCENE.instantiate()
	column.custom_minimum_size.y = COLUMN_HEIGHT
	row.add_child(column)
	column.set_viewer(viewer)
	column.hide_concede()
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
		(
			StackView
			. StackLine
			. new(STACK_ENTRY_IDS[0], "Recrue", DuelPalette.Tint.UNIT, DuelState.PlayerSide.A)
			. with_help("Unit · Joueur A")
		),
		(
			StackView
			. StackLine
			. new(STACK_ENTRY_IDS[1], "Foudre", DuelPalette.Tint.SPELL, DuelState.PlayerSide.B)
			. with_help("Spell · Joueur B")
		),
		(
			StackView
			. StackLine
			. new(
				STACK_ENTRY_IDS[2], "Contrecarrer", DuelPalette.Tint.SPELL, DuelState.PlayerSide.A
			)
			. with_help("Spell · Joueur A")
		),
	]
