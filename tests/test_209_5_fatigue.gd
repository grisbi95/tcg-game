extends GdUnitTestSuite
## Compteur de fatigue à la pioche du début du tour (ruleset 0.30, section 209.5).

const HAND_LIMIT: int = 7  # 201.3.4
const CARDS_PER_TURN: int = 2  # 204.3.6
const STARTING_FATIGUE: int = 0  # 209.5.1
const HERO_HEALTH: int = 15
const CARD: StringName = &"CARD_TEST"

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B

var _builder: DuelStateBuilder
var _engine: DuelEngine


func before_test() -> void:
	_builder = DuelStateBuilder.new()
	_builder.with_hero_health(B, HERO_HEALTH)
	_engine = DuelEngine.new(SetupSamples.catalog())


func test_209_5_1_fatigue_starts_at_zero() -> void:
	_engine.start_new_duel(SetupSamples.setup())
	for player: PlayerState in _engine.get_state().players:
		assert_int(player.fatigue_counter).is_equal(STARTING_FATIGUE)


func test_209_5_1_starting_fatigue_read_from_config() -> void:
	var config := DuelConfig.new()
	config.starting_fatigue = 1
	_engine = DuelEngine.new(SetupSamples.catalog(), config)
	_engine.start_new_duel(SetupSamples.setup())
	for player: PlayerState in _engine.get_state().players:
		assert_int(player.fatigue_counter).is_equal(1)


func test_209_2_4_fatigue_never_takes_health_below_zero() -> void:
	_builder.with_hero_health(B, 2).with_fatigue(B, 4)
	var events := _end_turn_of_a()
	assert_int(_engine.get_state().find_hero(B).health).is_equal(0)
	var losses: Array[int] = []
	for event: DuelEvent in events:
		if event is HeroLostHealth:
			losses.append((event as HeroLostHealth).amount)
	assert_array(losses).contains_exactly([2])


func test_209_5_2_each_draw_from_empty_deck_increases_fatigue() -> void:
	var events := _end_turn_of_a()
	var expected: Array[String] = []
	for draw: int in CARDS_PER_TURN:
		expected.append_array(["FatigueIncreased:B", "HeroLostHealth:B"])
	assert_array(EventLog.describe(events).slice(3)).contains_exactly(expected)
	assert_int(_engine.get_state().get_player(B).fatigue_counter).is_equal(CARDS_PER_TURN)


func test_209_5_3_hero_loses_new_counter_value() -> void:
	_builder.with_fatigue(B, 2)
	var events := _end_turn_of_a()
	assert_int((events[3] as FatigueIncreased).fatigue_counter).is_equal(3)
	assert_int((events[4] as HeroLostHealth).amount).is_equal(3)
	assert_int((events[6] as HeroLostHealth).amount).is_equal(4)
	assert_int(_engine.get_state().find_hero(B).health).is_equal(HERO_HEALTH - 3 - 4)


func test_209_5_2_last_card_then_fatigue() -> void:
	_builder.add_to_deck(B, CARD)
	var labels := EventLog.describe(_end_turn_of_a()).slice(3)
	assert_array(labels).contains_exactly(["CardDrawn:B", "FatigueIncreased:B", "HeroLostHealth:B"])


func test_209_5_2a_full_hand_does_not_prevent_fatigue() -> void:
	_fill_hand(B)
	_end_turn_of_a()
	assert_int(_engine.get_state().get_player(B).fatigue_counter).is_equal(CARDS_PER_TURN)


func test_209_5_4_card_kept_out_by_hand_limit_causes_no_fatigue() -> void:
	_fill_hand(B)
	for draw: int in CARDS_PER_TURN:
		_builder.add_to_deck(B, CARD)
	var labels := EventLog.describe(_end_turn_of_a()).slice(3)
	assert_array(labels).contains_exactly(
		EventLog.repeat("DrawBlockedByHandLimit:B", CARDS_PER_TURN)
	)
	var player := _engine.get_state().get_player(B)
	assert_int(player.fatigue_counter).is_equal(STARTING_FATIGUE)
	assert_int(player.deck.size()).is_equal(CARDS_PER_TURN)


func test_209_5_4a_hand_limit_rule_needs_a_card_in_deck() -> void:
	_fill_hand(B)
	var labels := EventLog.describe(_end_turn_of_a())
	assert_array(labels).not_contains(["DrawBlockedByHandLimit:B"])
	assert_array(labels).contains(["FatigueIncreased:B"])


func _end_turn_of_a() -> Array[DuelEvent]:
	_engine.start_from_state(_builder.build())
	return _engine.submit(EndTurn.new(A))


func _fill_hand(side: DuelState.PlayerSide) -> void:
	for index: int in HAND_LIMIT:
		_builder.add_to_hand(side, CARD)
