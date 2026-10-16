extends GdUnitTestSuite
## Victoire, partie nulle et abandon (ruleset 0.30, sections 201.1, 209.2 et 209.3).

const CARD: StringName = &"CARD_TEST"

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const REASON := IntentRejected.RejectReason

var _builder: DuelStateBuilder
var _engine: DuelEngine


func before_test() -> void:
	_builder = DuelStateBuilder.new()
	_engine = DuelEngine.new(SetupSamples.catalog())


func test_209_2_2_hero_at_zero_ends_duel_at_once() -> void:
	_builder.with_hero_health(B, 1)
	var events := _end_turn_of_a()
	var labels := EventLog.describe(events)
	assert_array(labels.slice(labels.size() - 3)).contains_exactly(
		["FatigueIncreased:B", "HeroLostHealth:B", "DuelEnded"]
	)
	var state := _engine.get_state()
	assert_int(state.phase).is_equal(DuelState.DuelPhase.ENDED)
	assert_int(state.get_player(B).fatigue_counter).is_equal(1)


func test_201_1_2_player_wins_when_opposing_hero_reaches_zero() -> void:
	_builder.with_hero_health(B, 1)
	var events := _end_turn_of_a()
	assert_int((events.back() as DuelEnded).result).is_equal(DuelState.DuelResult.PLAYER_A_WINS)
	assert_int(_engine.get_state().result).is_equal(DuelState.DuelResult.PLAYER_A_WINS)


func test_209_2_1_hero_above_zero_leaves_duel_running() -> void:
	_builder.with_hero_health(B, 10)
	_end_turn_of_a()
	var state := _engine.get_state()
	assert_int(state.phase).is_equal(DuelState.DuelPhase.MAIN)
	assert_int(state.result).is_equal(DuelState.DuelResult.NONE)


func test_209_2_1_check_changes_nothing_while_both_heroes_stand() -> void:
	var state := _builder.build()
	var snapshot := state.clone()
	var events: Array[DuelEvent] = []
	assert_bool(StateCheckRules.check_victory(state, events)).is_false()
	assert_array(events).is_empty()
	assert_array(DeepCompare.find_clone_defects(snapshot, state)).is_empty()


func test_209_3_1_both_heroes_at_zero_is_a_draw() -> void:
	_builder.with_hero_health(A, 0).with_hero_health(B, 0)
	var state := _builder.build()
	var events: Array[DuelEvent] = []
	assert_bool(StateCheckRules.check_victory(state, events)).is_true()
	assert_int(state.result).is_equal(DuelState.DuelResult.DRAW)
	assert_int((events[0] as DuelEnded).result).is_equal(DuelState.DuelResult.DRAW)


func test_201_1_2a_draw_is_no_win() -> void:
	_builder.with_hero_health(A, 0).with_hero_health(B, 0)
	var state := _builder.build()
	var events: Array[DuelEvent] = []
	StateCheckRules.check_victory(state, events)
	assert_int(state.result).is_not_equal(DuelState.DuelResult.PLAYER_A_WINS)
	assert_int(state.result).is_not_equal(DuelState.DuelResult.PLAYER_B_WINS)


func test_209_2_2_turn_start_stops_when_duel_ends() -> void:
	_builder.with_hero_health(B, 1)
	var labels := EventLog.describe(_end_turn_of_a())
	assert_int(labels.count("FatigueIncreased:B")).is_equal(1)
	assert_int(labels.count("DuelEnded")).is_equal(1)
	assert_int(_engine.get_state().phase).is_equal(DuelState.DuelPhase.ENDED)


func test_209_2_5_player_concedes_during_opponent_turn() -> void:
	_engine.start_from_state(_builder.build())
	var events := _engine.submit(Concede.new(B))
	assert_array(EventLog.describe(events)).contains_exactly(["PlayerConceded:B", "DuelEnded"])


func test_209_2_5_player_concedes_during_mulligan() -> void:
	_engine.start_new_duel(SetupSamples.setup())
	var events := _engine.submit(Concede.new(A))
	assert_array(EventLog.describe(events)).contains_exactly(["PlayerConceded:A", "DuelEnded"])
	assert_object(_engine.get_state().pending_decision).is_null()


func test_209_2_6_conceding_player_loses() -> void:
	_engine.start_from_state(_builder.build())
	_engine.submit(Concede.new(A))
	assert_int(_engine.get_state().result).is_equal(DuelState.DuelResult.PLAYER_B_WINS)


func test_201_1_3a_opponent_of_conceding_player_wins() -> void:
	_engine.start_from_state(_builder.build())
	var events := _engine.submit(Concede.new(B))
	assert_int((events.back() as DuelEnded).result).is_equal(DuelState.DuelResult.PLAYER_A_WINS)


func test_209_2_7_concede_ends_duel_and_leaves_stack_unresolved() -> void:
	var entry_id := _builder.push_spell(_builder.make_card_instance(A, CARD))
	_engine.start_from_state(_builder.build())
	_engine.submit(Concede.new(B))
	var state := _engine.get_state()
	assert_int(state.phase).is_equal(DuelState.DuelPhase.ENDED)
	assert_object(state.find_stack_entry(entry_id)).is_not_null()


func test_209_2_7_no_intent_after_duel_ended() -> void:
	_engine.start_from_state(_builder.build())
	_engine.submit(Concede.new(A))
	for intent: DuelIntent in [Concede.new(B), EndTurn.new(A)]:
		assert_array(DuelChecks.rejection_defects(_engine, intent, REASON.DUEL_ENDED)).is_empty()


func _end_turn_of_a() -> Array[DuelEvent]:
	_engine.start_from_state(_builder.build())
	return _engine.submit(EndTurn.new(A))
