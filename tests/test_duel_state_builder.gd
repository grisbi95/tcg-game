extends GdUnitTestSuite
## DuelStateBuilder et EventLog : outils de tests/support (décisions 0001 et 0008).

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B


func test_204_1_1_default_state_has_both_heroes_on_their_start_cells() -> void:
	var state := DuelStateBuilder.new().build()
	assert_str(BoardGeometry.cell_name(state.find_hero(A).cell)).is_equal("C1")
	assert_str(BoardGeometry.cell_name(state.find_hero(B).cell)).is_equal("C5")
	assert_int(state.find_hero(A).health).is_equal(DuelStateBuilder.DEFAULT_HERO_HEALTH)
	assert_bool(state.find_hero(A).is_token()).is_false()


func test_204_1_2_default_state_takes_sources_and_times_from_config() -> void:
	var config := DuelConfig.new()
	var player := DuelStateBuilder.new(config).build().get_player(B)
	assert_int(player.sources_upright).is_equal(config.starting_sources)
	assert_int(player.sources_in_reserve).is_equal(config.setup_sources_in_reserve)
	assert_int(player.total_sources()).is_equal(config.total_sources_per_player)
	assert_int(player.turn_time_remaining_msec).is_equal(config.turn_time_msec)
	assert_int(player.response_time_remaining_msec).is_equal(config.response_time_msec)


func test_201_0_1_place_piece_refuses_an_occupied_cell() -> void:
	var builder := DuelStateBuilder.new()
	var hero_cell := BoardGeometry.hero_start_cell(A)
	var place_on_hero := func() -> void:
		builder.place_piece(A, Piece.PieceKind.UNIT, hero_cell, &"U")
	await assert_error(place_on_hero).is_push_error(
		"DuelStateBuilder : case %s hors plateau ou occupée (201.0.1)" % hero_cell
	)
	assert_array(builder.build().pieces).has_size(DuelState.PLAYER_COUNT)


func test_202_4_2_token_has_no_card() -> void:
	var builder := DuelStateBuilder.new()
	var token_id := builder.place_token(A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B2"), 3)
	var token := builder.build().find_piece(token_id)
	assert_bool(token.is_token()).is_true()
	assert_int(token.token_force).is_equal(3)


func test_builder_allocates_distinct_ids_from_state_counters() -> void:
	var builder := DuelStateBuilder.new()
	var first := builder.add_to_hand(A, &"U")
	var second := builder.add_to_hand(B, &"U")
	assert_int(second).is_not_equal(first)
	assert_int(builder.build().next_card_instance_id).is_greater(second)


func test_event_log_describes_events_with_their_player() -> void:
	var events: Array[DuelEvent] = [DuelEvent.new(), PlayerEvent.new(B)]
	assert_array(EventLog.describe(events)).contains_exactly(["DuelEvent", "PlayerEvent:B"])


func test_event_log_reports_a_single_rejection_reason() -> void:
	var rejected: Array[DuelEvent] = [
		IntentRejected.new(DuelIntent.new(A), IntentRejected.RejectReason.WRONG_PHASE)
	]
	assert_int(EventLog.rejection_reason(rejected)).is_equal(
		IntentRejected.RejectReason.WRONG_PHASE
	)
	var not_rejected: Array[DuelEvent] = [DuelEvent.new()]
	assert_int(EventLog.rejection_reason(not_rejected)).is_equal(EventLog.NOT_A_SINGLE_REJECTION)


func test_reject_reason_none_is_the_first_value() -> void:
	assert_int(IntentRejected.RejectReason.NONE).is_equal(0)
	assert_int(IntentRejected.new().reason).is_equal(IntentRejected.RejectReason.NONE)
