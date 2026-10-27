extends GdUnitTestSuite
## Effets déclenchés par une défausse de leur joueur (ruleset 0.54, 212.2.4, 212.2.5, 212.2.2a,
## 207.3.5, 207.3.5a ; décision 0060) : un événement par carte défaussée ; « une fois par tour »
## n'ajoute l'effet à la pile qu'une fois pour l'ensemble des défausses du tour.

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const SOLDIER: StringName = TriggerSamples.SOLDIER
const DISCARD_ONE: StringName = HandEffectSamples.DISCARD_ONE
const DISCARD_TWO: StringName = HandEffectSamples.DISCARD_TWO

var _catalog: Catalog
var _builder: DuelStateBuilder
var _engine: DuelEngine


func before_test() -> void:
	_catalog = NamedTriggerSamples.catalog()
	_builder = HandEffectSamples.builder(_catalog)
	_engine = DuelEngine.new(_catalog)


func test_212_2_4_each_discarded_card_is_a_distinct_event_that_triggers() -> void:
	_place(A, NamedTriggerSamples.GHOST, "B2")
	var spell_id := _builder.add_to_hand(A, DISCARD_TWO)
	HandEffectSamples.fill_hand(_builder, A, 2)
	var labels := _cast_and_resolve(spell_id)
	assert_int(labels.count("CardDiscardedFromHand:A")).is_equal(2)
	assert_int(labels.count("EffectTriggered:A")).is_equal(2)
	var first := labels.find("CardDiscardedFromHand:A")
	assert_str(labels[first + 1]).is_equal("EffectTriggered:A")
	assert_str(labels[first + 2]).is_equal("CardDiscardedFromHand:A")
	assert_str(labels[first + 3]).is_equal("EffectTriggered:A")


func test_212_2_4_trigger_belongs_to_the_player_who_discards() -> void:
	_place(A, NamedTriggerSamples.GHOST, "B2")
	_place(B, NamedTriggerSamples.GHOST, "D4")
	var spell_id := _builder.add_to_hand(A, DISCARD_ONE)
	HandEffectSamples.fill_hand(_builder, A, 1)
	var labels := _cast_and_resolve(spell_id)
	assert_int(labels.count("EffectTriggered:A")).is_equal(1)
	assert_bool(labels.has("EffectTriggered:B")).is_false()


func test_212_2_5_once_per_turn_effect_is_added_once_for_all_the_discards_of_a_resolution() -> void:
	var spectre_id := _place(A, NamedTriggerSamples.SPECTRE, "B2")
	var spell_id := _builder.add_to_hand(A, DISCARD_TWO)
	HandEffectSamples.fill_hand(_builder, A, 2)
	var labels := _cast_and_resolve(spell_id)
	assert_int(labels.count("CardDiscardedFromHand:A")).is_equal(2)
	assert_int(labels.count("EffectTriggered:A")).is_equal(2)
	assert_int(labels.count("TriggerSkipped:A")).is_equal(1)
	assert_int(labels.count("StackEntryAdded:A")).is_equal(1)
	var state := _engine.get_state()
	assert_bool(state.pending_decision == null).is_true()
	var spectre_card := state.find_piece(spectre_id).card
	assert_array(state.once_per_turn_card_ids).contains_exactly([spectre_card.card_instance_id])


func test_212_2_5_once_per_turn_effect_is_added_once_for_all_the_discards_of_the_turn() -> void:
	_place(A, NamedTriggerSamples.SPECTRE, "B2")
	var first_id := _builder.add_to_hand(A, DISCARD_ONE)
	var second_id := _builder.add_to_hand(A, DISCARD_ONE)
	var soldier_ids := HandEffectSamples.fill_hand(_builder, A, 2)
	var first := _cast_and_resolve(first_id, [soldier_ids[0]])
	assert_int(first.count("StackEntryAdded:A")).is_equal(1)
	DuelChecks.pass_once(_engine, B)
	var second := _cast_and_resolve(second_id)
	assert_int(second.count("CardDiscardedFromHand:A")).is_equal(1)
	assert_int(second.count("EffectTriggered:A")).is_equal(1)
	assert_int(second.count("TriggerSkipped:A")).is_equal(1)
	assert_int(second.count("StackEntryAdded:A")).is_equal(0)


func test_212_2_2a_resolved_spell_going_to_the_discard_is_not_a_discard_event() -> void:
	_place(A, NamedTriggerSamples.GHOST, "B2")
	var spell_id := _builder.add_to_hand(A, HandEffectSamples.DRAW_ONE)
	_builder.add_to_deck(A, SOLDIER)
	var labels := _cast_and_resolve(spell_id)
	assert_bool(labels.has("CardDiscarded:A")).is_true()
	assert_bool(labels.has("EffectTriggered:A")).is_false()


# A annonce le Spell `spell_id` ; le joueur B passe, la pile se résout, A choisit `chosen_ids` s'il
# doit choisir. Renvoie les événements (les effets déclenchés par les défausses s'ajoutent à la fin
# de la résolution, 208.4.3).
func _cast_and_resolve(spell_id: int, chosen_ids: Array[int] = []) -> Array[String]:
	if _engine.get_state() == null:
		_engine.start_from_state(_builder.build())
	_engine.submit(HandEffectSamples.cast(A, spell_id))
	var events := DuelChecks.pass_once(_engine, B)
	if not chosen_ids.is_empty():
		events.append_array(_engine.submit(HandEffectSamples.discard(A, chosen_ids)))
	return EventLog.describe(events)


func _place(side: DuelState.PlayerSide, definition_id: StringName, cell: String) -> int:
	return NamedTriggerSamples.place(_builder, side, Piece.PieceKind.UNIT, definition_id, cell)
