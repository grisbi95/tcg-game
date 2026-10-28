class_name DuelColumnView
extends PanelContainer
## Colonne de duel (décisions 0030, 0032 et 0053, fiche E16 à E20c), trois parties fixes de haut en
## bas : l'en-tête (le tour ou la taille de la pile, le joueur qui doit agir, l'abandon), la pile
## qui s'étend (« Pile vide » en pointillé quand elle n'a aucune entrée), et le grand bouton, ancré
## en bas, qui reste en place grisé quand il ne sert pas. Le parent choisit l'état du centre
## (`show_turn`, `show_stack`, `show_mulligan`, `show_choice`, `show_ended`) ; la colonne ne calcule
## rien et n'a aucune règle. Les temps sont dans `TurnTimerBar`, au bord du plateau.

signal end_turn_pressed
signal pass_pressed
signal confirm_pressed
signal concede_pressed
## Décision 0068 : choix de X, boutons de choix (Ordre, place de la carte regardée), abandon.
signal x_decrease_pressed
signal x_increase_pressed
signal x_confirm_pressed
signal choice_pressed(index: int)
signal cancel_pressed
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
const END_TURN_HELP_FORMAT: String = "Fin du tour %d"
const PASS_TEXT: String = "Passer"
const PASS_HELP: String = "laisser résoudre"
const CONFIRM_TEXT: String = "Confirmer"
const CONFIRM_HELP: String = "garder ces cartes"
const MULLIGAN_HINT: String = "Mulligan : choisis les cartes à écarter"
const TURN_FORMAT: String = "Tour %d"
const STACK_FORMAT: String = "Pile · %d"
const MULLIGAN_TITLE: String = "Mulligan"
const CHOICE_TITLE: String = "Choix"
const ENDED_TITLE: String = "Fin du duel"
const YOUR_TURN_TEXT: String = "À toi de jouer"
const OTHER_TURN_FORMAT: String = "%s joue"
const YOUR_ANSWER_TEXT: String = "À toi de répondre"
const OTHER_ANSWER_FORMAT: String = "%s peut répondre"
const OTHER_TURN_BUTTON_FORMAT: String = "Tour de %s"
const OTHER_ANSWER_BUTTON_FORMAT: String = "Réponse de %s"
const WAITING_FORMAT: String = "En attente de %s"
const CHOICE_BUTTON_TEXT: String = "Choix en cours"
const CHOICE_BUTTON_HELP: String = "choisis sur le plateau"
const ENDED_BUTTON_TEXT: String = "Duel terminé"
const NO_HELP: String = ""
const DOT_SIZE: float = 10.0
const DOT_LINE_HEIGHT: float = 20.0

var _center_state: CenterState = CenterState.TURN
var _has_stack: bool = false
var _response_display: ResponseDisplay = ResponseDisplay.NONE
var _viewer: DuelState.PlayerSide = DuelState.PlayerSide.A
var _dot_color: Color = DuelPalette.NEUTRAL_COLOR

@onready var _turn_number_label: Label = %TurnNumberLabel
@onready var _concede_button: Button = %ConcedeButton
@onready var _concede_icon: Control = %ConcedeIcon
@onready var _actor_dot: Control = %ActorDot
@onready var _actor_label: Label = %TurnActorLabel
@onready var _stack_area: PanelContainer = %StackArea
@onready var _empty_label: Label = %EmptyLabel
@onready var _stack_box: VBoxContainer = %StackBox
@onready var _response_label: Label = %ResponseLabel
@onready var _stack_view: StackView = %StackView
@onready var _announcement_box: VBoxContainer = %AnnouncementBox
@onready var _x_stepper: XStepperView = %XStepper
@onready var _choices: ChoiceButtonsView = %Choices
@onready var _cancel_button: Button = %CancelButton
@onready var _big_button: Button = %BigButton
@onready var _button_title: Label = %ButtonTitle
@onready var _button_help: Label = %ButtonHelp


## « À toi de jouer » quand c'est à `viewer` (le joueur qui a l'appareil) d'agir, sinon qui joue.
static func turn_actor_text(actor: DuelState.PlayerSide, viewer: DuelState.PlayerSide) -> String:
	if actor == viewer:
		return YOUR_TURN_TEXT
	return OTHER_TURN_FORMAT % PlayerNames.letter(actor)


## « À toi de répondre » quand `responder` est `viewer`, sinon qui peut répondre (208.6.1).
static func responder_text(responder: DuelState.PlayerSide, viewer: DuelState.PlayerSide) -> String:
	if responder == viewer:
		return YOUR_ANSWER_TEXT
	return OTHER_ANSWER_FORMAT % PlayerNames.letter(responder)


func _ready() -> void:
	_big_button.pressed.connect(_on_big_button_pressed)
	_concede_button.pressed.connect(concede_pressed.emit)
	_concede_button.mouse_entered.connect(_concede_icon.queue_redraw)
	_concede_button.mouse_exited.connect(_concede_icon.queue_redraw)
	DuelIcons.bind(
		_concede_icon,
		func() -> DuelIcons.Icon: return DuelIcons.Icon.CONCEDE,
		func() -> Color: return _concede_ink()
	)
	_x_stepper.decrease_pressed.connect(x_decrease_pressed.emit)
	_x_stepper.increase_pressed.connect(x_increase_pressed.emit)
	_x_stepper.confirm_pressed.connect(x_confirm_pressed.emit)
	_choices.choice_pressed.connect(choice_pressed.emit)
	_cancel_button.pressed.connect(cancel_pressed.emit)
	_actor_dot.draw.connect(_draw_dot)
	_stack_area.draw.connect(_draw_empty_frame)
	_stack_view.stack_entry_pressed.connect(stack_entry_pressed.emit)
	_stack_view.stack_entry_hovered.connect(stack_entry_hovered.emit)
	_stack_view.stack_entry_unhovered.connect(stack_entry_unhovered.emit)
	_refresh_center()


## Le joueur qui a l'appareil : la colonne lui parle (« À toi de jouer ») et dit à qui elle
## attend quand ce n'est pas lui. À poser avant chaque `show_*`.
func set_viewer(viewer: DuelState.PlayerSide) -> void:
	_viewer = viewer


## Pile vide : « Tour N », qui joue, et « Terminer le tour » si `can_end_turn`.
func show_turn(turn_number: int, actor: DuelState.PlayerSide, can_end_turn: bool) -> void:
	_center_state = CenterState.TURN
	_show_stack_lines([], [])
	_turn_number_label.text = TURN_FORMAT % turn_number
	_set_actor(turn_actor_text(actor, _viewer), actor)
	if can_end_turn or actor == _viewer:
		_set_button(END_TURN_TEXT, END_TURN_HELP_FORMAT % turn_number, actor, can_end_turn)
	else:
		_set_waiting_button(OTHER_TURN_BUTTON_FORMAT, actor)
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
	_turn_number_label.text = STACK_FORMAT % lines.size()
	_set_actor(responder_text(responder, _viewer), responder)
	if can_pass or responder == _viewer:
		_set_button(PASS_TEXT, PASS_HELP, responder, can_pass)
	else:
		_set_waiting_button(OTHER_ANSWER_BUTTON_FORMAT, responder)
	_refresh_center()


## Mulligan (204.2) de `player` : la consigne et « Confirmer », actif si `can_confirm`.
func show_mulligan(player: DuelState.PlayerSide, can_confirm: bool) -> void:
	_center_state = CenterState.MULLIGAN
	_show_stack_lines([], [])
	_turn_number_label.text = MULLIGAN_TITLE
	_set_actor(MULLIGAN_HINT, player)
	_set_button(CONFIRM_TEXT, CONFIRM_HELP, player, can_confirm)
	_refresh_center()


## Choix demandé par le moteur à `chooser` : la `instruction`, un bouton grisé ; si l'ordre des
## effets se choisit dans la pile, ses `lines` restent affichées et `highlighted_ids` se pressent.
func show_choice(
	instruction: String,
	chooser: DuelState.PlayerSide,
	lines: Array[StackView.StackLine] = [],
	highlighted_ids: Array[int] = []
) -> void:
	_center_state = CenterState.CHOICE
	_show_stack_lines(lines, highlighted_ids)
	_turn_number_label.text = CHOICE_TITLE if lines.is_empty() else STACK_FORMAT % lines.size()
	_set_actor(instruction, chooser)
	var help := CHOICE_BUTTON_HELP
	if chooser != _viewer:
		help = WAITING_FORMAT % PlayerNames.letter(chooser)
	_set_button(CHOICE_BUTTON_TEXT, help, chooser, false)
	_refresh_center()


## Fin de partie : une ligne de résultat (le relais et l'écran de fin viennent à l'étape 2.4).
func show_ended(result_text: String) -> void:
	_center_state = CenterState.ENDED
	_show_stack_lines([], [])
	_turn_number_label.text = ENDED_TITLE
	_set_actor(result_text, _viewer)
	_actor_dot.visible = false
	_set_button(ENDED_BUTTON_TEXT, NO_HELP, _viewer, false)
	_refresh_center()


## La fenêtre de réponse est ouverte (208.6.1) : le joueur doit répondre ou passer, sans échéance
## (208.6.2).
func show_response_open() -> void:
	_set_response_display(ResponseDisplay.OPEN)


## Aucune fenêtre de réponse à montrer : relais en cours ou événements à l'affichage.
func hide_response() -> void:
	_set_response_display(ResponseDisplay.NONE)


## Décision 0068 : le choix de X de l'annonce commencée, de `minimum` à `maximum`.
func show_x_choice(value: int, minimum: int, maximum: int) -> void:
	_x_stepper.show_value(value, minimum, maximum)
	_x_stepper.visible = true
	_refresh_announcement()


## Les commandes du choix de X : bornes atteintes, annonce sans cible qui peut partir.
func show_x_controls(can_decrease: bool, can_increase: bool, can_confirm: bool) -> void:
	_x_stepper.show_controls(can_decrease, can_increase, can_confirm)


func hide_x_choice() -> void:
	_x_stepper.visible = false
	_refresh_announcement()


## Un bouton par texte de `labels` (Ordres du Hero, place de la carte regardée).
func show_choices(labels: Array[String]) -> void:
	_choices.show_choices(labels)
	_choices.visible = true
	_refresh_announcement()


func hide_choices() -> void:
	_choices.visible = false
	_refresh_announcement()


## Le bouton « Annuler » d'une annonce commencée.
func show_cancel(is_available: bool) -> void:
	_cancel_button.visible = is_available
	_refresh_announcement()


## Montre le bouton « Abandonner », pour le joueur de l'écran (décision 0036).
func show_concede() -> void:
	_concede_button.visible = true


func hide_concede() -> void:
	_concede_button.visible = false


func _set_actor(text: String, side: DuelState.PlayerSide) -> void:
	_actor_label.text = text
	_actor_label.add_theme_color_override("font_color", DuelPalette.player_ink(side))
	_dot_color = DuelPalette.player_color(side)
	_actor_dot.visible = true
	_actor_dot.queue_redraw()


func _set_button(title: String, help: String, side: DuelState.PlayerSide, is_enabled: bool) -> void:
	_button_title.text = title
	_button_help.text = help
	_button_help.visible = not help.is_empty()
	_big_button.disabled = not is_enabled
	_big_button.modulate.a = 1.0 if is_enabled else DuelPalette.DIMMED_ALPHA
	DuelPalette.apply_player_button(_big_button, side)


# Q6 : le bouton reste en place, grisé, et dit ce qu'on attend.
func _set_waiting_button(title_format: String, side: DuelState.PlayerSide) -> void:
	var letter := PlayerNames.letter(side)
	_set_button(title_format % letter, WAITING_FORMAT % letter, side, false)


func _show_stack_lines(lines: Array[StackView.StackLine], highlighted_ids: Array[int]) -> void:
	_has_stack = not lines.is_empty()
	_stack_view.show_entries(lines, highlighted_ids)


func _set_response_display(response_display: ResponseDisplay) -> void:
	if response_display == _response_display:
		return
	_response_display = response_display
	_refresh_center()


func _refresh_center() -> void:
	_empty_label.visible = not _has_stack
	_stack_box.visible = _has_stack
	_response_label.visible = (
		_center_state == CenterState.STACK and _response_display == ResponseDisplay.OPEN
	)
	_stack_area.queue_redraw()


func _refresh_announcement() -> void:
	_announcement_box.visible = (_x_stepper.visible or _choices.visible or _cancel_button.visible)


func _concede_ink() -> Color:
	return DuelPalette.INK_COLOR if _concede_button.is_hovered() else DuelPalette.MUTED_COLOR


func _draw_dot() -> void:
	var radius := DOT_SIZE / 2.0
	_actor_dot.draw_circle(Vector2(radius, DOT_LINE_HEIGHT / 2.0), radius, _dot_color)


func _draw_empty_frame() -> void:
	if not _has_stack:
		DashedOutline.draw(_stack_area, _stack_area.size)


func _on_big_button_pressed() -> void:
	match _center_state:
		CenterState.TURN:
			end_turn_pressed.emit()
		CenterState.STACK:
			pass_pressed.emit()
		CenterState.MULLIGAN:
			confirm_pressed.emit()
