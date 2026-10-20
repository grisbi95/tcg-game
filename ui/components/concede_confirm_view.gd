class_name ConcedeConfirmView
extends Control
## Confirmation d'abandon (209.2.5 ; décision 0036, point 5) : un voile sur tout l'écran, qui
## bloque le jeu dessous, et « Abandonner la partie ? » avec « Oui » et « Non ». Le parent dit
## quand la montrer et quoi faire de la réponse.

signal concede_confirmed
signal concede_cancelled

const QUESTION_TEXT: String = "Abandonner la partie ?"
const YES_TEXT: String = "Oui"
const NO_TEXT: String = "Non"

@onready var _scrim: ColorRect = %Scrim
@onready var _panel: PanelContainer = %Panel
@onready var _question_label: Label = %QuestionLabel
@onready var _yes_button: Button = %YesButton
@onready var _no_button: Button = %NoButton


func _ready() -> void:
	_scrim.color = DuelPalette.SCRIM_COLOR
	_question_label.text = QUESTION_TEXT
	_yes_button.text = YES_TEXT
	_no_button.text = NO_TEXT
	_yes_button.pressed.connect(concede_confirmed.emit)
	_no_button.pressed.connect(concede_cancelled.emit)
	hide_confirm()


## Demande à `side`, qui a l'appareil, de confirmer ; le cadre prend ses couleurs.
func show_confirm(side: DuelState.PlayerSide) -> void:
	_panel.add_theme_stylebox_override(
		"panel", DuelPalette.modal_style(DuelPalette.player_color(side))
	)
	_question_label.add_theme_color_override("font_color", DuelPalette.INK_COLOR)
	DuelPalette.apply_player_button(_yes_button, side)
	visible = true


func hide_confirm() -> void:
	visible = false
