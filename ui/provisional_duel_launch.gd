class_name ProvisionalDuelLaunch
extends RefCounted
## Lancement provisoire de l'écran de duel (étape 2.3) : les cartes de `data/cards/` et un duel de
## deux humains avec le Hero de test des deux côtés. L'étape 2.4 le remplace par la préparation
## (decks, graine, mulligan).

const CARDS_DIRECTORY: String = "res://data/cards"
const HERO_ID: StringName = &"capitaine"


static func load_catalog() -> Catalog:
	var loader := CatalogLoader.new()
	loader.load_directory(CARDS_DIRECTORY)
	for error: String in loader.find_errors():
		push_error("ProvisionalDuelLaunch : " + error)
	return loader.get_catalog()


## Chaque carte du catalogue à tour de rôle jusqu'à la taille d'un deck (201.6.1), pour les deux
## joueurs, graine tirée.
static func make_setup(catalog: Catalog) -> DuelSetup:
	var duel_setup := DuelSetup.new()
	var card_ids := catalog.card_ids()
	for index: int in DuelConfig.new().deck_size:
		duel_setup.deck_a.append(card_ids[index % card_ids.size()])
	duel_setup.deck_b.assign(duel_setup.deck_a)
	duel_setup.hero_a = HERO_ID
	duel_setup.hero_b = HERO_ID
	duel_setup.rng_seed = randi()
	return duel_setup
