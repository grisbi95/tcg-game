# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## Expiration du temps de tour et du temps de réponse (209.4.9 à 209.4.12, 201.1.3d).
## Ruleset 0.40, décisions 0018 et 0045, décisions de design 0205 et 0206 du ruleset.
##
## 209.4.11 : une annonce est une intention entière ; avant sa soumission, le moteur ne l'a pas
## vue et rien n'est payé. Q-110 : l'abandon d'un effet déclenché ne se code que sans autre effet
## en attente et sans « une fois par tour » ; le reste n'est pas testé.

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


# --- 209.4.9 à 209.4.12 : expirations ---


func test_209_4_9_turn_time_expiry_ends_turn() -> void:
	_engine.start_from_state(_builder.with_turn_time_remaining(A, STEP_MSEC).build())
	assert_array(_engine.advance_clock(STEP_MSEC - 1)).is_empty()
	var labels := EventLog.describe(_engine.advance_clock(1))
	var expected: Array[String] = ["TimeExpired:A", "TurnEnded:A", "TurnStarted:B"]
	assert_array(labels.slice(0, 3)).contains_exactly(expected)
	var state := _engine.get_state()
	assert_int(state.active_player).is_equal(B)
	assert_int(state.phase).is_equal(PHASE.MAIN)
	assert_int(TimeScenarios.turn_time(_engine, B)).is_equal(TURN_MSEC)


func test_209_4_9_expiry_event_names_the_turn_clock() -> void:
	_engine.start_from_state(_builder.with_turn_time_remaining(A, STEP_MSEC).build())
	var expired := _engine.advance_clock(STEP_MSEC)[0] as TimeExpired
	assert_int(expired.kind).is_equal(KIND.TURN)
	assert_int(expired.player).is_equal(A)


func test_209_4_9_turn_time_expiry_has_the_effect_of_ending_the_turn_by_hand() -> void:
	var catalog := _builder.build().catalog
	var by_hand := TimeScenarios.engine_with_turn_time(catalog, TURN_MSEC)
	var by_time := TimeScenarios.engine_with_turn_time(catalog, STEP_MSEC)
	var hand_events := EventLog.describe(by_hand.submit(EndTurn.new(A)))
	var time_events := EventLog.describe(by_time.advance_clock(STEP_MSEC))
	assert_array(time_events.slice(1)).contains_exactly(hand_events)
	var defects := DeepCompare.find_clone_defects(by_hand.get_state(), by_time.get_state())
	# Seuls diffèrent le temps de tour, le compteur d'inactivité et l'instance de configuration.
	var unexpected := Array(defects).filter(
		func(defect: String) -> bool:
			return not (["turn_time", "idle_turns", "config"] as Array[String]).any(
				func(field: String) -> bool: return field in defect
			)
	)
	assert_array(unexpected).is_empty()


func test_209_4_9_end_of_turn_effects_follow_the_expiry() -> void:
	_builder.place_piece(
		A, Piece.PieceKind.BUILDING, DuelStateBuilder.cell("B2"), TriggerSamples.BEACON
	)
	_builder.place_piece(
		A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("D1"), TriggerSamples.SOLDIER
	)
	_engine.start_from_state(_builder.with_turn_time_remaining(A, STEP_MSEC).build())
	var labels := EventLog.describe(_engine.advance_clock(STEP_MSEC))
	var expected: Array[String] = ["TimeExpired:A", "TurnEnded:A", "EffectTriggered:A"]
	expected.append_array(EventLog.repeat("DecisionResolvedAutomatically:A", 2))
	expected.append("StackEntryAdded:A")
	assert_array(labels).contains_exactly(expected)
	assert_int(_engine.get_state().active_player).is_equal(A)
	assert_int(_engine.get_state().phase).is_equal(PHASE.TURN_END)


func test_209_4_10_response_time_expiry_passes() -> void:
	TimeScenarios.push_spell(_builder, A)
	_engine.start_from_state(
		_builder.with_priority_player(B).with_response_time_remaining(B, STEP_MSEC).build()
	)
	var events := _engine.advance_clock(STEP_MSEC)
	assert_array(EventLog.describe(events)).contains_exactly(
		["TimeExpired:B", "PriorityPassed:B", "CardDiscarded:A", "StackEntryResolved:A"]
	)
	assert_int((events[0] as TimeExpired).kind).is_equal(KIND.RESPONSE)
	assert_bool(_engine.get_state().stack.is_empty()).is_true()
	assert_array(_engine.clock_owners()).contains_exactly([A])


func test_209_4_10_response_expiry_leaves_the_turn_time_alone() -> void:
	TimeScenarios.push_spell(_builder, A)
	_engine.start_from_state(
		_builder.with_priority_player(B).with_response_time_remaining(B, STEP_MSEC).build()
	)
	_engine.advance_clock(STEP_MSEC)
	assert_int(_engine.get_state().active_player).is_equal(A)
	assert_int(TimeScenarios.turn_time(_engine, A)).is_equal(TURN_MSEC)


func test_209_4_10_a_player_who_cannot_answer_still_waits_for_the_expiry() -> void:
	TimeScenarios.push_spell(_builder, A)
	_engine.start_from_state(_builder.with_priority_player(B).build())
	assert_array(_engine.clock_owners()).contains_exactly([B])
	assert_array(_engine.advance_clock(RESPONSE_MSEC - 1)).is_empty()
	assert_bool(_engine.get_state().stack.is_empty()).is_false()


func test_209_4_11_expiry_before_an_announcement_changes_nothing_but_the_turn() -> void:
	var card_id := _builder.add_to_hand(A, SPELL)
	_engine.start_from_state(_builder.with_turn_time_remaining(A, STEP_MSEC).build())
	var hand_before := DuelChecks.card_ids(_engine.get_state().get_player(A).hand)
	_engine.advance_clock(STEP_MSEC)
	var state := _engine.get_state()
	assert_bool(state.stack.is_empty()).is_true()
	assert_bool(DuelChecks.card_ids(state.get_player(A).hand).has(card_id)).is_true()
	assert_int(hand_before.size()).is_equal(state.get_player(A).hand.size())
	assert_int(state.get_player(A).sources_upright).is_equal(2)


func test_209_4_11a_expiry_abandons_a_triggered_effect_without_targets() -> void:
	TimeScenarios.ask_herald_targets(_builder, _engine)
	var state := _engine.get_state()
	var entry_id := state.pending_decision.subject_stack_entry_id
	TimeScenarios.set_turn_time(_engine, A, STEP_MSEC)
	var events := _engine.advance_clock(STEP_MSEC)
	assert_array(EventLog.describe(events)).contains_exactly(["TimeExpired:A", "TriggerSkipped:A"])
	assert_int((events[1] as TriggerSkipped).stack_entry_id).is_equal(entry_id)
	assert_object(state.pending_decision).is_null()
	assert_bool(state.stack.is_empty()).is_true()
	assert_bool(state.triggers_to_add.is_empty()).is_true()


func test_209_4_11a_the_turn_then_ends_by_209_4_9() -> void:
	TimeScenarios.ask_herald_targets(_builder, _engine)
	TimeScenarios.set_turn_time(_engine, A, STEP_MSEC)
	var labels := EventLog.describe(_engine.advance_clock(STEP_MSEC * 2))
	assert_array(labels.slice(0, 4)).contains_exactly(
		["TimeExpired:A", "TriggerSkipped:A", "TimeExpired:A", "TurnEnded:A"]
	)


func test_209_4_12_expiry_orders_triggers_as_they_were_triggered() -> void:
	var first_id := TimeScenarios.end_turn_with_two_beacons(_builder, _engine)
	var second_id := _engine.get_state().pending_decision.candidate_ids[1]
	TimeScenarios.set_turn_time(_engine, A, STEP_MSEC)
	var events := _engine.advance_clock(STEP_MSEC)
	var expected: Array[String] = ["TimeExpired:A", "TriggersOrdered:A"]
	for index: int in 2:
		expected.append_array(["DecisionResolvedAutomatically:A", "StackEntryAdded:A"])
	assert_array(EventLog.describe(events)).contains_exactly(expected)
	var stack_ids: Array[int] = []
	for entry: StackEntry in _engine.get_state().stack:
		stack_ids.append(entry.stack_entry_id)
	assert_array(stack_ids).contains_exactly([first_id, second_id])
	assert_object(_engine.get_state().pending_decision).is_null()


func test_209_4_12_response_time_expiry_orders_the_other_players_triggers() -> void:
	var first_id := TimeScenarios.end_turn_with_two_beacons(_builder, _engine)
	var state := _engine.get_state()
	state.pending_decision.awaited_players.assign([B])
	state.get_player(B).response_time_remaining_msec = STEP_MSEC
	var events := _engine.advance_clock(STEP_MSEC)
	var expired := events[0] as TimeExpired
	assert_int(expired.kind).is_equal(KIND.RESPONSE)
	assert_int(expired.player).is_equal(B)
	assert_int(state.stack[0].stack_entry_id).is_equal(first_id)


# --- Contrat de décision 0045 ---


func test_decision_0045_time_never_goes_below_zero() -> void:
	_engine.start_from_state(_builder.with_turn_time_remaining(A, STEP_MSEC).build())
	_engine.advance_clock(STEP_MSEC * 5)
	assert_int(TimeScenarios.turn_time(_engine, A)).is_greater_equal(0)
	assert_int(TimeScenarios.response_time(_engine, B)).is_greater_equal(0)


func test_decision_0045_time_left_after_an_expiry_runs_in_the_next_state() -> void:
	_engine.start_from_state(_builder.with_turn_time_remaining(A, STEP_MSEC).build())
	_engine.advance_clock(STEP_MSEC + 250)
	assert_int(_engine.get_state().active_player).is_equal(B)
	assert_int(TimeScenarios.turn_time(_engine, B)).is_equal(TURN_MSEC - 250)


func test_decision_0045_zero_or_negative_time_changes_nothing() -> void:
	_engine.start_from_state(_builder.build())
	var snapshot := _engine.get_state().clone()
	assert_array(_engine.advance_clock(0)).is_empty()
	assert_array(_engine.advance_clock(-STEP_MSEC)).is_empty()
	assert_array(DeepCompare.find_clone_defects(snapshot, _engine.get_state())).is_empty()


func test_decision_0045_clock_before_the_duel_does_nothing() -> void:
	assert_array(_engine.advance_clock(STEP_MSEC)).is_empty()
	assert_array(_engine.clock_owners()).is_empty()


func test_decision_0045_the_clock_never_makes_a_player_lose_the_game() -> void:
	_engine.start_from_state(_builder.with_turn_time_remaining(A, STEP_MSEC).build())
	_engine.advance_clock(TURN_MSEC * 2)
	assert_int(_engine.get_state().result).is_equal(RESULT.NONE)
