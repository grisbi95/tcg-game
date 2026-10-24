extends Control
## Essai de InfoTooltips (fiche de l'écran de duel, E27) : trois piles de bulles côte à côte, celle
## d'une Unit à Assaut et Rempart avec un Gear, celle d'une Unit endormie, celle d'une carte sans
## mot-clé (vide, donc cachée).

const TOOLTIPS_SCENE: PackedScene = preload("res://ui/components/info_tooltips.tscn")
const COLUMN_GAP: float = 300.0


func _ready() -> void:
	var table := ColorRect.new()
	table.color = DuelPalette.TABLE_COLOR
	table.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(table)
	var catalog := TrySamples.catalog()
	var armed := catalog.get_card(&"pillard")
	var plain := catalog.get_card(&"renfort")
	_add_stack(InfoBubble.list_for(armed, catalog.get_card(&"lame"), false), 0)
	_add_stack(InfoBubble.list_for(catalog.get_card(&"gardien"), null, true), 1)
	_add_stack(InfoBubble.list_for(plain, null, false), 2)


func _add_stack(bubbles: Array[InfoBubble], column: int) -> void:
	var tooltips: InfoTooltips = TOOLTIPS_SCENE.instantiate()
	add_child(tooltips)
	tooltips.show_bubbles(bubbles)
	tooltips.position = Vector2(40.0 + COLUMN_GAP * column, 40.0)
