extends GdUnitTestSuite
## Effets déclenchés d'un Gear (ruleset 0.54, 207.3.12 à 207.3.12c, 207.3.7 ; décision 0060) : le
## Gear déclenche tant qu'il est attaché à une Unit en jeu, pour son propre joueur, et son effet a
## lieu même si le Gear est détaché ou l'Unit partie ensuite.

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const SOLDIER: StringName = TriggerSamples.SOLDIER  # Force 2
const GIANT: StringName = TriggerSamples.GIANT  # Force 5
const GRIMOIRE: StringName = NamedTriggerSamples.GRIMOIRE
const LANTERN: StringName = NamedTriggerSamples.LANTERN
const DECK_SIZE: int = 4

var _catalog: Catalog
var _builder: DuelStateBuilder
var _events: Array[DuelEvent] = []


func before_test() -> void:
	_catalog = NamedTriggerSamples.catalog()
	_builder = HandEffectSamples.builder(_catalog)
	_events.clear()
	for index: int in DECK_SIZE:
		_builder.add_to_deck(A, SOLDIER)
		_builder.add_to_deck(B, SOLDIER)


func test_207_3_12_gear_can_carry_a_triggered_effect() -> void:
	for data: Dictionary in NamedTriggerSamples.card_data():
		assert_array(Array(CardDefinition.from_dict(data).find_errors())).is_empty()
	var effects := _catalog.triggerable_effects(GRIMOIRE)
	assert_int(effects.size()).is_equal(1)
	assert_int(effects[0].timing).is_equal(EffectDefinition.EffectTiming.TRIGGERED)
	assert_int(effects[0].trigger).is_equal(EffectDefinition.TriggerEvent.DESTROYS_DEFENDER)
	assert_int(_catalog.get_card(GRIMOIRE).card_type).is_equal(CardDefinition.CardType.GEAR)


func test_207_3_12a_gear_triggers_while_attached_to_a_unit_in_play() -> void:
	var unit_id := _place(A, SOLDIER, "B2")
	_builder.attach_gear(unit_id, LANTERN)
	var triggered := _end_turn_of_a().filter(
		func(event: DuelEvent) -> bool: return event is EffectTriggered
	)
	assert_int(triggered.size()).is_equal(1)
	var event: EffectTriggered = triggered[0]
	assert_int(event.source_piece_id).is_equal(unit_id)


func test_207_3_12a_gear_that_is_not_attached_does_not_trigger() -> void:
	_place(A, SOLDIER, "B2")
	_builder.add_to_hand(A, LANTERN)
	_builder.add_to_discard(A, LANTERN)
	var labels := EventLog.describe(_end_turn_of_a())
	assert_bool(labels.has("EffectTriggered:A")).is_false()


func test_207_3_12a_gear_of_a_unit_that_left_the_board_does_not_trigger() -> void:
	var unit_id := _place(A, SOLDIER, "B2")
	_builder.attach_gear(unit_id, GRIMOIRE)
	var state := _builder.build()
	var piece := state.find_piece(unit_id)
	CombatRules.destroy_piece(state, piece, _events)
	_events.clear()
	TriggerRules.trigger(state, piece, EffectDefinition.TriggerEvent.DESTROYS_DEFENDER, _events)
	assert_array(_events).is_empty()


func test_207_3_12b_gear_effect_belongs_to_the_player_who_owns_the_gear() -> void:
	_place(A, SOLDIER, "B2")
	var enemy_id := _place(B, SOLDIER, "D4")
	var gear_id := _builder.attach_gear(enemy_id, LANTERN)
	var state := _builder.build()
	TriggerRules.trigger_end_of_turn(state, _events)
	assert_int(state.waiting_triggers.size()).is_equal(1)
	assert_int(state.waiting_triggers[0].owner).is_equal(B)
	assert_int(state.waiting_triggers[0].source_card_instance_id).is_equal(gear_id)
	assert_array(EventLog.describe(_events)).contains_exactly(["EffectTriggered:B"])


func test_207_3_12c_effect_already_triggered_happens_though_the_gear_was_detached() -> void:
	var state := _trigger_grimoire()
	state.find_piece(state.waiting_triggers[0].source_piece_id).attached_gear = null
	var labels := _resolve(state)
	assert_array(labels).contains_exactly(
		["PriorityPassed:B", "CardDrawn:A", "StackEntryResolved:A"]
	)


func test_207_3_12c_effect_already_triggered_happens_though_the_unit_left_the_board() -> void:
	var state := _trigger_grimoire()
	var unit := state.find_piece(state.waiting_triggers[0].source_piece_id)
	CombatRules.destroy_piece(state, unit, _events)
	assert_object(state.find_piece(unit.piece_id)).is_null()
	var labels := _resolve(state)
	assert_array(labels).contains_exactly(
		["PriorityPassed:B", "CardDrawn:A", "StackEntryResolved:A"]
	)


func test_207_3_7_once_per_turn_of_a_gear_is_counted_by_the_gear_card() -> void:
	var first_unit := _place(A, SOLDIER, "B2")
	var second_unit := _place(B, SOLDIER, "D4")
	var first_gear := _builder.attach_gear(first_unit, LANTERN)
	var second_gear := _builder.attach_gear(second_unit, LANTERN)
	var state := _builder.build()
	TriggerRules.trigger_end_of_turn(state, _events)
	TriggerRules.add_waiting_triggers(state, _events)
	assert_array(state.once_per_turn_effects).contains_exactly_in_any_order(
		[Vector2i(first_gear, 0), Vector2i(second_gear, 0)]
	)
	_events.clear()
	TriggerRules.trigger_end_of_turn(state, _events)
	TriggerRules.add_waiting_triggers(state, _events)
	assert_array(EventLog.describe(_events)).contains_exactly(
		["EffectTriggered:A", "EffectTriggered:B", "TriggerSkipped:A", "TriggerSkipped:B"]
	)


# Le Géant de A, porteur d'un Grimoire, détruit un Soldat de B : l'effet du Gear attend.
func _trigger_grimoire() -> DuelState:
	var attacker_id := _place(A, GIANT, "B2")
	_builder.attach_gear(attacker_id, GRIMOIRE)
	var defender_id := _place(B, SOLDIER, "B3")
	var state := _builder.build()
	CombatRules.resolve_attack(
		state, state.find_piece(attacker_id), state.find_piece(defender_id), _events
	)
	assert_int(state.waiting_triggers.size()).is_equal(1)
	return state


func _resolve(state: DuelState) -> Array[String]:
	var engine := DuelEngine.new(_catalog)
	engine.start_from_state(state)
	TriggerRules.add_waiting_triggers(state, _events)
	return EventLog.describe(DuelChecks.pass_once(engine, B))


func _end_turn_of_a() -> Array[DuelEvent]:
	var engine := DuelEngine.new(_catalog)
	engine.start_from_state(_builder.build())
	return engine.submit(EndTurn.new(A))


func _place(side: DuelState.PlayerSide, definition_id: StringName, cell: String) -> int:
	return NamedTriggerSamples.place(_builder, side, Piece.PieceKind.UNIT, definition_id, cell)
