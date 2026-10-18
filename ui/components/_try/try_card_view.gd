extends Control
## Essai de CardView (décision 0027) : chaque carte des decks de test, le Hero, un jeton Unit et un
## jeton Building. Survoler une carte l'entoure d'un anneau clair ; un clic la fait passer de
## normale à surlignée (anneau jaune), puis à choisie (deux anneaux verts).

const CARD_SCENE: PackedScene = preload("res://ui/components/card_view.tscn")
const MARK_STEPS: int = 3
const UNIT_TOKEN_FORCE: int = 2
const BUILDING_TOKEN_FORCE: int = 3

var _mark_steps: Dictionary[CardView, int] = {}


func _ready() -> void:
	var flow := HFlowContainer.new()
	TrySamples.frame(self, flow)
	var catalog := TrySamples.catalog()
	var card_ids := catalog.card_ids()
	for index: int in card_ids.size():
		_add_card(flow).show_card(index, catalog.get_card(card_ids[index]))
	_add_card(flow).show_hero(catalog.get_hero(TrySamples.HERO_ID))
	_add_card(flow).show_token(CardDefinition.CardType.UNIT, UNIT_TOKEN_FORCE)
	_add_card(flow).show_token(CardDefinition.CardType.BUILDING, BUILDING_TOKEN_FORCE)


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
