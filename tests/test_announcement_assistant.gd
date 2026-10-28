extends GdUnitTestSuite
## Assistant d'annonce de DuelSelection (décision 0068) : X puis cible (213.1.9), deux cibles
## (214, 215), Ordre du Hero (211), annulation, aucune intention illégale. Les cartes viennent de
## ValueSamples, MovementSamples et OrderSamples.

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const SELECTION := DuelSelection.SelectionState
const SOLDIER_FORCE: int = ValueSamples.UNIT_FORCE
const ESSENCE_RESERVE: int = 5

var _builder: DuelStateBuilder
var _engine: DuelEngine
var _selection: DuelSelection
var _emitted: Array[DuelIntent] = []
var _enemy_id: int = DuelState.NO_ID


func before_test() -> void:
	_selection = DuelSelection.new()
	_emitted = []
	_selection.intent_chosen.connect(func(intent: DuelIntent) -> void: _emitted.append(intent))


# --- X puis cible : 213.1.9 ---


func test_213_1_9_x_is_asked_before_the_target_and_bounded_by_the_engine() -> void:
	var card_id := _x_spell_setup()
	_selection.press_card(card_id)
	var shown := _selection.snapshot()
	assert_bool(shown.has_x_choice).is_true()
	assert_int(shown.x_min).is_equal(SOLDIER_FORCE)  # moins, aucune Unit ennemie n'est ciblable
	assert_int(shown.x_max).is_equal(ESSENCE_RESERVE)  # plus, l'Essence ne couvre pas
	assert_int(shown.x_value).is_equal(SOLDIER_FORCE)
	assert_bool(shown.can_decrease_x).is_false()
	assert_bool(shown.can_increase_x).is_true()
	assert_array(_emitted).is_empty()


func test_213_1_9_target_is_announced_with_the_chosen_x() -> void:
	var card_id := _x_spell_setup()
	var enemy_id := _enemy_id
	_selection.press_card(card_id)
	_selection.press_x_increase()
	assert_int(_selection.snapshot().x_value).is_equal(SOLDIER_FORCE + 1)
	assert_array(_selection.snapshot().legal_piece_ids).contains_exactly([enemy_id])
	_selection.press_piece(enemy_id)
	var cast := _emitted[0] as CastSpell
	assert_int(cast.x_value).is_equal(SOLDIER_FORCE + 1)
	assert_array(cast.target_piece_ids).contains_exactly([enemy_id])
	assert_int(_engine.validate(cast)).is_equal(IntentRejected.RejectReason.NONE)
	assert_int(_selection.snapshot().selection_state).is_equal(SELECTION.IDLE)


func test_decision_0068_x_stops_at_the_bounds_the_engine_accepts() -> void:
	var card_id := _x_spell_setup()
	_selection.press_card(card_id)
	for press: int in 10:
		_selection.press_x_increase()
	assert_int(_selection.snapshot().x_value).is_equal(ESSENCE_RESERVE)
	assert_bool(_selection.snapshot().can_increase_x).is_false()
	for press: int in 10:
		_selection.press_x_decrease()
	assert_int(_selection.snapshot().x_value).is_equal(SOLDIER_FORCE)


func test_decision_0068_x_spell_without_a_legal_target_is_not_playable() -> void:
	var catalog := ValueSamples.catalog()
	_builder = ValueSamples.builder(catalog)
	var card_id := _builder.add_to_hand(A, ValueSamples.EXECUTION)
	_builder.with_essence_reserve(A, ESSENCE_RESERVE)
	_start(catalog, A)
	assert_array(_selection.snapshot().playable_card_ids).is_empty()
	_selection.press_card(card_id)
	assert_int(_selection.snapshot().selection_state).is_equal(SELECTION.IDLE)


func test_decision_0068_an_untargeted_x_spell_leaves_by_the_confirmation_of_x() -> void:
	var catalog := ValueSamples.catalog()
	_builder = ValueSamples.builder(catalog)
	var unit_id := _builder.place_piece(A, Piece.PieceKind.UNIT, _cell("B2"), ValueSamples.SOLDIER)
	var card_id := _builder.add_to_hand(A, ValueSamples.BLESSING)
	_builder.with_essence_reserve(A, ESSENCE_RESERVE)
	_start(catalog, A)
	_selection.press_card(card_id)
	assert_bool(_selection.snapshot().has_x_choice).is_true()
	_selection.press_piece(unit_id)
	var cast := _emitted[0] as CastSpell
	assert_int(cast.x_value).is_equal(1)
	assert_array(cast.target_piece_ids).contains_exactly([unit_id])


func test_decision_0068_cancel_drops_the_announcement_without_sending_anything() -> void:
	var card_id := _x_spell_setup()
	_selection.press_card(card_id)
	_selection.press_x_increase()
	_selection.press_cancel()
	assert_array(_emitted).is_empty()
	assert_int(_selection.snapshot().selection_state).is_equal(SELECTION.IDLE)
	assert_bool(_selection.snapshot().has_x_choice).is_false()


# --- deux cibles : 214, 215 ---


func test_decision_0068_swap_takes_two_units_then_announces() -> void:
	var catalog := MovementSamples.catalog()
	_builder = _sources_builder(catalog)
	var first_id := _unit(A, "B2")
	var second_id := _unit(A, "D3")
	var card_id := _builder.add_to_hand(A, MovementSamples.SWAP_SPELL)
	_builder.with_essence_reserve(A, MovementSamples.SPELL_COST)
	_start(catalog, A)
	assert_array(_selection.snapshot().playable_card_ids).contains_exactly([card_id])
	_selection.press_card(card_id)
	assert_array(_selection.snapshot().legal_piece_ids).contains_exactly([first_id, second_id])
	_selection.press_piece(first_id)
	assert_array(_emitted).is_empty()
	assert_int(_selection.snapshot().chosen_piece_id).is_equal(first_id)
	assert_array(_selection.snapshot().legal_piece_ids).contains_exactly([second_id])
	_selection.press_piece(second_id)
	var cast := _emitted[0] as CastSpell
	assert_array(cast.target_piece_ids).contains_exactly([first_id, second_id])
	assert_int(_engine.validate(cast)).is_equal(IntentRejected.RejectReason.NONE)


func test_decision_0068_a_unit_is_not_chosen_twice_for_a_swap() -> void:
	var catalog := MovementSamples.catalog()
	_builder = _sources_builder(catalog)
	var first_id := _unit(A, "B2")
	_unit(A, "D3")
	var card_id := _builder.add_to_hand(A, MovementSamples.SWAP_SPELL)
	_builder.with_essence_reserve(A, MovementSamples.SPELL_COST)
	_start(catalog, A)
	_selection.press_card(card_id)
	_selection.press_piece(first_id)
	_selection.press_piece(first_id)
	assert_array(_emitted).is_empty()


func test_decision_0068_move_asks_a_unit_then_a_cell_next_to_it() -> void:
	var catalog := MovementSamples.catalog()
	_builder = _sources_builder(catalog)
	var enemy_id := _unit(B, "B4")
	var card_id := _builder.add_to_hand(A, MovementSamples.MOVE_SPELL)
	_builder.with_essence_reserve(A, MovementSamples.SPELL_COST)
	_start(catalog, A)
	_selection.press_card(card_id)
	assert_array(_selection.snapshot().legal_piece_ids).contains_exactly([enemy_id])
	assert_array(_selection.snapshot().legal_cells).is_empty()
	_selection.press_piece(enemy_id)
	var cells := _selection.snapshot().legal_cells
	assert_array(cells).contains([_cell("B5"), _cell("C4"), _cell("A4")])
	assert_array(cells).not_contains([_cell("D4"), _cell("B4")])
	_selection.press_cell(_cell("C4"))
	var cast := _emitted[0] as CastSpell
	assert_array(cast.target_piece_ids).contains_exactly([enemy_id])
	assert_array(cast.target_cells).contains_exactly([_cell("C4")])


func test_decision_0068_triggered_move_proposes_cells_only_after_the_unit() -> void:
	var catalog := MovementSamples.catalog()
	_builder = _sources_builder(catalog)
	var first_id := _unit(B, "B4")
	_unit(B, "D4")
	_builder.push_deploy(_builder.make_card_instance(A, MovementSamples.SHIFTER), _cell("B1"))
	_builder.with_priority_player(B)
	_start(catalog, A)
	DuelChecks.pass_once(_engine, B)
	assert_int(_engine.get_state().pending_decision.candidate_cells.size()).is_greater(0)
	_selection.reset()
	assert_array(_selection.snapshot().legal_cells).is_empty()
	assert_array(_selection.snapshot().legal_piece_ids).contains([first_id])
	_selection.press_piece(first_id)
	assert_array(_selection.snapshot().legal_cells).contains_exactly_in_any_order(
		[_cell("A4"), _cell("C4"), _cell("B5"), _cell("B3")].filter(_is_free)
	)
	_selection.press_cell(_cell("C4"))
	var answer := _emitted[0] as ChooseTargets
	assert_array(answer.target_piece_ids).contains_exactly([first_id])
	assert_array(answer.target_cells).contains_exactly([_cell("C4")])
	assert_int(_engine.validate(answer)).is_equal(IntentRejected.RejectReason.NONE)


# --- Ordre du Hero : 211 ---


func test_211_4_1_order_is_announced_from_the_hero_with_its_target() -> void:
	var unit_id := _order_setup()
	var hero_id := _engine.get_state().find_hero(A).piece_id
	assert_array(_selection.snapshot().legal_piece_ids).contains([hero_id])
	_selection.press_piece(hero_id)
	var shown := _selection.snapshot()
	assert_int(shown.choice_kind).is_equal(SelectionSnapshot.ChoiceKind.ORDER)
	assert_array(shown.choice_values).contains_exactly([OrderSamples.BOOST_ORDER])
	_selection.press_choice(0)
	assert_array(_selection.snapshot().legal_piece_ids).contains([unit_id])
	_selection.press_piece(unit_id)
	var order := _emitted[0] as AnnounceOrder
	assert_int(order.order_index).is_equal(OrderSamples.BOOST_ORDER)
	assert_array(order.target_piece_ids).contains_exactly([unit_id])
	assert_int(_engine.validate(order)).is_equal(IntentRejected.RejectReason.NONE)


func test_decision_0068_cancelling_an_order_sends_nothing() -> void:
	_order_setup()
	var hero_id := _engine.get_state().find_hero(A).piece_id
	_selection.press_piece(hero_id)
	_selection.press_choice(0)
	assert_bool(_selection.snapshot().can_cancel).is_true()
	_selection.press_cancel()
	assert_array(_emitted).is_empty()
	assert_int(_selection.snapshot().selection_state).is_equal(SELECTION.IDLE)
	assert_bool(_engine.get_state().find_hero(A).is_awake).is_true()


func test_decision_0068_a_target_the_engine_does_not_propose_sends_nothing() -> void:
	_order_setup()
	var hero_id := _engine.get_state().find_hero(A).piece_id
	_selection.press_piece(hero_id)
	_selection.press_choice(0)
	_selection.press_cell(_cell("E5"))
	_selection.press_stack_entry(DuelState.NO_ID)
	assert_array(_emitted).is_empty()
	assert_int(_selection.snapshot().selection_state).is_equal(SELECTION.TARGET_PENDING)


func test_decision_0068_the_hero_without_announceable_order_or_move_is_not_chosen() -> void:
	var catalog := ValueSamples.catalog()
	_builder = ValueSamples.builder(catalog)
	_start(catalog, B)
	var hero_id := _engine.get_state().find_hero(B).piece_id
	_selection.press_piece(hero_id)
	assert_int(_selection.snapshot().selection_state).is_equal(SELECTION.IDLE)


# --- pile : 211, 213 ---


func test_decision_0068_an_order_on_the_stack_shows_the_hero_and_a_spell_its_x() -> void:
	var unit_id := _order_setup()
	_engine.submit(OrderSamples.boost_order(A, unit_id))
	var model := DuelViewModel.new(_engine.get_state(), _engine.get_state().catalog, A)
	var lines := model.stack_lines()
	assert_int(lines.size()).is_equal(1)
	assert_str(lines[0].label).is_equal("Hero %s" % OrderSamples.HERO)
	assert_str(lines[0].help).starts_with("Ordre")
	var entry := _engine.get_state().stack[0]
	assert_object(model.entry_definition(entry)).is_null()


func test_213_1_6_x_value_is_shown_on_the_stack_entry() -> void:
	var card_id := _x_spell_setup()
	_selection.press_card(card_id)
	_selection.press_piece(_enemy_id)
	_engine.submit(_emitted[0])
	var model := DuelViewModel.new(_engine.get_state(), _engine.get_state().catalog, A)
	assert_str(model.stack_lines()[0].help).ends_with("X = %d" % SOLDIER_FORCE)


# --- aides ---


func _x_spell_setup() -> int:
	var catalog := ValueSamples.catalog()
	_builder = ValueSamples.builder(catalog)
	_enemy_id = _builder.place_piece(B, Piece.PieceKind.UNIT, _cell("B4"), ValueSamples.SOLDIER)
	var card_id := _builder.add_to_hand(A, ValueSamples.EXECUTION)
	_builder.with_essence_reserve(A, ESSENCE_RESERVE)
	_start(catalog, A)
	return card_id


func _order_setup() -> int:
	var catalog := OrderSamples.catalog()
	_builder = DuelStateBuilder.new(DuelConfig.new(), catalog)
	for side: DuelState.PlayerSide in DuelState.SIDES:
		_builder.with_hero_definition(side, OrderSamples.HERO)
		_builder.with_sources_in_play(side, 4, 0)
	var unit_id := _builder.place_piece(A, Piece.PieceKind.UNIT, _cell("B2"), OrderSamples.UNIT)
	_start(catalog, A)
	return unit_id


func _sources_builder(catalog: Catalog) -> DuelStateBuilder:
	var result := DuelStateBuilder.new(DuelConfig.new(), catalog)
	for side: DuelState.PlayerSide in DuelState.SIDES:
		result.with_sources_in_play(side, 4, 0)
	return result


func _unit(side: DuelState.PlayerSide, cell_name: String) -> int:
	return _builder.place_piece(
		side, Piece.PieceKind.UNIT, _cell(cell_name), TriggerSamples.SOLDIER
	)


func _is_free(cell: Vector2i) -> bool:
	return _engine.get_state().piece_at(cell) == null


func _cell(cell_name: String) -> Vector2i:
	return DuelStateBuilder.cell(cell_name)


func _start(catalog: Catalog, side: DuelState.PlayerSide) -> void:
	_engine = DuelEngine.new(catalog)
	_engine.start_from_state(_builder.build())
	_selection.setup(_engine, side)
