extends Control
## Essai de StackView (décision 0028) : trois entrées, la dernière en haut, chacune à la teinte de
## sa carte et liserée de son joueur ; celle du milieu pressable, la dernière déjà numérotée.

const STACK_SCENE: PackedScene = preload("res://ui/components/stack_view.tscn")
const COLUMN_WIDTH: float = 200.0


func _ready() -> void:
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = COLUMN_WIDTH
	column.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	TrySamples.frame(self, column)
	var stack: StackView = STACK_SCENE.instantiate()
	column.add_child(stack)
	var lines: Array[StackView.StackLine] = [
		(
			StackView
			. StackLine
			. new(1, "Soldat", DuelPalette.Tint.UNIT, DuelState.PlayerSide.A)
			. with_help("Unit · Joueur A")
		),
		(
			StackView
			. StackLine
			. new(2, "Frappe", DuelPalette.Tint.SPELL, DuelState.PlayerSide.B)
			. with_help("Spell · Joueur B")
		),
		(
			StackView
			. StackLine
			. new(3, "Contre", DuelPalette.Tint.SPELL, DuelState.PlayerSide.A)
			. with_order(1)
			. with_help("Spell · Joueur A")
		),
	]
	var highlighted_ids: Array[int] = [2]
	stack.show_entries(lines, highlighted_ids)
	stack.stack_entry_pressed.connect(func(entry_id: int) -> void: print("entrée ", entry_id))
