class_name GameLibrary
extends RefCounted
## Données du jeu lues au lancement : catalogue de `data/cards/` (décisions 0002 et 0010) et
## decks de `data/decks/`, à l'édition du catalogue (décision 0037). Chaque erreur de lecture est
## signalée par `push_error()`, et la fonction rend alors null : un catalogue ou un deck en erreur
## ne sert jamais au moteur.

const CARDS_DIRECTORY: String = "res://data/cards"
const DECKS_DIRECTORY: String = "res://data/decks"
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


static func _has_reported(errors: PackedStringArray) -> bool:
	for error: String in errors:
		push_error("GameLibrary : " + error)
	return not errors.is_empty()
