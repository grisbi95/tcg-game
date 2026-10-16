extends GdUnitTestSuite
## DuelEngine : façade, refus généraux et déterminisme (décisions 0001 et 0012).

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const REASON := IntentRejected.RejectReason

var _catalog: Catalog


func before() -> void:
	_catalog = SetupSamples.catalog()


func test_intent_before_start_rejected() -> void:
	var engine := DuelEngine.new(_catalog)
	assert_object(engine.get_state()).is_null()
	assert_int(engine.validate(EndTurn.new(A))).is_equal(REASON.DUEL_NOT_STARTED)
	var events := engine.submit(EndTurn.new(A))
	assert_int(EventLog.rejection_reason(events)).is_equal(REASON.DUEL_NOT_STARTED)
	assert_object((events[0] as IntentRejected).intent).is_instanceof(EndTurn)


func test_intent_after_duel_ended_rejected() -> void:
	var engine := _engine_on(DuelStateBuilder.new().with_phase(DuelState.DuelPhase.ENDED))
	_assert_rejected(engine, EndTurn.new(A), REASON.DUEL_ENDED)


func test_unknown_intent_rejected() -> void:
	var engine := _engine_on(DuelStateBuilder.new())
	_assert_rejected(engine, DuelIntent.new(A), REASON.UNKNOWN_INTENT)


func test_validate_is_pure() -> void:
	var engine := _engine_on(DuelStateBuilder.new())
	var snapshot := engine.get_state().clone()
	assert_int(engine.validate(EndTurn.new(A))).is_equal(REASON.NONE)
	assert_array(DeepCompare.find_clone_defects(snapshot, engine.get_state())).is_empty()


func test_same_seed_and_intents_give_same_duel() -> void:
	var shared_config := DuelConfig.new()
	var states: Array[DuelState] = []
	var descriptions: Array[Array] = []
	for attempt: int in 2:
		var engine := DuelEngine.new(_catalog, shared_config)
		var events := engine.start_new_duel(SetupSamples.setup())
		var hand := engine.get_state().get_player(B).hand
		var set_aside_ids: Array[int] = [hand[0].card_instance_id, hand[3].card_instance_id]
		events.append_array(engine.submit(ChooseMulligan.new(B, set_aside_ids)))
		events.append_array(engine.submit(ChooseMulligan.new(A)))
		var active := engine.get_state().active_player
		events.append_array(engine.submit(EndTurn.new(active)))
		states.append(engine.get_state())
		descriptions.append(EventLog.describe(events))
	assert_array(DeepCompare.find_clone_defects(states[0], states[1])).is_empty()
	assert_array(descriptions[0]).is_equal(descriptions[1])


func _engine_on(builder: DuelStateBuilder) -> DuelEngine:
	var engine := DuelEngine.new(_catalog)
	engine.start_from_state(builder.build())
	return engine


func _assert_rejected(
	engine: DuelEngine, intent: DuelIntent, expected: IntentRejected.RejectReason
) -> void:
	var snapshot := engine.get_state().clone()
	assert_int(EventLog.rejection_reason(engine.submit(intent))).is_equal(expected)
	assert_array(DeepCompare.find_clone_defects(snapshot, engine.get_state())).is_empty()
