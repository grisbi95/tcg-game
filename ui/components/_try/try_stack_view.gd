extends Control
## Essai de StackView : trois entrées, le sommet en haut, celle du milieu pressable ; puis une
## pile vide.

const STACK_SCENE: PackedScene = preload("res://ui/components/stack_view.tscn")


func _ready() -> void:
	var row := HBoxContainer.new()
	TrySamples.frame(self, row)
	var stack: StackView = STACK_SCENE.instantiate()
	row.add_child(stack)
	var labels := PackedStringArray(
		["A : déploiement de Soldat", "B : Spell Frappe", "A : Spell Contre"]
	)
	var entry_ids: Array[int] = [1, 2, 3]
	var highlighted_ids: Array[int] = [2]
	stack.show_entries(entry_ids, labels, highlighted_ids)
	stack.stack_entry_pressed.connect(func(entry_id: int) -> void: print("entrée ", entry_id))
	var empty: StackView = STACK_SCENE.instantiate()
	row.add_child(empty)
	var no_ids: Array[int] = []
	empty.show_entries(no_ids, PackedStringArray(), no_ids)
