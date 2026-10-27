extends GdUnitTestSuite
## DuelSeries : numéro de partie, decks et premier joueur choisis par l'hôte, préparation du duel
## (décisions 0036 et 0066 ; décision 0012 pour le DuelSetup).

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


func test_decision_0066_game_number_advances_and_choices_stay() -> void:
	var series := DuelSeries.new(_deck, _deck)
	series.set_first_player_choice(DuelSeries.FirstPlayerChoice.PLAYER_B)
	var numbers: Array[int] = []
	for game: int in GAME_COUNT:
		numbers.append(series.get_game_number())
		series.advance_to_next_game()
	assert_array(numbers).is_equal([1, 2, 3])
	assert_int(series.get_first_player_choice()).is_equal(DuelSeries.FirstPlayerChoice.PLAYER_B)
	assert_object(series.get_deck(A)).is_same(_deck)


func test_decision_0066_player_a_starts_by_default() -> void:
	var duel_setup := DuelSeries.new(_deck, _deck).make_setup(SEED)
	assert_bool(duel_setup.is_first_player_imposed).is_true()
	assert_int(duel_setup.imposed_first_player).is_equal(A)


func test_decision_0066_chosen_first_player_is_imposed() -> void:
	var series := DuelSeries.new(_deck, _deck)
	series.set_first_player_choice(DuelSeries.FirstPlayerChoice.PLAYER_B)
	var duel_setup := series.make_setup(SEED)
	assert_bool(duel_setup.is_first_player_imposed).is_true()
	assert_int(duel_setup.imposed_first_player).is_equal(B)


func test_decision_0066_drawn_first_player_is_left_to_the_engine() -> void:
	var series := DuelSeries.new(_deck, _deck)
	series.set_first_player_choice(DuelSeries.FirstPlayerChoice.DRAWN)
	var duel_setup := series.make_setup(SEED)
	assert_bool(duel_setup.is_first_player_imposed).is_false()
	var engine := DuelEngine.new(_catalog)
	engine.start_new_duel(duel_setup)
	assert_bool(engine.get_state().first_player_imposed).is_false()


func test_decision_0066_host_changes_the_deck_of_a_side() -> void:
	var other := DeckList.new()
	other.deck_id = &"autre"
	other.hero_id = &"autre_hero"
	other.copies = {&"recrue": 1}
	var series := DuelSeries.new(_deck, _deck)
	series.set_deck(B, other)
	assert_object(series.get_deck(B)).is_same(other)
	assert_array(series.make_setup(SEED).deck_b).is_equal([&"recrue"])


func test_decision_0036_setup_carries_decks_heroes_seed_and_imposed_first_player() -> void:
	var series := DuelSeries.new(_deck, _deck)
	series.set_first_player_choice(DuelSeries.FirstPlayerChoice.PLAYER_B)
	var duel_setup := series.make_setup(SEED)
	assert_array(duel_setup.deck_a).is_equal(_deck.card_ids())
	assert_array(duel_setup.deck_b).is_equal(_deck.card_ids())
	assert_str(String(duel_setup.hero_a)).is_equal(String(_deck.hero_id))
	assert_str(String(duel_setup.hero_b)).is_equal(String(_deck.hero_id))
	assert_int(duel_setup.rng_seed).is_equal(SEED)
	assert_bool(duel_setup.is_first_player_imposed).is_true()
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
		series.set_first_player_choice(game as DuelSeries.FirstPlayerChoice)
		var duel_setup := series.make_setup(SEED)
		assert_array(Array(duel_setup.find_errors(_catalog, DuelConfig.new()))).is_empty()
		var engine := DuelEngine.new(_catalog)
		var events := engine.start_new_duel(duel_setup)
		assert_array(EventLog.describe(events).slice(0, 2)).contains_exactly(
			["HeroPlaced:A", "HeroPlaced:B"]
		)
		var state := engine.get_state()
		var is_imposed := duel_setup.is_first_player_imposed
		assert_bool(state.first_player_imposed).is_equal(is_imposed)
		if is_imposed:
			assert_int(state.first_player).is_equal(duel_setup.imposed_first_player)


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
