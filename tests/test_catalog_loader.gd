# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## Catalogue : chargement JSON, édition, identifiants et construction du deck (ruleset 0.28,
## décisions 0002 et 0010).

const DATA_DIRECTORY: String = "res://data/cards"
const EDITION_FILE: String = "res://docs/ruleset/RULESET_EDITION"
const EDITION: String = "0.28"
const DECK_SIZE: int = 30  # 201.6.1
const MAX_COPIES: int = 3  # 201.6.2

var _config: DuelConfig


func before_test() -> void:
	_config = DuelConfig.new()


func _load(json_text: String, expected_edition: String = "") -> CatalogLoader:
	var loader := CatalogLoader.new(expected_edition)
	loader.load_text(json_text, "essai.json")
	return loader


func _mentions(errors: PackedStringArray, fragment: String) -> bool:
	return CatalogSamples.mentions(errors, fragment)


func _card_named(card_id: String, card_name: String) -> Dictionary:
	var card := CatalogSamples.unit()
	card["id"] = card_id
	card["name"] = card_name
	return card


## Catalogue d'essai : `distinct_cards` cartes de noms différents, hors Hero.
func _catalog_of(distinct_cards: int) -> Catalog:
	var cards: Array[Dictionary] = []
	for index: int in distinct_cards:
		cards.append(_card_named("sample_%d" % index, "Carte %d" % index))
	return _load(CatalogSamples.catalog_text(cards)).get_catalog()


func _deck_of(card_ids: Array[String], copies: int) -> Array[StringName]:
	var deck: Array[StringName] = []
	for card_id: String in card_ids:
		for copy_index: int in copies:
			deck.append(StringName(card_id))
	return deck


func test_in_memory_catalog_resolves_definitions_by_id() -> void:
	var loader := _load(
		CatalogSamples.catalog_text(
			[CatalogSamples.unit(), CatalogSamples.spell()], [CatalogSamples.hero()]
		)
	)
	var catalog := loader.get_catalog()
	assert_array(Array(loader.find_errors())).is_empty()
	assert_int(catalog.card_count()).is_equal(2)
	assert_int(catalog.hero_count()).is_equal(1)
	assert_str(catalog.get_card(&"sample_unit").card_name).is_equal("Unit d'essai")
	assert_int(catalog.get_hero(&"sample_hero").health).is_equal(15)
	assert_object(catalog.get_card(&"absent")).is_null()
	assert_bool(catalog.has_definition(&"sample_hero")).is_true()
	assert_str(catalog.edition).is_equal(EDITION)


func test_card_ids_keep_the_file_order() -> void:
	var catalog := (
		_load(CatalogSamples.catalog_text([_card_named("b_card", "B"), _card_named("a_card", "A")]))
		. get_catalog()
	)
	assert_array(catalog.card_ids()).contains_exactly([&"b_card", &"a_card"])


func test_a_card_is_not_a_hero() -> void:
	var catalog := (
		_load(CatalogSamples.catalog_text([CatalogSamples.unit()], [CatalogSamples.hero()]))
		. get_catalog()
	)
	assert_object(catalog.get_card(&"sample_hero")).is_null()
	assert_object(catalog.get_hero(&"sample_unit")).is_null()


func test_invalid_json_is_refused_with_its_source_and_line() -> void:
	var errors := _load('{"edition": "0.28",\n "cards": [,]}').find_errors()
	assert_bool(_mentions(errors, "essai.json : JSON invalide, ligne")).is_true()


func test_root_must_be_an_object() -> void:
	var errors := _load("[1, 2]").find_errors()
	assert_bool(_mentions(errors, "l'objet racine est attendu")).is_true()


func test_every_error_of_an_invalid_card_surfaces_with_its_id() -> void:
	var bad_unit := CatalogSamples.without_field(CatalogSamples.unit(), "force")
	var errors := _load(CatalogSamples.catalog_text([bad_unit])).find_errors()
	assert_bool(_mentions(errors, "carte « sample_unit » : 202.1.5")).is_true()


func test_a_hero_error_surfaces_with_its_id() -> void:
	var bad_hero := CatalogSamples.with_field(CatalogSamples.hero(), "health", 0)
	var errors := _load(CatalogSamples.catalog_text([], [bad_hero])).find_errors()
	assert_bool(_mentions(errors, "hero « sample_hero » : 202.3.7")).is_true()


func test_entries_must_be_objects() -> void:
	var errors := _load(CatalogSamples.catalog_text([3], ["x"])).find_errors()
	assert_bool(_mentions(errors, "chaque entrée de « cards » est un objet")).is_true()
	assert_bool(_mentions(errors, "chaque entrée de « heroes » est un objet")).is_true()


func test_duplicate_ids_are_refused() -> void:
	var errors := (
		_load(CatalogSamples.catalog_text([CatalogSamples.unit(), CatalogSamples.unit()]))
		. find_errors()
	)
	assert_bool(_mentions(errors, "carte « sample_unit » : id déjà pris")).is_true()


func test_202_3_4_hero_and_cards_share_one_id_space() -> void:
	var card_with_hero_id := CatalogSamples.with_field(CatalogSamples.unit(), "id", "sample_hero")
	var errors := (
		_load(CatalogSamples.catalog_text([card_with_hero_id], [CatalogSamples.hero()]))
		. find_errors()
	)
	assert_bool(_mentions(errors, "id déjà pris")).is_true()


func test_unknown_top_level_field_is_refused() -> void:
	var text := JSON.stringify({"edition": EDITION, "decks": []})
	assert_bool(_mentions(_load(text).find_errors(), "« decks » inconnu")).is_true()


func test_edition_is_required_in_every_file() -> void:
	var text := JSON.stringify({"cards": []})
	assert_bool(_mentions(_load(text).find_errors(), "champ « edition » absent")).is_true()


func test_edition_must_match_the_expected_one() -> void:
	var text := CatalogSamples.catalog_text([], [], "0.27")
	(
		assert_bool(_mentions(_load(text, EDITION).find_errors(), "édition 0.27, attendue 0.28"))
		. is_true()
	)
	assert_array(Array(_load(text).find_errors())).is_empty()


func test_files_must_agree_on_the_edition() -> void:
	var loader := CatalogLoader.new()
	loader.load_text(CatalogSamples.catalog_text([], [], "0.28"), "premier.json")
	loader.load_text(CatalogSamples.catalog_text([], [], "0.27"), "second.json")
	assert_bool(_mentions(loader.find_errors(), "second.json : édition 0.27")).is_true()


func test_two_files_merge_into_one_catalog() -> void:
	var loader := CatalogLoader.new()
	loader.load_text(CatalogSamples.catalog_text([CatalogSamples.unit()]), "units.json")
	loader.load_text(CatalogSamples.catalog_text([CatalogSamples.spell()]), "spells.json")
	assert_array(Array(loader.find_errors())).is_empty()
	assert_int(loader.get_catalog().card_count()).is_equal(2)


func test_missing_file_and_directory_are_reported() -> void:
	var loader := CatalogLoader.new()
	loader.load_file("res://data/cards/absent.json")
	loader.load_directory("res://data/absent")
	assert_bool(_mentions(loader.find_errors(), "absent.json : lecture impossible")).is_true()
	(
		assert_bool(_mentions(loader.find_errors(), "res://data/absent : dossier introuvable"))
		. is_true()
	)


func test_data_cards_directory_loads_without_errors_in_the_pinned_edition() -> void:
	var edition := FileAccess.get_file_as_string(EDITION_FILE).strip_edges()
	var loader := CatalogLoader.new(edition)
	loader.load_directory(DATA_DIRECTORY)
	assert_array(Array(loader.find_errors())).is_empty()


func test_201_6_1_deck_has_exactly_the_configured_size() -> void:
	assert_int(_config.deck_size).is_equal(DECK_SIZE)
	var catalog := _catalog_of(10)
	var ids: Array[String] = []
	for index: int in 10:
		ids.append("sample_%d" % index)
	var full := catalog.find_deck_errors(_deck_of(ids, 3), _config)
	var short := catalog.find_deck_errors(_deck_of(ids, 2), _config)
	var long := catalog.find_deck_errors(_deck_of(ids, 4), _config)
	assert_array(Array(full)).is_empty()
	assert_bool(_mentions(short, "201.6.1 : 20 cartes au lieu de 30")).is_true()
	assert_bool(_mentions(long, "201.6.1 : 40 cartes au lieu de 30")).is_true()


func test_201_6_2_at_most_three_copies_of_a_card() -> void:
	assert_int(_config.max_copies_per_card).is_equal(MAX_COPIES)
	var catalog := _catalog_of(10)
	var deck: Array[StringName] = []
	for index: int in 26:
		deck.append(StringName("sample_%d" % (index % 9 + 1)))
	for index: int in 4:
		deck.append(&"sample_0")
	var errors := catalog.find_deck_errors(deck, _config)
	assert_bool(_mentions(errors, "201.6.2 : 4 exemplaires de « Carte 0 », au plus 3")).is_true()


func test_201_6_2_copies_are_cards_of_the_same_name() -> void:
	var twin_a := _card_named("twin_a", "Jumelle")
	var twin_b := _card_named("twin_b", "Jumelle")
	var catalog := _load(CatalogSamples.catalog_text([twin_a, twin_b])).get_catalog()
	var deck: Array[StringName] = [&"twin_a", &"twin_a", &"twin_b", &"twin_b"]
	var errors := catalog.find_deck_errors(deck, _config)
	assert_bool(_mentions(errors, "201.6.2 : 4 exemplaires de « Jumelle »")).is_true()


func test_202_3_5_hero_is_not_a_deck_card() -> void:
	var catalog := (
		_load(CatalogSamples.catalog_text([CatalogSamples.unit()], [CatalogSamples.hero()]))
		. get_catalog()
	)
	var errors := catalog.find_deck_errors([&"sample_hero", &"absent"], _config)
	(
		assert_bool(_mentions(errors, "202.3.5 : « sample_hero » n'est pas une carte de deck"))
		. is_true()
	)
	assert_bool(_mentions(errors, "202.3.5 : « absent » n'est pas une carte de deck")).is_true()
