extends GdUnitTestSuite
## Destructions simultanées (ruleset 0.55, 207.3.15, 207.3.3, 206.3.6 ; décisions 0064 et 0065) :
## un effet déclenché par la destruction d'une autre pièce se déclenche même si la pièce qui le
## porte est détruite en même temps. Les cartes viennent de GameValueSamples (Vautour : « quand une
## autre pièce est détruite, piochez une carte »).

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const SOLDIER: StringName = TriggerSamples.SOLDIER  # Force 2
const GIANT: StringName = TriggerSamples.GIANT  # Force 5
const VULTURE: StringName = GameValueSamples.VULTURE  # Force 2
const PURGE: StringName = TextSamples.PURGE
const DECK_SIZE: int = 6

var _catalog: Catalog
var _builder: DuelStateBuilder
var _events: Array[DuelEvent] = []


func before_test() -> void:
	_catalog = GameValueSamples.catalog()
	_builder = HandEffectSamples.builder(_catalog)
	_events.clear()
	for index: int in DECK_SIZE:
		_builder.add_to_deck(A, SOLDIER)
		_builder.add_to_deck(B, SOLDIER)


func test_207_3_15_combat_tie_each_piece_sees_the_destruction_of_the_other() -> void:
	var attacker_id := _place(A, VULTURE, "B2")
	var defender_id := _place(B, VULTURE, "B3")
	var state := _builder.build()
	CombatRules.resolve_attack(
		state, state.find_piece(attacker_id), state.find_piece(defender_id), _events
	)
	(
		assert_array(EventLog.describe(_events))
		. contains_exactly(
			[
				"CombatResolved",
				"PieceDestroyed:B",
				"PieceDestroyed:A",
				"EffectTriggered:A",
				"EffectTriggered:B",
			]
		)
	)
	assert_object(state.find_piece(attacker_id)).is_null()
	assert_object(state.find_piece(defender_id)).is_null()


func test_207_3_15_the_effect_of_a_piece_destroyed_at_the_same_time_has_place() -> void:
	var attacker_id := _place(A, VULTURE, "B2")
	var defender_id := _place(B, VULTURE, "B3")
	var state := _builder.build()
	CombatRules.resolve_attack(
		state, state.find_piece(attacker_id), state.find_piece(defender_id), _events
	)
	TriggerRules.add_waiting_triggers(state, _events)
	var engine := DuelEngine.new(_catalog)
	engine.start_from_state(state)
	var hand_a := state.get_player(A).hand.size()
	var hand_b := state.get_player(B).hand.size()
	DuelChecks.pass_until_stack_empty(engine)
	assert_int(state.get_player(A).hand.size()).is_equal(hand_a + 1)
	assert_int(state.get_player(B).hand.size()).is_equal(hand_b + 1)


func test_207_3_15_a_piece_that_wins_the_combat_sees_the_destruction_of_its_defender() -> void:
	var attacker_id := _place(A, GIANT, "B2")
	var defender_id := _place(B, SOLDIER, "B3")
	_place(A, VULTURE, "D4")
	_place(B, VULTURE, "D2")
	var state := _builder.build()
	CombatRules.resolve_attack(
		state, state.find_piece(attacker_id), state.find_piece(defender_id), _events
	)
	(
		assert_array(EventLog.describe(_events))
		. contains_exactly(
			[
				"CombatResolved",
				"PieceDestroyed:B",
				"EffectTriggered:A",
				"EffectTriggered:B",
				"PieceMoved:A",
			]
		)
	)


func test_207_3_15_a_piece_destroyed_earlier_does_not_see_the_next_destruction() -> void:
	var first_id := _place(B, VULTURE, "B3")
	var second_id := _place(B, SOLDIER, "C3")
	_place(A, VULTURE, "D4")
	var state := _builder.build()
	CombatRules.destroy_piece(state, state.find_piece(first_id), _events)
	_events.clear()
	CombatRules.destroy_piece(state, state.find_piece(second_id), _events)
	assert_array(EventLog.describe(_events)).contains_exactly(
		["PieceDestroyed:B", "EffectTriggered:A"]
	)


func test_207_3_15_pieces_destroyed_by_the_same_effect_see_each_other() -> void:
	_place(A, VULTURE, "D4")
	var first_id := _place(B, VULTURE, "B3")
	var second_id := _place(B, VULTURE, "C3")
	var spell_id := _builder.add_to_hand(A, PURGE)
	var engine := _start()
	engine.submit(HandEffectSamples.cast(A, spell_id))
	var events := HandEffectSamples.resolve(engine)
	var state := engine.get_state()
	assert_object(state.find_piece(first_id)).is_null()
	assert_object(state.find_piece(second_id)).is_null()
	var labels := EventLog.describe(events)
	assert_int(labels.count("PieceDestroyed:B")).is_equal(2)
	assert_int(labels.count("EffectTriggered:A")).is_equal(2)
	assert_int(labels.count("EffectTriggered:B")).is_equal(2)
	var first_trigger := labels.find("EffectTriggered:A")
	assert_int(labels.rfind("PieceDestroyed:B")).is_less(first_trigger)  # toutes parties d'abord


func test_207_3_3_the_effect_of_a_piece_that_left_the_board_keeps_its_place() -> void:
	var attacker_id := _place(A, VULTURE, "B2")
	var defender_id := _place(B, SOLDIER, "B3")
	_builder.with_piece_awake(attacker_id)
	var state := _builder.build()
	CombatRules.resolve_attack(
		state, state.find_piece(attacker_id), state.find_piece(defender_id), _events
	)
	assert_object(state.find_piece(attacker_id)).is_null()
	assert_array(state.waiting_triggers).has_size(1)
	assert_int(state.waiting_triggers[0].source_piece_id).is_equal(attacker_id)


func test_207_3_15_a_single_destruction_is_not_given_to_the_destroyed_piece() -> void:
	var unit_id := _place(A, VULTURE, "B2")
	var state := _builder.build()
	CombatRules.destroy_piece(state, state.find_piece(unit_id), _events)
	assert_array(EventLog.describe(_events)).contains_exactly(["PieceDestroyed:A"])
	assert_array(state.waiting_triggers).is_empty()


func _place(side: DuelState.PlayerSide, definition_id: StringName, cell_name: String) -> int:
	return _builder.place_piece(
		side, Piece.PieceKind.UNIT, DuelStateBuilder.cell(cell_name), definition_id
	)


func _start() -> DuelEngine:
	var engine := DuelEngine.new(_catalog)
	engine.start_from_state(_builder.build())
	return engine
