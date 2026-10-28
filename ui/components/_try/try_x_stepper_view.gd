extends Control
## Essai de XStepperView (décision 0068) : X de 2 à 5, « Lancer » visible ; « − » et « + » changent
## la valeur dans les bornes et s'écrivent dans la sortie.

const STEPPER_SCENE: PackedScene = preload("res://ui/components/x_stepper_view.tscn")
const COLUMN_WIDTH: float = 200.0
const MINIMUM: int = 2
const MAXIMUM: int = 5

var _value: int = 3
var _stepper: XStepperView


func _ready() -> void:
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = COLUMN_WIDTH
	column.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	TrySamples.frame(self, column)
	_stepper = STEPPER_SCENE.instantiate()
	column.add_child(_stepper)
	_stepper.decrease_pressed.connect(func() -> void: _move(-1))
	_stepper.increase_pressed.connect(func() -> void: _move(1))
	_stepper.confirm_pressed.connect(func() -> void: print("lancer avec X = ", _value))
	_show()


func _move(step: int) -> void:
	_value = clampi(_value + step, MINIMUM, MAXIMUM)
	_show()


func _show() -> void:
	_stepper.show_value(_value, MINIMUM, MAXIMUM)
	_stepper.show_controls(_value > MINIMUM, _value < MAXIMUM, true)
