class_name TestCatalog
extends RefCounted
## Hero et deck de test de docs/ruleset/70-playtest/decks-de-test.md, chargés depuis data/cards/
## (étape 1.9). Le contrôle de l'édition est fait par test_catalog_loader.gd.

const DATA_DIRECTORY: String = "res://data/cards"
const HERO_ID: StringName = &"capitaine"
## Décision 0171 du ruleset : nombre d'exemplaires de chaque carte du deck de test.
const DECK_COPIES: Dictionary[StringName, int] = {
	&"recrue": 2,
	&"soldat": 3,
	&"veteran": 3,
	&"champion": 2,
	&"colosse": 2,
	&"pillard": 2,
	&"gardien": 2,
	&"heraut": 1,
	&"martyr": 1,
	&"palissade": 1,
	&"bastion": 1,
	&"campement": 2,
	&"renfort": 2,
	&"frappe": 2,
	&"contre": 1,
	&"levee": 1,
	&"lame": 2,
}


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


## Deck de 30 cartes, groupées par définition dans l'ordre de DECK_COPIES.
static func deck() -> Array[StringName]:
	var ids: Array[StringName] = []
	for card_id: StringName in DECK_COPIES:
		for copy: int in DECK_COPIES[card_id]:
			ids.append(card_id)
	return ids


## Les deux joueurs jouent le Capitaine et le même deck (décisions 0153 et 0164 du ruleset).
static func setup(rng_seed: int) -> DuelSetup:
	return SetupSamples.mirror_setup(deck(), HERO_ID, rng_seed)
