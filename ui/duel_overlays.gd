class_name DuelOverlays
extends Control
## Couche d'affichage de l'écran de duel, au-dessus du jeu et de son bouclier d'entrées
## (décision 0036) : confirmation d'abandon et panneau de fin, sans rideau de relais (0048).
## Elle transmet les gestes de ces deux vues ; ce qu'ils déclenchent reste à l'écran de duel.

signal concede_confirmed
signal rematch_pressed
signal setup_pressed
signal sheet_pressed

@onready var _concede_confirm: ConcedeConfirmView = %ConcedeConfirm
@onready var _end_panel: EndPanelView = %EndPanel


func _ready() -> void:
	_concede_confirm.concede_confirmed.connect(concede_confirmed.emit)
	_concede_confirm.concede_cancelled.connect(_concede_confirm.hide_confirm)
	_end_panel.rematch_pressed.connect(rematch_pressed.emit)
	_end_panel.setup_pressed.connect(setup_pressed.emit)
	_end_panel.sheet_pressed.connect(sheet_pressed.emit)


## Demande à `side`, qui a l'appareil, de confirmer son abandon.
func show_concede_confirm(side: DuelState.PlayerSide) -> void:
	_concede_confirm.show_confirm(side)


func hide_concede_confirm() -> void:
	_concede_confirm.hide_confirm()


## Panneau de fin de `result` (voir `EndPanelView.show_end`).
func show_end(
	result: DuelState.DuelResult, title_text: String, reason_text: String, details_text: String
) -> void:
	_end_panel.show_end(result, title_text, reason_text, details_text)


## Dit sous les boutons du panneau de fin où est allée la fiche demandée.
func show_sheet_status(text: String) -> void:
	_end_panel.show_sheet_status(text)
