extends GdUnitTestSuite
## Endormir par un effet (ruleset 0.55, 205.5.7 à 205.5.7c, glossaire Endormir ; 200.4.1,
## 204.3.10, 204.3.11, 207.3.3 ; décisions 0046 de design, 0062 et 0246 du ruleset). Le Spell
## SLEEPER et l'Unit DROWSY viennent de FilterSamples. Un jeton qui est une Unit est une Unit
## (205.5.4a) : il s'endort comme elle.

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const SOLDIER: StringName = TriggerSamples.SOLDIER
const DECK_SIZE: int = 4
const REASON := IntentRejected.RejectReason

var _builder: DuelStateBuilder
var _engine: DuelEngine


func before_test() -> void:
	var catalog := FilterSamples.catalog()
	_builder = HandEffectSamples.builder(catalog)
	_engine = DuelEngine.new(catalog)
	for index: int in DECK_SIZE:
		_builder.add_to_deck(A, SOLDIER)
		_builder.add_to_deck(B, SOLDIER)


func test_205_5_7_sleep_effect_puts_an_awake_unit_to_sleep() -> void:
	var unit_id := _place(B, "D4", true)
	var events := _cast_and_resolve([unit_id])
	assert_array(EventLog.describe(events)).contains_exactly(
		["PriorityPassed:B", "PieceFellAsleep:B", "CardDiscarded:A", "StackEntryResolved:A"]
	)
	assert_int((events[1] as PieceFellAsleep).piece_id).is_equal(unit_id)
	assert_bool(_engine.get_state().find_piece(unit_id).is_awake).is_false()


func test_205_5_7_sleep_effect_puts_an_awake_hero_to_sleep() -> void:
	var card_id := _builder.add_to_hand(A, FilterSamples.SLEEPER)
	_engine.start_from_state(_builder.build())
	var hero := _engine.get_state().find_hero(B)
	hero.is_awake = true
	_engine.submit(HandEffectSamples.cast(A, card_id, [hero.piece_id]))
	var events := HandEffectSamples.resolve(_engine)
	assert_array(EventLog.describe(events)).contains_exactly(
		["PriorityPassed:B", "PieceFellAsleep:B", "CardDiscarded:A", "StackEntryResolved:A"]
	)
	assert_bool(hero.is_awake).is_false()


func test_205_5_7_sleep_effect_puts_an_awake_token_unit_to_sleep() -> void:
	var token_id := _builder.place_token(B, Piece.PieceKind.UNIT, DuelStateBuilder.cell("D4"), 1)
	_builder.with_piece_awake(token_id, true)
	var events := _cast_and_resolve([token_id])
	assert_array(EventLog.describe(events)).contains_exactly(
		["PriorityPassed:B", "PieceFellAsleep:B", "CardDiscarded:A", "StackEntryResolved:A"]
	)
	assert_bool(_engine.get_state().find_piece(token_id).is_awake).is_false()


func test_205_5_7_sleep_effect_of_the_source_piece_puts_this_unit_to_sleep() -> void:
	var unit_id := _place(A, "B2", true)
	var drowsy_id := _builder.place_piece(
		A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("D2"), FilterSamples.DROWSY
	)
	_builder.with_piece_awake(drowsy_id, true)
	_engine.start_from_state(_builder.build())
	var labels := EventLog.describe(_engine.submit(EndTurn.new(A)))
	assert_array(labels).contains(
		["EffectTriggered:A", "StackEntryAdded:A", "PieceFellAsleep:A", "StackEntryResolved:A"]
	)
	var state := _engine.get_state()
	assert_bool(state.find_piece(drowsy_id).is_awake).is_false()
	assert_bool(state.find_piece(unit_id).is_awake).is_true()


func test_205_5_7a_sleep_effect_on_a_piece_already_asleep_does_not_happen_for_it() -> void:
	var unit_id := _place(B, "D4", false)
	var events := _cast_and_resolve([unit_id])
	assert_array(EventLog.describe(events)).contains_exactly(
		["PriorityPassed:B", "CardDiscarded:A", "StackEntryResolved:A"]
	)
	assert_bool(_engine.get_state().find_piece(unit_id).is_awake).is_false()


func test_205_5_7b_sleep_effect_on_a_building_does_not_happen_for_it() -> void:
	var building_id := _builder.place_piece(
		B, Piece.PieceKind.BUILDING, DuelStateBuilder.cell("D4"), TriggerSamples.BEACON
	)
	var events := _cast_and_resolve([building_id])
	assert_array(EventLog.describe(events)).contains_exactly(
		["PriorityPassed:B", "CardDiscarded:A", "StackEntryResolved:A"]
	)
	var building := _engine.get_state().find_piece(building_id)
	assert_bool(building.is_asleep()).is_false()


func test_205_5_7b_sleep_effect_of_the_source_piece_does_not_happen_for_a_building() -> void:
	var state := _builder.build()
	var building := Piece.new()
	building.piece_id = state.allocate_piece_id()
	building.kind = Piece.PieceKind.BUILDING
	building.cell = DuelStateBuilder.cell("B2")
	var events: Array[DuelEvent] = []
	ActionRules.sleep_pieces([building], events)
	assert_array(events).is_empty()
	assert_bool(building.is_awake).is_false()


func test_205_5_7c_piece_put_to_sleep_wakes_at_the_start_of_its_owner_turn() -> void:
	var unit_id := _place(B, "D4", true)
	_cast_and_resolve([unit_id])
	assert_bool(_engine.get_state().find_piece(unit_id).is_awake).is_false()
	var ended := EventLog.describe(_engine.submit(EndTurn.new(A)))
	assert_array(ended).contains(["TurnStarted:B", "PiecesAwakened:B"])
	var state := _engine.get_state()
	assert_bool(state.find_piece(unit_id).is_awake).is_true()


func test_205_5_7c_piece_put_to_sleep_stays_asleep_during_the_other_player_turn() -> void:
	var unit_id := _place(A, "B2", true)
	var card_id := _builder.add_to_hand(A, FilterSamples.SLEEPER)
	_engine.start_from_state(_builder.build())
	_engine.submit(HandEffectSamples.cast(A, card_id, [unit_id]))
	HandEffectSamples.resolve(_engine)
	var state := _engine.get_state()
	assert_bool(state.find_piece(unit_id).is_awake).is_false()
	_engine.submit(EndTurn.new(A))
	assert_bool(state.find_piece(unit_id).is_awake).is_false()
	_engine.submit(EndTurn.new(B))
	assert_bool(state.find_piece(unit_id).is_awake).is_true()


func test_205_5_7_sleeping_unit_cannot_take_a_normal_action() -> void:
	var unit_id := _place(A, "B2", true)
	var card_id := _builder.add_to_hand(A, FilterSamples.SLEEPER)
	_engine.start_from_state(_builder.build())
	_engine.submit(HandEffectSamples.cast(A, card_id, [unit_id]))
	HandEffectSamples.resolve(_engine)
	var intent := TakeNormalAction.new(A, unit_id, DuelStateBuilder.cell("B3"))
	var defects := DuelChecks.rejection_defects(_engine, intent, REASON.PIECE_ASLEEP)
	assert_array(defects).is_empty()


func _place(side: DuelState.PlayerSide, cell_name: String, awake: bool) -> int:
	var piece_id := _builder.place_piece(
		side, Piece.PieceKind.UNIT, DuelStateBuilder.cell(cell_name), SOLDIER
	)
	_builder.with_piece_awake(piece_id, awake)
	return piece_id


func _cast_and_resolve(piece_ids: Array[int]) -> Array[DuelEvent]:
	var card_id := _builder.add_to_hand(A, FilterSamples.SLEEPER)
	_engine.start_from_state(_builder.build())
	_engine.submit(HandEffectSamples.cast(A, card_id, piece_ids))
	return HandEffectSamples.resolve(_engine)
