class_name DuelColumnView
extends PanelContainer
## Colonne de duel (décisions 0028, 0030 et 0032) : pendule de B en haut, de A en bas, et au
## centre un seul grand bouton qui change selon le moment. Le parent choisit l'état du centre
## (`show_turn`, `show_stack`, `show_mulligan`, `show_choice`, `show_ended`) et dit quelles
## pendules tournent ; la colonne ne calcule rien et n'a aucune règle.

signal end_turn_pressed
signal pass_pressed
signal confirm_pressed
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

const MSEC_PER_SECOND: int = 1000
const MSEC_PER_TENTH: int = 100
const TENTHS_PER_SECOND: int = 10
const BAR_STEPS: int = 100
const BAR_RADIUS: int = 4
const PANEL_BORDER_WIDTH: int = 1
const PANEL_MARGIN: float = 10.0
const HINT_BORDER_WIDTH: int = 1
const HINT_MARGIN: float = 8.0
const END_TURN_TEXT: String = "Terminer le tour"
const PASS_TEXT: String = "Passer"
const CONFIRM_TEXT: String = "Confirmer"
const MULLIGAN_HINT: String = "Mulligan : choisis les cartes à écarter"
const STOPPED_TEXT: String = "Décompte arrêté : réponds ou passe"
const BUTTON_COLOR_NAMES: Array[StringName] = [
	&"font_color",
	&"font_hover_color",
	&"font_pressed_color",
	&"font_hover_pressed_color",
	&"font_focus_color",
]
const BUTTON_STATE_STYLES: Dictionary[DuelPalette.ButtonState, StringName] = {
	DuelPalette.ButtonState.NORMAL: &"normal",
	DuelPalette.ButtonState.HOVER: &"hover",
	DuelPalette.ButtonState.PRESSED: &"pressed",
	DuelPalette.ButtonState.DISABLED: &"disabled",
}

var _center_state: CenterState = CenterState.TURN
var _has_stack: bool = false
var _is_response_running: bool = false
var _response_tenths: int = -1
var _response_bar_step: int = -1
var _clock_stamps: Dictionary[DuelState.PlayerSide, int] = {}

@onready var _clocks: Dictionary[DuelState.PlayerSide, ClockView] = {
	DuelState.PlayerSide.A: %BottomClock,
	DuelState.PlayerSide.B: %TopClock,
}
@onready var _turn_number_label: Label = %TurnNumberLabel
@onready var _hint_panel: PanelContainer = %HintPanel
@onready var _hint_label: Label = %HintLabel
@onready var _stack_title_label: Label = %StackTitleLabel
@onready var _stack_scroll: ScrollContainer = %StackScroll
@onready var _stack_view: StackView = %StackView
@onready var _actor_label: Label = %ActorLabel
@onready var _big_button: Button = %BigButton
@onready var _response_zone: VBoxContainer = %ResponseZone
@onready var _countdown_row: HBoxContainer = %CountdownRow
@onready var _countdown_bar: ProgressBar = %CountdownBar
@onready var _countdown_label: Label = %CountdownLabel
@onready var _stopped_label: Label = %StoppedLabel


func _ready() -> void:
	add_theme_stylebox_override(
		"panel",
		DuelPalette.framed_style(
			DuelPalette.PANEL_COLOR, DuelPalette.CELL_LINE_COLOR, PANEL_BORDER_WIDTH, PANEL_MARGIN
		)
	)
	_hint_panel.add_theme_stylebox_override(
		"panel",
		DuelPalette.framed_style(
			DuelPalette.HINT_COLOR, DuelPalette.CELL_LINE_COLOR, HINT_BORDER_WIDTH, HINT_MARGIN
		)
	)
	_style_texts()
	_big_button.pressed.connect(_on_big_button_pressed)
	_stack_view.stack_entry_pressed.connect(stack_entry_pressed.emit)
	_stack_view.stack_entry_hovered.connect(stack_entry_hovered.emit)
	_stack_view.stack_entry_unhovered.connect(stack_entry_unhovered.emit)
	_refresh_center()


## Pendules de A et de B, qui partent de `clock_duration_msec` (209.4.3).
func setup(clock_duration_msec: int) -> void:
	for side: DuelState.PlayerSide in _clocks:
		_clocks[side].setup(side, "Joueur %s" % _side_letter(side), clock_duration_msec)
	_clock_stamps.clear()


## Temps restant de chaque joueur ; `running_owners` sont ceux dont la pendule tourne (209.4.4).
## Peut être appelée à chaque image : une pendule ne se redessine que si ses secondes changent.
func show_clocks(
	remaining_a_msec: int, remaining_b_msec: int, running_owners: Array[DuelState.PlayerSide]
) -> void:
	_show_clock(DuelState.PlayerSide.A, remaining_a_msec, running_owners)
	_show_clock(DuelState.PlayerSide.B, remaining_b_msec, running_owners)


## Pile vide : « Tour N », qui joue, et « Terminer le tour » si `can_end_turn`.
func show_turn(turn_number: int, actor: DuelState.PlayerSide, can_end_turn: bool) -> void:
	_center_state = CenterState.TURN
	_turn_number_label.text = "Tour %d" % turn_number
	_set_actor("Au joueur %s" % _side_letter(actor), actor)
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
	_set_actor("Joueur %s peut répondre" % _side_letter(responder), responder)
	_set_button(PASS_TEXT, responder, can_pass)
	_style_countdown(responder)
	_refresh_center()


## Mulligan (205.2) de `player` : la consigne et « Confirmer », actif si `can_confirm`.
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


## Décompte de la fenêtre de réponse (208.6), à appeler chaque image tant qu'il tourne ; ne
## redessine que si les dixièmes de seconde ou la barre changent.
func show_response_time(time_left_msec: int, window_msec: int) -> void:
	_set_response_running(true)
	var tenths := ceili(maxi(time_left_msec, 0) / float(MSEC_PER_TENTH))
	var bar_step := roundi(
		clampf(float(time_left_msec) / maxi(window_msec, 1), 0.0, 1.0) * BAR_STEPS
	)
	if tenths != _response_tenths:
		_response_tenths = tenths
		_countdown_label.text = (
			"%d,%d s" % [tenths / TENTHS_PER_SECOND, tenths % TENTHS_PER_SECOND]
		)
	if bar_step != _response_bar_step:
		_response_bar_step = bar_step
		_countdown_bar.value = float(bar_step) / BAR_STEPS


## Le décompte est arrêté (208.6.5a) : le joueur doit répondre ou passer lui-même.
func show_response_stopped() -> void:
	_set_response_running(false)


static func _side_letter(side: DuelState.PlayerSide) -> String:
	return DuelState.PlayerSide.keys()[side]


func _style_texts() -> void:
	for label: Label in [_turn_number_label, _stack_title_label, _stopped_label]:
		label.add_theme_color_override("font_color", DuelPalette.MUTED_COLOR)
	_hint_label.add_theme_color_override("font_color", DuelPalette.INK_COLOR)
	_countdown_label.add_theme_color_override("font_color", DuelPalette.INK_COLOR)
	_stopped_label.text = STOPPED_TEXT
	_countdown_bar.add_theme_stylebox_override(
		"background", DuelPalette.fill_style(DuelPalette.BAR_TRACK_COLOR, BAR_RADIUS, 0.0)
	)


func _style_countdown(responder: DuelState.PlayerSide) -> void:
	_countdown_bar.add_theme_stylebox_override(
		"fill", DuelPalette.fill_style(DuelPalette.player_color(responder), BAR_RADIUS, 0.0)
	)


func _set_actor(text: String, side: DuelState.PlayerSide) -> void:
	_actor_label.text = text
	_actor_label.add_theme_color_override("font_color", DuelPalette.player_ink(side))


func _set_button(text: String, side: DuelState.PlayerSide, is_enabled: bool) -> void:
	_big_button.text = text
	_big_button.disabled = not is_enabled
	for state: DuelPalette.ButtonState in BUTTON_STATE_STYLES:
		_big_button.add_theme_stylebox_override(
			BUTTON_STATE_STYLES[state], DuelPalette.player_button_style(side, state)
		)
	for color_name: StringName in BUTTON_COLOR_NAMES:
		_big_button.add_theme_color_override(color_name, DuelPalette.INK_COLOR)
	_big_button.add_theme_color_override("font_disabled_color", DuelPalette.MUTED_COLOR)


func _show_stack_lines(lines: Array[StackView.StackLine], highlighted_ids: Array[int]) -> void:
	_has_stack = not lines.is_empty()
	_stack_title_label.text = "Pile · %d" % lines.size()
	_stack_view.show_entries(lines, highlighted_ids)


func _show_clock(
	side: DuelState.PlayerSide, remaining_msec: int, running_owners: Array[DuelState.PlayerSide]
) -> void:
	var is_running := running_owners.has(side)
	var seconds := ceili(maxi(remaining_msec, 0) / float(MSEC_PER_SECOND))
	var stamp := seconds * 2 + (1 if is_running else 0)
	if _clock_stamps.get(side, -1) == stamp:
		return
	_clock_stamps[side] = stamp
	_clocks[side].show_clock(remaining_msec, is_running)


func _set_response_running(is_running: bool) -> void:
	if is_running == _is_response_running:
		return
	_is_response_running = is_running
	_response_tenths = -1
	_response_bar_step = -1
	_refresh_center()


func _refresh_center() -> void:
	var shown: Array[Control] = []
	match _center_state:
		CenterState.TURN:
			shown = [_turn_number_label, _actor_label, _big_button]
		CenterState.STACK:
			shown = [_stack_title_label, _stack_scroll, _actor_label, _big_button]
			shown.append(_countdown_row if _is_response_running else _stopped_label)
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
	var is_stacked := _center_state == CenterState.STACK
	_countdown_row.visible = is_stacked and _is_response_running
	_stopped_label.visible = is_stacked and not _is_response_running


func _center_nodes() -> Array[Control]:
	return [
		_turn_number_label,
		_hint_panel,
		_stack_title_label,
		_stack_scroll,
		_actor_label,
		_big_button,
		_countdown_row,
		_stopped_label,
	]


func _on_big_button_pressed() -> void:
	match _center_state:
		CenterState.TURN:
			end_turn_pressed.emit()
		CenterState.STACK:
			pass_pressed.emit()
		CenterState.MULLIGAN:
			confirm_pressed.emit()
