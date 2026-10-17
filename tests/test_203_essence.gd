# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## EssenceRules : paiement d'un coût en inclinant et en recyclant des Sources (ruleset 0.33,
## chapitre 203, décision 0003).

const TOTAL_SOURCES: int = 10  # 203.5.7
const MAX_ESSENCE_PER_UPRIGHT_SOURCE: int = 2  # 203.2.7
const SOURCES_IN_PLAY: int = 2  # 204.1.12, ici 1 redressée et 1 inclinée
const FONTE_SOURCES: int = 3
const OTHER_FONTE_SOURCES: int = 5
const CARD: StringName = &"CARD_TEST"
const CARDS_PER_DECK: int = 6

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const REASON := IntentRejected.RejectReason

var _builder: DuelStateBuilder
var _events: Array[DuelEvent]


func before_test() -> void:
	_builder = DuelStateBuilder.new()
	_events = []


func test_203_2_1_incline_upright_sources_pays_cost() -> void:
	var state := _with_sources(3, 0, 7)
	var payment := EssencePayment.new(2, 0)
	assert_int(EssenceRules.validate_payment(state, A, payment, 2)).is_equal(REASON.NONE)
	EssenceRules.apply_payment(state, A, payment, _events)
	assert_array(EventLog.describe(_events)).contains_exactly(
		EventLog.repeat("SourceInclined:A", 2)
	)
	var player := state.get_player(A)
	assert_int(player.sources_upright).is_equal(1)
	assert_int(player.sources_tilted).is_equal(2)
	assert_int(player.sources_in_fonte).is_equal(0)


func test_203_2_1_not_enough_upright_sources_rejected() -> void:
	var state := _with_sources(1, 3, 6)
	_assert_rejected(state, EssencePayment.new(2, 0), 2, REASON.NOT_ENOUGH_UPRIGHT_SOURCES)


func test_203_2_2_recycle_tilted_sources_pays_cost() -> void:
	var state := _with_sources(0, 3, 7)
	var payment := EssencePayment.new(0, 2)
	assert_int(EssenceRules.validate_payment(state, A, payment, 2)).is_equal(REASON.NONE)
	EssenceRules.apply_payment(state, A, payment, _events)
	assert_array(EventLog.describe(_events)).contains_exactly(
		EventLog.repeat("SourceRecycled:A", 2)
	)
	assert_int(state.get_player(A).sources_tilted).is_equal(1)


func test_203_2_2_not_enough_tilted_sources_rejected() -> void:
	var state := _with_sources(0, 1, 9)
	_assert_rejected(state, EssencePayment.new(0, 2), 2, REASON.NOT_ENOUGH_TILTED_SOURCES)


func test_203_2_3_recycled_source_leaves_play() -> void:
	var state := _with_sources(1, 2, 7)
	EssenceRules.apply_payment(state, A, EssencePayment.new(0, 2), _events)
	var player := state.get_player(A)
	assert_int(player.sources_upright + player.sources_tilted).is_equal(1)


func test_203_5_3_recycled_source_joins_fonte() -> void:
	_builder.with_sources_in_fonte(A, 1)
	var state := _with_sources(0, 3, 6)
	EssenceRules.apply_payment(state, A, EssencePayment.new(0, 2), _events)
	assert_int(state.get_player(A).sources_in_fonte).is_equal(3)


func test_203_2_6_source_inclined_by_payment_is_recycled_in_same_payment() -> void:
	var state := _with_sources(2, 0, 8)
	var payment := EssencePayment.new(2, 2)
	assert_int(EssenceRules.validate_payment(state, A, payment, 4)).is_equal(REASON.NONE)
	EssenceRules.apply_payment(state, A, payment, _events)
	var expected := EventLog.repeat("SourceInclined:A", 2)
	expected.append_array(EventLog.repeat("SourceRecycled:A", 2))
	assert_array(EventLog.describe(_events)).contains_exactly(expected)
	var player := state.get_player(A)
	assert_int(player.sources_upright).is_equal(0)
	assert_int(player.sources_tilted).is_equal(0)
	assert_int(player.sources_in_fonte).is_equal(2)


func test_203_2_6_mixes_already_tilted_and_newly_inclined_sources() -> void:
	var state := _with_sources(1, 2, 7)
	var payment := EssencePayment.new(1, 3)
	assert_int(EssenceRules.validate_payment(state, A, payment, 4)).is_equal(REASON.NONE)
	EssenceRules.apply_payment(state, A, payment, _events)
	assert_int(state.get_player(A).sources_in_fonte).is_equal(3)


func test_203_2_7_upright_source_produces_at_most_two_essence() -> void:
	var upright_count := 2
	var state := _with_sources(upright_count, 0, 8)
	var most_essence := upright_count * MAX_ESSENCE_PER_UPRIGHT_SOURCE
	var too_much := EssencePayment.new(upright_count, upright_count + 1)
	_assert_rejected(state, too_much, most_essence + 1, REASON.NOT_ENOUGH_TILTED_SOURCES)


func test_203_2_5_player_pays_during_opponent_turn() -> void:
	_builder.with_active_player(A).with_priority_player(B)
	var state := _builder.build()
	var payment := EssencePayment.new(1, 0)
	assert_int(EssenceRules.validate_payment(state, B, payment, 1)).is_equal(REASON.NONE)
	EssenceRules.apply_payment(state, B, payment, _events)
	assert_array(EventLog.describe(_events)).contains_exactly(["SourceInclined:B"])


func test_203_3_1_payment_must_produce_exactly_the_cost() -> void:
	var state := _with_sources(3, 3, 4)
	_assert_rejected(state, EssencePayment.new(1, 0), 2, REASON.PAYMENT_DOES_NOT_MATCH_COST)
	_assert_rejected(state, EssencePayment.new(2, 1), 2, REASON.PAYMENT_DOES_NOT_MATCH_COST)


func test_negative_payment_rejected() -> void:
	var state := _with_sources(3, 0, 7)
	_assert_rejected(state, EssencePayment.new(3, -1), 2, REASON.NEGATIVE_PAYMENT)


func test_zero_cost_paid_with_empty_payment() -> void:
	var state := _with_sources(0, 0, 10)
	var payment := EssencePayment.new()
	assert_int(EssenceRules.validate_payment(state, A, payment, 0)).is_equal(REASON.NONE)
	EssenceRules.apply_payment(state, A, payment, _events)
	assert_array(_events).is_empty()


func test_203_4_2_recycles_unlimited_during_a_turn() -> void:
	_builder.with_recycled_this_turn(A, 5)
	var state := _with_sources(0, 4, 1)
	var payment := EssencePayment.new(0, 4)
	assert_int(EssenceRules.validate_payment(state, A, payment, 4)).is_equal(REASON.NONE)
	EssenceRules.apply_payment(state, A, payment, _events)
	assert_int(state.get_player(A).sources_recycled_this_turn).is_equal(9)


func test_203_4_2_configured_recycle_limit_rejects_extra_recycle() -> void:
	var config := DuelConfig.new()
	config.max_recycles_per_turn = 1
	_builder = DuelStateBuilder.new(config)
	_builder.with_recycled_this_turn(A, 1)
	var state := _with_sources(0, 2, 8)
	_assert_rejected(state, EssencePayment.new(0, 1), 1, REASON.RECYCLE_LIMIT_REACHED)


func test_203_5_7_payment_keeps_total_sources() -> void:
	var state := _with_sources(3, 2, 5)
	EssenceRules.apply_payment(state, A, EssencePayment.new(3, 4), _events)
	assert_int(state.get_player(A).total_sources()).is_equal(TOTAL_SOURCES)


func test_payment_leaves_opponent_sources_unchanged() -> void:
	var state := _builder.build()
	var opponent_before := state.get_player(B).clone()
	EssenceRules.apply_payment(state, A, EssencePayment.new(1, 1), _events)
	var defects := DeepCompare.find_clone_defects(opponent_before, state.get_player(B))
	assert_array(defects).is_empty()


func test_203_1_3_essence_is_not_kept_beyond_the_cost() -> void:
	var state := _with_sources(2, 0, 8)
	_assert_rejected(state, EssencePayment.new(1, 1), 1, REASON.PAYMENT_DOES_NOT_MATCH_COST)
	_assert_rejected(state, EssencePayment.new(2, 0), 1, REASON.PAYMENT_DOES_NOT_MATCH_COST)


func test_203_2_4_no_essence_is_produced_without_a_cost_to_pay() -> void:
	var state := _with_sources(2, 2, 6)
	_assert_rejected(state, EssencePayment.new(1, 0), 0, REASON.PAYMENT_DOES_NOT_MATCH_COST)
	_assert_rejected(state, EssencePayment.new(0, 1), 0, REASON.PAYMENT_DOES_NOT_MATCH_COST)


func test_203_5_1_each_player_has_his_own_reserve() -> void:
	_builder.with_sources_in_reserve(A, 3).with_sources_in_reserve(B, 5)
	var engine := _start_engine()
	engine.submit(EndTurn.new(A))
	assert_int(engine.get_state().get_player(A).sources_in_reserve).is_equal(3)
	assert_int(engine.get_state().get_player(B).sources_in_reserve).is_equal(4)


func test_203_5_2_each_player_has_his_own_fonte() -> void:
	_builder.with_sources_in_fonte(A, FONTE_SOURCES).with_sources_in_fonte(B, OTHER_FONTE_SOURCES)
	_builder.with_sources_in_play(B, 0, 1)
	var state := _builder.build()
	EssenceRules.apply_payment(state, B, EssencePayment.new(0, 1), _events)
	assert_int(state.get_player(A).sources_in_fonte).is_equal(FONTE_SOURCES)
	assert_int(state.get_player(B).sources_in_fonte).is_equal(OTHER_FONTE_SOURCES + 1)


func test_203_5_4_source_in_fonte_never_returns_to_play() -> void:
	_builder.with_sources_in_fonte(B, FONTE_SOURCES).with_sources_in_reserve(B, 0)
	_builder.with_sources_in_play(B, 1, 1)
	var engine := _start_engine()
	for side: DuelState.PlayerSide in [A, B, A, B]:
		engine.submit(EndTurn.new(side))
	var player := engine.get_state().get_player(B)
	assert_int(player.sources_in_fonte).is_equal(FONTE_SOURCES)
	assert_int(player.sources_in_reserve).is_equal(0)
	assert_int(player.sources_upright + player.sources_tilted).is_equal(2)


func test_203_5_6_fonte_changes_neither_the_game_state_nor_the_rules() -> void:
	var without_fonte := _play_two_turns_with_fonte(0)
	var with_fonte := _play_two_turns_with_fonte(OTHER_FONTE_SOURCES)
	assert_array(with_fonte).is_equal(without_fonte)


func _play_two_turns_with_fonte(fonte_sources: int) -> Array[String]:
	var builder := DuelStateBuilder.new()
	var reserve_before := TOTAL_SOURCES - SOURCES_IN_PLAY - fonte_sources
	builder.with_sources_in_fonte(B, fonte_sources).with_sources_in_play(B, 1, 1)
	builder.with_sources_in_reserve(B, reserve_before)
	for index: int in CARDS_PER_DECK:
		builder.add_to_deck(A, CARD)
		builder.add_to_deck(B, CARD)
	var engine := DuelEngine.new(SetupSamples.catalog())
	engine.start_from_state(builder.build())
	var described: Array[String] = []
	for side: DuelState.PlayerSide in [A, B]:
		described.append_array(EventLog.describe(engine.submit(EndTurn.new(side))))
	var player := engine.get_state().get_player(B)
	described.append(
		(
			"B : %d redressées, %d inclinées, %d prises en réserve, %d en main"
			% [
				player.sources_upright,
				player.sources_tilted,
				reserve_before - player.sources_in_reserve,
				player.hand.size()
			]
		)
	)
	return described


func _start_engine() -> DuelEngine:
	var engine := DuelEngine.new(SetupSamples.catalog())
	engine.start_from_state(_builder.build())
	return engine


func _with_sources(upright: int, tilted: int, in_reserve: int) -> DuelState:
	_builder.with_sources_in_play(A, upright, tilted).with_sources_in_reserve(A, in_reserve)
	return _builder.build()


func _assert_rejected(
	state: DuelState, payment: EssencePayment, cost: int, expected: IntentRejected.RejectReason
) -> void:
	var snapshot := state.clone()
	assert_int(EssenceRules.validate_payment(state, A, payment, cost)).is_equal(expected)
	assert_array(DeepCompare.find_clone_defects(snapshot, state)).is_empty()
