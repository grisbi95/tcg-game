extends GdUnitTestSuite
## Ensemble touché sans cible (ruleset 0.55 ; 207.4.11 à 207.4.11c, 207.5.18, 207.4.2, 207.4.7a,
## 206.5.5 ; décisions 0062, 0063 et 0064) : « les Units ennemies ont −1 Force jusqu'à la fin du
## tour », fixé à la résolution de l'entrée, posé pièce par pièce. Les cartes viennent de
## TextSamples.

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const SOLDIER: StringName = TriggerSamples.SOLDIER
const SOLDIER_FORCE: int = TriggerSamples.SOLDIER_FORCE
const MALUS: int = TextSamples.MALUS
const DECK_SIZE: int = 4

var _catalog: Catalog
var _builder: DuelStateBuilder
var _engine: DuelEngine


func before_test() -> void:
	_catalog = TextSamples.catalog()
	_builder = HandEffectSamples.builder(_catalog)
	_engine = DuelEngine.new(_catalog)
	for index: int in DECK_SIZE:
		_builder.add_to_deck(A, SOLDIER)


func test_207_4_11_the_set_is_fixed_when_the_entry_resolves() -> void:
	var near_id := _place(B, "D4")
	var far_id := _place(B, "E5")
	var spell_id := _builder.add_to_hand(A, TextSamples.WEAKEN_ALL)
	_start()
	_engine.submit(HandEffectSamples.cast(A, spell_id))
	var arrived_id := DuelStateBuilder.place_unit_in(_engine.get_state(), B, SOLDIER, "C4")
	var events := HandEffectSamples.resolve(_engine)
	(
		assert_array(EventLog.describe(events))
		. contains_exactly(
			[
				"PriorityPassed:B",
				"ForceModified:B",
				"ForceModified:B",
				"ForceModified:B",
				"CardDiscarded:A",
				"StackEntryResolved:A",
			]
		)
	)
	for piece_id: int in [near_id, far_id, arrived_id]:
		assert_int(_engine.current_force(piece_id)).is_equal(SOLDIER_FORCE + MALUS)


func test_207_4_11_the_effect_lasts_until_the_end_of_the_turn_for_each_piece() -> void:
	_place(B, "D4")
	_place(B, "E5")
	var spell_id := _builder.add_to_hand(A, TextSamples.WEAKEN_ALL)
	_start()
	_engine.submit(HandEffectSamples.cast(A, spell_id))
	HandEffectSamples.resolve(_engine)
	var state := _engine.get_state()
	assert_int(state.active_effects.size()).is_equal(2)  # un effet par pièce touchée (207.4.7a)
	for effect: ActiveEffect in state.active_effects:
		assert_int(effect.duration).is_equal(ActiveEffect.EffectDuration.UNTIL_END_OF_TURN)
	var ended := EventLog.describe(_engine.submit(EndTurn.new(A)))
	assert_int(ended.count("ActiveEffectEnded")).is_equal(2)


func test_207_4_11_an_empty_set_has_no_effect() -> void:
	var spell_id := _builder.add_to_hand(A, TextSamples.WEAKEN_ALL)
	_start()
	_engine.submit(HandEffectSamples.cast(A, spell_id))
	var events := HandEffectSamples.resolve(_engine)
	assert_array(EventLog.describe(events)).contains_exactly(
		["PriorityPassed:B", "CardDiscarded:A", "StackEntryResolved:A"]
	)
	assert_array(_engine.get_state().active_effects).is_empty()


func test_207_4_11a_a_piece_that_arrives_afterwards_is_not_touched() -> void:
	var present_id := _place(B, "D4")
	var spell_id := _builder.add_to_hand(A, TextSamples.WEAKEN_ALL)
	_start()
	_engine.submit(HandEffectSamples.cast(A, spell_id))
	HandEffectSamples.resolve(_engine)
	var arrived_id := DuelStateBuilder.place_unit_in(_engine.get_state(), B, SOLDIER, "E5")
	assert_int(_engine.current_force(present_id)).is_equal(SOLDIER_FORCE + MALUS)
	assert_int(_engine.current_force(arrived_id)).is_equal(SOLDIER_FORCE)


func test_207_4_11b_a_static_effect_is_computed_for_as_long_as_its_bearer_is_in_play() -> void:
	_place(A, "B2", FilterSamples.STANDARD_BEARER)
	var neighbour_id := _place(A, "B3")
	var state := _builder.build()
	assert_int(ForceRules.current_force(state, state.find_piece(neighbour_id))).is_equal(
		SOLDIER_FORCE + FilterSamples.BONUS
	)
	# Une pièce arrivée après est touchée à son tour : l'ensemble n'est fixé à aucune résolution.
	var arrived_id := DuelStateBuilder.place_unit_in(state, A, SOLDIER, "C2")
	assert_int(ForceRules.current_force(state, state.find_piece(arrived_id))).is_equal(
		SOLDIER_FORCE + FilterSamples.BONUS
	)
	# Et une pièce qui cesse de correspondre cesse d'être touchée.
	state.find_piece(neighbour_id).cell = DuelStateBuilder.cell("E5")
	assert_int(ForceRules.current_force(state, state.find_piece(neighbour_id))).is_equal(
		SOLDIER_FORCE
	)


func test_207_4_11c_a_piece_stays_touched_when_it_stops_matching() -> void:
	var hero_cell := BoardGeometry.hero_start_cell(A)
	var next_to_hero := BoardGeometry.adjacent_cells(hero_cell)[0]
	var near_id := _builder.place_piece(B, Piece.PieceKind.UNIT, next_to_hero, SOLDIER)
	var far_id := _place(B, "E5")
	var spell_id := _builder.add_to_hand(A, TextSamples.WEAKEN_NEAR)
	_start()
	_engine.submit(HandEffectSamples.cast(A, spell_id))
	HandEffectSamples.resolve(_engine)
	assert_int(_engine.current_force(near_id)).is_equal(SOLDIER_FORCE + MALUS)
	assert_int(_engine.current_force(far_id)).is_equal(SOLDIER_FORCE)  # pas dans l'ensemble
	_engine.get_state().find_piece(near_id).cell = DuelStateBuilder.cell("E4")  # ne correspond plus
	assert_int(_engine.current_force(near_id)).is_equal(SOLDIER_FORCE + MALUS)
	# Elle cesse d'être touchée en quittant le plateau (207.4.7a, fin de la durée en 207.4.3).
	_engine.get_state().pieces.erase(_engine.get_state().find_piece(far_id))
	assert_int(_engine.get_state().active_effects.size()).is_equal(1)


func test_207_4_11_destruction_applies_to_the_set_fixed_at_the_resolution() -> void:
	var first_id := _place(B, "D4")
	var second_id := _place(B, "E5")
	var ally_id := _place(A, "B2")
	var spell_id := _builder.add_to_hand(A, TextSamples.PURGE)
	_start()
	_engine.submit(HandEffectSamples.cast(A, spell_id))
	var events := HandEffectSamples.resolve(_engine)
	(
		assert_array(EventLog.describe(events))
		. contains_exactly(
			[
				"PriorityPassed:B",
				"PieceDestroyed:B",
				"PieceDestroyed:B",
				"CardDiscarded:A",
				"StackEntryResolved:A",
			]
		)
	)
	var state := _engine.get_state()
	assert_object(state.find_piece(first_id)).is_null()
	assert_object(state.find_piece(second_id)).is_null()
	assert_object(state.find_piece(ally_id)).is_not_null()
	assert_object(state.find_hero(B)).is_not_null()  # Q-097 : le Hero n'est pas dans l'ensemble


func test_207_4_11_sleep_applies_to_every_piece_of_the_set() -> void:
	var first_id := _place(B, "D4")
	var second_id := _place(B, "E5")
	var ally_id := _place(A, "B2")
	var spell_id := _builder.add_to_hand(A, TextSamples.LULL)
	_start()
	_engine.submit(HandEffectSamples.cast(A, spell_id))
	HandEffectSamples.resolve(_engine)
	var state := _engine.get_state()
	assert_bool(state.find_piece(first_id).is_asleep()).is_true()
	assert_bool(state.find_piece(second_id).is_asleep()).is_true()
	assert_bool(state.find_piece(ally_id).is_asleep()).is_false()


func test_207_4_11_a_granted_keyword_applies_to_every_piece_of_the_set() -> void:
	var first_id := _place(A, "B2")
	var second_id := _place(A, "B3")
	var enemy_id := _place(B, "D4")
	var spell_id := _builder.add_to_hand(A, TextSamples.ARM)
	_start()
	_engine.submit(HandEffectSamples.cast(A, spell_id))
	var events := HandEffectSamples.resolve(_engine)
	assert_int(EventLog.describe(events).count("KeywordGranted:A")).is_equal(2)
	var state := _engine.get_state()
	assert_int(KeywordRules.assault_value(state, state.find_piece(first_id))).is_equal(1)
	assert_int(KeywordRules.assault_value(state, state.find_piece(second_id))).is_equal(1)
	assert_int(KeywordRules.assault_value(state, state.find_piece(enemy_id))).is_equal(0)


func test_207_4_11_the_set_of_a_triggered_text_is_relative_to_its_source_piece() -> void:
	var chill_id := _place(A, "C3", TextSamples.CHILL)
	var next_id := _place(B, "C4")
	var apart_id := _place(B, "E5")
	var state := _builder.build()
	var events: Array[DuelEvent] = []
	TriggerRules.trigger(
		state, state.find_piece(chill_id), EffectDefinition.TriggerEvent.ARRIVAL, events
	)
	_engine.start_from_state(state)
	TriggerRules.add_waiting_triggers(state, events)
	HandEffectSamples.resolve(_engine)
	assert_int(_engine.current_force(next_id)).is_equal(SOLDIER_FORCE + MALUS)
	assert_int(_engine.current_force(apart_id)).is_equal(SOLDIER_FORCE)
	assert_int(_engine.current_force(chill_id)).is_equal(TextSamples.UNIT_FORCE)


func _start() -> void:
	_engine.start_from_state(_builder.build())


func _place(side: DuelState.PlayerSide, cell: String, definition_id: StringName = SOLDIER) -> int:
	return NamedTriggerSamples.place(_builder, side, Piece.PieceKind.UNIT, definition_id, cell)
