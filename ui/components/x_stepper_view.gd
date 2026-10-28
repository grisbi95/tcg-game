class_name XStepperView
extends VBoxContainer
## Choix de la valeur de X d'un coût X (213.1, décision 0068) : « − », la valeur, « + », et sous
## eux les bornes que le moteur accepte. « Lancer » n'apparaît que pour une annonce sans cible,
## qui n'a pas d'autre geste pour partir. Le parent donne les valeurs et les bornes ; rien n'est
## calculé ici.

signal decrease_pressed
signal increase_pressed
signal confirm_pressed

const VALUE_FORMAT: String = "X = %d"
const RANGE_FORMAT: String = "de %d à %d"
const DECREASE_TEXT: String = "−"
const INCREASE_TEXT: String = "+"
const CONFIRM_TEXT: String = "Lancer"

@onready var _decrease_button: Button = %DecreaseButton
@onready var _value_label: Label = %ValueLabel
@onready var _increase_button: Button = %IncreaseButton
@onready var _range_label: Label = %RangeLabel
@onready var _confirm_button: Button = %ConfirmButton


func _ready() -> void:
	_decrease_button.text = DECREASE_TEXT
	_increase_button.text = INCREASE_TEXT
	_confirm_button.text = CONFIRM_TEXT
	_decrease_button.pressed.connect(decrease_pressed.emit)
	_increase_button.pressed.connect(increase_pressed.emit)
	_confirm_button.pressed.connect(confirm_pressed.emit)


## La valeur choisie `value`, entre `minimum` et `maximum` (les bornes acceptées par le moteur).
func show_value(value: int, minimum: int, maximum: int) -> void:
	_value_label.text = VALUE_FORMAT % value
	_range_label.text = RANGE_FORMAT % [minimum, maximum]


## « − » et « + » se grisent quand la valeur ne peut plus bouger ; « Lancer » se montre si
## `can_confirm`.
func show_controls(can_decrease: bool, can_increase: bool, can_confirm: bool) -> void:
	_decrease_button.disabled = not can_decrease
	_increase_button.disabled = not can_increase
	_confirm_button.visible = can_confirm
