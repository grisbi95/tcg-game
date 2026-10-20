extends GdUnitTestSuite
## GameLibrary : catalogue et deck de test lus au lancement (ruleset 0.36, décisions 0037 et 0036).

const UNKNOWN_DECK_ID: StringName = &"deck_inexistant"


func test_decision_0037_library_loads_the_catalog_without_error() -> void:
	var catalog := GameLibrary.load_catalog()
	assert_int(catalog.card_count()).is_greater(0)
	assert_str(catalog.edition).is_not_empty()
	assert_object(catalog.get_hero(TestCatalog.HERO_ID)).is_not_null()


func test_decision_0036_library_loads_the_test_deck() -> void:
	var catalog := GameLibrary.load_catalog()
	var deck := GameLibrary.load_deck(catalog)
	assert_object(deck).is_not_null()
	assert_str(String(deck.deck_id)).is_equal(String(GameLibrary.TEST_DECK_ID))
	assert_str(String(deck.deck_id)).is_equal(String(TestCatalog.DECK_ID))
	assert_array(deck.card_ids()).is_equal(TestCatalog.deck())


func test_decision_0036_library_deck_is_valid_for_a_duel_setup() -> void:
	var catalog := GameLibrary.load_catalog()
	var deck := GameLibrary.load_deck(catalog)
	var duel_setup := DuelSeries.new(deck, deck).make_setup(1)
	assert_array(Array(duel_setup.find_errors(catalog, DuelConfig.new()))).is_empty()


func test_decision_0037_unknown_deck_id_gives_null_and_reports_an_error() -> void:
	var catalog := GameLibrary.load_catalog()
	var found: Array[DeckList] = []
	var load_unknown := func() -> void:
		found.append(GameLibrary.load_deck(catalog, UNKNOWN_DECK_ID))
	await assert_error(load_unknown).is_push_error(
		"GameLibrary : deck « %s » absent de %s" % [UNKNOWN_DECK_ID, GameLibrary.DECKS_DIRECTORY]
	)
	assert_array(found).has_size(1)
	assert_object(found[0]).is_null()
