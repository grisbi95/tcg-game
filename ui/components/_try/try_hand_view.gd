extends Control
## Essai de HandView (décision 0030) : sept cartes variées du deck de test, deux jouables (anneau
## jaune), une choisie (deux anneaux verts). Survol et clic s'écrivent dans la sortie.

const HAND_SCENE: PackedScene = preload("res://ui/components/hand_view.tscn")
const CARD_IDS: Array[StringName] = [
	&"soldat", &"heraut", &"bastion", &"frappe", &"lame", &"contre", &"colosse"
]
const FIRST_INSTANCE_ID: int = 11
const PLAYABLE_INDEXES: Array[int] = [0, 3]
const CHOSEN_INDEX: int = 4


func _ready() -> void:
	var column := VBoxContainer.new()
	TrySamples.frame(self, column)
	var hand: HandView = HAND_SCENE.instantiate()
	column.add_child(hand)
	var catalog := TrySamples.catalog()
	var cards: Array[HandView.HandCard] = []
	for index: int in CARD_IDS.size():
		var definition := catalog.get_card(CARD_IDS[index])
		cards.append(HandView.HandCard.new(FIRST_INSTANCE_ID + index, definition))
	hand.show_cards(cards)
	var playable_ids: Array[int] = []
	for index: int in PLAYABLE_INDEXES:
		playable_ids.append(FIRST_INSTANCE_ID + index)
	var chosen_ids: Array[int] = [FIRST_INSTANCE_ID + CHOSEN_INDEX]
	hand.show_marks(playable_ids, chosen_ids)
	hand.card_pressed.connect(func(id: int) -> void: print("carte pressée ", id))
	hand.card_hovered.connect(func(id: int) -> void: print("survol ", id))
	hand.card_unhovered.connect(func(id: int) -> void: print("fin de survol ", id))
