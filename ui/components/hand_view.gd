class_name HandView
extends HBoxContainer
## Main du joueur en bas (201.3 ; décision 0030) : jusqu'à `MAX_CARDS` CardView de 158×220, droites
## et entières, sans chevauchement, centrées dans leur zone. Le parent donne les cartes et les
## marques ; une carte pressée ou survolée est relayée avec son identifiant d'instance.

signal card_pressed(card_instance_id: int)
signal card_hovered(card_instance_id: int)
signal card_unhovered(card_instance_id: int)

## Décision 0030 : sept cartes de 158 px, écart de 5 px, soit 1136×220.
const MAX_CARDS: int = 7
const CARD_GAP: int = 5
const AREA_SIZE := Vector2(
	CardView.CARD_SIZE.x * MAX_CARDS + CARD_GAP * (MAX_CARDS - 1), CardView.CARD_SIZE.y
)

const CARD_SCENE: PackedScene = preload("res://ui/components/card_view.tscn")

var _card_views: Dictionary[int, CardView] = {}


## Une carte de la main telle que l'écran la montre.
class HandCard:
	extends RefCounted
	var card_instance_id: int = DuelState.NO_ID
	var definition: CardDefinition

	func _init(instance_id: int, card_definition: CardDefinition) -> void:
		card_instance_id = instance_id
		definition = card_definition


func _ready() -> void:
	custom_minimum_size = AREA_SIZE
	add_theme_constant_override("separation", CARD_GAP)


## Remplace la main par `cards`, dans l'ordre ; les marques sont à redonner par `show_marks`.
func show_cards(cards: Array[HandCard]) -> void:
	ViewNodes.free_children(self)
	_card_views.clear()
	for hand_card in cards:
		_add_card(hand_card)


## `playable_ids` portent l'anneau jaune, `chosen_ids` les deux anneaux verts.
func show_marks(playable_ids: Array[int], chosen_ids: Array[int]) -> void:
	for card_instance_id: int in _card_views:
		_card_views[card_instance_id].set_marks(
			playable_ids.has(card_instance_id), chosen_ids.has(card_instance_id)
		)


func _add_card(hand_card: HandCard) -> void:
	var card_view: CardView = CARD_SCENE.instantiate()
	add_child(card_view)
	card_view.show_card(hand_card.card_instance_id, hand_card.definition)
	card_view.card_pressed.connect(card_pressed.emit)
	card_view.card_hovered.connect(card_hovered.emit)
	card_view.card_unhovered.connect(card_unhovered.emit)
	_card_views[hand_card.card_instance_id] = card_view
