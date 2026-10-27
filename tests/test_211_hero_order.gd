# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## Ordre du Hero (ruleset 0.52, chapitre 211 ; décision de design 0211 du ruleset ; décision 0055).

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const REASON := IntentRejected.RejectReason
const SOURCES_IN_PLAY: int = 4

var _builder: DuelStateBuilder
var _engine: DuelEngine


func before_test() -> void:
	var catalog := OrderSamples.catalog()
	_builder = DuelStateBuilder.new(DuelConfig.new(), catalog)
	for side: DuelState.PlayerSide in [A, B]:
		_builder.with_hero_definition(side, OrderSamples.HERO)
		_builder.with_sources_in_play(side, SOURCES_IN_PLAY, 0)
	_engine = DuelEngine.new(catalog)


func test_211_1_1_order_is_an_effect_the_hero_card_carries() -> void:
	var unit_id := _place(A, "B2")
	_start()
	var definition := _engine.get_state().catalog.get_hero(OrderSamples.HERO)
	assert_int(definition.orders[OrderSamples.BOOST_ORDER].texts[0].effects[0].kind).is_equal(
		EffectDefinition.EffectKind.MODIFY_FORCE
	)
	_engine.submit(OrderSamples.boost_order(A, unit_id))
	DuelChecks.pass_once(_engine, B)
	assert_int(_engine.current_force(unit_id)).is_equal(
		OrderSamples.UNIT_FORCE + OrderSamples.BOOST
	)


func test_211_1_2_order_has_a_speed_action_or_reaction() -> void:
	_start()
	var orders := _engine.get_state().catalog.get_hero(OrderSamples.HERO).orders
	assert_int(orders[OrderSamples.BOOST_ORDER].speed).is_equal(CardDefinition.SpellSpeed.ACTION)
	assert_int(orders[OrderSamples.TOKEN_ORDER].speed).is_equal(CardDefinition.SpellSpeed.REACTION)


func test_211_1_3_order_cost_is_nil_unless_the_card_gives_one() -> void:
	var unit_id := _place(A, "B2")
	_start()
	var free := OrderSamples.boost_order(A, unit_id)
	assert_int(_engine.validate(free)).is_equal(REASON.NONE)
	var paid_for_nothing := OrderSamples.boost_order(A, unit_id)
	paid_for_nothing.payment = EssencePayment.new(1)
	_assert_rejected(paid_for_nothing, REASON.PAYMENT_DOES_NOT_MATCH_COST)
	var orders := _engine.get_state().catalog.get_hero(OrderSamples.HERO).orders
	assert_int(orders[OrderSamples.TOKEN_ORDER].cost).is_equal(OrderSamples.TOKEN_ORDER_COST)


func test_211_1_4_order_is_not_a_spell() -> void:
	_place(A, "B2")
	var counter_id := _builder.add_to_hand(B, OrderSamples.COUNTER_SPELL)
	_start()
	_engine.submit(OrderSamples.boost_order(A, OrderSamples.first_unit_id(_engine.get_state(), A)))
	var state := _engine.get_state()
	var order_entry_id := state.stack[0].stack_entry_id
	var spec := TargetSpec.from_dict({"what": "spell_on_stack"})
	assert_array(TriggerTargets.legal_target_ids(state, B, spec, DuelState.NO_ID)).is_empty()
	var counter := CastSpell.new(B, counter_id, EssencePayment.new(OrderSamples.COUNTER_COST))
	counter.target_stack_entry_ids.append(order_entry_id)
	_assert_rejected(counter, REASON.ILLEGAL_TARGET)
	var resolved := EventLog.describe(DuelChecks.pass_once(_engine, B))
	assert_array(resolved).contains_exactly(
		["PriorityPassed:B", "ForceModified:A", "StackEntryResolved:A"]
	)
	assert_array(state.get_player(A).discard).is_empty()


func test_211_2_1_asleep_hero_does_not_announce_its_order() -> void:
	var unit_id := _place(A, "B2")
	_builder.with_piece_awake(_builder.build().find_hero(A).piece_id, false)
	_start()
	_assert_rejected(OrderSamples.boost_order(A, unit_id), REASON.PIECE_ASLEEP)


func test_211_2_2_hero_falls_asleep_at_announcement() -> void:
	var unit_id := _place(A, "B2")
	_start()
	var state := _engine.get_state()
	_engine.submit(OrderSamples.boost_order(A, unit_id))
	assert_bool(state.find_hero(A).is_awake).is_false()
	state.pieces.erase(state.find_piece(unit_id))
	var resolved := DuelChecks.pass_once(_engine, B)
	assert_array(EventLog.describe(resolved)).contains(["EffectLostAllTargets:A"])
	assert_bool(state.find_hero(A).is_awake).is_false()


# Le seul cas où « pas un coût » change le comportement relève de Q-116, encore ouverte.
func test_211_2_3_falling_asleep_is_not_a_cost() -> void:
	var unit_id := _place(A, "B2")
	_start()
	var player := _engine.get_state().get_player(A)
	var events := _engine.submit(OrderSamples.boost_order(A, unit_id))
	assert_array(EventLog.describe(events)).contains_exactly(
		["OrderAnnounced:A", "StackEntryAdded:A"]
	)
	assert_int(player.sources_upright).is_equal(SOURCES_IN_PLAY)
	assert_int(player.essence_reserve).is_equal(0)
	assert_bool(_engine.get_state().find_hero(A).is_asleep()).is_true()


func test_211_2_4_action_order_only_in_own_main_phase() -> void:
	var unit_id := _place(A, "B2")
	var enemy_unit_id := _place(B, "D4")
	_start()
	_assert_rejected(OrderSamples.boost_order(B, enemy_unit_id), REASON.NOT_YOUR_TURN)
	_engine.get_state().phase = DuelState.DuelPhase.TURN_END
	_assert_rejected(OrderSamples.boost_order(A, unit_id), REASON.WRONG_PHASE)


func test_211_2_5_action_order_only_with_an_empty_stack() -> void:
	var unit_id := _place(A, "B2")
	_builder.push_spell(_builder.make_card_instance(B, OrderSamples.COUNTER_SPELL))
	_builder.with_priority_player(A)
	_start()
	_assert_rejected(OrderSamples.boost_order(A, unit_id), REASON.STACK_NOT_EMPTY)


func test_211_2_6_reaction_order_in_own_main_phase_with_an_empty_stack() -> void:
	_start()
	var cell := OrderSamples.free_first_row_cell(_engine.get_state(), A)
	assert_int(_engine.validate(OrderSamples.token_order(A, cell))).is_equal(REASON.NONE)
	_engine.get_state().phase = DuelState.DuelPhase.TURN_END
	_assert_rejected(OrderSamples.token_order(A, cell), REASON.WRONG_PHASE)


func test_211_2_7_reaction_order_whenever_the_player_may_respond() -> void:
	_builder.push_spell(_builder.make_card_instance(A, OrderSamples.COUNTER_SPELL))
	_builder.with_priority_player(B)
	_start()
	var cell := OrderSamples.free_first_row_cell(_engine.get_state(), B)
	assert_int(_engine.get_state().active_player).is_equal(A)
	assert_int(_engine.validate(OrderSamples.token_order(B, cell))).is_equal(REASON.NONE)
	_engine.get_state().priority_player = A
	_assert_rejected(OrderSamples.token_order(B, cell), REASON.NOT_YOUR_PRIORITY)


func test_211_2_8_order_entry_belongs_to_the_player_of_the_hero() -> void:
	_place(A, "B2")
	_start()
	_engine.submit(OrderSamples.boost_order(A, OrderSamples.first_unit_id(_engine.get_state(), A)))
	_engine.submit(
		OrderSamples.token_order(B, OrderSamples.free_first_row_cell(_engine.get_state(), B))
	)
	var stack := _engine.get_state().stack
	assert_int(stack[0].owner).is_equal(A)
	assert_int(stack[1].owner).is_equal(B)
	assert_int(stack[1].source_piece_id).is_equal(_engine.get_state().find_hero(B).piece_id)


func test_211_3_1_order_cost_is_paid_at_announcement() -> void:
	_start()
	var cell := OrderSamples.free_first_row_cell(_engine.get_state(), A)
	var player := _engine.get_state().get_player(A)
	var short := OrderSamples.token_order(A, cell)
	short.payment = EssencePayment.new(OrderSamples.TOKEN_ORDER_COST - 1)
	_assert_rejected(short, REASON.PAYMENT_DOES_NOT_MATCH_COST)
	var events := _engine.submit(OrderSamples.token_order(A, cell))
	var labels := EventLog.describe(events)
	assert_array(labels.slice(0, OrderSamples.TOKEN_ORDER_COST)).is_equal(
		EventLog.repeat("SourceInclined:A", OrderSamples.TOKEN_ORDER_COST)
	)
	assert_int(player.sources_upright).is_equal(SOURCES_IN_PLAY - OrderSamples.TOKEN_ORDER_COST)
	assert_int(player.sources_tilted).is_equal(OrderSamples.TOKEN_ORDER_COST)


func test_211_3_2_essence_paid_for_an_order_stays_spent_when_it_does_not_happen() -> void:
	_start()
	var cell := OrderSamples.free_first_row_cell(_engine.get_state(), A)
	var player := _engine.get_state().get_player(A)
	_engine.submit(OrderSamples.token_order(A, cell))
	DuelStateBuilder.place_unit_in(
		_engine.get_state(), B, OrderSamples.UNIT, BoardGeometry.cell_name(cell)
	)
	var resolved := DuelChecks.pass_once(_engine, B)
	assert_array(EventLog.describe(resolved)).contains(["EffectLostAllTargets:A"])
	assert_int(player.sources_tilted).is_equal(OrderSamples.TOKEN_ORDER_COST)
	assert_int(player.sources_upright).is_equal(SOURCES_IN_PLAY - OrderSamples.TOKEN_ORDER_COST)


func test_211_4_1_order_targets_are_chosen_at_announcement() -> void:
	var unit_id := _place(A, "B2")
	_start()
	_assert_rejected(AnnounceOrder.new(A, OrderSamples.BOOST_ORDER), REASON.WRONG_TARGET_COUNT)
	var extra := OrderSamples.boost_order(A, unit_id)
	extra.target_cells.append(DuelStateBuilder.cell("C3"))
	_assert_rejected(extra, REASON.WRONG_TARGET_COUNT)
	_engine.submit(OrderSamples.boost_order(A, unit_id))
	assert_array(_engine.get_state().stack[0].target_piece_ids).contains_exactly([unit_id])


func test_211_4_2_order_without_the_minimum_of_legal_targets_is_not_announced() -> void:
	var enemy_unit_id := _place(B, "D4")
	_start()
	_assert_rejected(OrderSamples.boost_order(A, enemy_unit_id), REASON.ILLEGAL_TARGET)
	_assert_rejected(AnnounceOrder.new(A, OrderSamples.BOOST_ORDER), REASON.WRONG_TARGET_COUNT)


func _start() -> void:
	_engine.start_from_state(_builder.build())


func _assert_rejected(intent: DuelIntent, reason: IntentRejected.RejectReason) -> void:
	assert_array(Array(DuelChecks.rejection_defects(_engine, intent, reason))).is_empty()


func _place(side: DuelState.PlayerSide, cell_name: String) -> int:
	return _builder.place_piece(
		side, Piece.PieceKind.UNIT, DuelStateBuilder.cell(cell_name), OrderSamples.UNIT
	)
