extends GdUnitTestSuite
## Sujet « pièce source » de MODIFY_FORCE et DESTROY (ruleset 0.55 ; 207.3.12 à 207.3.12c, 207.2.8,
## 207.3.3, 207.4.2, 207.4.3, 207.4.7, 200.4.1, glossaire Détruire ; décisions 0061 et 0062) :
## Apprenti, Spectre des archives, Trophée et « détruisez ce Building », sous leur texte (« cette
## Unit », « elle », « ce Building »). Les cartes viennent de NamedTriggerSamples et FilterSamples.

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const SOLDIER: StringName = TriggerSamples.SOLDIER
const GIANT: StringName = TriggerSamples.GIANT
const DECK_SIZE: int = 6
const APPRENTICE_BONUS: int = 1  # « +1 Force jusqu'à la fin du tour »

var _catalog: Catalog
var _builder: DuelStateBuilder
var _engine: DuelEngine
var _events: Array[DuelEvent] = []


func before_test() -> void:
	_catalog = FilterSamples.catalog()
	_builder = HandEffectSamples.builder(_catalog)
	_engine = DuelEngine.new(_catalog)
	_events.clear()
	for index: int in DECK_SIZE:
		_builder.add_to_deck(A, SOLDIER)
		_builder.add_to_deck(B, SOLDIER)


func test_207_4_2_apprentice_has_force_until_the_end_of_the_turn() -> void:
	var apprentice_id := _place(A, NamedTriggerSamples.APPRENTICE, "B2")
	var spell_id := _builder.add_to_hand(A, HandEffectSamples.DRAW_ONE)
	_engine.start_from_state(_builder.build())
	_engine.submit(HandEffectSamples.cast(A, spell_id))
	var labels := EventLog.describe(DuelChecks.pass_once(_engine, B))
	assert_array(labels.slice(0, 3)).contains_exactly(
		["PriorityPassed:B", "ForceModified:A", "StackEntryResolved:A"]
	)
	var state := _engine.get_state()
	var apprentice := state.find_piece(apprentice_id)
	assert_int(ForceRules.current_force(state, apprentice)).is_equal(
		NamedTriggerSamples.APPRENTICE_FORCE + APPRENTICE_BONUS
	)
	var effect := state.active_effects[0]
	assert_int(effect.duration).is_equal(ActiveEffect.EffectDuration.UNTIL_END_OF_TURN)
	assert_int(effect.affected_piece_id).is_equal(apprentice_id)


func test_207_4_3_apprentice_force_ends_with_the_turn() -> void:
	var apprentice_id := _place(A, NamedTriggerSamples.APPRENTICE, "B2")
	var spell_id := _builder.add_to_hand(A, HandEffectSamples.DRAW_ONE)
	_engine.start_from_state(_builder.build())
	_engine.submit(HandEffectSamples.cast(A, spell_id))
	DuelChecks.pass_once(_engine, B)
	var labels := EventLog.describe(_engine.submit(EndTurn.new(A)))
	assert_bool(labels.has("ActiveEffectEnded")).is_true()
	var state := _engine.get_state()
	var force := ForceRules.current_force(state, state.find_piece(apprentice_id))
	assert_int(force).is_equal(NamedTriggerSamples.APPRENTICE_FORCE)


func test_207_4_2_apprentice_gets_force_for_each_spell_announced() -> void:
	var apprentice_id := _place(A, NamedTriggerSamples.APPRENTICE, "B2")
	var first_id := _builder.add_to_hand(A, HandEffectSamples.DRAW_ONE)
	var second_id := _builder.add_to_hand(A, HandEffectSamples.DRAW_ONE)
	_engine.start_from_state(_builder.build())
	_engine.submit(HandEffectSamples.cast(A, first_id))
	DuelChecks.pass_once(_engine, B)
	_engine.submit(HandEffectSamples.cast(A, second_id))
	DuelChecks.pass_once(_engine, B)
	var state := _engine.get_state()
	var force := ForceRules.current_force(state, state.find_piece(apprentice_id))
	assert_int(force).is_equal(NamedTriggerSamples.APPRENTICE_FORCE + 2 * APPRENTICE_BONUS)


func test_212_2_4_spectre_has_force_when_a_card_is_discarded_from_the_hand() -> void:
	var spectre_id := _place(A, NamedTriggerSamples.SPECTRE, "B2")
	var spell_id := _builder.add_to_hand(A, HandEffectSamples.DISCARD_ONE)
	var soldier_ids := HandEffectSamples.fill_hand(_builder, A, 2)
	_engine.start_from_state(_builder.build())
	_engine.submit(HandEffectSamples.cast(A, spell_id))
	DuelChecks.pass_once(_engine, B)
	_engine.submit(HandEffectSamples.discard(A, [soldier_ids[0]]))
	DuelChecks.pass_once(_engine, B)
	var state := _engine.get_state()
	var force := ForceRules.current_force(state, state.find_piece(spectre_id))
	assert_int(force).is_equal(
		NamedTriggerSamples.SPECTRE_FORCE + NamedTriggerSamples.SPECTRE_BONUS
	)


func test_207_3_12_trophy_gives_force_to_the_unit_that_bears_the_gear() -> void:
	var state := _trigger_trophy()
	var attacker_id := state.waiting_triggers[0].source_piece_id
	var labels := _resolve(state)
	assert_array(labels).contains_exactly(
		["PriorityPassed:B", "ForceModified:A", "StackEntryResolved:A"]
	)
	var attacker := state.find_piece(attacker_id)
	assert_int(ForceRules.current_force(state, attacker)).is_equal(
		TriggerSamples.GIANT_FORCE + NamedTriggerSamples.TROPHY_BONUS
	)
	var effect := state.active_effects[0]
	assert_int(effect.duration).is_equal(ActiveEffect.EffectDuration.WHILE_PIECE_IN_PLAY)
	assert_int(effect.affected_piece_id).is_equal(attacker_id)


func test_207_3_12c_trophy_effect_happens_for_the_unit_though_the_gear_was_detached() -> void:
	var state := _trigger_trophy()
	var attacker := state.find_piece(state.waiting_triggers[0].source_piece_id)
	attacker.attached_gear = null
	_resolve(state)
	assert_int(ForceRules.current_force(state, attacker)).is_equal(
		TriggerSamples.GIANT_FORCE + NamedTriggerSamples.TROPHY_BONUS
	)


func test_200_4_1_effect_on_a_source_piece_that_left_the_board_does_not_happen() -> void:
	var state := _trigger_trophy()
	var attacker := state.find_piece(state.waiting_triggers[0].source_piece_id)
	CombatRules.destroy_piece(state, attacker, _events)
	var labels := _resolve(state)
	assert_array(labels).contains_exactly(["PriorityPassed:B", "StackEntryResolved:A"])
	assert_array(state.active_effects).is_empty()


func test_206_3_2_demolition_sends_its_own_building_to_the_discard() -> void:
	var building_id := _builder.place_piece(
		A, Piece.PieceKind.BUILDING, DuelStateBuilder.cell("B2"), FilterSamples.DEMOLITION
	)
	_builder.with_active_player(B)
	_engine.start_from_state(_builder.build())
	var events := _engine.submit(EndTurn.new(B))
	events.append_array(DuelChecks.pass_until_stack_empty(_engine))
	var labels := EventLog.describe(events)
	assert_bool(labels.has("PieceDestroyed:A")).is_true()
	var state := _engine.get_state()
	assert_object(state.find_piece(building_id)).is_null()
	assert_int(state.get_player(A).discard.size()).is_equal(1)


func test_200_4_1_destroy_effect_on_a_source_piece_that_left_the_board_does_not_happen() -> void:
	var worksite_id := _builder.place_piece(
		A, Piece.PieceKind.BUILDING, DuelStateBuilder.cell("B2"), FilterSamples.DEMOLITION
	)
	var state := _builder.build()
	var entry := StackEntry.new()
	entry.source_piece_id = worksite_id
	entry.owner = A
	state.pieces.erase(state.find_piece(worksite_id))
	var effect := _catalog.triggerable_effects(FilterSamples.DEMOLITION)[0]
	EffectRules.resolve_effect(state, entry, effect, _events)
	assert_array(_events).is_empty()


# Le Géant de A, qui porte le Trophée, attaque le Soldat de B et le détruit : l'effet du Trophée
# attend (207.3.12).
func _trigger_trophy() -> DuelState:
	var attacker_id := _place(A, GIANT, "B2")
	_builder.attach_gear(attacker_id, NamedTriggerSamples.TROPHY)
	var defender_id := _place(B, SOLDIER, "B3")
	var state := _builder.build()
	CombatRules.resolve_attack(
		state, state.find_piece(attacker_id), state.find_piece(defender_id), _events
	)
	assert_int(state.waiting_triggers.size()).is_equal(1)
	return state


func _resolve(state: DuelState) -> Array[String]:
	var engine := DuelEngine.new(_catalog)
	engine.start_from_state(state)
	TriggerRules.add_waiting_triggers(state, _events)
	return EventLog.describe(DuelChecks.pass_once(engine, B))


func _place(side: DuelState.PlayerSide, definition_id: StringName, cell: String) -> int:
	return NamedTriggerSamples.place(_builder, side, Piece.PieceKind.UNIT, definition_id, cell)
