class_name DuelColumnView
extends PanelContainer
## Colonne de duel (décisions 0028, 0030 et 0032) : temps de B en haut, de A en bas, et au centre
## un seul grand bouton qui change selon le moment. Le parent choisit l'état du centre
## (`show_turn`, `show_stack`, `show_mulligan`, `show_choice`, `show_ended`) et ce que montre le
## temps de chaque joueur ; la colonne ne calcule rien et n'a aucune règle. Un petit bouton
## « Abandonner » (décision 0036) se pose près du temps du joueur qui a l'appareil.

signal end_turn_pressed
signal pass_pressed
signal confirm_pressed
signal concede_pressed
signal stack_entry_pressed(stack_entry_id: int)
signal stack_entry_hovered(stack_entry_id: int)
signal stack_entry_unhovered(stack_entry_id: int)

## Ajouter à la fin, sans réordonner.
enum CenterState {
	TURN,
	STACK,
	MULLIGAN,
	CHOICE,
	ENDED,
}

## Ce que montre la pile sous « Passer » : rien tant que le joueur n'a pas l'appareil (décision
## 0036), ou la mention de sa fenêtre de réponse ouverte (208.6.1).
enum ResponseDisplay { NONE, OPEN }

const END_TURN_TEXT: String = "Terminer le tour"
const PASS_TEXT: String = "Passer"
const CONFIRM_TEXT: String = "Confirmer"
const MULLIGAN_HINT: String = "Mulligan : choisis les cartes à écarter"

var _center_state: CenterState = CenterState.TURN
var _has_stack: bool = false
var _response_display: ResponseDisplay = ResponseDisplay.NONE
var _clock_keys: Dictionary[DuelState.PlayerSide, String] = {}

@onready var _clocks: Dictionary[DuelState.PlayerSide, ClockView] = {
	DuelState.PlayerSide.A: %BottomClock,
	DuelState.PlayerSide.B: %TopClock,
}
@onready var _concede_buttons: Dictionary[DuelState.PlayerSide, Button] = {
	DuelState.PlayerSide.A: %BottomConcedeButton,
	DuelState.PlayerSide.B: %TopConcedeButton,
}
@onready var _turn_number_label: Label = %TurnNumberLabel
@onready var _hint_panel: PanelContainer = %HintPanel
@onready var _hint_label: Label = %HintLabel
@onready var _stack_title_label: Label = %StackTitleLabel
@onready var _stack_scroll: ScrollContainer = %StackScroll
@onready var _stack_view: StackView = %StackView
@onready var _actor_label: Label = %ActorLabel
@onready var _big_button: Button = %BigButton
@onready var _response_label: Label = %ResponseLabel


func _ready() -> void:
	_big_button.pressed.connect(_on_big_button_pressed)
	for button: Button in _concede_buttons.values():
		button.pressed.connect(concede_pressed.emit)
	_stack_view.stack_entry_pressed.connect(stack_entry_pressed.emit)
	_stack_view.stack_entry_hovered.connect(stack_entry_hovered.emit)
	_stack_view.stack_entry_unhovered.connect(stack_entry_unhovered.emit)
	_refresh_center()


## Temps des joueurs : un temps de tour part de `turn_duration_msec`, un temps de réponse de
## `response_duration_msec` (209.4.3) ; le temps de `bottom_side` est en bas (décision 0050).
func setup(
	turn_duration_msec: int,
	response_duration_msec: int,
	bottom_side: DuelState.PlayerSide = DuelState.PlayerSide.A
) -> void:
	if bottom_side != DuelState.PlayerSide.A:
		ScreenSides.swap(_clocks)
		ScreenSides.swap(_concede_buttons)
	for side: DuelState.PlayerSide in _clocks:
		_clocks[side].setup(
			side, PlayerNames.display_name(side), turn_duration_msec, response_duration_msec
		)
	_clock_keys.clear()


## Temps de `side` tel que `reading` le décrit (209.4.4). Peut être appelée à chaque image : le
## temps ne se redessine que si son affichage change.
func show_clock(side: DuelState.PlayerSide, reading: ClockReading) -> void:
	var key := reading.display_key()
	if _clock_keys.get(side, "") == key:
		return
	_clock_keys[side] = key
	_clocks[side].show_clock(reading)


## Pile vide : « Tour N », qui joue, et « Terminer le tour » si `can_end_turn`.
func show_turn(turn_number: int, actor: DuelState.PlayerSide, can_end_turn: bool) -> void:
	_center_state = CenterState.TURN
	_turn_number_label.text = "Tour %d" % turn_number
	_set_actor("Au joueur %s" % PlayerNames.letter(actor), actor)
	_set_button(END_TURN_TEXT, actor, can_end_turn)
	_refresh_center()


## Pile non vide : ses `lines` (de la base au sommet), dont `highlighted_ids` se pressent, et
## « Passer » aux couleurs de `responder`, actif si `can_pass`.
func show_stack(
	lines: Array[StackView.StackLine],
	highlighted_ids: Array[int],
	responder: DuelState.PlayerSide,
	can_pass: bool
) -> void:
	_center_state = CenterState.STACK
	_show_stack_lines(lines, highlighted_ids)
	_set_actor("%s peut répondre" % PlayerNames.display_name(responder), responder)
	_set_button(PASS_TEXT, responder, can_pass)
	_refresh_center()


## Mulligan (204.2) de `player` : la consigne et « Confirmer », actif si `can_confirm`.
func show_mulligan(player: DuelState.PlayerSide, can_confirm: bool) -> void:
	_center_state = CenterState.MULLIGAN
	_hint_label.text = MULLIGAN_HINT
	_set_button(CONFIRM_TEXT, player, can_confirm)
	_refresh_center()


## Choix demandé par le moteur : la `instruction`, sans bouton ; si l'ordre des effets se choisit
## dans la pile, ses `lines` restent affichées et `highlighted_ids` se pressent.
func show_choice(
	instruction: String, lines: Array[StackView.StackLine] = [], highlighted_ids: Array[int] = []
) -> void:
	_center_state = CenterState.CHOICE
	_hint_label.text = instruction
	_show_stack_lines(lines, highlighted_ids)
	_refresh_center()


## Fin de partie : une ligne de résultat (le relais et l'écran de fin viennent à l'étape 2.4).
func show_ended(result_text: String) -> void:
	_center_state = CenterState.ENDED
	_hint_label.text = result_text
	_refresh_center()


## La fenêtre de réponse est ouverte (208.6.1) : le joueur doit répondre ou passer, sans échéance
## (208.6.2).
func show_response_open() -> void:
	_set_response_display(ResponseDisplay.OPEN)


## Aucune fenêtre de réponse à montrer : relais en cours ou événements à l'affichage.
func hide_response() -> void:
	_set_response_display(ResponseDisplay.NONE)


## Montre « Abandonner » près du temps de `side` seulement ; l'autre est caché.
func show_concede(side: DuelState.PlayerSide) -> void:
	for button_side: DuelState.PlayerSide in _concede_buttons:
		_concede_buttons[button_side].visible = button_side == side


func hide_concede() -> void:
	for button: Button in _concede_buttons.values():
		button.visible = false


func _set_actor(text: String, side: DuelState.PlayerSide) -> void:
	_actor_label.text = text
	_actor_label.add_theme_color_override("font_color", DuelPalette.player_ink(side))


func _set_button(text: String, side: DuelState.PlayerSide, is_enabled: bool) -> void:
	_big_button.text = text
	_big_button.disabled = not is_enabled
	DuelPalette.apply_player_button(_big_button, side)


func _show_stack_lines(lines: Array[StackView.StackLine], highlighted_ids: Array[int]) -> void:
	_has_stack = not lines.is_empty()
	_stack_title_label.text = "Pile · %d" % lines.size()
	_stack_view.show_entries(lines, highlighted_ids)


func _set_response_display(response_display: ResponseDisplay) -> void:
	if response_display == _response_display:
		return
	_response_display = response_display
	_refresh_center()


func _refresh_center() -> void:
	var shown: Array[Control] = []
	match _center_state:
		CenterState.TURN:
			shown = [_turn_number_label, _actor_label, _big_button]
		CenterState.STACK:
			shown = [_stack_title_label, _stack_scroll, _actor_label, _big_button]
			if _response_display == ResponseDisplay.OPEN:
				shown.append(_response_label)
		CenterState.MULLIGAN:
			shown = [_hint_panel, _big_button]
		CenterState.CHOICE:
			shown = [_hint_panel]
			if _has_stack:
				shown.append_array([_stack_title_label, _stack_scroll])
		CenterState.ENDED:
			shown = [_hint_panel]
	for node: Control in _center_nodes():
		node.visible = shown.has(node)


func _center_nodes() -> Array[Control]:
	return [
		_turn_number_label,
		_hint_panel,
		_stack_title_label,
		_stack_scroll,
		_actor_label,
		_big_button,
		_response_label,
	]


func _on_big_button_pressed() -> void:
	match _center_state:
		CenterState.TURN:
			end_turn_pressed.emit()
		CenterState.STACK:
			pass_pressed.emit()
		CenterState.MULLIGAN:
			confirm_pressed.emit()
