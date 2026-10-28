class_name DuelSeries
extends RefCounted
## Suite de duels entre deux humains (décision 0036). Décision 0069 : l'hôte choisit à la
## préparation une partie du plan de série, qui fixe le deck de chaque joueur et le premier joueur,
## ou la partie libre, où il choisit decks et premier joueur (décision 0066) ; le premier joueur
## est imposé au `DuelSetup` ou tiré par le moteur (décision 0012). La graine d'une partie est
## tirée ici, hors du moteur, et reste affichable pour rejouer la partie.

## Décision 0066 : le premier joueur choisi par l'hôte pour la partie libre.
enum FirstPlayerChoice {
	PLAYER_A,
	PLAYER_B,
	DRAWN,  # tiré au sort par le moteur (décision 0012)
}

## Décision 0069 : numéro de la partie libre, hors du plan de série ; celui de la fiche hors plan.
const NO_PLAN_GAME: int = PlaytestSheet.OFF_PLAN_GAME_NUMBER
const DEFAULT_FIRST_PLAYER_CHOICE: FirstPlayerChoice = FirstPlayerChoice.PLAYER_A
const UNKNOWN_GAME_FORMAT: String = "DuelSeries : partie %d absente du plan de série"
const FIRST_PLAYER_CHOICES: Dictionary[DuelState.PlayerSide, FirstPlayerChoice] = {
	DuelState.PlayerSide.A: FirstPlayerChoice.PLAYER_A,
	DuelState.PlayerSide.B: FirstPlayerChoice.PLAYER_B,
}

## Decks de la partie libre, choisis par l'hôte (décision 0066).
var _free_decks: Dictionary[DuelState.PlayerSide, DeckList] = {}
var _first_player_choice: FirstPlayerChoice = DEFAULT_FIRST_PLAYER_CHOICE
var _plan: SeriesPlan = SeriesPlan.new()
var _plan_decks: Dictionary[StringName, DeckList] = {}
var _chosen_game: SeriesPlanGame = null


## Decks de la partie libre ; la partie choisie est la partie libre.
func _init(deck_a: DeckList, deck_b: DeckList) -> void:
	_free_decks[DuelState.PlayerSide.A] = deck_a
	_free_decks[DuelState.PlayerSide.B] = deck_b


## Décision 0069 : `plan` lu par `GameLibrary.load_series_plan`, ses decks pris dans `decks`.
func set_plan(plan: SeriesPlan, decks: Array[DeckList]) -> void:
	_plan = plan
	_plan_decks.clear()
	for deck: DeckList in decks:
		_plan_decks[deck.deck_id] = deck
	_chosen_game = null


## Parties du plan, dans l'ordre des numéros ; vide sans plan.
func get_plan_games() -> Array[SeriesPlanGame]:
	return _plan.games


## Décision 0069 : l'hôte choisit la partie `game_number` du plan, dans l'ordre qu'il veut
## (Q-142 du ruleset) ; un numéro que le plan n'a pas est signalé par `push_error()` et ne change
## rien.
func choose_plan_game(game_number: int) -> void:
	var game := _plan.find_game(game_number)
	if game == null:
		push_error(UNKNOWN_GAME_FORMAT % game_number)
		return
	_chosen_game = game


## Décision 0069 : l'hôte choisit la partie libre, aux decks et premier joueur de la décision 0066.
func choose_free_game() -> void:
	_chosen_game = null


func is_free_game() -> bool:
	return _chosen_game == null


## Partie du plan choisie ; null pour la partie libre.
func get_chosen_game() -> SeriesPlanGame:
	return _chosen_game


## Décision 0069 : numéro de la partie choisie dans le plan de série, `NO_PLAN_GAME` pour la
## partie libre ; c'est le numéro de la fiche de relevé.
func get_game_number() -> int:
	return NO_PLAN_GAME if is_free_game() else _chosen_game.game_number


## Deck du joueur `side` pour la partie choisie : celui du plan, ou celui de l'hôte.
func get_deck(side: DuelState.PlayerSide) -> DeckList:
	if is_free_game():
		return _free_decks[side]
	return _plan_decks[_chosen_game.deck_id(side)]


## Noms affichés des decks de la partie choisie, par joueur.
func get_deck_names() -> Dictionary[DuelState.PlayerSide, String]:
	var names: Dictionary[DuelState.PlayerSide, String] = {}
	for side: DuelState.PlayerSide in DuelState.SIDES:
		names[side] = get_deck(side).deck_name
	return names


## Décision 0066 : l'hôte donne `deck` au joueur `side` pour la partie libre.
func set_deck(side: DuelState.PlayerSide, deck: DeckList) -> void:
	_free_decks[side] = deck


## Décision 0066 : le premier joueur choisi par l'hôte pour la partie libre.
func get_first_player_choice() -> FirstPlayerChoice:
	return _first_player_choice


## Premier joueur de la partie choisie : celui qu'impose une partie du plan (décision 0069), ou
## celui que l'hôte a choisi pour la partie libre (décision 0066).
func get_chosen_first_player_choice() -> FirstPlayerChoice:
	if is_free_game():
		return _first_player_choice
	return FIRST_PLAYER_CHOICES[_chosen_game.first_player]


## « Revanche » : vrai si elle ramène à la préparation, faux si elle rejoue la partie libre avec
## une graine neuve (décisions 0036 et 0066) ; décision 0050 : un duel à distance (`is_remote`)
## ramène à la préparation ; décision 0069 : après une partie du plan aussi, pour choisir la
## suivante.
func rematch_returns_to_setup(is_remote: bool) -> bool:
	return is_remote or not is_free_game()


## Décision 0066 : l'hôte choisit qui commence la partie libre.
func set_first_player_choice(choice: FirstPlayerChoice) -> void:
	_first_player_choice = choice


## Préparation de la partie choisie, avec `rng_seed` ; décision 0069 : une partie du plan impose
## son premier joueur.
func make_setup(rng_seed: int) -> DuelSetup:
	var duel_setup := DuelSetup.new()
	var deck_a := get_deck(DuelState.PlayerSide.A)
	var deck_b := get_deck(DuelState.PlayerSide.B)
	duel_setup.deck_a = deck_a.card_ids()
	duel_setup.deck_b = deck_b.card_ids()
	duel_setup.hero_a = deck_a.hero_id
	duel_setup.hero_b = deck_b.hero_id
	duel_setup.rng_seed = rng_seed
	if not is_free_game():
		duel_setup.impose_first_player(_chosen_game.first_player)
		return duel_setup
	match _first_player_choice:
		FirstPlayerChoice.PLAYER_A:
			duel_setup.impose_first_player(DuelState.PlayerSide.A)
		FirstPlayerChoice.PLAYER_B:
			duel_setup.impose_first_player(DuelState.PlayerSide.B)
		FirstPlayerChoice.DRAWN:
			pass
	return duel_setup


## Graine d'une nouvelle partie ; le moteur ne tire au hasard que par elle (CLAUDE.md §3).
static func draw_seed() -> int:
	return randi()
