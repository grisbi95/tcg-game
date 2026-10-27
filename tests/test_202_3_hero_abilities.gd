# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## Capacités du Hero hors chapitre 211 (ruleset 0.52 ; 201.4.12, 201.5.4c, 202.3.19 à 202.3.21,
## 202.4.6, 204.4.8, 207.3.7, 208.1.12, 208.2.3, 208.7.17, 209.2.10 ; décision de design 0211 du
## ruleset ; décisions 0055 et 0019).

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const REASON := IntentRejected.RejectReason
const TRIGGER_SEQUENCE_LENGTH: int = 10
const SOURCES_IN_PLAY: int = 4
const FIRST_TURN_SEED: int = 11

var _builder: DuelStateBuilder
var _engine: DuelEngine


func before_test() -> void:
	var catalog := OrderSamples.catalog()
	_builder = DuelStateBuilder.new(DuelConfig.new(), catalog)
	for side: DuelState.PlayerSide in [A, B]:
		_builder.with_hero_definition(side, OrderSamples.HERO)
		_builder.with_sources_in_play(side, SOURCES_IN_PLAY, 0)
	_engine = DuelEngine.new(catalog)


# Le moteur est omniscient (201.4, décision 0043) : aucune requête de lecture par joueur n'existe,
# le test lit la carte Hero de chaque joueur dans l'état et le catalogue.
func test_201_4_12_hero_card_and_text_are_readable_for_both_players() -> void:
	_start()
	var state := _engine.get_state()
	for side: DuelState.PlayerSide in [A, B]:
		var definition := state.catalog.get_hero(state.find_hero(side).card.definition_id)
		assert_str(definition.text).is_not_empty()
		assert_int(definition.orders.size()).is_equal(OrderSamples.ORDER_COUNT)


func test_201_5_4c_token_created_by_an_order_belongs_to_the_order_owner() -> void:
	_place(A, "B2")
	_start()
	_engine.submit(OrderSamples.boost_order(A, OrderSamples.first_unit_id(_engine.get_state(), A)))
	var cell := OrderSamples.free_first_row_cell(_engine.get_state(), B)
	_engine.submit(OrderSamples.token_order(B, cell))
	var entry: StackEntry = _engine.get_state().stack.back()
	assert_int(entry.owner).is_equal(B)
	DuelChecks.pass_once(_engine, A)
	assert_int(_engine.get_state().piece_at(cell).owner).is_equal(B)


func test_202_3_19_hero_announces_an_order_its_text_carries() -> void:
	var unit_id := _place(A, "B2")
	_start()
	var events := _engine.submit(OrderSamples.boost_order(A, unit_id))
	assert_array(EventLog.describe(events)).contains_exactly(
		["OrderAnnounced:A", "StackEntryAdded:A"]
	)
	var announced := events[0] as OrderAnnounced
	assert_int(announced.piece_id).is_equal(_engine.get_state().find_hero(A).piece_id)
	assert_int(announced.order_index).is_equal(OrderSamples.BOOST_ORDER)


func test_202_3_20_hero_triggered_effect_goes_on_the_stack_at_end_of_turn() -> void:
	var unit_id := _place(A, "B2")
	_start()
	var events := _engine.submit(EndTurn.new(A))
	var labels := EventLog.describe(events)
	(
		assert_array(labels.slice(0, TRIGGER_SEQUENCE_LENGTH))
		. contains_exactly(
			[
				"TurnEnded:A",
				"EffectTriggered:A",
				"EffectTriggered:B",
				"DecisionResolvedAutomatically:A",
				"DecisionResolvedAutomatically:A",
				"StackEntryAdded:A",
				"TriggerSkipped:B",
				"ForceModified:A",
				"StackEntryResolved:A",
				"ActiveEffectEnded",
			]
		)
	)
	var modified := events[labels.find("ForceModified:A")] as ForceModified
	assert_int(modified.piece_id).is_equal(unit_id)
	assert_int(modified.amount).is_equal(OrderSamples.BOOST)


func test_202_3_21_order_rank_beyond_the_text_is_rejected() -> void:
	var unit_id := _place(A, "B2")
	_start()
	for rank: int in [OrderSamples.ORDER_COUNT, -1]:
		var intent := AnnounceOrder.new(A, rank)
		intent.target_piece_ids.append(unit_id)
		_assert_rejected(intent, REASON.ORDER_NOT_FOUND)


func test_202_4_6_order_may_create_a_token() -> void:
	_start()
	var cell := OrderSamples.free_first_row_cell(_engine.get_state(), A)
	var events := _engine.submit(OrderSamples.token_order(A, cell))
	assert_array(EventLog.describe(events)).contains(["OrderAnnounced:A", "StackEntryAdded:A"])
	var resolved := DuelChecks.pass_once(_engine, B)
	assert_array(EventLog.describe(resolved)).contains_exactly(
		["PriorityPassed:B", "TokenCreated:A", "StackEntryResolved:A"]
	)
	assert_bool(_engine.get_state().piece_at(cell).is_token()).is_true()


func test_204_4_8_active_player_announces_the_order_of_an_awake_hero_in_main_phase() -> void:
	var unit_id := _place(A, "B2")
	_start()
	assert_int(_engine.validate(OrderSamples.boost_order(A, unit_id))).is_equal(REASON.NONE)
	var state := _engine.get_state()
	assert_int(state.phase).is_equal(DuelState.DuelPhase.MAIN)
	assert_int(state.active_player).is_equal(A)
	assert_bool(state.find_hero(A).is_awake).is_true()


func test_208_1_12_order_is_announced_on_the_stack() -> void:
	var unit_id := _place(A, "B2")
	_start()
	_engine.submit(OrderSamples.boost_order(A, unit_id))
	var state := _engine.get_state()
	var hero := state.find_hero(A)
	var entry := state.stack[0]
	assert_int(entry.kind).is_equal(StackEntry.StackEntryKind.ORDER)
	assert_int(entry.source_piece_id).is_equal(hero.piece_id)
	assert_int(entry.source_card_instance_id).is_equal(hero.card.card_instance_id)
	assert_str(entry.source_definition_id).is_equal(OrderSamples.HERO)
	assert_int(entry.text_index).is_equal(OrderSamples.BOOST_ORDER)
	assert_array(entry.target_piece_ids).contains_exactly([unit_id])
	assert_object(entry.card).is_null()


func test_208_2_3_response_may_be_a_reaction_order() -> void:
	_place(A, "B2")
	var enemy_id := _place(B, "D4")
	_start()
	_engine.submit(OrderSamples.boost_order(A, OrderSamples.first_unit_id(_engine.get_state(), A)))
	var cell := OrderSamples.free_first_row_cell(_engine.get_state(), B)
	assert_int(_engine.validate(OrderSamples.token_order(B, cell))).is_equal(REASON.NONE)
	var action_order := OrderSamples.boost_order(B, enemy_id)
	_assert_rejected(action_order, REASON.NOT_YOUR_TURN)


func test_208_7_17_player_may_respond_to_the_announcement_of_an_order() -> void:
	_place(A, "B2")
	_start()
	_engine.submit(OrderSamples.boost_order(A, OrderSamples.first_unit_id(_engine.get_state(), A)))
	var state := _engine.get_state()
	assert_bool(state.stack[0].allows_response).is_true()
	assert_int(state.priority_player).is_equal(B)
	var events := _engine.submit(
		OrderSamples.token_order(B, OrderSamples.free_first_row_cell(_engine.get_state(), B))
	)
	assert_array(EventLog.describe(events)).contains(["OrderAnnounced:B", "StackEntryAdded:B"])
	assert_int(state.stack.size()).is_equal(2)
	assert_int(state.priority_player).is_equal(A)


func test_209_2_10_order_announcement_counts_as_an_announcement() -> void:
	var unit_id := _place(A, "B2")
	_start()
	var state := _engine.get_state()
	assert_bool(state.get_player(A).announced_this_turn).is_false()
	_engine.submit(OrderSamples.boost_order(A, unit_id))
	assert_bool(state.get_player(A).announced_this_turn).is_true()


func test_207_3_7_hero_once_per_turn_effect_is_counted_by_its_card() -> void:
	_place(A, "B2")
	_builder.with_hero_definition(A, OrderSamples.ONCE_HERO)
	_builder.with_phase(DuelState.DuelPhase.TURN_END)
	_start()
	var state := _engine.get_state()
	var hero_card_id := state.find_hero(A).card.card_instance_id
	var events: Array[DuelEvent] = []
	TurnRules.trigger_end_of_turn(state, events)
	TriggerRules.add_waiting_triggers(state, events)
	assert_array(state.once_per_turn_texts).contains_exactly([Vector2i(hero_card_id, 0)])
	assert_int(state.stack.size()).is_equal(1)
	events.clear()
	TurnRules.trigger_end_of_turn(state, events)
	TriggerRules.add_waiting_triggers(state, events)
	var own_labels := EventLog.describe(events).filter(
		func(label: String) -> bool: return label.ends_with(":A")
	)
	assert_array(own_labels).contains_exactly(["EffectTriggered:A", "TriggerSkipped:A"])
	assert_int(state.stack.size()).is_equal(1)


func test_decision_0019_agent_tries_an_order_among_its_candidates() -> void:
	_place(A, "B2")
	_start()
	var orders := RandomLegalAgent.candidates(_engine.get_state(), A).filter(
		func(intent: DuelIntent) -> bool: return intent is AnnounceOrder
	)
	assert_array(orders).is_not_empty()
	var legal := orders.filter(
		func(intent: DuelIntent) -> bool: return _engine.validate(intent) == REASON.NONE
	)
	assert_array(legal).is_not_empty()


func test_decision_0055_duel_where_the_hero_uses_its_order_and_its_triggered_effect() -> void:
	_engine = DuelEngine.new(OrderSamples.catalog())
	var setup := SetupSamples.mirror_setup(SetupSamples.deck(), OrderSamples.HERO, FIRST_TURN_SEED)
	setup.impose_first_player(A)
	_engine.start_new_duel(setup)
	_engine.submit(ChooseMulligan.new(A))
	_engine.submit(ChooseMulligan.new(B))
	var state := _engine.get_state()
	var card := state.get_player(A).hand[0]
	var cell := OrderSamples.free_first_row_cell(_engine.get_state(), A)
	var deploy := DeployCard.new(A, card.card_instance_id, cell, EssencePayment.new(2))
	_engine.submit(deploy)
	var unit := state.piece_at(cell)
	assert_object(unit).is_not_null()
	var base_force := _engine.current_force(unit.piece_id)
	var events := _engine.submit(OrderSamples.boost_order(A, unit.piece_id))
	assert_array(EventLog.describe(events)).contains_exactly(
		["OrderAnnounced:A", "StackEntryAdded:A"]
	)
	DuelChecks.pass_once(_engine, B)
	assert_int(_engine.current_force(unit.piece_id)).is_equal(base_force + OrderSamples.BOOST)
	var end_events := EventLog.describe(_engine.submit(EndTurn.new(A)))
	assert_array(end_events).contains(["EffectTriggered:A", "StackEntryAdded:A"])
	DuelChecks.pass_once(_engine, B)
	assert_int(state.active_player).is_equal(B)


func _start() -> void:
	_engine.start_from_state(_builder.build())


func _assert_rejected(intent: DuelIntent, reason: IntentRejected.RejectReason) -> void:
	assert_array(Array(DuelChecks.rejection_defects(_engine, intent, reason))).is_empty()


func _place(side: DuelState.PlayerSide, cell_name: String) -> int:
	return _builder.place_piece(
		side, Piece.PieceKind.UNIT, DuelStateBuilder.cell(cell_name), OrderSamples.UNIT
	)
