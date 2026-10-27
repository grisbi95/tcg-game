extends GdUnitTestSuite
## « Détruit son défenseur » (ruleset 0.54, 206.3.7 à 206.3.7b, 207.3.12 ; décision 0060) : une Unit
## qui attaque détruit son défenseur quand le défenseur est détruit sans qu'elle le soit ; ni à
## égalité, ni contre un Hero. Les attaques se résolvent directement par CombatRules.

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const SOLDIER: StringName = TriggerSamples.SOLDIER  # Force 2
const GIANT: StringName = TriggerSamples.GIANT  # Force 5
const CONQUEROR: StringName = NamedTriggerSamples.CONQUEROR  # Force 4

var _catalog: Catalog
var _builder: DuelStateBuilder
var _events: Array[DuelEvent] = []


func before_test() -> void:
	_catalog = NamedTriggerSamples.catalog()
	_builder = HandEffectSamples.builder(_catalog)
	_events.clear()


func test_206_3_7_unit_that_wins_its_combat_destroys_its_defender() -> void:
	var attacker_id := _place(A, CONQUEROR, "B2")
	var defender_id := _place(B, SOLDIER, "B3")
	var state := _attack(attacker_id, defender_id)
	assert_array(EventLog.describe(_events)).contains_exactly(
		["CombatResolved", "PieceDestroyed:B", "PieceMoved:A", "EffectTriggered:A"]
	)
	var waiting := state.waiting_triggers[0]
	assert_int(waiting.source_piece_id).is_equal(attacker_id)
	assert_int(waiting.owner).is_equal(A)


func test_206_3_7_effect_of_the_attacker_goes_on_the_stack() -> void:
	var attacker_id := _place(A, CONQUEROR, "B2")
	_builder.add_to_deck(A, SOLDIER)
	var state := _attack(attacker_id, _place(B, SOLDIER, "B3"))
	TriggerRules.add_waiting_triggers(state, _events)
	assert_int(state.stack.size()).is_equal(1)
	assert_int(state.stack[0].kind).is_equal(StackEntry.StackEntryKind.TRIGGERED_EFFECT)
	assert_str(String(state.stack[0].source_definition_id)).is_equal(String(CONQUEROR))


func test_206_3_7_the_unit_that_carries_a_gear_is_the_author_for_the_gear() -> void:
	var attacker_id := _place(A, GIANT, "B2")
	var gear_id := _builder.attach_gear(attacker_id, NamedTriggerSamples.GRIMOIRE)
	var state := _attack(attacker_id, _place(B, SOLDIER, "B3"))
	assert_array(EventLog.describe(_events)).contains_exactly(
		["CombatResolved", "PieceDestroyed:B", "PieceMoved:A", "EffectTriggered:A"]
	)
	var waiting := state.waiting_triggers[0]
	assert_int(waiting.source_piece_id).is_equal(attacker_id)
	assert_int(waiting.source_card_instance_id).is_equal(gear_id)


func test_206_3_7_defender_destroyed_alone_does_not_trigger_a_gear_of_the_defender() -> void:
	var defender_id := _place(B, SOLDIER, "B3")
	_builder.attach_gear(defender_id, NamedTriggerSamples.GRIMOIRE)
	var state := _attack(_place(A, GIANT, "B2"), defender_id)
	assert_array(state.waiting_triggers).is_empty()


func test_206_3_7_attacker_destroyed_by_a_stronger_defender_destroys_nothing() -> void:
	var attacker_id := _place(A, CONQUEROR, "B2")
	var state := _attack(attacker_id, _place(B, GIANT, "B3"))
	assert_array(EventLog.describe(_events)).contains_exactly(
		["CombatResolved", "PieceDestroyed:A"]
	)
	assert_array(state.waiting_triggers).is_empty()


func test_206_3_7a_tie_does_not_destroy_the_defender() -> void:
	var attacker_id := _place(A, CONQUEROR, "B2")
	_builder.attach_gear(attacker_id, NamedTriggerSamples.GRIMOIRE)
	var defender_id := _place(B, NamedTriggerSamples.CONQUEROR, "B3")
	var state := _attack(attacker_id, defender_id)
	assert_array(EventLog.describe(_events)).contains_exactly(
		["CombatResolved", "PieceDestroyed:B", "PieceDestroyed:A", "CardDiscarded:A"]
	)
	assert_array(state.waiting_triggers).is_empty()


func test_206_3_7a_tie_without_destruction_does_not_destroy_the_defender_either() -> void:
	var config := DuelConfig.new()
	config.tie_destroys_both = false
	_builder = DuelStateBuilder.new(config, _catalog)
	var attacker_id := _place(A, CONQUEROR, "B2")
	var state := _attack(attacker_id, _place(B, NamedTriggerSamples.CONQUEROR, "B3"))
	assert_array(EventLog.describe(_events)).contains_exactly(["CombatResolved"])
	assert_array(state.waiting_triggers).is_empty()


func test_206_3_7b_unit_that_attacks_a_hero_does_not_destroy_a_defender() -> void:
	var attacker_id := _place(A, CONQUEROR, "C4")
	_builder.attach_gear(attacker_id, NamedTriggerSamples.GRIMOIRE)
	var state := _builder.build()
	var hero := state.find_hero(B)
	CombatRules.resolve_attack(state, state.find_piece(attacker_id), hero, _events)
	assert_array(EventLog.describe(_events)).contains(["HeroAttacked:B"])
	assert_array(state.waiting_triggers).is_empty()


func _place(side: DuelState.PlayerSide, definition_id: StringName, cell: String) -> int:
	return NamedTriggerSamples.place(_builder, side, Piece.PieceKind.UNIT, definition_id, cell)


func _attack(attacker_id: int, defender_id: int) -> DuelState:
	var state := _builder.build()
	CombatRules.resolve_attack(
		state, state.find_piece(attacker_id), state.find_piece(defender_id), _events
	)
	return state
