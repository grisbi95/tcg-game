extends GdUnitTestSuite
## Condition « si » d'un effet déclenché (ruleset 0.54, 207.3.13 à 207.3.13b, 204.3.12a ; décisions
## 0060 et 0065) : comparaison sur une valeur du jeu, lue à l'événement, effet non déclenché si elle
## est fausse, jamais relue à la résolution.

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const SOLDIER: StringName = TriggerSamples.SOLDIER
const START: EffectDefinition.TriggerEvent = EffectDefinition.TriggerEvent.START_OF_OWN_TURN
const LIMIT: int = NamedTriggerSamples.PILLEUSE_HAND_LIMIT  # Pilleuse : une carte ou moins

var _catalog: Catalog
var _builder: DuelStateBuilder
var _events: Array[DuelEvent] = []


func before_test() -> void:
	_catalog = GameValueSamples.catalog()
	_builder = HandEffectSamples.builder(_catalog)
	_events.clear()


func test_207_3_13_condition_is_read_when_the_event_occurs() -> void:
	var condition := EffectCondition.from_dict(CatalogSamples.hand_size_condition("at_most", LIMIT))
	var state := _builder.build()
	var reading := _reading(A)
	for hand_size: int in [0, LIMIT, LIMIT + 1]:
		state.get_player(A).hand.clear()
		for index: int in hand_size:
			state.get_player(A).hand.append(_builder.make_card_instance(A, SOLDIER))
		assert_bool(ValueRules.condition_holds(state, condition, reading)).is_equal(
			hand_size <= LIMIT
		)
	assert_bool(ValueRules.condition_holds(state, null, reading)).is_true()


func test_207_3_13_condition_compares_the_value_at_least_or_at_most() -> void:
	var at_least := EffectCondition.from_dict(CatalogSamples.hand_size_condition("at_least", LIMIT))
	var at_most := EffectCondition.from_dict(CatalogSamples.hand_size_condition("at_most", LIMIT))
	var state := _builder.build()
	var reading := _reading(A)
	for hand_size: int in [0, LIMIT, LIMIT + 1]:
		state.get_player(A).hand.clear()
		for index: int in hand_size:
			state.get_player(A).hand.append(_builder.make_card_instance(A, SOLDIER))
		assert_bool(ValueRules.condition_holds(state, at_least, reading)).is_equal(
			hand_size >= LIMIT
		)
		assert_bool(ValueRules.condition_holds(state, at_most, reading)).is_equal(
			hand_size <= LIMIT
		)


func test_207_3_13_condition_counts_the_pieces_of_a_filter_at_the_event() -> void:
	_builder.place_piece(
		A, Piece.PieceKind.BUILDING, DuelStateBuilder.cell("A1"), GameValueSamples.CROWD
	)
	for cell_name: String in ["B2", "C2"]:
		_builder.place_piece(A, Piece.PieceKind.UNIT, DuelStateBuilder.cell(cell_name), SOLDIER)
	_builder.place_piece(B, Piece.PieceKind.UNIT, DuelStateBuilder.cell("D4"), SOLDIER)
	var state := _builder.build()
	TriggerRules.trigger_for_player(state, A, START, _events)
	assert_array(_events).is_empty()  # deux Units alliées : l'Unit ennemie ne compte pas
	DuelStateBuilder.place_unit_in(state, A, SOLDIER, "D2")
	TriggerRules.trigger_for_player(state, A, START, _events)
	assert_array(EventLog.describe(_events)).contains_exactly(["EffectTriggered:A"])


func test_207_3_13_condition_reads_the_cost_of_the_spell_of_the_event() -> void:
	_builder.place_piece(
		A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B2"), GameValueSamples.HAGGLER
	)
	var cheap_id := _builder.add_to_hand(A, HandEffectSamples.DRAW_ONE)
	var big_id := _builder.add_to_hand(A, GameValueSamples.BIG_SPELL)
	for index: int in 2:
		_builder.add_to_deck(A, SOLDIER)
	var engine := DuelEngine.new(_catalog)
	engine.start_from_state(_builder.build())
	var cheap_events := engine.submit(HandEffectSamples.cast(A, cheap_id))
	assert_array(EventLog.describe(cheap_events)).not_contains("EffectTriggered:A")
	DuelChecks.pass_until_stack_empty(engine)
	var big_cast := CastSpell.new(A, big_id, EssencePayment.new(GameValueSamples.BIG_COST))
	assert_array(EventLog.describe(engine.submit(big_cast))).contains("EffectTriggered:A")


func test_207_3_13_condition_reads_the_cost_of_a_countered_spell_with_its_x() -> void:
	_builder.place_piece(
		A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B2"), GameValueSamples.MOURNING_MERCHANT
	)
	var cheap := _builder.push_spell(_builder.make_card_instance(B, HandEffectSamples.DRAW_ONE))
	var surge := _builder.make_card_instance(B, GameValueSamples.SURGE)
	var costly := _builder.push_spell(surge, [], GameValueSamples.BIG_COST)
	var small := _builder.push_spell(_builder.make_card_instance(B, GameValueSamples.SURGE), [], 1)
	var state := _builder.build()
	for spell_id: int in [cheap, small]:
		_counter(state, spell_id)
	assert_array(state.waiting_triggers).is_empty()
	_counter(state, costly)
	assert_array(state.waiting_triggers).has_size(1)


func test_decision_0065_a_value_that_cannot_be_read_does_not_fulfil_the_condition() -> void:
	var state := _builder.build()
	var strong := EffectCondition.from_dict(
		CatalogSamples.condition({"kind": "source_force"}, "at_most", 99)
	)
	assert_bool(ValueRules.condition_holds(state, strong, _reading(A))).is_false()
	var cost := EffectCondition.from_dict(
		CatalogSamples.condition({"kind": "event_spell_cost"}, "at_most", 99)
	)
	assert_bool(ValueRules.condition_holds(state, cost, _reading(A))).is_false()


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
	data["condition"] = CatalogSamples.hand_size_condition("at_most", LIMIT)
	var errors := EffectText.from_dict(data).find_errors()
	assert_bool(CatalogSamples.mentions(errors, "207.3.13 : condition ne vaut que")).is_true()
	data["timing"] = "triggered"
	data["trigger"] = "start_of_own_turn"
	assert_array(Array(EffectText.from_dict(data).find_errors())).is_empty()


func test_207_3_13_condition_is_a_closed_comparison_with_a_required_amount() -> void:
	var unknown_value := CatalogSamples.condition({"kind": "hand_empty"}, "at_most", 0)
	var unknown := EffectCondition.from_dict(unknown_value)
	assert_bool(CatalogSamples.mentions(unknown.find_errors(), "« hand_empty » inconnu")).is_true()
	var unknown_comparison := CatalogSamples.condition({"kind": "hand_size"}, "equal", 0)
	var errors := EffectCondition.from_dict(unknown_comparison).find_errors()
	assert_bool(CatalogSamples.mentions(errors, "« equal » inconnu")).is_true()
	var missing := EffectCondition.from_dict(
		{"value": {"kind": "hand_size"}, "comparison": "at_most"}
	)
	assert_bool(CatalogSamples.mentions(missing.find_errors(), "« amount » absent")).is_true()
	var without_value := EffectCondition.from_dict({"comparison": "at_most", "amount": 1})
	assert_bool(CatalogSamples.mentions(without_value.find_errors(), "« value » absent")).is_true()
	var negative := CatalogSamples.hand_size_condition("at_most", -1)
	assert_array(Array(EffectCondition.from_dict(negative).find_errors())).is_not_empty()
	var data := CatalogSamples.hand_size_condition("at_most", 1)
	data["extra"] = 2
	(
		assert_bool(CatalogSamples.mentions(EffectCondition.from_dict(data).find_errors(), "extra"))
		. is_true()
	)


func test_207_3_13_pilleuse_hero_reads_its_condition_from_the_json() -> void:
	var hero := HeroDefinition.from_dict(NamedTriggerSamples.hero_data(&"x_hero", false))
	assert_array(Array(hero.find_errors())).is_empty()
	var condition := hero.triggered[0].condition
	assert_int(condition.value.kind).is_equal(GameValue.Kind.HAND_SIZE)
	assert_int(condition.comparison).is_equal(EffectCondition.Comparison.AT_MOST)
	assert_int(condition.amount).is_equal(LIMIT)


func _reading(side: DuelState.PlayerSide) -> ValueReading:
	var reading := ValueReading.new()
	reading.owner = side
	return reading


func _counter(state: DuelState, spell_id: int) -> void:
	var entry := StackEntry.new()
	entry.kind = StackEntry.StackEntryKind.SPELL
	entry.owner = A
	entry.target_stack_entry_ids.append(spell_id)
	var effect := CatalogSamples.effect_from(CatalogSamples.counter_spell_effect())
	EffectRules.resolve_effect(state, entry, effect, _events)
