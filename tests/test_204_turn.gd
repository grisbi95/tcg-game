extends GdUnitTestSuite
## Début, phase principale et fin du tour par DuelEngine (ruleset 0.30, sections 204.3 à 204.5).

const CARDS_PER_TURN: int = 2  # 204.3.6
const SOURCES_IN_PLAY: int = 2  # 204.1.12
const SOURCES_IN_RESERVE: int = 8  # 204.1.13
const OPENING_HAND_SIZE: int = 5  # 204.1.15
const CARD: StringName = &"CARD_TEST"

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const REASON := IntentRejected.RejectReason

var _builder: DuelStateBuilder
var _engine: DuelEngine


func before_test() -> void:
	_builder = DuelStateBuilder.new()
	_engine = DuelEngine.new(SetupSamples.catalog())
	for side: DuelState.PlayerSide in [A, B]:
		for index: int in CARDS_PER_TURN:
			_builder.add_to_deck(side, CARD)


func test_204_4_7_active_player_ends_turn() -> void:
	var events := _end_turn_of_a()
	var expected: Array[String] = ["TurnEnded:A", "TurnStarted:B", "SourceReceived:B"]
	expected.append_array(EventLog.repeat("CardDrawn:B", CARDS_PER_TURN))
	assert_array(EventLog.describe(events)).contains_exactly(expected)


func test_204_5_2_opponent_starts_next_turn() -> void:
	var events := _end_turn_of_a()
	var state := _engine.get_state()
	assert_int(state.active_player).is_equal(B)
	assert_int(state.priority_player).is_equal(B)
	assert_int(state.turn_number).is_equal(TurnRules.FIRST_TURN + 1)
	assert_int((events[1] as TurnStarted).turn_number).is_equal(TurnRules.FIRST_TURN + 1)


func test_204_4_1_main_phase_follows_turn_start() -> void:
	_end_turn_of_a()
	assert_int(_engine.get_state().phase).is_equal(DuelState.DuelPhase.MAIN)


func test_204_3_2_turn_start_untaps_sources() -> void:
	_builder.with_sources_in_play(B, 1, 3)
	var events := _end_turn_of_a()
	var untapped := events[2] as SourcesUntapped
	assert_int(untapped.count).is_equal(3)
	var player := _engine.get_state().get_player(B)
	assert_int(player.sources_tilted).is_equal(0)
	assert_int(player.sources_upright).is_equal(1 + 3 + 1)


func test_204_3_1_player_receives_one_source() -> void:
	_end_turn_of_a()
	var player := _engine.get_state().get_player(B)
	assert_int(player.sources_upright).is_equal(SOURCES_IN_PLAY + 1)


func test_204_3_3_received_source_arrives_upright() -> void:
	_builder.with_sources_in_play(B, 0, 0)
	_end_turn_of_a()
	var player := _engine.get_state().get_player(B)
	assert_int(player.sources_upright).is_equal(1)
	assert_int(player.sources_tilted).is_equal(0)


func test_204_3_5_received_source_comes_from_reserve() -> void:
	_end_turn_of_a()
	assert_int(_engine.get_state().get_player(B).sources_in_reserve).is_equal(
		SOURCES_IN_RESERVE - 1
	)


func test_200_4_1_empty_reserve_gives_no_source() -> void:
	_builder.with_sources_in_reserve(B, 0)
	var labels := EventLog.describe(_end_turn_of_a())
	assert_array(labels).not_contains(["SourceReceived:B"])
	assert_int(_engine.get_state().get_player(B).sources_upright).is_equal(SOURCES_IN_PLAY)


func test_204_3_4_first_player_receives_no_source_on_first_turn() -> void:
	_start_full_duel(A)
	var player := _engine.get_state().get_player(A)
	assert_int(player.sources_upright).is_equal(SOURCES_IN_PLAY)
	assert_int(player.sources_in_reserve).is_equal(SOURCES_IN_RESERVE)


func test_204_3_4_second_player_receives_source_on_first_turn() -> void:
	_start_full_duel(A)
	_engine.submit(EndTurn.new(A))
	assert_int(_engine.get_state().get_player(B).sources_upright).is_equal(SOURCES_IN_PLAY + 1)


func test_204_3_6_player_draws_two_cards() -> void:
	_end_turn_of_a()
	var player := _engine.get_state().get_player(B)
	assert_int(player.hand.size()).is_equal(CARDS_PER_TURN)
	assert_array(player.deck).is_empty()


func test_204_3_7_first_player_draws_on_first_turn() -> void:
	_start_full_duel(B)
	var hand_size := _engine.get_state().get_player(B).hand.size()
	assert_int(hand_size).is_equal(OPENING_HAND_SIZE + CARDS_PER_TURN)


func test_204_3_8_turn_start_steps_in_order() -> void:
	_builder.with_sources_in_play(B, 0, 2)
	var expected: Array[String] = ["TurnStarted:B", "SourcesUntapped:B", "SourceReceived:B"]
	expected.append_array(EventLog.repeat("CardDrawn:B", CARDS_PER_TURN))
	assert_array(EventLog.describe(_end_turn_of_a()).slice(1)).contains_exactly(expected)


func test_turn_start_resets_turn_counters_of_both_players() -> void:
	for side: DuelState.PlayerSide in [A, B]:
		_builder.with_recycled_this_turn(side, 2)
		_builder.with_hero_power_used(side)
		_builder.with_normal_action_used(side)
	_end_turn_of_a()
	for player: PlayerState in _engine.get_state().players:
		assert_int(player.sources_recycled_this_turn).is_equal(0)
		assert_bool(player.hero_power_used_this_turn).is_false()
		assert_bool(player.normal_action_used_this_turn).is_false()


func test_204_5_7_until_end_of_turn_effects_end() -> void:
	var piece_id := _builder.place_piece(A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B2"), CARD)
	var ending_id := _builder.add_active_effect(
		_make_effect(piece_id, ActiveEffect.EffectDuration.UNTIL_END_OF_TURN)
	)
	var lasting_id := _builder.add_active_effect(
		_make_effect(piece_id, ActiveEffect.EffectDuration.WHILE_PIECE_IN_PLAY)
	)
	var events := _end_turn_of_a()
	var ended := events[1] as ActiveEffectEnded
	assert_int(ended.effect_id).is_equal(ending_id)
	var effects := _engine.get_state().active_effects
	assert_int(effects.size()).is_equal(1)
	assert_int(effects[0].effect_id).is_equal(lasting_id)


func test_204_4_7_only_active_player_ends_turn() -> void:
	_engine.start_from_state(_builder.build())
	_assert_rejected(EndTurn.new(B), REASON.NOT_YOUR_TURN)


func test_204_4_7_end_turn_outside_main_phase_rejected() -> void:
	_builder.with_phase(DuelState.DuelPhase.TURN_END)
	_engine.start_from_state(_builder.build())
	_assert_rejected(EndTurn.new(A), REASON.WRONG_PHASE)


func test_204_4_7_end_turn_with_stack_not_empty_rejected() -> void:
	_builder.push_spell(_builder.make_card_instance(B, CARD))
	_engine.start_from_state(_builder.build())
	_assert_rejected(EndTurn.new(A), REASON.STACK_NOT_EMPTY)


func test_end_turn_while_decision_pending_rejected() -> void:
	var decision := PendingDecision.new()
	decision.kind = PendingDecision.DecisionKind.ORDER_TRIGGERS
	decision.awaited_players.append(A)
	_builder.with_pending_decision(decision)
	_engine.start_from_state(_builder.build())
	_assert_rejected(EndTurn.new(A), REASON.DECISION_PENDING)


func _end_turn_of_a() -> Array[DuelEvent]:
	_engine.start_from_state(_builder.build())
	return _engine.submit(EndTurn.new(A))


func _start_full_duel(first_player: DuelState.PlayerSide) -> void:
	var setup := SetupSamples.setup()
	setup.impose_first_player(first_player)
	_engine.start_new_duel(setup)
	_engine.submit(ChooseMulligan.new(A))
	_engine.submit(ChooseMulligan.new(B))


func _make_effect(piece_id: int, duration: ActiveEffect.EffectDuration) -> ActiveEffect:
	var effect := ActiveEffect.new()
	effect.duration = duration
	effect.affected_piece_id = piece_id
	return effect


func _assert_rejected(intent: DuelIntent, expected: IntentRejected.RejectReason) -> void:
	var snapshot := _engine.get_state().clone()
	assert_int(EventLog.rejection_reason(_engine.submit(intent))).is_equal(expected)
	assert_array(DeepCompare.find_clone_defects(snapshot, _engine.get_state())).is_empty()
