extends GdUnitTestSuite
## Condition « si » d'un effet déclenché (ruleset 0.54, 207.3.13 à 207.3.13b, 204.3.12a ; décision
## 0060) : lue à l'événement, effet non déclenché si elle est fausse, jamais relue à la résolution.

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const SOLDIER: StringName = TriggerSamples.SOLDIER
const START: EffectDefinition.TriggerEvent = EffectDefinition.TriggerEvent.START_OF_OWN_TURN
const LIMIT: int = NamedTriggerSamples.PILLEUSE_HAND_LIMIT  # Pilleuse : une carte ou moins

var _catalog: Catalog
var _builder: DuelStateBuilder
var _events: Array[DuelEvent] = []


func before_test() -> void:
	_catalog = NamedTriggerSamples.catalog()
	_builder = HandEffectSamples.builder(_catalog)
	_events.clear()


func test_207_3_13_condition_is_read_when_the_event_occurs() -> void:
	var condition := EffectCondition.from_dict({"kind": "hand_size_at_most", "amount": LIMIT})
	var state := _builder.build()
	for hand_size: int in [0, LIMIT, LIMIT + 1]:
		state.get_player(A).hand.clear()
		for index: int in hand_size:
			state.get_player(A).hand.append(_builder.make_card_instance(A, SOLDIER))
		assert_bool(EffectRules.condition_holds(state, condition, A)).is_equal(hand_size <= LIMIT)
	assert_bool(EffectRules.condition_holds(state, null, A)).is_true()


func test_207_3_13_condition_reads_the_hand_of_the_player_who_owns_the_effect() -> void:
	_builder.with_hero_definition(A, NamedTriggerSamples.PILLEUSE)
	_builder.add_to_hand(B, SOLDIER)
	_builder.add_to_hand(B, SOLDIER)
	var state := _builder.build()
	TriggerRules.trigger_for_player(state, A, START, _events)
	assert_array(EventLog.describe(_events)).contains_exactly(["EffectTriggered:A"])


func test_207_3_13a_false_condition_does_not_trigger_the_effect() -> void:
	_builder.with_hero_definition(A, NamedTriggerSamples.PILLEUSE)
	for index: int in LIMIT + 1:
		_builder.add_to_hand(A, SOLDIER)
	var state := _builder.build()
	TriggerRules.trigger_for_player(state, A, START, _events)
	TriggerRules.add_waiting_triggers(state, _events)
	assert_array(_events).is_empty()
	assert_array(state.waiting_triggers).is_empty()
	assert_array(state.stack).is_empty()


func test_207_3_13a_false_condition_does_not_count_for_once_per_turn() -> void:
	_builder.with_hero_definition(A, NamedTriggerSamples.ONCE_PILLEUSE)
	for index: int in LIMIT + 1:
		_builder.add_to_hand(A, SOLDIER)
	var state := _builder.build()
	TriggerRules.trigger_for_player(state, A, START, _events)
	TriggerRules.add_waiting_triggers(state, _events)
	assert_array(state.once_per_turn_texts).is_empty()
	state.get_player(A).hand.pop_back()
	TriggerRules.trigger_for_player(state, A, START, _events)
	TriggerRules.add_waiting_triggers(state, _events)
	assert_array(EventLog.describe(_events)).contains_exactly(
		["EffectTriggered:A", "DecisionResolvedAutomatically:A", "StackEntryAdded:A"]
	)
	assert_array(state.once_per_turn_texts).has_size(1)


func test_207_3_13b_condition_is_not_read_again_at_resolution() -> void:
	_builder.with_hero_definition(A, NamedTriggerSamples.PILLEUSE)
	for index: int in NamedTriggerSamples.PILLEUSE_DRAWN:
		_builder.add_to_deck(A, SOLDIER)
	var state := _builder.build()
	TriggerRules.trigger_for_player(state, A, START, _events)
	TriggerRules.add_waiting_triggers(state, _events)
	for index: int in LIMIT + 2:
		state.get_player(A).hand.append(_builder.make_card_instance(A, SOLDIER))
	var hand_before := state.get_player(A).hand.size()
	var engine := DuelEngine.new(_catalog)
	engine.start_from_state(state)
	var labels := EventLog.describe(DuelChecks.pass_once(engine, B))
	assert_array(labels).contains_exactly(
		["PriorityPassed:B", "CardDrawn:A", "CardDrawn:A", "StackEntryResolved:A"]
	)
	assert_int(state.get_player(A).hand.size()).is_equal(
		hand_before + NamedTriggerSamples.PILLEUSE_DRAWN
	)


func test_207_3_13_condition_is_only_for_triggered_texts() -> void:
	var data := CatalogSamples.flat_text_of(HandEffectSamples.draw_effect(1))
	data["condition"] = {"kind": "hand_size_at_most", "amount": LIMIT}
	var errors := EffectText.from_dict(data).find_errors()
	assert_bool(CatalogSamples.mentions(errors, "207.3.13 : condition ne vaut que")).is_true()
	data["timing"] = "triggered"
	data["trigger"] = "start_of_own_turn"
	assert_array(Array(EffectText.from_dict(data).find_errors())).is_empty()


func test_207_3_13_condition_kind_is_a_closed_list_with_a_required_amount() -> void:
	var unknown := EffectCondition.from_dict({"kind": "hand_empty", "amount": 0})
	assert_bool(CatalogSamples.mentions(unknown.find_errors(), "« hand_empty » inconnu")).is_true()
	var missing := EffectCondition.from_dict({"kind": "hand_size_at_most"})
	assert_bool(CatalogSamples.mentions(missing.find_errors(), "« amount » absent")).is_true()
	var negative := EffectCondition.from_dict({"kind": "hand_size_at_most", "amount": -1})
	assert_array(Array(negative.find_errors())).is_not_empty()
	var data := {"kind": "hand_size_at_most", "amount": 1, "extra": 2}
	(
		assert_bool(CatalogSamples.mentions(EffectCondition.from_dict(data).find_errors(), "extra"))
		. is_true()
	)


func test_207_3_13_pilleuse_hero_reads_its_condition_from_the_json() -> void:
	var hero := HeroDefinition.from_dict(NamedTriggerSamples.hero_data(&"x_hero", false))
	assert_array(Array(hero.find_errors())).is_empty()
	var condition := hero.triggered[0].condition
	assert_int(condition.kind).is_equal(EffectCondition.ConditionKind.HAND_SIZE_AT_MOST)
	assert_int(condition.amount).is_equal(LIMIT)
