# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## Défaite par inactivité (209.2.10, 201.1.3d, 206.4.6c).
## Ruleset 0.40, décisions 0018 et 0045, décisions de design 0205 et 0206 du ruleset.
##
## Q-109 : seules comptent les annonces faites pendant ses propres tours.

const TURN_MSEC: int = 90_000  # 209.4.3
const RESPONSE_MSEC: int = 30_000  # 209.4.6
const IDLE_LIMIT: int = 3  # 209.2.10
const STEP_MSEC: int = 1_000
const SPELL: StringName = TimeScenarios.SPELL

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const REASON := IntentRejected.RejectReason
const RESULT := DuelState.DuelResult
const DECISION := PendingDecision.DecisionKind
const PHASE := DuelState.DuelPhase
const KIND := DuelState.ClockKind

var _builder: DuelStateBuilder
var _engine: DuelEngine


func before_test() -> void:
	var catalog := TimeScenarios.catalog()
	_builder = TimeScenarios.builder(catalog)
	_engine = DuelEngine.new(catalog)


# --- 209.2.10, 201.1.3d, 206.4.6c : inactivité ---


func test_209_2_10_third_idle_turn_loses_the_game() -> void:
	_builder.with_idle_turns(A, IDLE_LIMIT - 1).with_turn_time_remaining(A, STEP_MSEC)
	_engine.start_from_state(_builder.build())
	var events := _engine.advance_clock(STEP_MSEC)
	assert_array(EventLog.describe(events)).contains_exactly(
		["TimeExpired:A", "TurnEnded:A", "IdleDefeat:A", "DuelEnded"]
	)
	var ended := events[3] as DuelEnded
	assert_int(ended.reason).is_equal(DuelState.EndReason.IDLE_TURNS)
	assert_int(ended.result).is_equal(RESULT.PLAYER_B_WINS)
	assert_int(EventLog.rejection_reason(_engine.submit(EndTurn.new(A)))).is_equal(
		REASON.DUEL_ENDED
	)
	assert_array(_engine.clock_owners()).is_empty()


func test_209_2_10_idle_turns_are_counted_one_by_one() -> void:
	_engine.start_from_state(_builder.with_turn_time_remaining(A, STEP_MSEC).build())
	_engine.advance_clock(STEP_MSEC)
	assert_int(_engine.get_state().get_player(A).idle_turns).is_equal(1)
	assert_int(_engine.get_state().result).is_equal(RESULT.NONE)


func test_209_2_10_the_idle_limit_comes_from_the_configuration() -> void:
	var config := DuelConfig.new()
	config.idle_turns_limit = 1
	var catalog := _builder.build().catalog
	_builder = DuelStateBuilder.new(config, catalog)
	_engine.start_from_state(_builder.with_turn_time_remaining(A, STEP_MSEC).build())
	_engine.advance_clock(STEP_MSEC)
	assert_int(_engine.get_state().result).is_equal(RESULT.PLAYER_B_WINS)


func test_209_2_10_any_announcement_of_the_turn_prevents_idleness() -> void:
	var card_id := _builder.add_to_hand(A, SPELL)
	_builder.with_idle_turns(A, IDLE_LIMIT - 1)
	_engine.start_from_state(_builder.build())
	_engine.submit(CastSpell.new(A, card_id, EssencePayment.new(1)))
	var state := _engine.get_state()
	assert_bool(state.get_player(A).announced_this_turn).is_true()
	_engine.submit(PassPriority.new(B))
	state.get_player(A).turn_time_remaining_msec = STEP_MSEC
	_engine.advance_clock(STEP_MSEC)
	assert_int(state.get_player(A).idle_turns).is_equal(0)
	assert_int(state.result).is_equal(RESULT.NONE)


func test_209_2_10_a_turn_ended_by_hand_breaks_the_idle_streak() -> void:
	_engine.start_from_state(_builder.with_idle_turns(A, IDLE_LIMIT - 1).build())
	_engine.submit(EndTurn.new(A))
	assert_int(_engine.get_state().get_player(A).idle_turns).is_equal(0)


func test_209_2_10_a_triggered_effect_is_not_an_announcement() -> void:
	_builder.place_piece(
		A, Piece.PieceKind.BUILDING, DuelStateBuilder.cell("B2"), TriggerSamples.BEACON
	)
	_builder.place_piece(
		A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("D1"), TriggerSamples.SOLDIER
	)
	_engine.start_from_state(
		_builder.with_idle_turns(A, 1).with_turn_time_remaining(A, STEP_MSEC).build()
	)
	_engine.advance_clock(STEP_MSEC)
	assert_int(_engine.get_state().get_player(A).idle_turns).is_equal(2)


func test_209_2_10_only_announcements_made_during_the_own_turn_count() -> void:
	TimeScenarios.push_spell(_builder, A)
	var card_id := _builder.add_to_hand(B, SPELL)
	_builder.with_priority_player(B).with_idle_turns(B, 2)
	_engine.start_from_state(_builder.build())
	_engine.submit(CastSpell.new(B, card_id, EssencePayment.new(1)))
	assert_int(_engine.get_state().get_player(B).idle_turns).is_equal(2)
	assert_bool(_engine.get_state().get_player(B).announced_this_turn).is_false()


func test_209_2_10_the_announcement_flag_is_renewed_each_turn() -> void:
	var card_id := _builder.add_to_hand(A, SPELL)
	_engine.start_from_state(_builder.build())
	_engine.submit(CastSpell.new(A, card_id, EssencePayment.new(1)))
	_engine.submit(PassPriority.new(B))
	_engine.submit(EndTurn.new(A))
	assert_bool(_engine.get_state().get_player(A).announced_this_turn).is_false()


func test_201_1_3d_the_opponent_of_an_idle_player_wins() -> void:
	_builder.with_idle_turns(B, IDLE_LIMIT - 1).with_active_player(B).with_priority_player(B)
	_engine.start_from_state(_builder.with_turn_time_remaining(B, STEP_MSEC).build())
	_engine.advance_clock(STEP_MSEC)
	assert_int(_engine.get_state().result).is_equal(RESULT.PLAYER_A_WINS)


func test_206_4_6c_a_player_can_lose_by_inactivity() -> void:
	_builder.with_idle_turns(A, IDLE_LIMIT - 1).with_turn_time_remaining(A, STEP_MSEC)
	_engine.start_from_state(_builder.build())
	_engine.advance_clock(STEP_MSEC)
	assert_bool(_engine.get_state().is_ended()).is_true()
	assert_int(_engine.get_state().result).is_not_equal(RESULT.PLAYER_A_WINS)
