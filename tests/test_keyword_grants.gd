# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## Mots-clés accordés par un effet (ruleset 0.53, 210.4, 202.4.13a, 207.2, 207.4 ; décision 0058) :
## effet à durée (Furie, Sève, Veille), Gear (Hache de guerre, Cape d'ombre) et aura (Tambour de
## guerre). Assaut et Rempart accordés s'additionnent à ceux de la carte (210.4.1a, 206.5.1).
## Cartes d'essai : ValueSamples.

const FORCE: int = ValueSamples.UNIT_FORCE
const AXE: int = ValueSamples.AXE_ASSAULT
const CLOAK: int = ValueSamples.CLOAK_RAMPART
const DRUM: int = ValueSamples.DRUM_ASSAULT
const WATCH_VALUE: int = 1  # ValueSamples.watch_effect()

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const REASON := IntentRejected.RejectReason
const ROLE := ForceRules.CombatRole

var _builder: DuelStateBuilder
var _engine: DuelEngine
var _events: Array[DuelEvent]


func before_test() -> void:
	var catalog := ValueSamples.catalog()
	_builder = ValueSamples.builder(catalog)
	_engine = DuelEngine.new(catalog)
	_events = []


# --- combat : 210.4.1, 210.4.2 ---


func test_210_4_1_granted_assault_counts_when_attacking() -> void:
	var attacker_id := _unit(A, ValueSamples.SOLDIER, "B2")
	var defender_id := _unit(B, ValueSamples.SOLDIER, "B3")
	var card_id := _builder.add_to_hand(A, ValueSamples.WATCH)
	_start()
	_engine.submit(ValueSamples.cast_fixed(A, card_id, ValueSamples.WATCH_COST, [attacker_id]))
	DuelChecks.pass_until_stack_empty(_engine)
	var events := _engine.submit(TakeNormalAction.new(A, attacker_id, DuelStateBuilder.cell("B3")))
	events.append_array(DuelChecks.pass_until_stack_empty(_engine))
	var combat: CombatResolved = null
	for event: DuelEvent in events:
		if event is CombatResolved:
			combat = event
	assert_object(combat).is_not_null()
	assert_int(combat.attacker_force).is_equal(FORCE + WATCH_VALUE)
	var state := _engine.get_state()
	assert_object(state.find_piece(defender_id)).is_null()
	assert_object(state.find_piece(attacker_id)).is_not_null()


func test_210_4_1_granted_assault_does_not_count_when_defending() -> void:
	var unit_id := _unit(A, ValueSamples.SOLDIER, "B2")
	_builder.attach_gear(unit_id, ValueSamples.WAR_AXE)
	var state := _builder.build()
	var unit := state.find_piece(unit_id)
	assert_int(ForceRules.combat_force(state, unit, ROLE.DEFENDER)).is_equal(FORCE)
	assert_int(ForceRules.combat_force(state, unit, ROLE.ATTACKER)).is_equal(FORCE + AXE)


func test_210_4_2_granted_rampart_counts_when_defending() -> void:
	var attacker_id := _unit(B, ValueSamples.SOLDIER, "B3")
	var defender_id := _unit(A, ValueSamples.SOLDIER, "B2")
	_builder.attach_gear(defender_id, ValueSamples.SHADOW_CLOAK)
	var state := _builder.build()
	CombatRules.resolve_attack(
		state, state.find_piece(attacker_id), state.find_piece(defender_id), _events
	)
	var combat := _events[0] as CombatResolved
	assert_int(combat.defender_force).is_equal(FORCE + CLOAK)
	assert_object(state.find_piece(defender_id)).is_not_null()
	assert_object(state.find_piece(attacker_id)).is_null()


func test_210_4_2_granted_rampart_does_not_count_when_attacking() -> void:
	var unit_id := _unit(A, ValueSamples.SOLDIER, "B2")
	_builder.attach_gear(unit_id, ValueSamples.SHADOW_CLOAK)
	var state := _builder.build()
	var unit := state.find_piece(unit_id)
	assert_int(ForceRules.combat_force(state, unit, ROLE.ATTACKER)).is_equal(FORCE)
	assert_int(ForceRules.combat_force(state, unit, ROLE.DEFENDER)).is_equal(FORCE + CLOAK)


# --- 210.4.1a, 210.4.2a : les valeurs s'additionnent ---


func test_210_4_1a_granted_assault_adds_to_the_assault_of_the_card() -> void:
	var raider_id := _unit(A, ValueSamples.RAIDER, "B2")
	_builder.attach_gear(raider_id, ValueSamples.WAR_AXE)
	_building(A, ValueSamples.WAR_DRUM, "C2")
	var state := _builder.build()
	var expected := ValueSamples.RAIDER_ASSAULT + AXE + DRUM
	assert_int(KeywordRules.assault_value(state, state.find_piece(raider_id))).is_equal(expected)
	var raider := state.find_piece(raider_id)
	assert_int(ForceRules.combat_force(state, raider, ROLE.ATTACKER)).is_equal(FORCE + expected)


func test_210_4_2a_granted_rampart_adds_to_the_rampart_of_the_card() -> void:
	var guard_id := _unit(A, ValueSamples.GUARD, "B2")
	_builder.attach_gear(guard_id, ValueSamples.SHADOW_CLOAK)
	var state := _builder.build()
	var expected := ValueSamples.GUARD_RAMPART + CLOAK
	assert_int(KeywordRules.rampart_value(state, state.find_piece(guard_id))).is_equal(expected)


func test_210_4_1a_assault_and_rampart_are_granted_separately() -> void:
	var unit_id := _unit(A, ValueSamples.SOLDIER, "B2")
	_builder.attach_gear(unit_id, ValueSamples.WAR_AXE)
	var state := _builder.build()
	assert_int(KeywordRules.assault_value(state, state.find_piece(unit_id))).is_equal(AXE)
	assert_int(KeywordRules.rampart_value(state, state.find_piece(unit_id))).is_equal(0)


# --- effet à durée : 207.4.3, 207.4.7a, 210.4.1 ---


func test_207_4_2_a_spell_grants_the_keyword_with_its_duration() -> void:
	var unit_id := _unit(A, ValueSamples.SOLDIER, "B2")
	var card_id := _builder.add_to_hand(A, ValueSamples.WATCH)
	_start()
	_engine.submit(ValueSamples.cast_fixed(A, card_id, ValueSamples.WATCH_COST, [unit_id]))
	var labels := EventLog.describe(DuelChecks.pass_until_stack_empty(_engine))
	assert_array(labels).contains_exactly(
		["PriorityPassed:B", "KeywordGranted:A", "CardDiscarded:A", "StackEntryResolved:A"]
	)
	var state := _engine.get_state()
	assert_int(state.active_effects.size()).is_equal(1)
	var effect := state.active_effects[0]
	assert_int(effect.keyword).is_equal(CardDefinition.Keyword.ASSAULT)
	assert_int(effect.amount).is_equal(WATCH_VALUE)
	assert_int(effect.duration).is_equal(ActiveEffect.EffectDuration.WHILE_PIECE_IN_PLAY)


func test_207_4_3_a_keyword_granted_until_end_of_turn_ends_with_the_turn() -> void:
	var unit_id := _unit(A, ValueSamples.SOLDIER, "B2")
	var card_id := _builder.add_to_hand(A, ValueSamples.FURY)
	_start()
	_engine.submit(ValueSamples.cast_fixed(A, card_id, ValueSamples.FURY_COST, [unit_id]))
	DuelChecks.pass_until_stack_empty(_engine)
	var state := _engine.get_state()
	assert_int(KeywordRules.assault_value(state, state.find_piece(unit_id))).is_equal(FORCE)
	var labels := EventLog.describe(_engine.submit(EndTurn.new(A)))
	assert_array(labels).contains(["ActiveEffectEnded"])
	assert_int(KeywordRules.assault_value(state, state.find_piece(unit_id))).is_equal(0)


func test_207_4_7a_a_granted_keyword_ends_when_the_piece_leaves_the_board() -> void:
	var unit_id := _unit(A, ValueSamples.SOLDIER, "B2")
	var other_id := _unit(A, ValueSamples.SOLDIER, "D2")
	var card_id := _builder.add_to_hand(A, ValueSamples.WATCH)
	_start()
	_engine.submit(ValueSamples.cast_fixed(A, card_id, ValueSamples.WATCH_COST, [unit_id]))
	DuelChecks.pass_until_stack_empty(_engine)
	var state := _engine.get_state()
	CombatRules.destroy_piece(state, state.find_piece(unit_id), _events)
	assert_array(EventLog.describe(_events)).contains(["ActiveEffectEnded"])
	assert_int(state.active_effects.size()).is_equal(0)
	assert_int(KeywordRules.assault_value(state, state.find_piece(other_id))).is_equal(0)


# --- Gear et aura : 207.2 ---


func test_207_2_8_a_gear_grants_the_keyword_to_the_unit_that_bears_it() -> void:
	var bearer_id := _unit(A, ValueSamples.SOLDIER, "B2")
	var other_id := _unit(A, ValueSamples.SOLDIER, "B3")
	_builder.attach_gear(bearer_id, ValueSamples.WAR_AXE)
	var state := _builder.build()
	assert_int(KeywordRules.assault_value(state, state.find_piece(bearer_id))).is_equal(AXE)
	assert_int(KeywordRules.assault_value(state, state.find_piece(other_id))).is_equal(0)


func test_207_2_9a_a_gear_grant_stops_when_the_gear_is_detached() -> void:
	var bearer_id := _unit(A, ValueSamples.SOLDIER, "B2")
	_builder.attach_gear(bearer_id, ValueSamples.WAR_AXE)
	var state := _builder.build()
	var bearer := state.find_piece(bearer_id)
	bearer.attached_gear = null
	assert_int(KeywordRules.assault_value(state, bearer)).is_equal(0)


func test_207_2_4_an_aura_grant_stops_when_its_building_leaves_the_board() -> void:
	var unit_id := _unit(A, ValueSamples.SOLDIER, "B2")
	var drum_id := _building(A, ValueSamples.WAR_DRUM, "C2")
	var state := _builder.build()
	assert_int(KeywordRules.assault_value(state, state.find_piece(unit_id))).is_equal(DRUM)
	CombatRules.destroy_piece(state, state.find_piece(drum_id), _events)
	assert_int(KeywordRules.assault_value(state, state.find_piece(unit_id))).is_equal(0)


func test_206_5_5_an_aura_grant_touches_only_adjacent_allied_units() -> void:
	var near_id := _unit(A, ValueSamples.SOLDIER, "B2")
	var far_id := _unit(A, ValueSamples.SOLDIER, "E5")
	var enemy_id := _unit(B, ValueSamples.SOLDIER, "C3")
	_building(A, ValueSamples.WAR_DRUM, "C2")
	var state := _builder.build()
	assert_int(KeywordRules.assault_value(state, state.find_piece(near_id))).is_equal(DRUM)
	assert_int(KeywordRules.assault_value(state, state.find_piece(far_id))).is_equal(0)
	assert_int(KeywordRules.assault_value(state, state.find_piece(enemy_id))).is_equal(0)
	state.find_piece(near_id).cell = DuelStateBuilder.cell("A5")
	assert_int(KeywordRules.assault_value(state, state.find_piece(near_id))).is_equal(0)


# --- 202.4.13a, 210.4.1c, 210.4.2c : qui reçoit un mot-clé ---


func test_202_4_13a_a_token_receives_a_keyword_from_an_aura() -> void:
	var token_id := _builder.place_token(
		A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B2"), FORCE
	)
	_building(A, ValueSamples.WAR_DRUM, "C2")
	var state := _builder.build()
	assert_int(KeywordRules.assault_value(state, state.find_piece(token_id))).is_equal(DRUM)


func test_202_4_13a_a_token_receives_a_keyword_from_a_spell() -> void:
	var token_id := _builder.place_token(
		A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B2"), FORCE
	)
	var card_id := _builder.add_to_hand(A, ValueSamples.FURY)
	_start()
	_engine.submit(ValueSamples.cast_fixed(A, card_id, ValueSamples.FURY_COST, [token_id]))
	DuelChecks.pass_until_stack_empty(_engine)
	var state := _engine.get_state()
	assert_int(KeywordRules.assault_value(state, state.find_piece(token_id))).is_equal(FORCE)


func test_210_4_1c_only_a_unit_receives_assault() -> void:
	var building_id := _building(A, ValueSamples.WAR_DRUM, "C2")
	var neighbour_id := _building(A, ValueSamples.WAR_DRUM, "C3")
	_builder.attach_gear(building_id, ValueSamples.WAR_AXE)
	var state := _builder.build()
	assert_int(KeywordRules.assault_value(state, state.find_piece(neighbour_id))).is_equal(0)
	assert_int(KeywordRules.assault_value(state, state.find_piece(building_id))).is_equal(0)
	var hero := state.find_hero(A)
	assert_int(KeywordRules.assault_value(state, hero)).is_equal(0)


func test_210_4_2c_only_a_unit_receives_rampart() -> void:
	var building_id := _building(A, ValueSamples.WAR_DRUM, "C2")
	_builder.attach_gear(building_id, ValueSamples.SHADOW_CLOAK)
	var state := _builder.build()
	assert_int(KeywordRules.rampart_value(state, state.find_piece(building_id))).is_equal(0)
	assert_int(KeywordRules.rampart_value(state, state.find_hero(A))).is_equal(0)


func _start() -> void:
	_engine.start_from_state(_builder.build())


func _unit(side: DuelState.PlayerSide, id: StringName, cell_name: String) -> int:
	return _builder.place_piece(side, Piece.PieceKind.UNIT, DuelStateBuilder.cell(cell_name), id)


func _building(side: DuelState.PlayerSide, id: StringName, cell_name: String) -> int:
	return _builder.place_piece(
		side, Piece.PieceKind.BUILDING, DuelStateBuilder.cell(cell_name), id
	)
