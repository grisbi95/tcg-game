extends GdUnitTestSuite
## « Une fois par tour » décomptée par effet (ruleset 0.55, 207.3.7, 207.3.7b, 207.3.7c ; 207.3.5,
## 207.3.9, 212.2.5 ; décisions 0062 et 0250 du ruleset). MIXED et TWICE_ONCE viennent de
## FilterSamples : deux effets déclenchés par l'annonce d'un Spell de leur joueur, dont un ou deux
## portent la mention.

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const ANNOUNCED := EffectDefinition.TriggerEvent.OWN_SPELL_ANNOUNCED
const FIRST_EFFECT: int = 0
const SECOND_EFFECT: int = 1

var _builder: DuelStateBuilder


func before_test() -> void:
	_builder = HandEffectSamples.builder(FilterSamples.catalog())


func test_207_3_7b_once_per_turn_limits_only_the_effect_that_carries_it() -> void:
	var card_id := _card_of(_place(FilterSamples.MIXED, "B2"))
	var state := _builder.build()
	_announce(state)
	assert_int(state.stack.size()).is_equal(2)
	assert_array(state.once_per_turn_effects).contains_exactly([Vector2i(card_id, FIRST_EFFECT)])
	var labels := _announce(state)
	assert_int(labels.count("TriggerSkipped:A")).is_equal(1)
	assert_int(labels.count("StackEntryAdded:A")).is_equal(1)
	assert_int(state.stack.size()).is_equal(3)
	assert_int(state.stack[2].effect_index).is_equal(SECOND_EFFECT)


func test_207_3_7b_effect_without_the_mention_is_added_at_every_event() -> void:
	_place(FilterSamples.MIXED, "B2")
	var state := _builder.build()
	for announcement: int in 3:
		_announce(state)
	var unlimited := state.stack.filter(
		func(entry: StackEntry) -> bool: return entry.effect_index == SECOND_EFFECT
	)
	assert_int(unlimited.size()).is_equal(3)


func test_207_3_7c_each_effect_with_the_mention_is_counted_separately() -> void:
	var card_id := _card_of(_place(FilterSamples.TWICE_ONCE, "B2"))
	var state := _builder.build()
	_announce(state)
	assert_int(state.stack.size()).is_equal(2)
	assert_array(state.once_per_turn_effects).contains_exactly_in_any_order(
		[Vector2i(card_id, FIRST_EFFECT), Vector2i(card_id, SECOND_EFFECT)]
	)
	var labels := _announce(state)
	assert_int(labels.count("TriggerSkipped:A")).is_equal(2)
	assert_int(labels.count("StackEntryAdded:A")).is_equal(0)
	assert_int(state.stack.size()).is_equal(2)


func test_207_3_7c_the_count_of_another_copy_of_the_card_is_separate() -> void:
	var first_card := _card_of(_place(FilterSamples.TWICE_ONCE, "B2"))
	var second_card := _card_of(_place(FilterSamples.TWICE_ONCE, "D2"))
	var state := _builder.build()
	_announce(state)
	assert_int(state.stack.size()).is_equal(4)
	assert_int(state.once_per_turn_effects.size()).is_equal(4)
	assert_bool(state.once_per_turn_effects.has(Vector2i(first_card, SECOND_EFFECT))).is_true()
	assert_bool(state.once_per_turn_effects.has(Vector2i(second_card, SECOND_EFFECT))).is_true()


func test_207_3_9_the_count_of_each_effect_restarts_at_the_next_turn() -> void:
	_place(FilterSamples.TWICE_ONCE, "B2")
	var state := _builder.build()
	_announce(state)
	assert_int(state.once_per_turn_effects.size()).is_equal(2)
	var events: Array[DuelEvent] = []
	TurnRules.start_turn(state, DuelState.PlayerSide.B, events)
	assert_array(state.once_per_turn_effects).is_empty()


func test_207_3_7_the_key_of_an_effect_is_its_card_and_its_rank() -> void:
	var entry := StackEntry.new()
	entry.source_card_instance_id = 12
	entry.effect_index = 3
	assert_vector(TriggerRules.once_per_turn_key(entry)).is_equal(Vector2i(12, 3))


# Annonce d'un Spell de A : les effets déclenchés attendent, A les ordonne s'il le faut, puis ils
# s'ajoutent à la pile. Renvoie les événements.
func _announce(state: DuelState) -> Array[String]:
	var events: Array[DuelEvent] = []
	TriggerRules.trigger_for_player(state, A, ANNOUNCED, events)
	TriggerRules.add_waiting_triggers(state, events)
	if state.pending_decision != null:
		var ordered_ids: Array[int] = state.pending_decision.candidate_ids
		TriggerRules.apply_order(state, OrderTriggers.new(A, ordered_ids), events)
		TriggerRules.add_waiting_triggers(state, events)
	return EventLog.describe(events)


func _place(definition_id: StringName, cell_name: String) -> int:
	return _builder.place_piece(
		A, Piece.PieceKind.UNIT, DuelStateBuilder.cell(cell_name), definition_id
	)


func _card_of(piece_id: int) -> int:
	return _builder.build().find_piece(piece_id).card.card_instance_id
