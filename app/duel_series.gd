class_name DuelSeries
extends RefCounted
## Suite de duels locaux entre deux humains (décision 0036) : numéro de la partie et premier
## joueur, qui alterne d'une partie à l'autre à partir du joueur A, comme le protocole de playtest
## (décisions 0158 et 0168 du ruleset) ; il est imposé au `DuelSetup` (décision 0012). La graine
## d'une partie est tirée ici, hors du moteur, et reste affichable pour rejouer la partie.

const FIRST_GAME_NUMBER: int = 1
const FIRST_GAME_FIRST_PLAYER: DuelState.PlayerSide = DuelState.PlayerSide.A

var _deck_a: DeckList
var _deck_b: DeckList
var _game_number: int = FIRST_GAME_NUMBER


func _init(deck_a: DeckList, deck_b: DeckList) -> void:
	_deck_a = deck_a
	_deck_b = deck_b


## Numéro de la partie à venir, 1 pour la première.
func get_game_number() -> int:
	return _game_number


## Décisions 0158 et 0168 du ruleset : A commence la partie 1, puis le premier joueur alterne.
func get_first_player() -> DuelState.PlayerSide:
	var is_odd_game := (_game_number - FIRST_GAME_NUMBER) % DuelState.PLAYER_COUNT == 0
	if is_odd_game:
		return FIRST_GAME_FIRST_PLAYER
	return DuelState.opponent_of(FIRST_GAME_FIRST_PLAYER)


func get_deck(side: DuelState.PlayerSide) -> DeckList:
	return _deck_a if side == DuelState.PlayerSide.A else _deck_b


## Préparation de la partie à venir, avec `rng_seed`.
func make_setup(rng_seed: int) -> DuelSetup:
	var duel_setup := DuelSetup.new()
	duel_setup.deck_a = _deck_a.card_ids()
	duel_setup.deck_b = _deck_b.card_ids()
	duel_setup.hero_a = _deck_a.hero_id
	duel_setup.hero_b = _deck_b.hero_id
	duel_setup.rng_seed = rng_seed
	duel_setup.impose_first_player(get_first_player())
	return duel_setup


## La partie en cours est finie : la suivante change de premier joueur.
func advance_to_next_game() -> void:
	_game_number += 1


## Graine d'une nouvelle partie ; le moteur ne tire au hasard que par elle (CLAUDE.md §3).
static func draw_seed() -> int:
	return randi()
