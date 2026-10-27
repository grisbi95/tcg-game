class_name DuelSeries
extends RefCounted
## Suite de duels entre deux humains (décision 0036) : numéro de la partie, deck de chaque joueur
## et premier joueur, choisis par l'hôte à la préparation (décision 0066) ; le premier joueur est
## imposé au `DuelSetup` ou tiré par le moteur (décision 0012). La graine d'une partie est tirée
## ici, hors du moteur, et reste affichable pour rejouer la partie.

## Décision 0066 : le premier joueur choisi par l'hôte.
enum FirstPlayerChoice {
	PLAYER_A,
	PLAYER_B,
	DRAWN,  # tiré au sort par le moteur (décision 0012)
}

const FIRST_GAME_NUMBER: int = 1
const DEFAULT_FIRST_PLAYER_CHOICE: FirstPlayerChoice = FirstPlayerChoice.PLAYER_A

var _decks: Dictionary[DuelState.PlayerSide, DeckList] = {}
var _first_player_choice: FirstPlayerChoice = DEFAULT_FIRST_PLAYER_CHOICE
var _game_number: int = FIRST_GAME_NUMBER


func _init(deck_a: DeckList, deck_b: DeckList) -> void:
	_decks[DuelState.PlayerSide.A] = deck_a
	_decks[DuelState.PlayerSide.B] = deck_b


## Numéro de la partie à venir, 1 pour la première.
func get_game_number() -> int:
	return _game_number


func get_deck(side: DuelState.PlayerSide) -> DeckList:
	return _decks[side]


## Décision 0066 : l'hôte donne `deck` au joueur `side` pour les parties à venir.
func set_deck(side: DuelState.PlayerSide, deck: DeckList) -> void:
	_decks[side] = deck


func get_first_player_choice() -> FirstPlayerChoice:
	return _first_player_choice


## Décision 0066 : l'hôte choisit qui commence les parties à venir.
func set_first_player_choice(choice: FirstPlayerChoice) -> void:
	_first_player_choice = choice


## Préparation de la partie à venir, avec `rng_seed`.
func make_setup(rng_seed: int) -> DuelSetup:
	var duel_setup := DuelSetup.new()
	var deck_a := get_deck(DuelState.PlayerSide.A)
	var deck_b := get_deck(DuelState.PlayerSide.B)
	duel_setup.deck_a = deck_a.card_ids()
	duel_setup.deck_b = deck_b.card_ids()
	duel_setup.hero_a = deck_a.hero_id
	duel_setup.hero_b = deck_b.hero_id
	duel_setup.rng_seed = rng_seed
	match _first_player_choice:
		FirstPlayerChoice.PLAYER_A:
			duel_setup.impose_first_player(DuelState.PlayerSide.A)
		FirstPlayerChoice.PLAYER_B:
			duel_setup.impose_first_player(DuelState.PlayerSide.B)
		FirstPlayerChoice.DRAWN:
			pass
	return duel_setup


## La partie en cours est finie ; decks et premier joueur restent ceux que l'hôte a choisis.
func advance_to_next_game() -> void:
	_game_number += 1


## Graine d'une nouvelle partie ; le moteur ne tire au hasard que par elle (CLAUDE.md §3).
static func draw_seed() -> int:
	return randi()
