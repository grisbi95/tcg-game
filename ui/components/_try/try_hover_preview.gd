extends Control
## Essai de HoverPreview (décisions 0027 et 0028) : survoler une carte de la rangée l'affiche en
## grand dessous ; le Soldat est montré avec la Lame, comme une pièce qui porte un Gear.

const CARD_SCENE: PackedScene = preload("res://ui/components/card_view.tscn")
const PREVIEW_SCENE: PackedScene = preload("res://ui/components/hover_preview.tscn")
const SAMPLE_IDS: Array[StringName] = [&"soldat", &"heraut", &"renfort", &"campement"]
const GEAR_ID: StringName = &"lame"
const ARMED_ID: StringName = &"soldat"


func _ready() -> void:
	var column := VBoxContainer.new()
	TrySamples.frame(self, column)
	var row := HBoxContainer.new()
	column.add_child(row)
	var preview: HoverPreview = PREVIEW_SCENE.instantiate()
	var catalog := TrySamples.catalog()
	var gear := catalog.get_card(GEAR_ID)
	for index: int in SAMPLE_IDS.size():
		var definition := catalog.get_card(SAMPLE_IDS[index])
		var shown_gear := gear if SAMPLE_IDS[index] == ARMED_ID else null
		var card: CardView = CARD_SCENE.instantiate()
		row.add_child(card)
		card.show_card(index, definition)
		card.card_hovered.connect(func(_id: int) -> void: preview.show_card(definition, shown_gear))
		card.card_unhovered.connect(func(_id: int) -> void: preview.hide_preview())
	var hero_card: CardView = CARD_SCENE.instantiate()
	row.add_child(hero_card)
	var hero := catalog.get_hero(TrySamples.HERO_ID)
	hero_card.show_hero(hero)
	hero_card.card_hovered.connect(func(_id: int) -> void: preview.show_hero(hero))
	hero_card.card_unhovered.connect(func(_id: int) -> void: preview.hide_preview())
	column.add_child(preview)
	preview.show_card(catalog.get_card(ARMED_ID), gear)
