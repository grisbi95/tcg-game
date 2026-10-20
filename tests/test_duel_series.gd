extends GdUnitTestSuite
## DuelSeries : numéro de partie, premier joueur alterné et préparation du duel (ruleset 0.36,
## décision 0036 ; décisions 0158 et 0168 du ruleset ; décision 0012 pour le DuelSetup).

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const SEED: int = 4242
const OTHER_SEED: int = 4243
const GAME_COUNT: int = 3

var _catalog: Catalog
var _deck: DeckList


func before() -> void:
	_catalog = TestCatalog.catalog()
	var loader := DeckLoader.new(_catalog.edition)
	loader.load_directory(TestCatalog.DECKS_DIRECTORY)
	_deck = loader.find_deck(TestCatalog.DECK_ID)


func test_decision_0036_first_player_alternates_starting_with_a() -> void:
	var series := DuelSeries.new(_deck, _deck)
	var expected: Array[DuelState.PlayerSide] = [A, B, A]
	var actual: Array[DuelState.PlayerSide] = []
	var numbers: Array[int] = []
	for game: int in GAME_COUNT:
		numbers.append(series.get_game_number())
		actual.append(series.get_first_player())
		series.advance_to_next_game()
	assert_array(numbers).is_equal([1, 2, 3])
	assert_array(actual).is_equal(expected)


func test_decision_0036_setup_carries_decks_heroes_seed_and_imposed_first_player() -> void:
	var series := DuelSeries.new(_deck, _deck)
	series.advance_to_next_game()
	var duel_setup := series.make_setup(SEED)
	assert_array(duel_setup.deck_a).is_equal(_deck.card_ids())
	assert_array(duel_setup.deck_b).is_equal(_deck.card_ids())
	assert_str(String(duel_setup.hero_a)).is_equal(String(_deck.hero_id))
	assert_str(String(duel_setup.hero_b)).is_equal(String(_deck.hero_id))
	assert_int(duel_setup.rng_seed).is_equal(SEED)
	assert_bool(duel_setup.is_first_player_imposed).is_true()
	assert_int(duel_setup.imposed_first_player).is_equal(series.get_first_player())
	assert_int(duel_setup.imposed_first_player).is_equal(B)


func test_decision_0036_each_side_takes_its_own_deck() -> void:
	var other := DeckList.new()
	other.deck_id = &"autre"
	other.hero_id = &"autre_hero"
	other.copies = {&"recrue": 1}
	var series := DuelSeries.new(_deck, other)
	var duel_setup := series.make_setup(SEED)
	assert_object(series.get_deck(A)).is_same(_deck)
	assert_object(series.get_deck(B)).is_same(other)
	assert_array(duel_setup.deck_b).is_equal([&"recrue"])
	assert_str(String(duel_setup.hero_b)).is_equal("autre_hero")
	assert_array(duel_setup.deck_a).is_equal(_deck.card_ids())


func test_decision_0036_setup_is_accepted_by_the_engine() -> void:
	for game: int in GAME_COUNT:
		var series := DuelSeries.new(_deck, _deck)
		for skipped: int in game:
			series.advance_to_next_game()
		var duel_setup := series.make_setup(SEED)
		assert_array(Array(duel_setup.find_errors(_catalog, DuelConfig.new()))).is_empty()
		var engine := DuelEngine.new(_catalog)
		var events := engine.start_new_duel(duel_setup)
		assert_array(EventLog.describe(events).slice(0, 2)).contains_exactly(
			["HeroPlaced:A", "HeroPlaced:B"]
		)
		var state := engine.get_state()
		assert_bool(state.first_player_imposed).is_true()
		assert_int(state.first_player).is_equal(series.get_first_player())


func test_decision_0036_same_seed_gives_the_same_duel() -> void:
	var config := DuelConfig.new()
	var first_engine := DuelEngine.new(_catalog, config)
	var second_engine := DuelEngine.new(_catalog, config)
	var first_events := first_engine.start_new_duel(DuelSeries.new(_deck, _deck).make_setup(SEED))
	var second_events := second_engine.start_new_duel(DuelSeries.new(_deck, _deck).make_setup(SEED))
	assert_array(EventLog.describe(first_events)).is_equal(EventLog.describe(second_events))
	var defects := DeepCompare.find_clone_defects(
		first_engine.get_state(), second_engine.get_state()
	)
	assert_array(Array(defects)).is_empty()


func test_decision_0036_another_seed_shuffles_differently() -> void:
	var series := DuelSeries.new(_deck, _deck)
	var first_engine := DuelEngine.new(_catalog)
	var second_engine := DuelEngine.new(_catalog)
	first_engine.start_new_duel(series.make_setup(SEED))
	second_engine.start_new_duel(series.make_setup(OTHER_SEED))
	var first_hand := first_engine.get_state().get_player(A).hand
	var second_hand := second_engine.get_state().get_player(A).hand
	var first_ids: Array[StringName] = []
	var second_ids: Array[StringName] = []
	for card: CardInstance in first_hand:
		first_ids.append(card.definition_id)
	for card: CardInstance in second_hand:
		second_ids.append(card.definition_id)
	assert_array(first_ids).is_not_equal(second_ids)
