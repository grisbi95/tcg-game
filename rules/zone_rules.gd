class_name ZoneRules
extends RefCounted
## Zones hors du plateau : deck, main, Écart, limite de main, appartenance (201.3, 201.5).
##
## Primitives appelées par les modules des autres chapitres ; aucune intention propre.
## Les fonctions qui déplacent des cartes supposent leurs arguments déjà validés.

## Issue d'une pioche.
enum DrawOutcome {
	DRAWN,
	BLOCKED_BY_HAND_LIMIT,  # 201.3.5, 201.3.6
	## Aucune carte à piocher. La fatigue (209.5) relève du chapitre 209, qui lit aussi la
	## main pleine : Q-077 n'est pas tranchée.
	DECK_EMPTY,
}


## 201.3.1, 201.5.1 : crée dans le deck de `side` un exemplaire de chaque définition, qui
## appartient à `side`. Le dernier identifiant de `definition_ids` est le sommet du deck.
static func create_deck(
	state: DuelState, side: DuelState.PlayerSide, definition_ids: Array[StringName]
) -> void:
	var deck := state.get_player(side).deck
	for definition_id: StringName in definition_ids:
		var card := CardInstance.new()
		card.card_instance_id = state.allocate_card_instance_id()
		card.definition_id = definition_id
		card.owner = side
		deck.append(card)


# 201.3.4
static func has_room_in_hand(state: DuelState, side: DuelState.PlayerSide) -> bool:
	return state.get_player(side).hand.size() < state.config.max_hand_size


## 201.3.2, 201.3.5, 201.3.6 : pioche la carte du sommet du deck de `side`. Une main pleine
## laisse la carte au sommet du deck.
static func draw_card(
	state: DuelState, side: DuelState.PlayerSide, events: Array[DuelEvent]
) -> DrawOutcome:
	var player := state.get_player(side)
	if player.deck.is_empty():
		return DrawOutcome.DECK_EMPTY
	if not has_room_in_hand(state, side):
		events.append(DrawBlockedByHandLimit.new(side))
		return DrawOutcome.BLOCKED_BY_HAND_LIMIT
	var card: CardInstance = player.deck.pop_back()
	player.hand.append(card)
	events.append(CardDrawn.new(side, card.card_instance_id))
	return DrawOutcome.DRAWN


## 201.3.9, 204.2.8, 204.2.10 : déplace de la main de `side` vers son Écart les cartes
## `card_instance_ids`, dans cet ordre.
static func set_aside_cards(
	state: DuelState,
	side: DuelState.PlayerSide,
	card_instance_ids: Array[int],
	events: Array[DuelEvent]
) -> void:
	var player := state.get_player(side)
	for card_instance_id: int in card_instance_ids:
		var card := player.find_card_in_hand(card_instance_id)
		player.hand.erase(card)
		player.set_aside.append(card)
		events.append(CardSetAside.new(side, card_instance_id))


## 201.3.10, 204.2.6, 204.2.11 : remet toutes les cartes de l'Écart de `side` au sommet de
## son deck, qui est mélangé ensuite (204.2.7) ; l'Écart est vide après l'appel.
static func return_set_aside_to_deck(
	state: DuelState, side: DuelState.PlayerSide, events: Array[DuelEvent]
) -> void:
	var player := state.get_player(side)
	for card: CardInstance in player.set_aside:
		player.deck.append(card)
		events.append(CardReturnedToDeck.new(side, card.card_instance_id))
	player.set_aside.clear()
