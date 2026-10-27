# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## Déclencheurs « une autre pièce est détruite » et « un Spell est contrecarré » (ruleset 0.55,
## 207.3.1, 207.6.4, 207.2.8, 207.3.12 ; décision 0065) : le texte qualifie l'objet de l'événement,
## la pièce détruite par un filtre relatif à la pièce qui porte l'effet, le Spell contrecarré par
## le côté de son propriétaire. Cartes : GameValueSamples ; une carte réagit, les autres non.

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const SOLDIER: StringName = TriggerSamples.SOLDIER
const WITNESS: StringName = GameValueSamples.WITNESS
const AVENGER: StringName = GameValueSamples.AVENGER
const VULTURE: StringName = GameValueSamples.VULTURE
const MOURNER: StringName = GameValueSamples.MOURNER
const NEIGHBOR: StringName = GameValueSamples.NEIGHBOR
const HUNTER: StringName = GameValueSamples.HUNTER
const GUARDIAN: StringName = GameValueSamples.GUARDIAN
const ONLOOKER: StringName = GameValueSamples.ONLOOKER
const SPELL: StringName = HandEffectSamples.DRAW_ONE

var _catalog: Catalog
var _builder: DuelStateBuilder
var _events: Array[DuelEvent] = []


func before_test() -> void:
	_catalog = GameValueSamples.catalog()
	_builder = HandEffectSamples.builder(_catalog)
	_events.clear()


func test_207_3_1_an_allied_unit_destroyed_triggers_the_witness_of_allied_units() -> void:
	var witness_id := _place(A, WITNESS, "B2")
	var ally_id := _place(A, SOLDIER, "D4")
	var state := _builder.build()
	CombatRules.destroy_piece(state, state.find_piece(ally_id), _events)
	assert_array(EventLog.describe(_events)).contains_exactly(
		["PieceDestroyed:A", "EffectTriggered:A"]
	)
	assert_int(state.waiting_triggers[0].source_piece_id).is_equal(witness_id)


func test_207_3_1_the_witness_ignores_an_enemy_unit_a_building_and_its_own_destruction() -> void:
	var witness_id := _place(A, WITNESS, "B2")
	var enemy_id := _place(B, SOLDIER, "D4")
	var building_id := _place_building(A, "E2")
	var state := _builder.build()
	CombatRules.destroy_piece(state, state.find_piece(enemy_id), _events)
	CombatRules.destroy_piece(state, state.find_piece(building_id), _events)
	CombatRules.destroy_piece(state, state.find_piece(witness_id), _events)
	assert_array(EventLog.describe(_events)).contains_exactly(
		["PieceDestroyed:B", "PieceDestroyed:A", "PieceDestroyed:A"]
	)
	assert_array(state.waiting_triggers).is_empty()


func test_207_3_1_an_enemy_unit_destroyed_triggers_the_avenger() -> void:
	_place(A, AVENGER, "B2")
	var enemy_id := _place(B, SOLDIER, "D4")
	var ally_id := _place(A, SOLDIER, "E2")
	var state := _builder.build()
	CombatRules.destroy_piece(state, state.find_piece(ally_id), _events)
	assert_array(state.waiting_triggers).is_empty()
	CombatRules.destroy_piece(state, state.find_piece(enemy_id), _events)
	assert_array(EventLog.describe(_events)).contains_exactly(
		["PieceDestroyed:A", "PieceDestroyed:B", "EffectTriggered:A"]
	)


func test_207_3_1_the_side_is_read_for_the_player_who_owns_the_effect() -> void:
	_place(A, AVENGER, "B2")
	_place(B, AVENGER, "B4")
	var enemy_id := _place(B, SOLDIER, "D4")
	var state := _builder.build()
	CombatRules.destroy_piece(state, state.find_piece(enemy_id), _events)
	assert_array(EventLog.describe(_events)).contains_exactly(
		["PieceDestroyed:B", "EffectTriggered:A"]
	)
	assert_int(state.waiting_triggers[0].owner).is_equal(A)


func test_207_3_1_a_piece_without_object_is_triggered_by_any_other_piece() -> void:
	_place(A, VULTURE, "B2")
	var unit_id := _place(B, SOLDIER, "D4")
	var building_id := _place_building(B, "D5")
	var token_id := _builder.place_token(A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("E2"), 2)
	var state := _builder.build()
	for piece_id: int in [unit_id, building_id, token_id]:
		CombatRules.destroy_piece(state, state.find_piece(piece_id), _events)
	assert_array(state.waiting_triggers).has_size(3)


func test_207_3_1_the_object_filters_the_type_of_the_destroyed_piece() -> void:
	_place(A, MOURNER, "B2")
	var ally_unit_id := _place(A, SOLDIER, "D4")
	var enemy_building_id := _place_building(B, "D5")
	var ally_building_id := _place_building(A, "E2")
	var state := _builder.build()
	CombatRules.destroy_piece(state, state.find_piece(ally_unit_id), _events)
	CombatRules.destroy_piece(state, state.find_piece(enemy_building_id), _events)
	assert_array(state.waiting_triggers).is_empty()
	CombatRules.destroy_piece(state, state.find_piece(ally_building_id), _events)
	assert_array(state.waiting_triggers).has_size(1)


func test_207_3_1_the_object_filters_the_position_relative_to_the_carrier() -> void:
	_place(A, NEIGHBOR, "C3")
	var near_id := _place(A, SOLDIER, "C4")
	var far_id := _place(A, SOLDIER, "A1")
	var state := _builder.build()
	CombatRules.destroy_piece(state, state.find_piece(far_id), _events)
	assert_array(state.waiting_triggers).is_empty()
	CombatRules.destroy_piece(state, state.find_piece(near_id), _events)
	assert_array(state.waiting_triggers).has_size(1)


func test_207_3_1_the_triggered_effect_resolves_and_its_owner_draws() -> void:
	_place(A, WITNESS, "B2")
	var ally_id := _place(A, SOLDIER, "D4")
	_builder.add_to_deck(A, SOLDIER)
	var state := _builder.build()
	CombatRules.destroy_piece(state, state.find_piece(ally_id), _events)
	TriggerRules.add_waiting_triggers(state, _events)
	var engine := DuelEngine.new(_catalog)
	engine.start_from_state(state)
	assert_array(EventLog.describe(DuelChecks.pass_once(engine, B))).contains_exactly(
		["PriorityPassed:B", "CardDrawn:A", "StackEntryResolved:A"]
	)


func test_207_3_1_a_spell_countered_triggers_the_matching_side() -> void:
	_place(A, HUNTER, "B2")  # Spell adverse
	_place(A, GUARDIAN, "B3")  # Spell allié
	_place(A, ONLOOKER, "B4")  # tout Spell
	_place(B, HUNTER, "D2")
	_place(B, GUARDIAN, "D3")
	_place(B, ONLOOKER, "D4")
	var spell_id := _builder.push_spell(_builder.make_card_instance(B, SPELL))
	var state := _builder.build()
	_counter(state, A, spell_id)
	(
		assert_array(EventLog.describe(_events))
		. contains_exactly(
			[
				"SpellCountered:B",
				"CardDiscarded:B",
				"EffectTriggered:A",  # HUNTER de A : le Spell de B est adverse
				"EffectTriggered:A",  # ONLOOKER de A
				"EffectTriggered:B",  # GUARDIAN de B : le Spell de B est allié
				"EffectTriggered:B",  # ONLOOKER de B
			]
		)
	)


func test_207_3_1_the_object_of_a_countered_spell_is_its_owner_not_the_counter() -> void:
	_place(A, GUARDIAN, "B2")
	var spell_id := _builder.push_spell(_builder.make_card_instance(A, SPELL))
	var state := _builder.build()
	_counter(state, B, spell_id)
	assert_array(EventLog.describe(_events)).contains_exactly(
		["SpellCountered:A", "CardDiscarded:A", "EffectTriggered:A"]
	)
	assert_int(state.waiting_triggers[0].owner).is_equal(A)


func test_207_3_1_the_countered_spell_has_left_the_stack_when_the_effect_triggers() -> void:
	_place(A, ONLOOKER, "B2")
	var spell_id := _builder.push_spell(_builder.make_card_instance(B, SPELL))
	var state := _builder.build()
	_counter(state, A, spell_id)
	assert_object(state.find_stack_entry(spell_id)).is_null()
	assert_array(state.waiting_triggers).has_size(1)


func test_207_3_1_a_spell_that_is_not_countered_triggers_nothing() -> void:
	_place(A, ONLOOKER, "B2")
	_builder.push_spell(_builder.make_card_instance(B, SPELL))
	var state := _builder.build()
	assert_array(state.waiting_triggers).is_empty()


func test_207_3_1_a_spell_countered_by_a_reaction_triggers_through_the_engine() -> void:
	_place(B, ONLOOKER, "D4")
	var spell_card_id := _builder.add_to_hand(A, SPELL)
	var counter_card_id := _builder.add_to_hand(B, HandEffectSamples.COUNTER)
	_builder.add_to_deck(B, SOLDIER)
	var engine := DuelEngine.new(_catalog)
	engine.start_from_state(_builder.build())
	engine.submit(HandEffectSamples.cast(A, spell_card_id))
	var spell_entry_id := engine.get_state().stack[0].stack_entry_id
	var counter := HandEffectSamples.cast(B, counter_card_id)
	counter.target_stack_entry_ids.append(spell_entry_id)
	engine.submit(counter)
	var labels := EventLog.describe(DuelChecks.pass_until_stack_empty(engine))
	assert_array(labels).contains(["SpellCountered:A", "CardDiscarded:A", "EffectTriggered:B"])
	assert_int(labels.find("EffectTriggered:B")).is_greater(labels.find("SpellCountered:A"))


func _counter(state: DuelState, side: DuelState.PlayerSide, spell_id: int) -> void:
	var entry := StackEntry.new()
	entry.kind = StackEntry.StackEntryKind.SPELL
	entry.owner = side
	entry.target_stack_entry_ids.append(spell_id)
	var effect := CatalogSamples.effect_from(CatalogSamples.counter_spell_effect())
	EffectRules.resolve_effect(state, entry, effect, _events)


func _place(side: DuelState.PlayerSide, definition_id: StringName, cell_name: String) -> int:
	return _builder.place_piece(
		side, Piece.PieceKind.UNIT, DuelStateBuilder.cell(cell_name), definition_id
	)


func _place_building(side: DuelState.PlayerSide, cell_name: String) -> int:
	return _builder.place_piece(
		side, Piece.PieceKind.BUILDING, DuelStateBuilder.cell(cell_name), GameValueSamples.CROWD
	)
