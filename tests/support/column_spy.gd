class_name ColumnSpy
extends DuelColumnView
## Colonne d'essai : enregistre ce qu'on lui demande de montrer, sans scène ni arbre (le script
## n'est jamais prêt, ses `@onready` restent vides). Sert aux suites de `DuelCenterPresenter`.

## Noms des appels reçus, dans l'ordre (`show_turn`, `show_stack`…).
var calls: Array[String] = []
var turn_number: int = 0
var turn_actor: DuelState.PlayerSide = DuelState.PlayerSide.A
var turn_can_end: bool = false
var stack_lines: Array[StackView.StackLine] = []
var stack_highlighted_ids: Array[int] = []
var stack_responder: DuelState.PlayerSide = DuelState.PlayerSide.A
var stack_can_pass: bool = false
var mulligan_player: DuelState.PlayerSide = DuelState.PlayerSide.A
var mulligan_can_confirm: bool = false
var choice_instruction: String = ""
var choice_chooser: DuelState.PlayerSide = DuelState.PlayerSide.A
var choice_lines: Array[StackView.StackLine] = []
var choice_highlighted_ids: Array[int] = []
var ended_text: String = ""


func count_calls(call_name: String) -> int:
	return calls.count(call_name)


func show_turn(turn: int, actor: DuelState.PlayerSide, can_end_turn: bool) -> void:
	calls.append("show_turn")
	turn_number = turn
	turn_actor = actor
	turn_can_end = can_end_turn


func show_stack(
	lines: Array[StackView.StackLine],
	highlighted_ids: Array[int],
	responder: DuelState.PlayerSide,
	can_pass: bool
) -> void:
	calls.append("show_stack")
	stack_lines = lines
	stack_highlighted_ids = highlighted_ids
	stack_responder = responder
	stack_can_pass = can_pass


func show_mulligan(player: DuelState.PlayerSide, can_confirm: bool) -> void:
	calls.append("show_mulligan")
	mulligan_player = player
	mulligan_can_confirm = can_confirm


func show_choice(
	instruction: String,
	chooser: DuelState.PlayerSide,
	lines: Array[StackView.StackLine] = [],
	highlighted_ids: Array[int] = []
) -> void:
	calls.append("show_choice")
	choice_instruction = instruction
	choice_chooser = chooser
	choice_lines = lines
	choice_highlighted_ids = highlighted_ids


func show_ended(result_text: String) -> void:
	calls.append("show_ended")
	ended_text = result_text


func show_response_open() -> void:
	calls.append("show_response_open")


func hide_response() -> void:
	calls.append("hide_response")
