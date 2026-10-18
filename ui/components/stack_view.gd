class_name StackView
extends PanelContainer
## Pile (208) : une ligne par entrée, le sommet en haut ; une entrée se presse quand la sélection
## la propose (cible d'un Contrecarrer, ordre des effets déclenchés).

signal stack_entry_pressed(stack_entry_id: int)

const EMPTY_TEXT: String = "Pile vide"

@onready var _entry_list: VBoxContainer = %EntryList


func _ready() -> void:
	add_theme_stylebox_override("panel", DuelPalette.panel_style(DuelPalette.NEUTRAL_COLOR, false))


## `entry_ids` et `labels` vont de la base au sommet de la pile ; `highlighted_ids` peuvent se
## presser.
func show_entries(
	entry_ids: Array[int], labels: PackedStringArray, highlighted_ids: Array[int]
) -> void:
	ViewNodes.free_children(_entry_list)
	if entry_ids.is_empty():
		var empty := Label.new()
		empty.text = EMPTY_TEXT
		_entry_list.add_child(empty)
	for index: int in range(entry_ids.size() - 1, -1, -1):
		var entry_id := entry_ids[index]
		_entry_list.add_child(_make_entry(entry_id, labels[index], highlighted_ids.has(entry_id)))


func _make_entry(entry_id: int, label: String, is_highlighted: bool) -> Button:
	var entry := Button.new()
	entry.text = label
	entry.disabled = not is_highlighted
	entry.alignment = HORIZONTAL_ALIGNMENT_LEFT
	entry.pressed.connect(func() -> void: stack_entry_pressed.emit(entry_id))
	return entry
