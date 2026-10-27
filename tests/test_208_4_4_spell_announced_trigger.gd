extends GdUnitTestSuite
## Effets déclenchés par l'annonce d'un Spell de leur joueur (ruleset 0.54, 208.4.4, 208.2.4,
## 207.3.5 ; décision 0060) : l'effet s'ajoute au sommet de la pile aussitôt après l'annonce, et
## l'adversaire peut y répondre le premier.

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const SOLDIER: StringName = TriggerSamples.SOLDIER
const DRAW_ONE: StringName = HandEffectSamples.DRAW_ONE
const DECK_SIZE: int = 6

var _catalog: Catalog
var _builder: DuelStateBuilder
var _engine: DuelEngine


func before_test() -> void:
	_catalog = NamedTriggerSamples.catalog()
	_builder = HandEffectSamples.builder(_catalog)
	for index: int in DECK_SIZE:
		_builder.add_to_deck(A, SOLDIER)
		_builder.add_to_deck(B, SOLDIER)
	_engine = DuelEngine.new(_catalog)


func test_208_4_4_trigger_of_a_spell_announcement_is_added_right_after_it() -> void:
	_place(A, NamedTriggerSamples.APPRENTICE, "B2")
	var spell_id := _builder.add_to_hand(A, DRAW_ONE)
	_engine.start_from_state(_builder.build())
	var labels := EventLog.describe(_engine.submit(HandEffectSamples.cast(A, spell_id)))
	(
		assert_array(labels.slice(labels.find("SpellAnnounced:A")))
		. contains_exactly(
			[
				"SpellAnnounced:A",
				"StackEntryAdded:A",
				"EffectTriggered:A",
				"DecisionResolvedAutomatically:A",
				"StackEntryAdded:A",
			]
		)
	)
	var stack := _engine.get_state().stack
	assert_int(stack.size()).is_equal(2)
	assert_int(stack[0].kind).is_equal(StackEntry.StackEntryKind.SPELL)
	assert_int(stack[1].kind).is_equal(StackEntry.StackEntryKind.TRIGGERED_EFFECT)


func test_208_2_4_opponent_answers_first_the_trigger_of_an_announcement() -> void:
	_place(A, NamedTriggerSamples.APPRENTICE, "B2")
	var spell_id := _builder.add_to_hand(A, DRAW_ONE)
	_engine.start_from_state(_builder.build())
	_engine.submit(HandEffectSamples.cast(A, spell_id))
	var state := _engine.get_state()
	assert_bool(state.stack[1].allows_response).is_true()
	assert_int(state.priority_player).is_equal(B)


func test_208_4_4_trigger_resolves_before_the_spell_that_triggered_it() -> void:
	_place(A, NamedTriggerSamples.APPRENTICE, "B2")
	var spell_id := _builder.add_to_hand(A, DRAW_ONE)
	_engine.start_from_state(_builder.build())
	_engine.submit(HandEffectSamples.cast(A, spell_id))
	var labels := EventLog.describe(DuelChecks.pass_once(_engine, B))
	(
		assert_array(labels)
		. contains_exactly(
			[
				"PriorityPassed:B",
				"ForceModified:A",
				"StackEntryResolved:A",
				"CardDrawn:A",
				"CardDiscarded:A",
				"StackEntryResolved:A",
			]
		)
	)


func test_208_4_4_announcement_of_the_opponent_does_not_trigger_an_own_event() -> void:
	_place(A, NamedTriggerSamples.APPRENTICE, "B2")
	_place(B, NamedTriggerSamples.APPRENTICE, "D4")
	var spell_id := _builder.add_to_hand(B, DRAW_ONE)
	_builder.with_active_player(B).with_priority_player(B)
	_engine.start_from_state(_builder.build())
	var events := _engine.submit(HandEffectSamples.cast(B, spell_id))
	var triggered := EventLog.describe(events).filter(
		func(label: String) -> bool: return label.begins_with("EffectTriggered")
	)
	assert_array(triggered).contains_exactly(["EffectTriggered:B"])


func test_208_4_4_every_announcement_triggers_a_trigger_without_once_per_turn() -> void:
	_place(A, NamedTriggerSamples.APPRENTICE, "B2")
	var first_id := _builder.add_to_hand(A, DRAW_ONE)
	var second_id := _builder.add_to_hand(A, DRAW_ONE)
	_engine.start_from_state(_builder.build())
	_engine.submit(HandEffectSamples.cast(A, first_id))
	DuelChecks.pass_once(_engine, B)
	var labels := EventLog.describe(_engine.submit(HandEffectSamples.cast(A, second_id)))
	assert_bool(labels.has("EffectTriggered:A")).is_true()
	assert_bool(labels.has("TriggerSkipped:A")).is_false()


func test_207_3_5a_once_per_turn_spell_trigger_happens_once_for_the_turn() -> void:
	_place(A, NamedTriggerSamples.SPELLBLADE, "B2")
	var first_id := _builder.add_to_hand(A, DRAW_ONE)
	var second_id := _builder.add_to_hand(A, DRAW_ONE)
	_engine.start_from_state(_builder.build())
	var first := EventLog.describe(_engine.submit(HandEffectSamples.cast(A, first_id)))
	assert_bool(first.has("EffectTriggered:A")).is_true()
	assert_int(_engine.get_state().stack.size()).is_equal(2)
	DuelChecks.pass_once(_engine, B)
	var second := EventLog.describe(_engine.submit(HandEffectSamples.cast(A, second_id)))
	assert_array(second.slice(second.find("SpellAnnounced:A"))).contains_exactly(
		["SpellAnnounced:A", "StackEntryAdded:A", "EffectTriggered:A", "TriggerSkipped:A"]
	)
	assert_int(_engine.get_state().stack.size()).is_equal(1)


func _place(side: DuelState.PlayerSide, definition_id: StringName, cell: String) -> int:
	return NamedTriggerSamples.place(_builder, side, Piece.PieceKind.UNIT, definition_id, cell)
