class_name PlayerState
extends RefCounted
## État d'un joueur : zones, Sources, temps, fatigue et limites du tour (201, 203, 204, 209).
##
## Les Sources sont fongibles (décision 0003) : elles se comptent par emplacement.

var side: DuelState.PlayerSide = DuelState.PlayerSide.A
## 201.3 : le sommet du deck est le dernier élément.
var deck: Array[CardInstance] = []
var hand: Array[CardInstance] = []
var discard: Array[CardInstance] = []
## 201.3.9 : Écart du mulligan, vide hors mulligan (201.3.10).
var set_aside: Array[CardInstance] = []
## 203.5.1
var sources_in_reserve: int = 0
## 203.2.1 : Sources en jeu redressées, qui produisent de l'Essence en s'inclinant.
var sources_upright: int = 0
## 203.2.2 : Sources en jeu inclinées, qui produisent de l'Essence en se recyclant.
var sources_tilted: int = 0
## 203.5.2, 203.5.3 : Sources recyclées, hors jeu pour toujours (203.5.4).
var sources_in_fonte: int = 0
## 203.6.1 : Essence produite pendant son tour et pas encore dépensée ; nulle pendant le tour
## adverse (203.6.2). Visible des deux joueurs (201.4.10).
var essence_reserve: int = 0
## 203.4.2 : recyclages du tour en cours.
var sources_recycled_this_turn: int = 0
## 202.3.14, 202.3.17 : le pouvoir du Hero compte dès son annonce.
var hero_power_used_this_turn: bool = false
## 209.5.1
var fatigue_counter: int = 0
## 209.4.3, 209.4.8a : temps de tour restant ; remis à la valeur de départ au début de son tour.
var turn_time_remaining_msec: int = 0
## 209.4.6, 209.4.7a : temps de réponse restant de la décision en cours.
var response_time_remaining_msec: int = 0
## 209.2.10 : tours consécutifs terminés par l'expiration du temps de tour sans annonce.
var idle_turns: int = 0
## 209.2.10 : le joueur a fait une annonce pendant son tour en cours.
var announced_this_turn: bool = false


## Renvoie la carte `card_instance_id` de la main, ou null si elle n'y est pas.
func find_card_in_hand(card_instance_id: int) -> CardInstance:
	for card: CardInstance in hand:
		if card.card_instance_id == card_instance_id:
			return card
	return null


## 203.5.7 : total des Sources du joueur, quel que soit leur emplacement.
func total_sources() -> int:
	return sources_in_reserve + sources_upright + sources_tilted + sources_in_fonte


func clone() -> PlayerState:
	var copy := PlayerState.new()
	copy.side = side
	copy.deck = _clone_cards(deck)
	copy.hand = _clone_cards(hand)
	copy.discard = _clone_cards(discard)
	copy.set_aside = _clone_cards(set_aside)
	copy.sources_in_reserve = sources_in_reserve
	copy.sources_upright = sources_upright
	copy.sources_tilted = sources_tilted
	copy.sources_in_fonte = sources_in_fonte
	copy.essence_reserve = essence_reserve
	copy.sources_recycled_this_turn = sources_recycled_this_turn
	copy.hero_power_used_this_turn = hero_power_used_this_turn
	copy.fatigue_counter = fatigue_counter
	copy.turn_time_remaining_msec = turn_time_remaining_msec
	copy.response_time_remaining_msec = response_time_remaining_msec
	copy.idle_turns = idle_turns
	copy.announced_this_turn = announced_this_turn
	return copy


static func _clone_cards(cards: Array[CardInstance]) -> Array[CardInstance]:
	var copies: Array[CardInstance] = []
	for card: CardInstance in cards:
		copies.append(card.clone())
	return copies
