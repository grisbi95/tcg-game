class_name DeckCornerView
extends VBoxContainer
## Coin deck et défausse d'un joueur (201.4.1, 201.4.3 ; décisions 0030 et 0032) : deux
## emplacements de la taille d'une carte de main, écart de 10 px ; le deck face cachée avec son
## nombre de cartes, la défausse avec sa carte du dessus (emplacement vide en pointillé sans
## carte). Le libellé est du côté du plateau ; à partir d'une fatigue de 1 (209.5), il l'annonce.
## Le survol de la défausse est relayé pour que le parent montre l'aperçu de sa carte du dessus.
## Le parent ancre le coin à sa marge droite.

signal discard_hovered(card_instance_id: int)
signal discard_unhovered(card_instance_id: int)

## Côté du libellé par rapport aux emplacements : au-dessus pour A (en bas de l'écran), en
## dessous pour B (en haut). Ajouter à la fin, sans réordonner.
enum LabelPlacement {
	ABOVE,
	BELOW,
}

const SLOT_SIZE := CardView.CARD_SIZE
const LABEL_TEXT: String = "Deck · Défausse"
const FATIGUE_LABEL_FORMAT: String = "Deck · Défausse · Fatigue %d"
## 209.5 : la fatigue n'est annoncée qu'à partir de 1.
const MIN_SHOWN_FATIGUE: int = 1
## Anneau du joueur autour de la carte du dessus de la défausse.
const DISCARD_RING_WIDTH: int = 3

var _player: DuelState.PlayerSide = DuelState.PlayerSide.A
var _has_discard_card: bool = false

@onready var _label: Label = %PileLabel
@onready var _piles: HBoxContainer = %Piles
@onready var _deck: CardBackView = %Deck
@onready var _discard_slot: Control = %DiscardSlot
@onready var _discard_card: CardView = %DiscardCard


func _ready() -> void:
	_label.add_theme_color_override("font_color", DuelPalette.MUTED_COLOR)
	_discard_slot.custom_minimum_size = SLOT_SIZE
	_discard_slot.draw.connect(_draw_discard_slot)
	_discard_card.card_hovered.connect(discard_hovered.emit)
	_discard_card.card_unhovered.connect(discard_unhovered.emit)
	show_fatigue(0)
	show_empty_discard()


## Coin du joueur `player`, libellé à `label_placement` des emplacements.
func setup(player: DuelState.PlayerSide, label_placement: LabelPlacement) -> void:
	_player = player
	_deck.show_back(player, CardBackView.DECK_SIZE)
	move_child(_label, 0 if label_placement == LabelPlacement.ABOVE else 1)
	_discard_slot.queue_redraw()


## Nombre de cartes du deck.
func show_deck(card_count: int) -> void:
	_deck.show_count(card_count)


## Fatigue du joueur (209.5) : annoncée dans le libellé à partir de 1.
func show_fatigue(fatigue: int) -> void:
	_label.text = (FATIGUE_LABEL_FORMAT % fatigue if fatigue >= MIN_SHOWN_FATIGUE else LABEL_TEXT)


## Carte du dessus de la défausse.
func show_discard(card_instance_id: int, definition: CardDefinition) -> void:
	_discard_card.show_card(card_instance_id, definition)
	_set_discard_card_shown(true)


## Défausse vide : emplacement en pointillé.
func show_empty_discard() -> void:
	_set_discard_card_shown(false)


func _set_discard_card_shown(has_card: bool) -> void:
	_has_discard_card = has_card
	_discard_card.visible = has_card
	_discard_slot.queue_redraw()


func _draw_discard_slot() -> void:
	if not _has_discard_card:
		DashedOutline.draw(_discard_slot, _discard_slot.size)
		return
	var ring := DuelPalette.framed_style(
		Color.TRANSPARENT, DuelPalette.player_color(_player), DISCARD_RING_WIDTH, 0.0
	)
	ring.draw_center = false
	_discard_slot.draw_style_box(
		ring, Rect2(Vector2.ZERO, _discard_slot.size).grow(DISCARD_RING_WIDTH)
	)
