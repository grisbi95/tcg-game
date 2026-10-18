extends Control
## Essai de CardView : chaque carte des decks de test, puis un dos de carte. Un clic fait passer
## une carte de normale à surlignée, puis à choisie.

const CARD_SCENE: PackedScene = preload("res://ui/components/card_view.tscn")
const MARK_STEPS: int = 3

var _mark_steps: Dictionary[CardView, int] = {}


func _ready() -> void:
	var flow := HFlowContainer.new()
	TrySamples.frame(self, flow)
	var catalog := TrySamples.catalog()
	var card_ids := catalog.card_ids()
	for index: int in card_ids.size():
		var side := DuelState.PlayerSide.A if index % 2 == 0 else DuelState.PlayerSide.B
		var card := _add_card(flow)
		card.show_card(index, catalog.get_card(card_ids[index]), side)
	_add_card(flow).show_hidden(card_ids.size(), DuelState.PlayerSide.B)


func _add_card(flow: HFlowContainer) -> CardView:
	var card: CardView = CARD_SCENE.instantiate()
	flow.add_child(card)
	_mark_steps[card] = 0
	card.card_pressed.connect(func(pressed_id: int) -> void: _cycle_marks(card, pressed_id))
	card.card_hovered.connect(func(hovered_id: int) -> void: print("survol ", hovered_id))
	return card


func _cycle_marks(card: CardView, card_instance_id: int) -> void:
	_mark_steps[card] = (_mark_steps[card] + 1) % MARK_STEPS
	card.set_marks(_mark_steps[card] == 1, _mark_steps[card] == 2)
	print("carte pressée ", card_instance_id)
