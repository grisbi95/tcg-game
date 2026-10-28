@abstract
class_name EntryScreen
extends Control
## Écran d'entrée (décision 0075) : accueil ou préparation. Le parent mène la connexion au relais
## et dit à l'écran affiché où elle en est, sans savoir lequel des deux c'est ; chaque écran dit
## quelles commandes il ouvre ou grise.

## « Annuler » est pressé pendant la connexion au relais.
signal cancel_pressed

const CANCEL_TEXT: String = "Annuler"

var _status_label: Label
var _cancel_button: Button


## Rien en cours : les choix sont ouverts ; `status` dit, s'il n'est pas vide, ce qui s'est passé
## (connexion perdue, code inconnu).
func show_idle(status: String = "") -> void:
	_set_controls_enabled(true)
	_cancel_button.visible = false
	_show_status(status)


## Connexion au relais en cours, ou attente de l'autre joueur : `status` le dit, « Annuler » arrête.
func show_connecting(status: String) -> void:
	_set_controls_enabled(false)
	_cancel_button.visible = true
	_show_status(status)


## Ouvre (`is_enabled`) ou grise les commandes propres à l'écran.
@abstract func _set_controls_enabled(is_enabled: bool) -> void


# À appeler dans `_ready` : le message de connexion et « Annuler » de l'écran.
func _bind_entry_controls(status_label: Label, cancel_button: Button) -> void:
	_status_label = status_label
	_cancel_button = cancel_button
	_cancel_button.text = CANCEL_TEXT
	_cancel_button.pressed.connect(cancel_pressed.emit)


func _show_status(status: String) -> void:
	_status_label.text = status
	_status_label.visible = not status.is_empty()
