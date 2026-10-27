extends GdUnitTestSuite
## Effets déclenchés : Arrivée, Dernier souffle, appartenance, « une fois par tour » (ruleset
## 0.41, sections 207.3, 210.3 ; 207.5.9 ; décisions 0004 et 0017).
##
## Les déploiements et actions sont posés sur la pile par le builder, comme des annonces déjà
## faites ; les cartes viennent de TriggerSamples.

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B

var _builder: DuelStateBuilder
var _engine: DuelEngine


func before_test() -> void:
	var catalog := TriggerSamples.catalog()
	_builder = DuelStateBuilder.new(DuelConfig.new(), catalog)
	_engine = DuelEngine.new(catalog)


func test_decision_0017_trigger_samples_are_valid() -> void:
	for data: Dictionary in TriggerSamples.card_data():
		assert_array(CardDefinition.from_dict(data).find_errors()).is_empty()


func test_210_3_1_arrival_triggers_when_the_piece_arrives() -> void:
	_place(B, TriggerSamples.SOLDIER, "B4")
	_push_deploy(A, TriggerSamples.HERALD, "B1")
	var events := _pass_once(B)
	var expected: Array[String] = [
		"PriorityPassed:B",
		"PieceDeployed:A",
		"EffectTriggered:A",
		"StackEntryResolved:A",
		"DecisionResolvedAutomatically:A",
		"DecisionResolvedAutomatically:A",
		"StackEntryAdded:A",
	]
	assert_array(EventLog.describe(events)).contains_exactly(expected)


func test_210_3_1b_arrival_effect_goes_on_the_stack() -> void:
	var soldier_id := _place(B, TriggerSamples.SOLDIER, "B4")
	_push_deploy(A, TriggerSamples.HERALD, "B1")
	_pass_once(B)
	var stack := _engine.get_state().stack
	assert_int(stack.size()).is_equal(1)
	assert_int(stack[0].kind).is_equal(StackEntry.StackEntryKind.TRIGGERED_EFFECT)
	assert_array(stack[0].target_piece_ids).contains_exactly([soldier_id])


func test_208_3_2a_trigger_resolves_like_an_announcement() -> void:
	var soldier_id := _place(B, TriggerSamples.SOLDIER, "B4")
	_push_deploy(A, TriggerSamples.HERALD, "B1")
	_pass_once(B)
	var labels := EventLog.describe(_pass_once(B))
	assert_array(labels).contains_exactly(
		["PriorityPassed:B", "ForceModified:B", "StackEntryResolved:A"]
	)
	assert_int(_force_of(soldier_id)).is_equal(
		TriggerSamples.SOLDIER_FORCE + TriggerSamples.HERALD_MALUS
	)


func test_210_3_1a_unit_entering_attacking_arrives() -> void:
	_place(B, TriggerSamples.SOLDIER, "B1")
	var other_id := _place(B, TriggerSamples.SOLDIER, "D4")
	_push_deploy(A, TriggerSamples.HERALD, "B1")
	var labels := EventLog.describe(_pass_once(B))
	labels.append_array(EventLog.describe(_pass_once(B)))
	assert_bool(labels.has("PieceEnteredAttacking:A")).is_true()
	assert_bool(labels.has("EffectTriggered:A")).is_true()
	assert_array(_engine.get_state().stack[0].target_piece_ids).contains_exactly([other_id])


func test_210_3_2_last_breath_triggers_when_the_piece_is_destroyed() -> void:
	_place(A, TriggerSamples.SOLDIER, "D1")
	var labels := EventLog.describe(_destroy_martyr())
	var destroyed_at := labels.find("PieceDestroyed:A")
	assert_int(destroyed_at).is_greater_equal(0)
	assert_str(labels[destroyed_at + 1]).is_equal("EffectTriggered:A")
	assert_str(labels[labels.size() - 1]).is_equal("StackEntryAdded:A")


func test_210_3_2b_last_breath_happens_after_the_piece_left_the_board() -> void:
	var soldier_id := _place(A, TriggerSamples.SOLDIER, "D1")
	_destroy_martyr()
	_pass_once(B)
	assert_int(_force_of(soldier_id)).is_equal(
		TriggerSamples.SOLDIER_FORCE + TriggerSamples.MARTYR_BONUS
	)
	var effect := _engine.get_state().active_effects[0]
	assert_int(effect.duration).is_equal(ActiveEffect.EffectDuration.WHILE_PIECE_IN_PLAY)


func test_207_3_2_triggered_effect_is_added_to_the_stack_before_it_happens() -> void:
	var soldier_id := _place(B, TriggerSamples.SOLDIER, "B4")
	_push_deploy(A, TriggerSamples.HERALD, "B1")
	_pass_once(B)
	var state := _engine.get_state()
	assert_int(state.stack.size()).is_equal(1)
	assert_int(state.stack[0].kind).is_equal(StackEntry.StackEntryKind.TRIGGERED_EFFECT)
	assert_array(state.active_effects).is_empty()
	assert_int(_force_of(soldier_id)).is_equal(TriggerSamples.SOLDIER_FORCE)


func test_207_3_3_triggered_effect_happens_though_its_piece_left_the_board() -> void:
	var soldier_id := _place(B, TriggerSamples.SOLDIER, "B4")
	_push_deploy(A, TriggerSamples.HERALD, "B1")
	_pass_once(B)
	var state := _engine.get_state()
	var herald := state.find_piece(state.stack[0].source_piece_id)
	CombatRules.destroy_piece(state, herald, [] as Array[DuelEvent])
	assert_object(state.find_piece(herald.piece_id)).is_null()
	var labels := EventLog.describe(_pass_once(B))
	assert_array(labels).contains(["ForceModified:B"])
	assert_int(_force_of(soldier_id)).is_equal(
		TriggerSamples.SOLDIER_FORCE + TriggerSamples.HERALD_MALUS
	)


func test_207_3_4_trigger_belongs_to_the_owner_of_its_card() -> void:
	_place(A, TriggerSamples.SOLDIER, "D1")
	_destroy_martyr()
	var state := _engine.get_state()
	assert_int(state.stack[0].owner).is_equal(A)
	assert_int(state.priority_player).is_equal(B)


func test_207_5_9_trigger_without_legal_target_is_not_added() -> void:
	_push_deploy(A, TriggerSamples.HERALD, "B1")
	var labels := EventLog.describe(_pass_once(B))
	assert_str(labels[labels.size() - 1]).is_equal("TriggerSkipped:A")
	var state := _engine.get_state()
	assert_array(state.stack).is_empty()
	assert_int(state.priority_player).is_equal(A)


func test_207_5_10_trigger_without_enough_legal_targets_is_not_added() -> void:
	_place(B, TriggerSamples.SOLDIER, "B4")
	_push_deploy(A, TriggerSamples.DOUBLE_HERALD, "B1")
	var labels := EventLog.describe(_pass_once(B))
	assert_str(labels[labels.size() - 1]).is_equal("TriggerSkipped:A")
	assert_array(_engine.get_state().stack).is_empty()


func test_207_3_5a_once_per_turn_trigger_already_used_adds_nothing() -> void:
	_place(A, TriggerSamples.SOLDIER, "D1")
	var beacon_id := _place_building(A, TriggerSamples.ONCE_BEACON, "B2")
	var state := _builder.build()
	state.once_per_turn_effects.append(
		Vector2i(state.find_piece(beacon_id).card.card_instance_id, 0)
	)
	_engine.start_from_state(state)
	var labels := EventLog.describe(_engine.submit(EndTurn.new(A)))
	assert_bool(labels.has("TriggerSkipped:A")).is_true()
	assert_bool(labels.has("StackEntryAdded:A")).is_false()
	assert_int(_engine.get_state().active_player).is_equal(B)


func test_207_3_6_once_per_turn_counts_at_addition() -> void:
	_place(A, TriggerSamples.SOLDIER, "D1")
	var beacon_id := _place_building(A, TriggerSamples.ONCE_BEACON, "B2")
	var state := _builder.build()
	var card_id := state.find_piece(beacon_id).card.card_instance_id
	var events: Array[DuelEvent] = []
	TriggerRules.trigger(
		state, state.find_piece(beacon_id), EffectDefinition.TriggerEvent.END_OF_TURN, events
	)
	assert_array(state.once_per_turn_effects).is_empty()
	TriggerRules.add_waiting_triggers(state, events)
	assert_int(state.stack.size()).is_equal(1)
	assert_array(state.once_per_turn_effects).contains_exactly([Vector2i(card_id, 0)])


func test_207_3_7_once_per_turn_count_is_kept_per_card() -> void:
	_place(A, TriggerSamples.SOLDIER, "D1")
	_place_building(A, TriggerSamples.ONCE_BEACON, "B2")
	_place_building(A, TriggerSamples.ONCE_BEACON, "D2")
	var state := _builder.build()
	_engine.start_from_state(state)
	var labels := EventLog.describe(_engine.submit(EndTurn.new(A)))
	assert_bool(labels.has("TriggerSkipped:A")).is_false()
	assert_int(state.pending_decision.candidate_ids.size()).is_equal(2)


func test_207_3_8_once_per_turn_count_lasts_from_turn_start_to_turn_end() -> void:
	_place(A, TriggerSamples.SOLDIER, "D1")
	var beacon_id := _place_building(A, TriggerSamples.ONCE_BEACON, "B2")
	var state := _builder.with_phase(DuelState.DuelPhase.TURN_END).build()
	var beacon := state.find_piece(beacon_id)
	var events: Array[DuelEvent] = []
	TriggerRules.trigger(state, beacon, EffectDefinition.TriggerEvent.END_OF_TURN, events)
	TriggerRules.add_waiting_triggers(state, events)
	events.clear()
	TriggerRules.trigger(state, beacon, EffectDefinition.TriggerEvent.END_OF_TURN, events)
	TriggerRules.add_waiting_triggers(state, events)
	assert_array(EventLog.describe(events)).contains_exactly(
		["EffectTriggered:A", "TriggerSkipped:A"]
	)
	_engine.start_from_state(state)
	_pass_once(B)
	assert_int(state.active_player).is_equal(B)
	assert_array(state.once_per_turn_effects).is_empty()


func test_207_3_9_once_per_turn_count_resets_at_each_turn_start() -> void:
	_place(A, TriggerSamples.SOLDIER, "D1")
	_place_building(A, TriggerSamples.ONCE_BEACON, "B2")
	_engine.start_from_state(_builder.build())
	_engine.submit(EndTurn.new(A))
	var state := _engine.get_state()
	assert_int(state.active_player).is_equal(B)
	assert_array(state.once_per_turn_effects).is_empty()


func test_207_3_10_count_follows_the_card_when_it_changes_zone() -> void:
	_place(A, TriggerSamples.SOLDIER, "D1")
	var beacon_id := _place_building(A, TriggerSamples.ONCE_BEACON, "B2")
	var state := _builder.build()
	var events: Array[DuelEvent] = []
	TriggerRules.trigger(
		state, state.find_piece(beacon_id), EffectDefinition.TriggerEvent.END_OF_TURN, events
	)
	TriggerRules.add_waiting_triggers(state, events)
	var beacon_card := state.find_piece(beacon_id).card
	CombatRules.destroy_piece(state, state.find_piece(beacon_id), [] as Array[DuelEvent])
	assert_array(DuelChecks.card_ids(state.get_player(A).discard)).contains(
		[beacon_card.card_instance_id]
	)
	assert_array(state.once_per_turn_effects).contains_exactly(
		[Vector2i(beacon_card.card_instance_id, 0)]
	)


func test_207_3_10a_card_back_in_play_keeps_its_count() -> void:
	_place(A, TriggerSamples.SOLDIER, "D1")
	var beacon_id := _place_building(A, TriggerSamples.ONCE_BEACON, "B2")
	var state := _builder.build()
	var events: Array[DuelEvent] = []
	var first := state.find_piece(beacon_id)
	TriggerRules.trigger(state, first, EffectDefinition.TriggerEvent.END_OF_TURN, events)
	TriggerRules.add_waiting_triggers(state, events)
	state.pieces.erase(first)
	var second := Piece.new()
	second.piece_id = state.allocate_piece_id()
	second.kind = Piece.PieceKind.BUILDING
	second.cell = DuelStateBuilder.cell("D2")
	second.card = first.card
	state.pieces.append(second)
	events.clear()
	TriggerRules.trigger(state, second, EffectDefinition.TriggerEvent.END_OF_TURN, events)
	TriggerRules.add_waiting_triggers(state, events)
	assert_array(EventLog.describe(events)).contains_exactly(
		["EffectTriggered:A", "TriggerSkipped:A"]
	)


# Le Géant de B, joueur actif, attaque le Martyr de A en B2 et le détruit.
func _destroy_martyr() -> Array[DuelEvent]:
	_place(A, TriggerSamples.MARTYR, "B2")
	var giant_id := _place(B, TriggerSamples.GIANT, "B3")
	_builder.with_active_player(B)
	_builder.push_normal_action(giant_id, DuelStateBuilder.cell("B2"))
	return _pass_once(A)


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


# Démarre le moteur s'il ne l'est pas, puis `first` passe : la pile se résout (208.3.1).
func _pass_once(first: DuelState.PlayerSide) -> Array[DuelEvent]:
	if _engine.get_state() == null:
		_engine.start_from_state(_builder.with_priority_player(first).build())
	return DuelChecks.pass_once(_engine, first)


func _force_of(piece_id: int) -> int:
	var state := _engine.get_state()
	return ForceRules.current_force(state, state.find_piece(piece_id))
