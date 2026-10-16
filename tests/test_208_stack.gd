extends GdUnitTestSuite
## Pile et priorité sans effet déclenché (ruleset 0.30, chapitre 208 ; 209.2.1 et 209.2.3).
##
## Les entrées sont posées par le builder ou par StackRules.add_to_stack, comme des annonces
## déjà faites : aucune annonce n'est encore codée (étapes 1.5 et 1.6). Le test de 209.2.3
## part d'un Hero déjà à 0 PV, faute d'effet : à réécrire avec un Spell à l'étape 1.6.

const CARD: StringName = &"plain_spell"

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const REASON := IntentRejected.RejectReason

var _builder: DuelStateBuilder
var _engine: DuelEngine


func before_test() -> void:
	var catalog := Catalog.new()
	var plain_spell := CatalogSamples.with_field(CatalogSamples.spell(), "id", String(CARD))
	plain_spell = CatalogSamples.with_field(plain_spell, "effects", [])
	catalog.add_card(CardDefinition.from_dict(plain_spell))
	_builder = DuelStateBuilder.new(DuelConfig.new(), catalog)
	_engine = DuelEngine.new(SetupSamples.catalog())


func test_208_4_1_announcement_goes_on_top_of_stack() -> void:
	var state := _builder.build()
	var events: Array[DuelEvent] = []
	var first_id := StackRules.add_to_stack(state, _make_entry(A), events)
	var second_id := StackRules.add_to_stack(state, _make_entry(B), events)
	assert_array(_stack_ids(state)).contains_exactly([first_id, second_id])
	assert_array(EventLog.describe(events)).contains_exactly(
		["StackEntryAdded:A", "StackEntryAdded:B"]
	)
	assert_int((events[1] as StackEntryAdded).stack_entry_id).is_equal(second_id)


func test_208_2_4_opponent_of_top_owner_answers_first() -> void:
	var state := _builder.build()
	var events: Array[DuelEvent] = []
	StackRules.add_to_stack(state, _make_entry(A), events)
	assert_int(state.priority_player).is_equal(B)
	StackRules.add_to_stack(state, _make_entry(B), events)
	assert_int(state.priority_player).is_equal(A)


func test_208_2_2_pass_lets_opponent_answer_or_pass() -> void:
	var entry_id := _push_spell_of(A)
	_engine.start_from_state(_builder.with_priority_player(B).build())
	var events := _engine.submit(PassPriority.new(B))
	assert_array(EventLog.describe(events)).contains_exactly(["PriorityPassed:B"])
	var state := _engine.get_state()
	assert_int(state.priority_player).is_equal(A)
	assert_int(state.consecutive_passes).is_equal(1)
	assert_object(state.find_stack_entry(entry_id)).is_not_null()


func test_208_3_1_two_passes_in_a_row_resolve_whole_stack() -> void:
	for side: DuelState.PlayerSide in [A, B, A]:
		_push_spell_of(side)
	_engine.start_from_state(_builder.with_priority_player(B).build())
	var events := _engine.submit(PassPriority.new(B))
	events.append_array(_engine.submit(PassPriority.new(A)))
	var expected: Array[String] = ["PriorityPassed:B", "PriorityPassed:A"]
	for side: String in ["A", "B", "A"]:
		expected.append_array(["CardDiscarded:" + side, "StackEntryResolved:" + side])
	assert_array(EventLog.describe(events)).contains_exactly(expected)
	assert_array(_engine.get_state().stack).is_empty()


func test_208_3_1_announcement_between_passes_restarts_count() -> void:
	_push_spell_of(A)
	_engine.start_from_state(_builder.with_priority_player(B).build())
	_engine.submit(PassPriority.new(B))
	var events: Array[DuelEvent] = []
	# Annonce simulée : les annonces arrivent avec leur chapitre (étapes 1.5 et 1.6).
	StackRules.add_to_stack(_engine.get_state(), _make_entry(A), events)
	assert_int(_engine.get_state().consecutive_passes).is_equal(0)
	var labels := EventLog.describe(_engine.submit(PassPriority.new(B)))
	assert_array(labels).contains_exactly(["PriorityPassed:B"])
	assert_int(_engine.get_state().stack.size()).is_equal(2)


func test_208_3_2_last_added_resolves_first() -> void:
	var added_ids: Array[int] = []
	for side: DuelState.PlayerSide in [A, B, A]:
		added_ids.append(_push_spell_of(side))
	_engine.start_from_state(_builder.with_priority_player(B).build())
	_engine.submit(PassPriority.new(B))
	var resolved_ids: Array[int] = []
	for event: DuelEvent in _engine.submit(PassPriority.new(A)):
		if event is StackEntryResolved:
			resolved_ids.append((event as StackEntryResolved).stack_entry_id)
	added_ids.reverse()
	assert_array(resolved_ids).is_equal(added_ids)


func test_208_3_3_whole_stack_resolves_within_one_submission() -> void:
	_push_spell_of(A)
	_push_spell_of(B)
	_engine.start_from_state(_builder.with_priority_player(A).build())
	_engine.submit(PassPriority.new(A))
	var labels := EventLog.describe(_engine.submit(PassPriority.new(B)))
	(
		assert_array(labels)
		. contains_exactly(
			[
				"PriorityPassed:B",
				"CardDiscarded:B",
				"StackEntryResolved:B",
				"CardDiscarded:A",
				"StackEntryResolved:A",
			]
		)
	)


func test_208_5_1_active_player_acts_again_once_stack_is_empty() -> void:
	_push_spell_of(A)
	_push_spell_of(B)
	_builder.with_active_player(A).with_priority_player(A)
	_engine.start_from_state(_builder.build())
	_engine.submit(PassPriority.new(A))
	_engine.submit(PassPriority.new(B))
	var state := _engine.get_state()
	assert_int(state.priority_player).is_equal(A)
	assert_int(state.consecutive_passes).is_equal(0)
	assert_int(_engine.validate(EndTurn.new(A))).is_equal(REASON.NONE)


func test_209_2_3_resolution_stops_when_duel_ends() -> void:
	var bottom_id := _push_spell_of(A)
	_push_spell_of(B)
	_builder.with_hero_health(B, 0).with_priority_player(A)
	_engine.start_from_state(_builder.build())
	_engine.submit(PassPriority.new(A))
	var labels := EventLog.describe(_engine.submit(PassPriority.new(B)))
	assert_array(labels.slice(labels.size() - 2)).contains_exactly(
		["StackEntryResolved:B", "DuelEnded"]
	)
	var state := _engine.get_state()
	assert_int(state.phase).is_equal(DuelState.DuelPhase.ENDED)
	assert_object(state.find_stack_entry(bottom_id)).is_not_null()


func test_208_2_4_pass_with_empty_stack_rejected() -> void:
	_engine.start_from_state(_builder.build())
	_assert_rejected(PassPriority.new(A), REASON.STACK_EMPTY)


func test_208_2_2_pass_out_of_turn_rejected() -> void:
	_push_spell_of(A)
	_engine.start_from_state(_builder.with_priority_player(B).build())
	_assert_rejected(PassPriority.new(A), REASON.NOT_YOUR_PRIORITY)


func test_pass_while_decision_pending_rejected() -> void:
	_push_spell_of(A)
	var decision := PendingDecision.new()
	decision.kind = PendingDecision.DecisionKind.ORDER_TRIGGERS
	decision.awaited_players.append(B)
	_builder.with_priority_player(B).with_pending_decision(decision)
	_engine.start_from_state(_builder.build())
	_assert_rejected(PassPriority.new(B), REASON.DECISION_PENDING)


func _push_spell_of(side: DuelState.PlayerSide) -> int:
	return _builder.push_spell(_builder.make_card_instance(side, CARD))


func _make_entry(side: DuelState.PlayerSide) -> StackEntry:
	var entry := StackEntry.new()
	entry.kind = StackEntry.StackEntryKind.SPELL
	entry.owner = side
	return entry


func _stack_ids(state: DuelState) -> Array[int]:
	var identifiers: Array[int] = []
	for entry: StackEntry in state.stack:
		identifiers.append(entry.stack_entry_id)
	return identifiers


func _assert_rejected(intent: DuelIntent, expected: IntentRejected.RejectReason) -> void:
	assert_array(DuelChecks.rejection_defects(_engine, intent, expected)).is_empty()
