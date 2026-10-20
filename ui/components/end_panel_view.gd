class_name EndPanelView
extends Control
## Panneau de fin de partie (décision 0036, point 4) : un voile sombre sur tout l'écran, le jeu
## figé visible dessous, et au centre le résultat, sa raison, le tour et la durée, puis « Rejouer »
## et « Préparation ». Le parent donne les textes ; la vue ne sait rien du jeu.

signal rematch_pressed
signal setup_pressed

const REMATCH_TEXT: String = "Rejouer"
const SETUP_TEXT: String = "Préparation"

@onready var _scrim: ColorRect = %Scrim
@onready var _panel: PanelContainer = %Panel
@onready var _title_label: Label = %TitleLabel
@onready var _reason_label: Label = %ReasonLabel
@onready var _details_label: Label = %DetailsLabel
@onready var _rematch_button: Button = %RematchButton
@onready var _setup_button: Button = %SetupButton


func _ready() -> void:
	_scrim.color = DuelPalette.SCRIM_COLOR
	_reason_label.add_theme_color_override("font_color", DuelPalette.INK_COLOR)
	_details_label.add_theme_color_override("font_color", DuelPalette.MUTED_COLOR)
	_rematch_button.text = REMATCH_TEXT
	_setup_button.text = SETUP_TEXT
	_rematch_button.pressed.connect(rematch_pressed.emit)
	_setup_button.pressed.connect(setup_pressed.emit)
	hide_end()


## Montre le panneau : `title_text` aux couleurs du vainqueur de `result` (neutres pour une
## égalité), sous lequel viennent la raison et le détail du tour et de la durée.
func show_end(
	result: DuelState.DuelResult, title_text: String, reason_text: String, details_text: String
) -> void:
	var accent := DuelPalette.result_color(result)
	_title_label.text = title_text
	_title_label.add_theme_color_override("font_color", DuelPalette.result_ink(result))
	_reason_label.text = reason_text
	_details_label.text = details_text
	_panel.add_theme_stylebox_override("panel", DuelPalette.modal_style(accent))
	visible = true


func hide_end() -> void:
	visible = false
