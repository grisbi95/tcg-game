extends GdUnitTestSuite
## DeckLoader et DeckList : decks en JSON dans data/decks/ (ruleset 0.36, décision 0037).
## Le contrôle des cartes et du Hero contre le catalogue relève de DuelSetup.find_errors.

const DECK_ID: StringName = &"deck_de_test"
const DECK_HERO: StringName = &"capitaine"
const SOURCE: String = "essai.json"
const EDITION: String = "0.36"
const OTHER_EDITION: String = "0.35"
const NOT_A_DIRECTORY: String = "res://data/decks_inexistants"
## Deck d'essai en mémoire : ordre de ses cartes et nombre d'exemplaires de chacune.
const FILE_ORDER: Array[StringName] = [&"recrue", &"soldat", &"veteran"]
const FILE_COPIES: Array[int] = [2, 3, 1]

var _catalog_edition: String


func before() -> void:
	_catalog_edition = TestCatalog.catalog().edition


func test_decision_0037_test_deck_file_loads_without_errors_in_the_catalog_edition() -> void:
	var loader := DeckLoader.new(_catalog_edition)
	loader.load_directory(TestCatalog.DECKS_DIRECTORY)
	assert_array(Array(loader.find_errors())).is_empty()
	var deck := loader.find_deck(DECK_ID)
	assert_object(deck).is_not_null()
	assert_str(String(deck.hero_id)).is_equal(String(DECK_HERO))
	assert_str(deck.deck_name).is_not_empty()


func test_decision_0037_card_ids_are_grouped_in_file_order() -> void:
	var loader := DeckLoader.new(EDITION)
	loader.load_text(_deck_text(_dictionary_text(FILE_ORDER, FILE_COPIES)), SOURCE)
	assert_array(Array(loader.find_errors())).is_empty()
	var expected: Array[StringName] = []
	for index: int in FILE_ORDER.size():
		for copy: int in FILE_COPIES[index]:
			expected.append(FILE_ORDER[index])
	assert_array(loader.find_deck(DECK_ID).card_ids()).is_equal(expected)


func test_decision_0037_find_deck_returns_null_for_an_unknown_id() -> void:
	var loader := DeckLoader.new()
	loader.load_text(_deck_text(_dictionary_text(FILE_ORDER, FILE_COPIES)), SOURCE)
	assert_object(loader.find_deck(&"absent")).is_null()
	assert_object(loader.find_deck(DECK_ID)).is_not_null()


func test_decision_0037_loaded_decks_keep_name_hero_and_order() -> void:
	var loader := DeckLoader.new()
	loader.load_text(_deck_text(_dictionary_text(FILE_ORDER, FILE_COPIES)), SOURCE)
	loader.load_text(_deck_text('{"x": 1}', "second"), SOURCE)
	var decks := loader.get_decks()
	assert_int(decks.size()).is_equal(2)
	assert_str(String(decks[0].deck_id)).is_equal(String(DECK_ID))
	assert_str(decks[0].deck_name).is_equal("Nom affiché")
	assert_str(String(decks[0].hero_id)).is_equal(String(DECK_HERO))
	assert_str(String(decks[1].deck_id)).is_equal("second")


func test_decision_0037_invalid_json_is_one_error() -> void:
	var loader := DeckLoader.new()
	loader.load_text('{"edition": "0.36",, }', SOURCE)
	_assert_one_error(loader, "JSON invalide")
	assert_array(loader.get_decks()).is_empty()


func test_decision_0037_root_must_be_an_object() -> void:
	var loader := DeckLoader.new()
	loader.load_text("[1, 2]", SOURCE)
	_assert_one_error(loader, "l'objet racine est attendu")
	assert_array(loader.get_decks()).is_empty()


func test_decision_0037_each_required_field_is_reported_when_absent() -> void:
	for field: String in ["edition", "id", "hero", "cards"]:
		var data := _deck_data()
		data.erase(field)
		var loader := DeckLoader.new()
		loader.load_text(JSON.stringify(data), SOURCE)
		_assert_one_error(loader, "champ « %s » absent" % field)


func test_decision_0037_unknown_field_is_one_error() -> void:
	var data := _deck_data()
	data["extra"] = 1
	var loader := DeckLoader.new()
	loader.load_text(JSON.stringify(data), SOURCE)
	_assert_one_error(loader, "champ « extra » inconnu")


func test_decision_0037_copies_must_be_integers_at_least_one() -> void:
	for bad_count: Variant in [1.5, 0, -2, "3", null]:
		var data := _deck_data()
		data["cards"] = {"recrue": bad_count}
		var loader := DeckLoader.new()
		loader.load_text(JSON.stringify(data), SOURCE)
		_assert_one_error(loader, "recrue")


func test_decision_0037_other_edition_than_expected_is_one_error() -> void:
	var data := _deck_data()
	data["edition"] = OTHER_EDITION
	var loader := DeckLoader.new(EDITION)
	loader.load_text(JSON.stringify(data), SOURCE)
	_assert_one_error(loader, "édition %s, attendue %s" % [OTHER_EDITION, EDITION])


func test_decision_0037_any_edition_is_accepted_without_an_expected_one() -> void:
	var data := _deck_data()
	data["edition"] = OTHER_EDITION
	var loader := DeckLoader.new()
	loader.load_text(JSON.stringify(data), SOURCE)
	assert_array(Array(loader.find_errors())).is_empty()


func test_decision_0037_duplicate_deck_is_one_error_and_keeps_the_first() -> void:
	var loader := DeckLoader.new()
	loader.load_text(JSON.stringify(_deck_data()), SOURCE)
	var second := _deck_data()
	second["hero"] = "autre"
	loader.load_text(JSON.stringify(second), SOURCE)
	_assert_one_error(loader, "déjà chargé")
	assert_int(loader.get_decks().size()).is_equal(1)
	assert_str(String(loader.find_deck(DECK_ID).hero_id)).is_equal(String(DECK_HERO))


func test_decision_0037_missing_directory_is_one_error() -> void:
	var loader := DeckLoader.new()
	loader.load_directory(NOT_A_DIRECTORY)
	_assert_one_error(loader, "dossier introuvable")


func _assert_one_error(loader: DeckLoader, fragment: String) -> void:
	var errors := loader.find_errors()
	assert_int(errors.size()).override_failure_message(str(errors)).is_equal(1)
	assert_bool(errors[0].contains(fragment)).override_failure_message(str(errors)).is_true()


func _deck_data() -> Dictionary:
	return {
		"edition": EDITION,
		"id": String(DECK_ID),
		"name": "Nom affiché",
		"hero": String(DECK_HERO),
		"cards": {"recrue": 2, "soldat": 3},
	}


func _deck_text(cards_text: String, deck_id: String = String(DECK_ID)) -> String:
	return (
		'{"edition": "%s", "id": "%s", "name": "Nom affiché", "hero": "%s", "cards": %s}'
		% [EDITION, deck_id, DECK_HERO, cards_text]
	)


func _dictionary_text(card_ids: Array[StringName], copies: Array[int]) -> String:
	var parts := PackedStringArray()
	for index: int in card_ids.size():
		parts.append('"%s": %d' % [card_ids[index], copies[index]])
	return "{" + ", ".join(parts) + "}"
