# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## Pendule : qui la fait tourner, temps écoulé, défaite et partie nulle au temps (ruleset 0.33,
## sections 209.4, 209.2.8 à 209.2.9, 201.1.2b, 201.1.3c ; décision 0018).
##
## 209.4.2a tient à la structure : la pile se résout dans un `submit()`, et `advance_clock`
## n'est jamais appelé pendant un `submit()`.

const CLOCK_MSEC: int = 600_000  # 209.4.3 : 10 minutes
const STEP_MSEC: int = 1_000
const CARD: StringName = &"clock_card"
const CARD_FORCE: int = 3
const SPELL: StringName = &"clock_spell"

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const REASON := IntentRejected.RejectReason
const RESULT := DuelState.DuelResult
const DECISION := PendingDecision.DecisionKind
const PHASE := DuelState.DuelPhase

var _builder: DuelStateBuilder
var _engine: DuelEngine


func before_test() -> void:
	var catalog := Catalog.new()
	SetupSamples.add_unit(catalog, CARD, CARD_FORCE)
	var spell := CatalogSamples.with_field(CatalogSamples.spell(), "id", String(SPELL))
	catalog.add_card(CardDefinition.from_dict(CatalogSamples.with_field(spell, "effects", [])))
	_builder = DuelStateBuilder.new(DuelConfig.new(), catalog)
	_engine = DuelEngine.new(catalog)
	for side: DuelState.PlayerSide in [A, B]:
		for index: int in 2:
			_builder.add_to_deck(side, CARD)


func test_209_4_3_each_clock_starts_at_ten_minutes() -> void:
	_start_sample_duel()
	for side: DuelState.PlayerSide in [A, B]:
		assert_int(_remaining(side)).is_equal(CLOCK_MSEC)


func test_209_4_4e_both_clocks_run_during_the_mulligan() -> void:
	_start_sample_duel()
	assert_array(_engine.clock_owners()).contains_exactly([A, B])
	_engine.submit(ChooseMulligan.new(A))
	assert_array(_engine.clock_owners()).contains_exactly([B])


func test_209_4_4e_mulligan_takes_time_from_each_undecided_player() -> void:
	_start_sample_duel()
	_engine.advance_clock(STEP_MSEC)
	_engine.submit(ChooseMulligan.new(A))
	_engine.advance_clock(STEP_MSEC)
	assert_int(_remaining(A)).is_equal(CLOCK_MSEC - STEP_MSEC)
	assert_int(_remaining(B)).is_equal(CLOCK_MSEC - 2 * STEP_MSEC)


func test_209_4_4a_active_player_clock_runs_in_main_phase_with_empty_stack() -> void:
	_engine.start_from_state(_builder.build())
	assert_array(_engine.clock_owners()).contains_exactly([A])


func test_209_4_4a_active_clock_runs_again_once_the_stack_is_resolved() -> void:
	_push_spell(A)
	_engine.start_from_state(_builder.with_priority_player(B).build())
	_engine.submit(PassPriority.new(B))
	_engine.submit(PassPriority.new(A))
	assert_array(_engine.clock_owners()).contains_exactly([A])


func test_209_4_4b_clock_of_the_player_who_can_answer_runs() -> void:
	_push_spell(A)
	_engine.start_from_state(_builder.with_priority_player(B).build())
	assert_array(_engine.clock_owners()).contains_exactly([B])


func test_209_4_4b_answering_clock_runs_during_turn_end() -> void:
	_push_spell(A)
	_builder.with_phase(PHASE.TURN_END).with_priority_player(B)
	_engine.start_from_state(_builder.build())
	assert_array(_engine.clock_owners()).contains_exactly([B])


func test_209_4_4c_clock_runs_for_ordering_triggers() -> void:
	_await(DECISION.ORDER_TRIGGERS, [B], DuelState.NO_ID)
	assert_array(_engine.clock_owners()).contains_exactly([B])


func test_209_4_4c_ordering_clock_runs_during_turn_end() -> void:
	_builder.with_phase(PHASE.TURN_END)
	_await(DECISION.ORDER_TRIGGERS, [A], DuelState.NO_ID)
	assert_array(_engine.clock_owners()).contains_exactly([A])


func test_209_4_4d_clock_runs_for_choosing_targets_of_own_entry() -> void:
	var entry_id := _push_spell(A)
	_builder.with_priority_player(B)
	_await(DECISION.CHOOSE_TARGETS, [A], entry_id)
	assert_array(_engine.clock_owners()).contains_exactly([A])


func test_209_4_4_clock_runs_as_soon_as_the_next_turn_awaits_a_decision() -> void:
	_engine.start_from_state(_builder.build())
	_engine.submit(EndTurn.new(A))
	_engine.advance_clock(STEP_MSEC)
	assert_int(_remaining(B)).is_equal(CLOCK_MSEC - STEP_MSEC)
	assert_int(_remaining(A)).is_equal(CLOCK_MSEC)


func test_209_4_2b_no_clock_runs_during_turn_start() -> void:
	_engine.start_from_state(_builder.with_phase(PHASE.TURN_START).build())
	assert_array(_engine.clock_owners()).is_empty()


func test_209_4_2c_no_clock_runs_in_turn_end_without_decision() -> void:
	_engine.start_from_state(_builder.with_phase(PHASE.TURN_END).build())
	assert_array(_engine.clock_owners()).is_empty()


func test_209_4_2_only_the_running_clock_loses_time() -> void:
	_engine.start_from_state(_builder.build())
	assert_array(_engine.advance_clock(STEP_MSEC)).is_empty()
	assert_int(_remaining(A)).is_equal(CLOCK_MSEC - STEP_MSEC)
	assert_int(_remaining(B)).is_equal(CLOCK_MSEC)


func test_209_4_1_each_player_has_his_own_clock() -> void:
	_push_spell(A)
	_engine.start_from_state(_builder.with_priority_player(B).build())
	_engine.advance_clock(STEP_MSEC)
	assert_int(_remaining(A)).is_equal(CLOCK_MSEC)
	assert_int(_remaining(B)).is_equal(CLOCK_MSEC - STEP_MSEC)


func test_209_4_5_time_runs_out_exactly_at_zero() -> void:
	_engine.start_from_state(_builder.with_clock_remaining(A, STEP_MSEC).build())
	assert_array(_engine.advance_clock(STEP_MSEC - 1)).is_empty()
	assert_int(_remaining(A)).is_equal(1)
	var labels := EventLog.describe(_engine.advance_clock(1))
	assert_array(labels).contains_exactly(["TimeExpired:A", "DuelEnded"])


func test_209_2_8_player_whose_time_runs_out_loses() -> void:
	_engine.start_from_state(_builder.with_clock_remaining(A, STEP_MSEC).build())
	_engine.advance_clock(STEP_MSEC)
	assert_int(_engine.get_state().result).is_equal(RESULT.PLAYER_B_WINS)


func test_201_1_3c_player_wins_when_only_the_opponent_time_runs_out() -> void:
	_push_spell(A)
	_builder.with_priority_player(B).with_clock_remaining(B, STEP_MSEC)
	_engine.start_from_state(_builder.build())
	var labels := EventLog.describe(_engine.advance_clock(STEP_MSEC))
	assert_array(labels).contains_exactly(["TimeExpired:B", "DuelEnded"])
	assert_int(_engine.get_state().result).is_equal(RESULT.PLAYER_A_WINS)


func test_209_2_9_the_duel_stops_at_once_when_time_runs_out() -> void:
	_engine.start_from_state(_builder.with_clock_remaining(A, STEP_MSEC).build())
	_engine.advance_clock(STEP_MSEC)
	assert_bool(_engine.get_state().is_ended()).is_true()
	assert_int(EventLog.rejection_reason(_engine.submit(EndTurn.new(A)))).is_equal(
		REASON.DUEL_ENDED
	)
	assert_array(_engine.clock_owners()).is_empty()


func test_209_2_8a_both_times_out_together_is_a_draw() -> void:
	_builder.with_clock_remaining(A, STEP_MSEC).with_clock_remaining(B, STEP_MSEC)
	_await_mulligan()
	var events := _engine.advance_clock(STEP_MSEC * 2)
	assert_array(EventLog.describe(events)).contains_exactly(
		["TimeExpired:A", "TimeExpired:B", "DuelEnded"]
	)
	assert_int(_engine.get_state().result).is_equal(RESULT.DRAW)


func test_201_1_2b_both_times_out_together_is_a_draw() -> void:
	_builder.with_clock_remaining(A, STEP_MSEC).with_clock_remaining(B, STEP_MSEC)
	_await_mulligan()
	_engine.advance_clock(STEP_MSEC)
	assert_int(_engine.get_state().result).is_equal(RESULT.DRAW)


func test_decision_0018_first_clock_at_zero_stops_the_others() -> void:
	_builder.with_clock_remaining(A, STEP_MSEC).with_clock_remaining(B, STEP_MSEC * 5)
	_await_mulligan()
	var events := _engine.advance_clock(STEP_MSEC * 10)
	assert_array(EventLog.describe(events)).contains_exactly(["TimeExpired:A", "DuelEnded"])
	assert_int(_remaining(B)).is_equal(STEP_MSEC * 4)
	assert_int(_engine.get_state().result).is_equal(RESULT.PLAYER_B_WINS)


func test_decision_0018_clock_never_goes_below_zero() -> void:
	_engine.start_from_state(_builder.with_clock_remaining(A, STEP_MSEC).build())
	_engine.advance_clock(STEP_MSEC * 5)
	assert_int(_remaining(A)).is_equal(0)


func test_decision_0018_zero_or_negative_time_changes_nothing() -> void:
	_engine.start_from_state(_builder.build())
	var snapshot := _engine.get_state().clone()
	assert_array(_engine.advance_clock(0)).is_empty()
	assert_array(_engine.advance_clock(-STEP_MSEC)).is_empty()
	assert_array(DeepCompare.find_clone_defects(snapshot, _engine.get_state())).is_empty()


func test_decision_0018_clock_before_the_duel_does_nothing() -> void:
	assert_array(_engine.advance_clock(STEP_MSEC)).is_empty()
	assert_array(_engine.clock_owners()).is_empty()


func _start_sample_duel() -> void:
	_engine = DuelEngine.new(SetupSamples.catalog())
	_engine.start_new_duel(SetupSamples.setup())


# Démarre le moteur sur une attente `kind` des joueurs `sides`, au sujet de `subject_id`.
func _await(
	kind: PendingDecision.DecisionKind, sides: Array[DuelState.PlayerSide], subject_id: int
) -> void:
	var decision := PendingDecision.new()
	decision.kind = kind
	decision.awaited_players.assign(sides)
	decision.subject_stack_entry_id = subject_id
	_engine.start_from_state(_builder.with_pending_decision(decision).build())


# 204.2.2 : les deux joueurs décident de leur mulligan pendant la préparation.
func _await_mulligan() -> void:
	_builder.with_phase(PHASE.PREPARATION)
	_await(DECISION.MULLIGAN, [A, B], DuelState.NO_ID)


func _push_spell(side: DuelState.PlayerSide) -> int:
	return _builder.push_spell(_builder.make_card_instance(side, SPELL))


func _remaining(side: DuelState.PlayerSide) -> int:
	return _engine.get_state().get_player(side).clock_remaining_msec
