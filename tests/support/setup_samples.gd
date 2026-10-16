class_name SetupSamples
extends RefCounted
## Catalogue et DuelSetup valides en mémoire, pour démarrer un duel par DuelEngine.

const HERO_ID: StringName = &"sample_hero"
const HERO_HEALTH: int = 15  # CatalogSamples.hero()
const DISTINCT_CARD_COUNT: int = 10
const COPIES_PER_CARD: int = 3  # 201.6.2 ; 10 × 3 = 30 cartes (201.6.1)
const DEFAULT_SEED: int = 7


## Dix Units de noms distincts et le Hero d'essai.
static func catalog() -> Catalog:
	var catalog := Catalog.new()
	for index: int in DISTINCT_CARD_COUNT:
		var data := CatalogSamples.with_field(CatalogSamples.unit(), "id", String(_card_id(index)))
		data = CatalogSamples.with_field(data, "name", "Unit d'essai %d" % index)
		catalog.add_card(CardDefinition.from_dict(data))
	catalog.add_hero(HeroDefinition.from_dict(CatalogSamples.hero()))
	return catalog


## Deck valide de 30 cartes, groupées par définition, dans l'ordre des identifiants.
static func deck() -> Array[StringName]:
	var ids: Array[StringName] = []
	for index: int in DISTINCT_CARD_COUNT:
		for copy: int in COPIES_PER_CARD:
			ids.append(_card_id(index))
	return ids


static func setup(rng_seed: int = DEFAULT_SEED) -> DuelSetup:
	var duel_setup := DuelSetup.new()
	duel_setup.deck_a = deck()
	duel_setup.deck_b = deck()
	duel_setup.hero_a = HERO_ID
	duel_setup.hero_b = HERO_ID
	duel_setup.rng_seed = rng_seed
	return duel_setup


## Ajoute à `catalog` une Unit de Force `force`, nommée d'après `id`.
static func add_unit(catalog: Catalog, id: StringName, force: int) -> void:
	catalog.add_card(CardDefinition.from_dict(_with_identity(CatalogSamples.unit(), id, force)))


## Ajoute à `catalog` un Building de Force `force`, nommé d'après `id`.
static func add_building(catalog: Catalog, id: StringName, force: int) -> void:
	catalog.add_card(CardDefinition.from_dict(_with_identity(CatalogSamples.building(), id, force)))


static func _with_identity(data: Dictionary, id: StringName, force: int) -> Dictionary:
	var named := CatalogSamples.with_field(data, "id", String(id))
	named = CatalogSamples.with_field(named, "name", "Carte %s" % id)
	return CatalogSamples.with_field(named, "force", force)


static func _card_id(index: int) -> StringName:
	return StringName("sample_unit_%d" % index)
