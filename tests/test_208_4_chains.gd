# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## Chaînes d'effets déclenchés : attente de fin de bloc, ordre d'ajout, cibles, fin du tour
## (ruleset 0.33, sections 208.4, 208.5, 204.5.3 à 204.5.7 ; 207.5.1b, 207.5.2 ; décisions
## 0004, 0009 et 0017).

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const REASON := IntentRejected.RejectReason
const DECISION := PendingDecision.DecisionKind
const SPELL_ID: StringName = &"sample_spell"  # CatalogSamples.spell(), Réaction
const UNKNOWN_ENTRY_ID: int = 99

var _builder: DuelStateBuilder
var _engine: DuelEngine


func before_test() -> void:
	var catalog := TriggerSamples.catalog()
	catalog.add_card(CardDefinition.from_dict(CatalogSamples.spell()))
	_builder = DuelStateBuilder.new(DuelConfig.new(), catalog)
	_engine = DuelEngine.new(catalog)


func test_208_4_2_trigger_waits_for_the_end_of_the_block() -> void:
	_place(B, TriggerSamples.SOLDIER, "D4")
	_push_deploy(A, TriggerSamples.SOLDIER, "D1")
	_push_deploy(A, TriggerSamples.HERALD, "B1")
	var expected: Array[String] = [
		"PriorityPassed:B",
		"PriorityPassed:A",
		"PieceDeployed:A",
		"EffectTriggered:A",
		"StackEntryResolved:A",
		"PieceDeployed:A",
		"StackEntryResolved:A",
		"DecisionResolvedAutomatically:A",
		"DecisionResolvedAutomatically:A",
		"StackEntryAdded:A",
	]
	assert_array(EventLog.describe(_pass_twice(B))).contains_exactly(expected)


func test_208_4_3_waiting_trigger_goes_on_top_of_the_stack() -> void:
	_place(B, TriggerSamples.SOLDIER, "D4")
	_push_deploy(A, TriggerSamples.HERALD, "B1")
	var events := _pass_twice(B)
	var added := events[events.size() - 1] as StackEntryAdded
	var triggered := _first_event_of(events, "EffectTriggered") as EffectTriggered
	assert_int(added.stack_entry_id).is_equal(triggered.stack_entry_id)
	assert_int(_engine.get_state().stack[0].stack_entry_id).is_equal(triggered.stack_entry_id)


func test_208_4_5_players_can_answer_the_added_trigger() -> void:
	_place(B, TriggerSamples.SOLDIER, "D4")
	_push_deploy(A, TriggerSamples.HERALD, "B1")
	_pass_twice(B)
	assert_int(_engine.validate(PassPriority.new(B))).is_equal(REASON.NONE)


func test_208_5_1a_trigger_is_added_before_the_active_player_acts_again() -> void:
	_place(B, TriggerSamples.SOLDIER, "D4")
	_push_deploy(A, TriggerSamples.HERALD, "B1")
	_pass_twice(B)
	var state := _engine.get_state()
	assert_int(state.stack.size()).is_equal(1)
	assert_int(state.priority_player).is_equal(B)


func test_208_4_6_active_player_orders_his_own_triggers() -> void:
	var first_id := _end_turn_with_two_beacons()
	var state := _engine.get_state()
	assert_int(state.pending_decision.kind).is_equal(DECISION.ORDER_TRIGGERS)
	assert_array(state.pending_decision.awaited_players).contains_exactly([A])
	var second_id := state.pending_decision.candidate_ids[1]
	var events := _engine.submit(OrderTriggers.new(A, [second_id, first_id]))
	var expected: Array[String] = ["TriggersOrdered:A"]
	for index: int in 2:
		expected.append_array(["DecisionResolvedAutomatically:A", "StackEntryAdded:A"])
	assert_array(EventLog.describe(events)).contains_exactly(expected)
	assert_array(_stack_ids()).contains_exactly([second_id, first_id])


func test_204_5_4_end_of_turn_triggers_ask_for_their_order() -> void:
	var events := _end_turn_events_with_two_beacons()
	var labels := EventLog.describe(events)
	assert_str(labels[labels.size() - 1]).is_equal("DecisionRequested:A")
	var requested := events[events.size() - 1] as DecisionRequested
	assert_int(requested.kind).is_equal(DECISION.ORDER_TRIGGERS)


func test_208_4_6_order_lists_each_awaited_effect_once() -> void:
	var first_id := _end_turn_with_two_beacons()
	var second_id := _engine.get_state().pending_decision.candidate_ids[1]
	var missing: Array[int] = [first_id]
	var repeated: Array[int] = [first_id, first_id]
	var extra: Array[int] = [first_id, second_id, UNKNOWN_ENTRY_ID]
	for order: Array[int] in [missing, repeated, extra]:
		var defects := DuelChecks.rejection_defects(
			_engine, OrderTriggers.new(A, order), REASON.WRONG_TRIGGER_ORDER
		)
		assert_array(defects).is_empty()


func test_208_4_6_only_the_awaited_player_orders() -> void:
	var first_id := _end_turn_with_two_beacons()
	var second_id := _engine.get_state().pending_decision.candidate_ids[1]
	var defects := DuelChecks.rejection_defects(
		_engine, OrderTriggers.new(B, [first_id, second_id]), REASON.PLAYER_NOT_AWAITED
	)
	assert_array(defects).is_empty()


func test_decision_0009_pending_order_refuses_other_intents() -> void:
	_end_turn_with_two_beacons()
	var defects := DuelChecks.rejection_defects(
		_engine, PassPriority.new(B), REASON.DECISION_PENDING
	)
	assert_array(defects).is_empty()


func test_decision_0017_answer_without_pending_decision_is_refused() -> void:
	_engine.start_from_state(_builder.build())
	var order := DuelChecks.rejection_defects(
		_engine, OrderTriggers.new(A, []), REASON.NOT_THE_PENDING_DECISION
	)
	var targets := DuelChecks.rejection_defects(
		_engine, ChooseTargets.new(A), REASON.NOT_THE_PENDING_DECISION
	)
	assert_array(order).is_empty()
	assert_array(targets).is_empty()


func test_208_4_7_opponent_adds_his_triggers_next() -> void:
	_place(A, TriggerSamples.SOLDIER, "D1")
	_place(B, TriggerSamples.SOLDIER, "D5")
	var a_beacon := _place_building(A, TriggerSamples.BEACON, "B2")
	var b_beacon := _place_building(B, TriggerSamples.BEACON, "B4")
	_engine.start_from_state(_builder.build())
	var expected: Array[String] = ["TurnEnded:A", "EffectTriggered:A", "EffectTriggered:B"]
	for side: String in ["A", "B"]:
		expected.append_array(EventLog.repeat("DecisionResolvedAutomatically:" + side, 2))
		expected.append("StackEntryAdded:" + side)
	assert_array(EventLog.describe(_engine.submit(EndTurn.new(A)))).contains_exactly(expected)
	var stack := _engine.get_state().stack
	assert_int(stack[0].source_piece_id).is_equal(a_beacon)
	assert_int(stack[1].source_piece_id).is_equal(b_beacon)


func test_208_4_8_opponent_triggers_resolve_first() -> void:
	_place(A, TriggerSamples.SOLDIER, "D1")
	_place(B, TriggerSamples.SOLDIER, "D5")
	_place_building(A, TriggerSamples.BEACON, "B2")
	_place_building(B, TriggerSamples.BEACON, "B4")
	_engine.start_from_state(_builder.build())
	_engine.submit(EndTurn.new(A))
	var labels := EventLog.describe(_pass_twice(A))
	assert_int(labels.find("ForceModified:B")).is_less(labels.find("ForceModified:A"))


func test_208_2_4_after_triggers_opponent_of_top_owner_answers_first() -> void:
	_place(A, TriggerSamples.SOLDIER, "D1")
	_place(B, TriggerSamples.SOLDIER, "D5")
	_place_building(A, TriggerSamples.BEACON, "B2")
	_place_building(B, TriggerSamples.BEACON, "B4")
	_engine.start_from_state(_builder.build())
	_engine.submit(EndTurn.new(A))
	assert_int(_engine.get_state().priority_player).is_equal(A)


func test_207_5_1b_owner_chooses_among_several_legal_targets() -> void:
	var first_id := _place(B, TriggerSamples.SOLDIER, "B4")
	var second_id := _place(B, TriggerSamples.SOLDIER, "D4")
	_push_deploy(A, TriggerSamples.HERALD, "B1")
	var labels := EventLog.describe(_pass_twice(B))
	assert_str(labels[labels.size() - 1]).is_equal("DecisionRequested:A")
	var decision := _engine.get_state().pending_decision
	assert_int(decision.kind).is_equal(DECISION.CHOOSE_TARGETS)
	assert_array(decision.candidate_ids).contains_exactly([first_id, second_id])
	var events := _engine.submit(_choose(A, [second_id]))
	assert_array(EventLog.describe(events)).contains_exactly(
		["TargetsChosen:A", "StackEntryAdded:A"]
	)
	var entry := _engine.get_state().stack[0]
	assert_int(entry.stack_entry_id).is_equal(decision.subject_stack_entry_id)
	assert_array(entry.target_piece_ids).contains_exactly([second_id])


func test_207_5_2_only_the_owner_of_the_trigger_chooses() -> void:
	var first_id := _ask_herald_targets()
	var defects := DuelChecks.rejection_defects(
		_engine, _choose(B, [first_id]), REASON.PLAYER_NOT_AWAITED
	)
	assert_array(defects).is_empty()


func test_207_5_6_chosen_target_must_be_legal() -> void:
	_ask_herald_targets()
	var own_hero := _engine.get_state().find_hero(A).piece_id
	var defects := DuelChecks.rejection_defects(
		_engine, _choose(A, [own_hero]), REASON.ILLEGAL_TARGET
	)
	assert_array(defects).is_empty()


func test_207_5_10_chosen_targets_respect_the_count() -> void:
	var first_id := _ask_herald_targets()
	var second_id := _engine.get_state().pending_decision.candidate_ids[1]
	var too_many := DuelChecks.rejection_defects(
		_engine, _choose(A, [first_id, second_id]), REASON.WRONG_TARGET_COUNT
	)
	var extra_cell := _choose(A, [first_id])
	extra_cell.target_cells.append(DuelStateBuilder.cell("C3"))
	var wrong_kind := DuelChecks.rejection_defects(_engine, extra_cell, REASON.WRONG_TARGET_COUNT)
	assert_array(too_many).is_empty()
	assert_array(wrong_kind).is_empty()


func test_204_5_3_end_of_turn_triggers_go_on_the_stack() -> void:
	_place(A, TriggerSamples.SOLDIER, "D1")
	_place_building(A, TriggerSamples.BEACON, "B2")
	_engine.start_from_state(_builder.build())
	var expected: Array[String] = [
		"TurnEnded:A",
		"EffectTriggered:A",
		"DecisionResolvedAutomatically:A",
		"DecisionResolvedAutomatically:A",
		"StackEntryAdded:A",
	]
	assert_array(EventLog.describe(_engine.submit(EndTurn.new(A)))).contains_exactly(expected)
	var state := _engine.get_state()
	assert_int(state.phase).is_equal(DuelState.DuelPhase.TURN_END)
	assert_int(state.active_player).is_equal(A)


func test_204_5_5_players_can_answer_end_of_turn_triggers() -> void:
	_place(B, TriggerSamples.SOLDIER, "D5")
	var spell_id := _builder.add_to_hand(B, SPELL_ID)
	_end_turn_with_one_beacon()
	var cast := CastSpell.new(B, spell_id, EssencePayment.new(1))
	cast.target_piece_ids.append(_engine.get_state().piece_at(DuelStateBuilder.cell("D5")).piece_id)
	assert_int(_engine.validate(cast)).is_equal(REASON.NONE)


func test_204_5_6_end_of_turn_stack_resolves_then_the_turn_passes() -> void:
	var soldier_id := _end_turn_with_one_beacon()
	var labels := EventLog.describe(_pass_twice(B))
	var resolved_at := labels.find("ForceModified:A")
	assert_int(resolved_at).is_less(labels.find("ActiveEffectEnded"))
	assert_int(labels.find("ActiveEffectEnded")).is_less(labels.find("TurnStarted:B"))
	assert_int(_force_of(soldier_id)).is_equal(TriggerSamples.SOLDIER_FORCE)


func test_204_5_7_effects_until_end_of_turn_wait_for_an_empty_stack() -> void:
	var soldier_id := _place(A, TriggerSamples.SOLDIER, "D1")
	var effect := ActiveEffect.new()
	effect.affected_piece_id = soldier_id
	effect.effect_kind = EffectDefinition.kind_id(EffectDefinition.EffectKind.MODIFY_FORCE)
	effect.amount = 1
	_builder.add_active_effect(effect)
	_place_building(A, TriggerSamples.BEACON, "B2")
	_engine.start_from_state(_builder.build())
	var labels := EventLog.describe(_engine.submit(EndTurn.new(A)))
	assert_bool(labels.has("ActiveEffectEnded")).is_false()
	assert_int(_engine.get_state().active_effects.size()).is_equal(1)


func _end_turn_events_with_two_beacons() -> Array[DuelEvent]:
	_place(A, TriggerSamples.SOLDIER, "D1")
	_place_building(A, TriggerSamples.BEACON, "B2")
	_place_building(A, TriggerSamples.BEACON, "E2")
	_engine.start_from_state(_builder.build())
	return _engine.submit(EndTurn.new(A))


# Renvoie l'identifiant du premier effet déclenché, que A doit ordonner avec le second.
func _end_turn_with_two_beacons() -> int:
	var events := _end_turn_events_with_two_beacons()
	return (_first_event_of(events, "EffectTriggered") as EffectTriggered).stack_entry_id


# Renvoie la pièce que l'effet de fin du tour renforce.
func _end_turn_with_one_beacon() -> int:
	var soldier_id := _place(A, TriggerSamples.SOLDIER, "D1")
	_place_building(A, TriggerSamples.BEACON, "B2")
	_engine.start_from_state(_builder.build())
	_engine.submit(EndTurn.new(A))
	return soldier_id


# Le Héraut de A arrive face à deux Units ennemies ; renvoie la première.
func _ask_herald_targets() -> int:
	var first_id := _place(B, TriggerSamples.SOLDIER, "B4")
	_place(B, TriggerSamples.SOLDIER, "D4")
	_push_deploy(A, TriggerSamples.HERALD, "B1")
	_pass_twice(B)
	return first_id


func _choose(side: DuelState.PlayerSide, piece_ids: Array[int]) -> ChooseTargets:
	var intent := ChooseTargets.new(side)
	intent.target_piece_ids.assign(piece_ids)
	return intent


func _place(side: DuelState.PlayerSide, definition_id: StringName, cell_name: String) -> int:
	return _builder.place_piece(
		side, Piece.PieceKind.UNIT, DuelStateBuilder.cell(cell_name), definition_id
	)


func _place_building(
	side: DuelState.PlayerSide, definition_id: StringName, cell_name: String
) -> int:
	return _builder.place_piece(
		side, Piece.PieceKind.BUILDING, DuelStateBuilder.cell(cell_name), definition_id
	)


func _push_deploy(side: DuelState.PlayerSide, definition_id: StringName, cell_name: String) -> void:
	var card := _builder.make_card_instance(side, definition_id)
	_builder.push_deploy(card, DuelStateBuilder.cell(cell_name))


# Démarre le moteur s'il ne l'est pas, puis `first` et son adversaire passent (208.3.1).
func _pass_twice(first: DuelState.PlayerSide) -> Array[DuelEvent]:
	if _engine.get_state() == null:
		_engine.start_from_state(_builder.with_priority_player(first).build())
	return DuelChecks.pass_twice(_engine, first)


func _stack_ids() -> Array[int]:
	var ids: Array[int] = []
	for entry: StackEntry in _engine.get_state().stack:
		ids.append(entry.stack_entry_id)
	return ids


func _first_event_of(events: Array[DuelEvent], class_label: String) -> DuelEvent:
	for event: DuelEvent in events:
		var script: Script = event.get_script()
		if script.get_global_name() == class_label:
			return event
	return null


func _force_of(piece_id: int) -> int:
	var state := _engine.get_state()
	return ForceRules.current_force(state, state.find_piece(piece_id))
