class_name GameLibrary
extends RefCounted
## Données du jeu lues au lancement : catalogue de `data/cards/` (décisions 0002 et 0010),
## decks de `data/decks/` (décision 0037) et plan de série de `data/series/` (décision 0069), à
## l'édition du catalogue. Chaque erreur de lecture est
## signalée par `push_error()`, et la fonction rend alors null : un catalogue ou un deck en erreur
## ne sert jamais au moteur.

const CARDS_DIRECTORY: String = "res://data/cards"
const DECKS_DIRECTORY: String = "res://data/decks"
## Décision 0069 : le plan de série du protocole de playtest.
const SERIES_PLAN_PATH: String = "res://data/series/plan_de_serie.json"
## Décision de design 0229 du ruleset : 6 affrontements de 4 parties, soit 24 parties.
const SERIES_MATCHUP_COUNT: int = 6
const SERIES_GAMES_PER_MATCHUP: int = 4
const SERIES_GAME_COUNT: int = SERIES_MATCHUP_COUNT * SERIES_GAMES_PER_MATCHUP
## Décision 0066 : deck proposé aux deux joueurs tant que l'hôte n'en choisit pas un autre.
const TEST_DECK_ID: StringName = &"deck_de_test"


## Catalogue de `data/cards/` ; null en cas d'erreur.
static func load_catalog() -> Catalog:
	var loader := CatalogLoader.new()
	loader.load_directory(CARDS_DIRECTORY)
	if _has_reported(loader.find_errors()):
		return null
	return loader.get_catalog()


## Deck `deck_id` à l'édition de `catalog` ; null s'il manque ou en cas d'erreur.
static func load_deck(catalog: Catalog, deck_id: StringName = TEST_DECK_ID) -> DeckList:
	var loader := DeckLoader.new(catalog.edition)
	loader.load_directory(DECKS_DIRECTORY)
	if _has_reported(loader.find_errors()):
		return null
	var deck := loader.find_deck(deck_id)
	if deck == null:
		push_error("GameLibrary : deck « %s » absent de %s" % [deck_id, DECKS_DIRECTORY])
	return deck


## Décision 0066 : tous les decks de `data/decks/` à l'édition de `catalog`, dans l'ordre de
## lecture ; vide en cas d'erreur.
static func load_decks(catalog: Catalog) -> Array[DeckList]:
	var loader := DeckLoader.new(catalog.edition)
	loader.load_directory(DECKS_DIRECTORY)
	if _has_reported(loader.find_errors()):
		return []
	return loader.get_decks()


## Décision 0069 : plan de série à l'édition de `catalog`, dont chaque deck est l'un de `decks` ;
## null en cas d'erreur (deck inconnu, numéro de partie manquant ou en double, nombre de parties
## autre que `SERIES_GAME_COUNT`).
static func load_series_plan(catalog: Catalog, decks: Array[DeckList]) -> SeriesPlan:
	var deck_ids: Array[StringName] = []
	for deck: DeckList in decks:
		deck_ids.append(deck.deck_id)
	var loader := SeriesPlanLoader.new(catalog.edition, deck_ids, SERIES_GAME_COUNT)
	loader.load_file(SERIES_PLAN_PATH)
	if _has_reported(loader.find_errors()):
		return null
	return loader.get_plan()


static func _has_reported(errors: PackedStringArray) -> bool:
	for error: String in errors:
		push_error("GameLibrary : " + error)
	return not errors.is_empty()
