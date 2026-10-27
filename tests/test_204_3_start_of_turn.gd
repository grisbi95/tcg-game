extends GdUnitTestSuite
## Événement « début du tour » et condition « si » qu'il lit (ruleset 0.54, 204.3.8 à 204.3.12b,
## 208.4.10, 208.7.15 ; décision 0060). Le tour de A se termine et celui de B commence ; les cartes
## viennent de NamedTriggerSamples.

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const DECK_SIZE: int = 6
const SOLDIER: StringName = TriggerSamples.SOLDIER

var _catalog: Catalog
var _builder: DuelStateBuilder
var _engine: DuelEngine


func before_test() -> void:
	_catalog = NamedTriggerSamples.catalog()
	_builder = HandEffectSamples.builder(_catalog)
	for index: int in DECK_SIZE:
		_builder.add_to_deck(B, SOLDIER)
		_builder.add_to_deck(A, SOLDIER)
	_engine = DuelEngine.new(_catalog)


func test_204_3_12_start_of_turn_event_happens_before_the_draw() -> void:
	_place_building(B, NamedTriggerSamples.LIBRARY, "D4")
	var labels := EventLog.describe(_end_turn_of_a())
	(
		assert_array(labels)
		. contains_exactly(
			[
				"TurnEnded:A",
				"TurnStarted:B",
				"SourceReceived:B",
				"EffectTriggered:B",
				"CardDrawn:B",
				"DecisionResolvedAutomatically:B",
				"StackEntryAdded:B",
				"CardDrawn:B",
				"StackEntryResolved:B",
			]
		)
	)


func test_204_3_12_start_of_turn_event_belongs_to_the_player_whose_turn_starts() -> void:
	_place_building(A, NamedTriggerSamples.LIBRARY, "B2")
	var labels := EventLog.describe(_end_turn_of_a())
	assert_bool(labels.has("EffectTriggered:A")).is_false()
	assert_int(_engine.get_state().get_player(A).hand.size()).is_equal(0)


func test_204_3_12a_condition_is_read_at_the_event_before_the_draw() -> void:
	_builder.add_to_hand(B, SOLDIER)
	_builder.with_hero_definition(B, NamedTriggerSamples.PILLEUSE)
	var labels := EventLog.describe(_end_turn_of_a())
	assert_bool(labels.has("EffectTriggered:B")).is_true()
	var hand_size := _engine.get_state().get_player(B).hand.size()
	var drawn := NamedTriggerSamples.PILLEUSE_DRAWN + 1  # la pioche du tour et l'effet
	assert_int(hand_size).is_equal(1 + drawn)


func test_204_3_12a_false_condition_at_the_event_triggers_nothing() -> void:
	var cards_in_hand := NamedTriggerSamples.PILLEUSE_HAND_LIMIT + 1
	for index: int in cards_in_hand:
		_builder.add_to_hand(B, SOLDIER)
	_builder.with_hero_definition(B, NamedTriggerSamples.PILLEUSE)
	var labels := EventLog.describe(_end_turn_of_a())
	assert_bool(labels.has("EffectTriggered:B")).is_false()
	assert_bool(labels.has("TriggerSkipped:B")).is_false()
	assert_int(_engine.get_state().get_player(B).hand.size()).is_equal(cards_in_hand + 1)


func test_204_3_12b_start_of_turn_event_follows_wake_untap_and_source_received() -> void:
	_place_building(B, NamedTriggerSamples.LIBRARY, "D4")
	var sleeper := _place_unit(B, SOLDIER, "D5")
	_builder.with_piece_awake(sleeper, false)
	_builder.with_sources_in_play(B, 1, 2)
	_builder.with_sources_in_reserve(B, 2)
	var labels := EventLog.describe(_end_turn_of_a())
	var order: Array[int] = [
		labels.find("PiecesAwakened:B"),
		labels.find("SourcesUntapped:B"),
		labels.find("SourceReceived:B"),
		labels.find("EffectTriggered:B"),
		labels.find("CardDrawn:B"),
	]
	assert_int(order[0]).is_greater_equal(0)
	for index: int in range(1, order.size()):
		assert_int(order[index]).is_greater(order[index - 1])


func test_204_3_9_start_of_turn_effect_waits_for_the_main_phase_without_response() -> void:
	_place_building(B, NamedTriggerSamples.LIBRARY, "D4")
	_end_turn_of_a()
	var state := _engine.get_state()
	assert_int(state.phase).is_equal(DuelState.DuelPhase.MAIN)
	assert_array(state.stack).is_empty()
	assert_int(state.priority_player).is_equal(B)


func test_208_7_15_start_of_turn_effect_is_resolved_at_once_after_its_addition() -> void:
	_place_building(B, NamedTriggerSamples.LIBRARY, "D4")
	var labels := EventLog.describe(_end_turn_of_a())
	var added := labels.find("StackEntryAdded:B")
	assert_int(added).is_greater(labels.find("CardDrawn:B"))
	assert_str(labels[added + 2]).is_equal("StackEntryResolved:B")


func test_208_4_10_start_of_turn_effect_is_added_only_after_the_whole_start_of_turn() -> void:
	_place_building(B, NamedTriggerSamples.LIBRARY, "D4")
	var labels := EventLog.describe(_end_turn_of_a())
	assert_int(labels.find("StackEntryAdded:B")).is_greater(labels.find("CardDrawn:B"))
	assert_int(labels.find("EffectTriggered:B")).is_less(labels.find("CardDrawn:B"))


func test_208_4_11_start_of_turn_effect_is_added_at_the_beginning_of_the_main_phase() -> void:
	_place_building(B, NamedTriggerSamples.LIBRARY, "D4")
	var labels := EventLog.describe(_end_turn_of_a())
	var state := _engine.get_state()
	assert_int(state.phase).is_equal(DuelState.DuelPhase.MAIN)
	assert_int(state.active_player).is_equal(B)
	assert_array(labels.slice(labels.find("StackEntryAdded:B"))).contains_exactly(
		["StackEntryAdded:B", "CardDrawn:B", "StackEntryResolved:B"]
	)
	assert_bool(labels.has("PieceDeployed:B")).is_false()


func test_204_3_12_forge_effect_targets_an_ally_unit_at_the_start_of_the_turn() -> void:
	_place_building(B, NamedTriggerSamples.FORGE, "D4")
	var unit_id := _place_unit(B, SOLDIER, "D5")
	_end_turn_of_a()
	var state := _engine.get_state()
	assert_int(ForceRules.current_force(state, state.find_piece(unit_id))).is_equal(
		TriggerSamples.SOLDIER_FORCE + NamedTriggerSamples.FORGE_BONUS
	)


func _end_turn_of_a() -> Array[DuelEvent]:
	_engine.start_from_state(_builder.build())
	return _engine.submit(EndTurn.new(A))


func _place_building(side: DuelState.PlayerSide, definition_id: StringName, cell: String) -> int:
	return NamedTriggerSamples.place(_builder, side, Piece.PieceKind.BUILDING, definition_id, cell)


func _place_unit(side: DuelState.PlayerSide, definition_id: StringName, cell: String) -> int:
	return NamedTriggerSamples.place(_builder, side, Piece.PieceKind.UNIT, definition_id, cell)
