# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## Temps de tour et temps de réponse : quand ils s'écoulent (209.4.2 à 209.4.8).
## Ruleset 0.40, décisions 0018 et 0045, décisions de design 0205 et 0206 du ruleset.
##
## 209.4.2a tient à la structure : la pile se résout dans un `submit()`, et `advance_clock`
## n'est jamais appelé pendant un `submit()`. 209.4.4f et 209.4.4g se vérifient par l'hôte
## (`test_duel_host.gd`, `test_208_6_response_window.gd`).

const TURN_MSEC: int = 90_000  # 209.4.3
const RESPONSE_MSEC: int = 30_000  # 209.4.6
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


# --- 209.4.2 : quand un temps s'écoule ---


func test_209_4_2_only_the_running_time_is_spent() -> void:
	_engine.start_from_state(_builder.build())
	assert_array(_engine.advance_clock(STEP_MSEC)).is_empty()
	assert_int(TimeScenarios.turn_time(_engine, A)).is_equal(TURN_MSEC - STEP_MSEC)
	assert_int(TimeScenarios.turn_time(_engine, B)).is_equal(TURN_MSEC)
	assert_int(TimeScenarios.response_time(_engine, A)).is_equal(RESPONSE_MSEC)
	assert_int(TimeScenarios.response_time(_engine, B)).is_equal(RESPONSE_MSEC)


func test_209_4_2a_no_time_runs_during_the_resolution_of_the_stack() -> void:
	TimeScenarios.push_spell(_builder, A)
	_engine.start_from_state(_builder.with_priority_player(B).build())
	_engine.submit(PassPriority.new(B))
	assert_array(_engine.clock_owners()).contains_exactly([A])
	assert_int(TimeScenarios.turn_time(_engine, A)).is_equal(TURN_MSEC)
	assert_int(TimeScenarios.response_time(_engine, B)).is_equal(RESPONSE_MSEC)


func test_209_4_2b_no_time_runs_during_turn_start() -> void:
	_engine.start_from_state(_builder.with_phase(PHASE.TURN_START).build())
	assert_array(_engine.clock_owners()).is_empty()
	assert_array(_engine.advance_clock(TURN_MSEC)).is_empty()


func test_209_4_2c_no_time_runs_in_turn_end_without_decision() -> void:
	_engine.start_from_state(_builder.with_phase(PHASE.TURN_END).build())
	assert_array(_engine.clock_owners()).is_empty()
	assert_array(_engine.advance_clock(TURN_MSEC)).is_empty()


func test_209_4_2d_no_time_runs_during_the_mulligan() -> void:
	_engine = TimeScenarios.start_sample_duel()
	assert_array(_engine.awaited_players()).contains_exactly([A, B])
	assert_array(_engine.clock_owners()).is_empty()
	_engine.submit(ChooseMulligan.new(A))
	assert_array(_engine.awaited_players()).contains_exactly([B])
	assert_array(_engine.clock_owners()).is_empty()
	assert_array(_engine.advance_clock(TURN_MSEC)).is_empty()
	assert_int(TimeScenarios.turn_time(_engine, A)).is_equal(TURN_MSEC)
	assert_int(TimeScenarios.response_time(_engine, B)).is_equal(RESPONSE_MSEC)


# --- 209.4.3, 209.4.4 : temps de tour ---


func test_209_4_3_turn_time_starts_at_ninety_seconds() -> void:
	_engine = TimeScenarios.start_sample_duel()
	_engine.submit(ChooseMulligan.new(A))
	_engine.submit(ChooseMulligan.new(B))
	var active := _engine.get_state().active_player
	assert_int(TimeScenarios.turn_time(_engine, active)).is_equal(TURN_MSEC)


func test_209_4_3_turn_time_is_renewed_at_each_turn() -> void:
	_engine.start_from_state(_builder.with_turn_time_remaining(B, STEP_MSEC).build())
	_engine.submit(EndTurn.new(A))
	assert_int(TimeScenarios.turn_time(_engine, B)).is_equal(TURN_MSEC)


func test_209_4_4_turn_time_of_the_active_player_runs_with_an_empty_stack() -> void:
	_engine.start_from_state(_builder.build())
	assert_array(_engine.clock_owners()).contains_exactly([A])
	assert_int(_engine.clock_kind(A)).is_equal(KIND.TURN)


func test_209_4_4_turn_time_runs_as_soon_as_the_next_turn_awaits_a_decision() -> void:
	_engine.start_from_state(_builder.build())
	_engine.submit(EndTurn.new(A))
	_engine.advance_clock(STEP_MSEC)
	assert_int(TimeScenarios.turn_time(_engine, B)).is_equal(TURN_MSEC - STEP_MSEC)
	assert_int(TimeScenarios.turn_time(_engine, A)).is_equal(TURN_MSEC)


func test_209_4_4a_turn_time_runs_in_the_main_phase_with_an_empty_stack() -> void:
	_engine.start_from_state(_builder.build())
	_engine.advance_clock(STEP_MSEC)
	assert_int(TimeScenarios.turn_time(_engine, A)).is_equal(TURN_MSEC - STEP_MSEC)


func test_209_4_4c_turn_time_runs_for_ordering_own_triggers() -> void:
	_builder.with_phase(PHASE.TURN_END)
	TimeScenarios.await_decision(_builder, _engine, DECISION.ORDER_TRIGGERS, [A], DuelState.NO_ID)
	assert_array(_engine.clock_owners()).contains_exactly([A])
	assert_int(_engine.clock_kind(A)).is_equal(KIND.TURN)
	_engine.advance_clock(STEP_MSEC)
	assert_int(TimeScenarios.turn_time(_engine, A)).is_equal(TURN_MSEC - STEP_MSEC)


func test_209_4_4d_turn_time_runs_for_choosing_targets_with_an_empty_stack() -> void:
	TimeScenarios.ask_herald_targets(_builder, _engine)
	assert_array(_engine.clock_owners()).contains_exactly([A])
	assert_int(_engine.clock_kind(A)).is_equal(KIND.TURN)


# --- 209.4.6, 209.4.7 : temps de réponse ---


func test_209_4_6_response_time_is_thirty_seconds() -> void:
	_engine = TimeScenarios.start_sample_duel()
	for side: DuelState.PlayerSide in [A, B]:
		assert_int(TimeScenarios.response_time(_engine, side)).is_equal(RESPONSE_MSEC)


func test_209_4_7_response_time_runs_for_the_player_who_can_answer() -> void:
	TimeScenarios.push_spell(_builder, A)
	_engine.start_from_state(_builder.with_priority_player(B).build())
	assert_array(_engine.clock_owners()).contains_exactly([B])
	assert_int(_engine.clock_kind(B)).is_equal(KIND.RESPONSE)
	_engine.advance_clock(STEP_MSEC)
	assert_int(TimeScenarios.response_time(_engine, B)).is_equal(RESPONSE_MSEC - STEP_MSEC)
	assert_int(TimeScenarios.response_time(_engine, A)).is_equal(RESPONSE_MSEC)


func test_209_4_7_response_time_runs_during_turn_end() -> void:
	TimeScenarios.push_spell(_builder, A)
	_builder.with_phase(PHASE.TURN_END).with_priority_player(B)
	_engine.start_from_state(_builder.build())
	assert_array(_engine.clock_owners()).contains_exactly([B])
	assert_int(_engine.clock_kind(B)).is_equal(KIND.RESPONSE)


func test_209_4_7_response_time_runs_for_choosing_targets_with_a_non_empty_stack() -> void:
	var entry_id := TimeScenarios.push_spell(_builder, A)
	_builder.with_priority_player(B)
	TimeScenarios.await_decision(_builder, _engine, DECISION.CHOOSE_TARGETS, [A], entry_id)
	assert_array(_engine.clock_owners()).contains_exactly([A])
	assert_int(_engine.clock_kind(A)).is_equal(KIND.RESPONSE)


func test_209_4_7a_each_addition_to_the_stack_gives_a_full_response_time() -> void:
	var card_id := _builder.add_to_hand(A, SPELL)
	_engine.start_from_state(_builder.with_response_time_remaining(B, STEP_MSEC).build())
	_engine.submit(CastSpell.new(A, card_id, EssencePayment.new(1)))
	assert_int(TimeScenarios.response_time(_engine, B)).is_equal(RESPONSE_MSEC)


func test_209_4_7a_the_answer_gives_a_full_response_time_to_the_first_player() -> void:
	TimeScenarios.push_spell(_builder, A)
	var card_id := _builder.add_to_hand(B, SPELL)
	_builder.with_priority_player(B).with_response_time_remaining(A, STEP_MSEC)
	_engine.start_from_state(_builder.build())
	_engine.submit(CastSpell.new(B, card_id, EssencePayment.new(1)))
	assert_array(_engine.clock_owners()).contains_exactly([A])
	assert_int(TimeScenarios.response_time(_engine, A)).is_equal(RESPONSE_MSEC)


func test_209_4_7b_response_time_runs_for_ordering_the_triggers_of_the_other_player() -> void:
	TimeScenarios.await_decision(_builder, _engine, DECISION.ORDER_TRIGGERS, [B], DuelState.NO_ID)
	assert_array(_engine.clock_owners()).contains_exactly([B])
	assert_int(_engine.clock_kind(B)).is_equal(KIND.RESPONSE)
	_engine.advance_clock(STEP_MSEC)
	assert_int(TimeScenarios.response_time(_engine, B)).is_equal(RESPONSE_MSEC - STEP_MSEC)
	assert_int(TimeScenarios.turn_time(_engine, A)).is_equal(TURN_MSEC)


func test_209_4_7b_a_pending_decision_gives_a_full_response_time() -> void:
	_builder.with_response_time_remaining(A, STEP_MSEC)
	TimeScenarios.ask_herald_targets(_builder, _engine)
	assert_int(TimeScenarios.response_time(_engine, A)).is_equal(RESPONSE_MSEC)


# --- 209.4.8 : pause du temps de tour ---


func test_209_4_8_turn_time_is_paused_while_the_stack_is_not_empty() -> void:
	TimeScenarios.push_spell(_builder, A)
	_engine.start_from_state(_builder.with_priority_player(B).build())
	_engine.advance_clock(STEP_MSEC * 10)
	assert_int(TimeScenarios.turn_time(_engine, A)).is_equal(TURN_MSEC)


func test_209_4_8_engine_says_when_the_turn_time_is_paused() -> void:
	TimeScenarios.push_spell(_builder, A)
	_engine.start_from_state(_builder.with_priority_player(B).build())
	assert_bool(_engine.is_turn_time_paused(A)).is_true()
	assert_bool(_engine.is_turn_time_paused(B)).is_false()
	assert_int(_engine.running_time_remaining_msec(B)).is_equal(RESPONSE_MSEC)


func test_209_4_6_a_player_not_awaited_will_get_a_full_response_time() -> void:
	_engine.start_from_state(_builder.with_response_time_remaining(B, STEP_MSEC).build())
	assert_int(_engine.running_time_remaining_msec(B)).is_equal(RESPONSE_MSEC)


func test_209_4_8a_turn_time_is_not_paused_on_an_empty_stack() -> void:
	_engine.start_from_state(_builder.build())
	assert_bool(_engine.is_turn_time_paused(A)).is_false()
	assert_int(_engine.running_time_remaining_msec(A)).is_equal(TURN_MSEC)


func test_209_4_8a_turn_time_resumes_where_it_was_when_the_stack_is_empty() -> void:
	var left_msec := STEP_MSEC * 50
	TimeScenarios.push_spell(_builder, A)
	_builder.with_priority_player(B).with_turn_time_remaining(A, left_msec)
	_engine.start_from_state(_builder.build())
	_engine.advance_clock(STEP_MSEC * 3)
	_engine.submit(PassPriority.new(B))
	assert_int(TimeScenarios.turn_time(_engine, A)).is_equal(left_msec)
	_engine.advance_clock(STEP_MSEC)
	assert_int(TimeScenarios.turn_time(_engine, A)).is_equal(left_msec - STEP_MSEC)
