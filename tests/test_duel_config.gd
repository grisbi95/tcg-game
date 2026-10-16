# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## DuelConfig : une valeur par règle PROVISOIRE (ruleset 0.28, décisions 0001 et 0007).
## Les valeurs du ruleset sont recopiées en constantes pour que le test contrôle la
## configuration.

const HAND_LIMIT: int = 7  # 201.3.4
const DECK_SIZE: int = 30  # 201.6.1
const MAX_COPIES: int = 3  # 201.6.2
const TOTAL_SOURCES: int = 10  # 203.5.7
const STARTING_SOURCES: int = 2  # 204.1.2
const SETUP_SOURCES_IN_PLAY: int = 2  # 204.1.12
const SETUP_SOURCES_IN_RESERVE: int = 8  # 204.1.13
const OPENING_HAND_SIZE: int = 5  # 204.1.15
const SOURCES_PER_TURN: int = 1  # 204.3.1
const CARDS_PER_TURN: int = 2  # 204.3.6
const CLOCK_MSEC: int = 600_000  # 209.4.3 : 10 minutes
const CLOCK_BONUS_MSEC: int = 0  # 209.4.3a
const STARTING_FATIGUE: int = 0  # 209.5.1
const FATIGUE_INCREASE: int = 1  # 209.5.2
const FATIGUE_DAMAGE_PER_POINT: int = 1  # 209.5.3

var _config: DuelConfig


func before_test() -> void:
	_config = DuelConfig.new()


func test_201_3_4_hand_limit() -> void:
	assert_int(_config.max_hand_size).is_equal(HAND_LIMIT)


func test_201_6_1_deck_size() -> void:
	assert_int(_config.deck_size).is_equal(DECK_SIZE)


func test_201_6_2_max_copies_per_card() -> void:
	assert_int(_config.max_copies_per_card).is_equal(MAX_COPIES)


func test_203_4_2_recycling_is_unlimited_per_turn() -> void:
	assert_int(_config.max_recycles_per_turn).is_equal(DuelConfig.UNLIMITED_RECYCLES)


func test_203_5_7_total_sources_per_player() -> void:
	assert_int(_config.total_sources_per_player).is_equal(TOTAL_SOURCES)


func test_204_1_2_starting_sources() -> void:
	assert_int(_config.starting_sources).is_equal(STARTING_SOURCES)


func test_204_1_12_setup_sources_in_play() -> void:
	assert_int(_config.setup_sources_in_play).is_equal(SETUP_SOURCES_IN_PLAY)


func test_204_1_13_setup_sources_in_reserve() -> void:
	assert_int(_config.setup_sources_in_reserve).is_equal(SETUP_SOURCES_IN_RESERVE)


func test_204_1_15_opening_hand_size() -> void:
	assert_int(_config.opening_hand_size).is_equal(OPENING_HAND_SIZE)


func test_204_3_1_sources_received_per_turn() -> void:
	assert_int(_config.sources_received_per_turn).is_equal(SOURCES_PER_TURN)


func test_204_3_4_first_player_receives_no_source_on_first_turn() -> void:
	assert_bool(_config.first_player_receives_source_on_first_turn).is_false()


func test_204_3_6_cards_drawn_per_turn() -> void:
	assert_int(_config.cards_drawn_per_turn).is_equal(CARDS_PER_TURN)


func test_206_3_6_tie_destroys_both() -> void:
	assert_bool(_config.tie_destroys_both).is_true()


func test_206_3_6_tie_without_destruction_is_undefined() -> void:
	_config.tie_destroys_both = false
	assert_bool(CatalogSamples.mentions(_config.find_errors(), "206.3.6")).is_true()


func test_209_4_3_clock_duration() -> void:
	assert_int(_config.clock_duration_msec).is_equal(CLOCK_MSEC)


func test_209_4_3a_clock_gains_no_time() -> void:
	assert_int(_config.clock_bonus_msec).is_equal(CLOCK_BONUS_MSEC)


func test_209_5_1_fatigue_starts_at_zero() -> void:
	assert_int(_config.starting_fatigue).is_equal(STARTING_FATIGUE)


func test_209_5_2_fatigue_increases_by_one() -> void:
	assert_int(_config.fatigue_increase).is_equal(FATIGUE_INCREASE)


func test_209_5_3_fatigue_damage_equals_the_counter() -> void:
	assert_int(_config.fatigue_damage_per_counter_point).is_equal(FATIGUE_DAMAGE_PER_POINT)


func test_203_5_7_default_values_are_consistent() -> void:
	assert_array(_config.find_errors()).is_empty()


func test_203_5_7_setup_sources_must_add_up_to_the_total() -> void:
	_config.setup_sources_in_reserve = SETUP_SOURCES_IN_RESERVE - 1
	assert_array(_config.find_errors()).has_size(1)


func test_204_1_12_setup_sources_must_match_starting_sources() -> void:
	_config.starting_sources = STARTING_SOURCES + 1
	assert_array(_config.find_errors()).has_size(1)
