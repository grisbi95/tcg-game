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
	var result := Catalog.new()
	for index: int in DISTINCT_CARD_COUNT:
		var data := CatalogSamples.with_field(CatalogSamples.unit(), "id", String(_card_id(index)))
		data = CatalogSamples.with_field(data, "name", "Unit d'essai %d" % index)
		result.add_card(CardDefinition.from_dict(data))
	result.add_hero(HeroDefinition.from_dict(CatalogSamples.hero()))
	return result


## Deck valide de 30 cartes, groupées par définition, dans l'ordre des identifiants.
static func deck() -> Array[StringName]:
	var ids: Array[StringName] = []
	for index: int in DISTINCT_CARD_COUNT:
		for copy: int in COPIES_PER_CARD:
			ids.append(_card_id(index))
	return ids


static func setup(rng_seed: int = DEFAULT_SEED) -> DuelSetup:
	return mirror_setup(deck(), HERO_ID, rng_seed)


## Les deux joueurs jouent le même Hero et le même deck.
static func mirror_setup(
	deck_ids: Array[StringName], hero_id: StringName, rng_seed: int
) -> DuelSetup:
	var duel_setup := DuelSetup.new()
	duel_setup.deck_a = deck_ids.duplicate()
	duel_setup.deck_b = deck_ids.duplicate()
	duel_setup.hero_a = hero_id
	duel_setup.hero_b = hero_id
	duel_setup.rng_seed = rng_seed
	return duel_setup


## Ajoute à `target_catalog` une Unit de Force `force`, nommée d'après `id`.
static func add_unit(target_catalog: Catalog, id: StringName, force: int) -> void:
	var data := _with_identity(CatalogSamples.unit(), id, force)
	target_catalog.add_card(CardDefinition.from_dict(data))


## Ajoute à `target_catalog` un Building de Force `force`, nommé d'après `id`.
static func add_building(target_catalog: Catalog, id: StringName, force: int) -> void:
	var data := _with_identity(CatalogSamples.building(), id, force)
	target_catalog.add_card(CardDefinition.from_dict(data))


static func _with_identity(data: Dictionary, id: StringName, force: int) -> Dictionary:
	var named := CatalogSamples.with_field(data, "id", String(id))
	named = CatalogSamples.with_field(named, "name", "Carte %s" % id)
	return CatalogSamples.with_field(named, "force", force)


static func _card_id(index: int) -> StringName:
	return StringName("sample_unit_%d" % index)
