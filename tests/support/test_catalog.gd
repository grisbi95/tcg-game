class_name TestCatalog
extends RefCounted
## Hero et deck de test de docs/ruleset/70-playtest/decks-de-test.md, chargés depuis data/cards/
## et data/decks/ (étape 1.9, décision 0037). Le contrôle de l'édition est fait par
## test_catalog_loader.gd.

const DATA_DIRECTORY: String = GameLibrary.CARDS_DIRECTORY
const HERO_ID: StringName = &"capitaine"
const DECKS_DIRECTORY: String = GameLibrary.DECKS_DIRECTORY
const DECK_ID: StringName = GameLibrary.TEST_DECK_ID


## Catalogue de data/cards/ ; une erreur de chargement est signalée par `push_error()`, un
## catalogue en erreur ne devant pas servir au moteur.
static func catalog() -> Catalog:
	var catalog_loader := loader()
	for error: String in catalog_loader.find_errors():
		push_error("TestCatalog : " + error)
	return catalog_loader.get_catalog()


static func loader() -> CatalogLoader:
	var catalog_loader := CatalogLoader.new()
	catalog_loader.load_directory(DATA_DIRECTORY)
	return catalog_loader


## Deck de 30 cartes de data/decks/ (décision 0037), groupées par définition dans l'ordre du
## fichier ; une erreur de chargement est signalée par `push_error()`.
static func deck() -> Array[StringName]:
	var deck_loader := DeckLoader.new()
	deck_loader.load_directory(DECKS_DIRECTORY)
	for error: String in deck_loader.find_errors():
		push_error("TestCatalog : " + error)
	var deck_list := deck_loader.find_deck(DECK_ID)
	if deck_list == null:
		push_error("TestCatalog : deck « %s » absent" % DECK_ID)
		return []
	return deck_list.card_ids()


## Les deux joueurs jouent le Capitaine et le même deck (décisions 0153 et 0164 du ruleset).
static func setup(rng_seed: int) -> DuelSetup:
	return SetupSamples.mirror_setup(deck(), HERO_ID, rng_seed)
