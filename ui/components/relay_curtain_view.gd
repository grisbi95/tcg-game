class_name RelayCurtainView
extends PanelContainer
## Rideau de relais (décision 0036, point 2) : couvre la main du bas, opaque, quand l'appareil doit
## passer au joueur attendu. « Joueur X, à vous » aux couleurs de X et un bouton « Voir ma main ».
## Le parent le pose aux cotes de la main et lui dit quand le montrer ou le cacher ; la vue ne sait
## rien du jeu.

signal relay_confirmed

const TITLE_FORMAT: String = "%s, à vous"
const BUTTON_TEXT: String = "Voir ma main"

@onready var _title_label: Label = %TitleLabel
@onready var _confirm_button: Button = %ConfirmButton


func _ready() -> void:
	_confirm_button.text = BUTTON_TEXT
	_confirm_button.pressed.connect(relay_confirmed.emit)
	hide_relay()


## Donne au rideau la taille de la zone qu'il couvre.
func setup(area_size: Vector2) -> void:
	custom_minimum_size = area_size


## Montre le rideau pour `side`, qui va prendre l'appareil.
func show_relay(side: DuelState.PlayerSide) -> void:
	_title_label.text = TITLE_FORMAT % PlayerNames.display_name(side)
	_title_label.add_theme_color_override("font_color", DuelPalette.player_ink(side))
	DuelPalette.apply_player_button(_confirm_button, side)
	add_theme_stylebox_override(
		"panel", DuelPalette.modal_style(DuelPalette.player_color(side), DuelPalette.TABLE_COLOR)
	)
	visible = true


func hide_relay() -> void:
	visible = false
