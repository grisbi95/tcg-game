extends Control
## Essai de ChoiceButtonsView (décision 0068) : deux boutons de place de la carte regardée, puis le
## rang pressé s'écrit dans la sortie.

const BUTTONS_SCENE: PackedScene = preload("res://ui/components/choice_buttons_view.tscn")
const COLUMN_WIDTH: float = 200.0


func _ready() -> void:
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = COLUMN_WIDTH
	column.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	TrySamples.frame(self, column)
	var buttons: ChoiceButtonsView = BUTTONS_SCENE.instantiate()
	column.add_child(buttons)
	var labels: Array[String] = ["Garder dessus", "Mettre dessous", "Ordre 1 · Réaction · coût 0"]
	buttons.show_choices(labels)
	buttons.choice_pressed.connect(func(index: int) -> void: print("choix ", index))
