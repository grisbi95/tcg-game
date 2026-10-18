extends Control
## Essai de HoverPreview : survoler une carte de la rangée l'affiche en grand à droite.

const CARD_SCENE: PackedScene = preload("res://ui/components/card_view.tscn")
const PREVIEW_SCENE: PackedScene = preload("res://ui/components/hover_preview.tscn")
const SAMPLE_COUNT: int = 4


func _ready() -> void:
	var row := HBoxContainer.new()
	TrySamples.frame(self, row)
	var preview: HoverPreview = PREVIEW_SCENE.instantiate()
	var catalog := TrySamples.catalog()
	var card_ids := catalog.card_ids()
	for index: int in mini(SAMPLE_COUNT, card_ids.size()):
		var definition := catalog.get_card(card_ids[index])
		var card: CardView = CARD_SCENE.instantiate()
		row.add_child(card)
		card.show_card(index, definition, DuelState.PlayerSide.A)
		card.card_hovered.connect(
			func(_id: int) -> void: preview.show_definition(definition, DuelState.PlayerSide.A)
		)
		card.card_unhovered.connect(func(_id: int) -> void: preview.hide_preview())
	row.add_child(preview)
	preview.show_definition(catalog.get_card(card_ids[0]), DuelState.PlayerSide.A)
