class_name LogView
extends PanelContainer
## Journal à l'écran : une phrase par événement joué (EventText), la plus récente en bas.

## Au-delà, les plus anciennes lignes s'effacent.
const MAX_LINES: int = 200

@onready var _lines: VBoxContainer = %Lines
@onready var _scroll: ScrollContainer = %Scroll


func _ready() -> void:
	add_theme_stylebox_override("panel", DuelPalette.panel_style(DuelPalette.NEUTRAL_COLOR, false))
	_scroll.get_v_scroll_bar().changed.connect(_scroll_to_bottom)


func append_events(events: Array[DuelEvent]) -> void:
	for event: DuelEvent in events:
		var line := Label.new()
		line.text = EventText.describe(event)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.theme_type_variation = DuelPalette.SMALL_LABEL
		_lines.add_child(line)
	while _lines.get_child_count() > MAX_LINES:
		var oldest := _lines.get_child(0)
		_lines.remove_child(oldest)
		oldest.queue_free()


func clear_log() -> void:
	ViewNodes.free_children(_lines)


# Contournement Godot : la barre ne connaît sa nouvelle hauteur qu'après la mise en page, d'où
# l'appel à chaque changement de la barre plutôt qu'après l'ajout des lignes.
func _scroll_to_bottom() -> void:
	_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)
