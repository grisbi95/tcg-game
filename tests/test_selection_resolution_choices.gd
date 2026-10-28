extends GdUnitTestSuite
## Choix posés pendant une résolution et expiration pendant une annonce, côté sélection (décisions
## 0057 et 0068) : défausse cliquée dans la main (212), carte regardée cachée à l'adversaire
## (201.4.1a, 217.1.5), annonce abandonnée à l'expiration du temps (209.4.11, 211.2.2a). Les Spells
## viennent de HandEffectSamples, ValueSamples et OrderSamples.

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const DECISION := PendingDecision.DecisionKind
const ESSENCE_RESERVE: int = 5
const EXPIRY_MARGIN_MSEC: int = 1_000

var _builder: DuelStateBuilder
var _engine: DuelEngine
var _selection: DuelSelection
var _emitted: Array[DuelIntent] = []


func before_test() -> void:
	_selection = DuelSelection.new()
	_emitted = []
	_selection.intent_chosen.connect(func(intent: DuelIntent) -> void: _emitted.append(intent))


# --- défausse : 212 ---


func test_212_1_3_discard_card_is_clicked_in_the_hand() -> void:
	var hand_ids := _cast_discard(HandEffectSamples.DISCARD_ONE, 3)
	assert_int(_engine.get_state().pending_decision.kind).is_equal(DECISION.CHOOSE_DISCARD)
	assert_array(_selection.snapshot().playable_card_ids).contains_exactly(hand_ids)
	_selection.press_card(hand_ids[1])
	var choice := _emitted[0] as ChooseDiscard
	assert_array(choice.card_ids).contains_exactly([hand_ids[1]])
	assert_int(_engine.validate(choice)).is_equal(IntentRejected.RejectReason.NONE)


func test_212_1_3_discard_goes_out_when_the_requested_count_is_reached() -> void:
	var hand_ids := _cast_discard(HandEffectSamples.DISCARD_TWO, 4)
	_selection.press_card(hand_ids[0])
	assert_array(_emitted).is_empty()
	assert_array(_selection.snapshot().picked_card_ids).contains_exactly([hand_ids[0]])
	_selection.press_card(hand_ids[0])
	assert_array(_selection.snapshot().picked_card_ids).is_empty()
	_selection.press_card(hand_ids[0])
	_selection.press_card(hand_ids[2])
	var choice := _emitted[0] as ChooseDiscard
	assert_array(choice.card_ids).contains_exactly([hand_ids[0], hand_ids[2]])


func test_decision_0057_the_resolving_spell_stays_on_the_shown_stack() -> void:
	_cast_discard(HandEffectSamples.DISCARD_ONE, 3)
	var model := DuelViewModel.new(_engine.get_state(), _engine.get_state().catalog, A)
	assert_int(model.stack_lines().size()).is_equal(1)


# --- regard : 217, 201.4.1a ---


func test_217_1_3_look_choice_is_two_buttons_the_second_puts_the_card_below() -> void:
	var top_id := _cast_look()
	var shown := _selection.snapshot()
	assert_int(shown.choice_kind).is_equal(SelectionSnapshot.ChoiceKind.TOP_CARD_PLACE)
	assert_int(shown.looked_card_id).is_equal(top_id)
	assert_int(shown.choice_values.size()).is_equal(2)
	_selection.press_choice(1)
	var choice := _emitted[0] as ChooseTopCardPlace
	assert_int(choice.place).is_equal(ChooseTopCardPlace.TopCardPlace.BELOW)
	assert_int(_engine.validate(choice)).is_equal(IntentRejected.RejectReason.NONE)


func test_217_1_2_keeping_the_card_on_top_is_the_first_button() -> void:
	_cast_look()
	_selection.press_choice(0)
	assert_int((_emitted[0] as ChooseTopCardPlace).place).is_equal(
		ChooseTopCardPlace.TopCardPlace.ON_TOP
	)


func test_217_1_5_the_opponent_does_not_see_the_looked_card() -> void:
	var top_id := _cast_look()
	var catalog := _engine.get_state().catalog
	var owner_model := DuelViewModel.new(_engine.get_state(), catalog, A)
	var opponent_model := DuelViewModel.new(_engine.get_state(), catalog, B)
	assert_object(opponent_model.visible_definition(top_id)).is_null()
	assert_object(owner_model.visible_definition(top_id)).is_not_null()
	var opponent_selection := DuelSelection.new()
	opponent_selection.setup(_engine, B)
	var shown := opponent_selection.snapshot()
	assert_int(shown.looked_card_id).is_equal(DuelState.NO_ID)
	assert_int(shown.choice_kind).is_equal(SelectionSnapshot.ChoiceKind.NONE)


func test_201_4_1a_the_looked_card_is_shown_to_its_owner_only_while_looking() -> void:
	var top_id := _cast_look()
	var catalog := _engine.get_state().catalog
	_selection.press_choice(0)
	_engine.submit(_emitted[0])
	var model := DuelViewModel.new(_engine.get_state(), catalog, A)
	assert_object(model.visible_definition(top_id)).is_null()


# --- expiration pendant l'annonce : 209.4.11, 211.2.2a ---


func test_209_4_11b_expired_x_choice_leaves_the_card_in_hand() -> void:
	var catalog := ValueSamples.catalog()
	_builder = ValueSamples.builder(catalog)
	var enemy_id := _builder.place_piece(
		B, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B4"), ValueSamples.SOLDIER
	)
	var card_id := _builder.add_to_hand(A, ValueSamples.EXECUTION)
	_builder.with_essence_reserve(A, ESSENCE_RESERVE)
	_start(catalog, A)
	_selection.press_card(card_id)
	_selection.press_x_increase()
	var state := _engine.get_state()
	_engine.advance_clock(state.config.turn_time_msec + EXPIRY_MARGIN_MSEC)
	assert_int(state.active_player).is_equal(B)
	_selection.press_piece(enemy_id)
	assert_array(_emitted).is_empty()
	assert_int(_selection.snapshot().selection_state).is_equal(DuelSelection.SelectionState.IDLE)
	assert_object(state.get_player(A).find_card_in_hand(card_id)).is_not_null()
	assert_array(state.get_player(A).discard).is_empty()
	assert_int(state.stack.size()).is_equal(0)


func test_209_4_11c_expired_spell_target_choice_leaves_the_card_in_hand() -> void:
	var catalog := ValueSamples.catalog()
	_builder = ValueSamples.builder(catalog)
	var ally_id := _builder.place_piece(
		A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B2"), ValueSamples.SOLDIER
	)
	var card_id := _builder.add_to_hand(A, ValueSamples.WATCH)
	_builder.with_essence_reserve(A, ESSENCE_RESERVE)
	_start(catalog, A)
	_selection.press_card(card_id)
	assert_int(_selection.snapshot().selection_state).is_equal(
		DuelSelection.SelectionState.TARGET_PENDING
	)
	assert_bool(_selection.snapshot().has_x_choice).is_false()
	var state := _engine.get_state()
	_engine.advance_clock(state.config.turn_time_msec + EXPIRY_MARGIN_MSEC)
	_selection.press_piece(ally_id)
	assert_array(_emitted).is_empty()
	assert_int(_selection.snapshot().selection_state).is_equal(DuelSelection.SelectionState.IDLE)
	assert_object(state.get_player(A).find_card_in_hand(card_id)).is_not_null()
	assert_array(state.get_player(A).discard).is_empty()
	assert_int(state.stack.size()).is_equal(0)


func test_211_2_2a_expired_order_announcement_leaves_the_hero_awake() -> void:
	var catalog := OrderSamples.catalog()
	_builder = DuelStateBuilder.new(DuelConfig.new(), catalog)
	for side: DuelState.PlayerSide in DuelState.SIDES:
		_builder.with_hero_definition(side, OrderSamples.HERO)
		_builder.with_sources_in_play(side, 4, 0)
	var unit_id := _builder.place_piece(
		A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B2"), OrderSamples.UNIT
	)
	_start(catalog, A)
	var state := _engine.get_state()
	_selection.press_piece(state.find_hero(A).piece_id)
	_selection.press_choice(0)
	_engine.advance_clock(state.config.turn_time_msec + EXPIRY_MARGIN_MSEC)
	_selection.press_piece(unit_id)
	assert_array(_emitted).is_empty()
	assert_bool(state.find_hero(A).is_awake).is_true()
	assert_int(state.stack.size()).is_equal(0)
	assert_int(_selection.snapshot().selection_state).is_equal(DuelSelection.SelectionState.IDLE)


# --- aides ---


func _cast_discard(spell_id: StringName, hand_size: int) -> Array[int]:
	var catalog := HandEffectSamples.catalog()
	_builder = HandEffectSamples.builder(catalog)
	var hand_ids := HandEffectSamples.fill_hand(_builder, A, hand_size)
	var card_id := _builder.add_to_hand(A, spell_id)
	_start(catalog, A)
	_engine.submit(HandEffectSamples.cast(A, card_id))
	HandEffectSamples.resolve(_engine)
	_selection.reset()
	return hand_ids


# Rend l'identifiant de la carte du dessus du deck de A, regardée.
func _cast_look() -> int:
	var catalog := HandEffectSamples.catalog()
	_builder = HandEffectSamples.builder(catalog)
	for index: int in 3:
		_builder.add_to_deck(A, TriggerSamples.SOLDIER)
	var card_id := _builder.add_to_hand(A, HandEffectSamples.LOOK)
	_start(catalog, A)
	_engine.submit(HandEffectSamples.cast(A, card_id))
	HandEffectSamples.resolve(_engine)
	_selection.reset()
	return _engine.get_state().pending_decision.candidate_ids[0]


func _start(catalog: Catalog, side: DuelState.PlayerSide) -> void:
	_engine = DuelEngine.new(catalog)
	_engine.start_from_state(_builder.build())
	_selection.setup(_engine, side)
