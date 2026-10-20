# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## DuelSelection sans scène : gestes traduits en intentions validées, éléments à surligner,
## paiement par les Sources, réponse commencée, annonce sans confirmation (ruleset 0.36 ; décisions
## 0023, 0024, 0029, 0030 et 0031).

const UNIT: StringName = &"selection_unit"
const UNIT_FORCE: int = 3
const UNIT_COST: int = 2  # CatalogSamples.unit()
const TARGETED_SPELL: StringName = &"sample_spell"  # cible une Unit alliée, coût 1
const PLAIN_SPELL: StringName = &"selection_plain_spell"  # sans effet ni cible, coût 1
const FREE_SPELL: StringName = &"selection_free_spell"  # Réaction sans effet ni cible, coût 0
const FREE_TARGETED_SPELL: StringName = &"selection_free_targeted"  # Réaction ciblée, coût 0
const DEPLOY_CELL: String = "B1"
const CENTRAL_CELL: String = "B3"
const UNIT_CELL: String = "A1"
const MOVE_CELL: String = "A2"

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const SELECTION := DuelSelection.SelectionState

var _builder: DuelStateBuilder
var _engine: DuelEngine
var _selection: DuelSelection
var _emitted: Array[DuelIntent] = []
var _response_start_count: int = 0
var _signal_order: Array[String] = []


func before_test() -> void:
	var catalog := Catalog.new()
	SetupSamples.add_unit(catalog, UNIT, UNIT_FORCE)
	catalog.add_card(CardDefinition.from_dict(CatalogSamples.spell()))
	var plain := CatalogSamples.with_field(CatalogSamples.spell(), "id", String(PLAIN_SPELL))
	catalog.add_card(CardDefinition.from_dict(CatalogSamples.with_field(plain, "effects", [])))
	var free := CatalogSamples.with_field(plain, "id", String(FREE_SPELL))
	free = CatalogSamples.with_field(free, "effects", [])
	catalog.add_card(CardDefinition.from_dict(CatalogSamples.with_field(free, "cost", 0)))
	var targeted := CatalogSamples.with_field(
		CatalogSamples.spell(), "id", String(FREE_TARGETED_SPELL)
	)
	catalog.add_card(CardDefinition.from_dict(CatalogSamples.with_field(targeted, "cost", 0)))
	_builder = DuelStateBuilder.new(DuelConfig.new(), catalog)
	_engine = DuelEngine.new(catalog)
	_selection = DuelSelection.new()
	_emitted = []
	_signal_order = []
	_selection.intent_chosen.connect(
		func(intent: DuelIntent) -> void:
			_emitted.append(intent)
			_signal_order.append("intent_chosen")
	)
	_response_start_count = 0
	_selection.response_started.connect(
		func() -> void:
			_response_start_count += 1
			_signal_order.append("response_started")
	)


func test_decision_0023_card_not_covered_by_the_reserve_is_not_playable() -> void:
	_builder.add_to_hand(A, UNIT)
	_start(A)
	assert_array(_selection.snapshot().playable_card_ids).is_empty()


func test_decision_0023_card_covered_by_the_reserve_is_playable() -> void:
	var card_id := _builder.add_to_hand(A, UNIT)
	_builder.with_essence_reserve(A, UNIT_COST)
	_start(A)
	assert_array(_selection.snapshot().playable_card_ids).contains_exactly([card_id])


func test_decision_0023_source_pressed_in_own_turn_produces_essence() -> void:
	_builder.with_sources_in_play(A, 1, 1)
	_start(A)
	_selection.press_source(false)
	_selection.press_source(true)
	assert_int(_emitted.size()).is_equal(2)
	_assert_payment((_emitted[0] as ProduceEssence).payment, 1, 0)
	_assert_payment((_emitted[1] as ProduceEssence).payment, 0, 1)


func test_decision_0024_unit_deploys_on_a_legal_cell_only() -> void:
	var card_id := _builder.add_to_hand(A, UNIT)
	_builder.with_essence_reserve(A, UNIT_COST)
	_start(A)
	_selection.press_card(card_id)
	assert_int(_selection.snapshot().selection_state).is_equal(SELECTION.CARD_CHOSEN)
	assert_array(_selection.snapshot().legal_cells).contains([_cell(DEPLOY_CELL)])
	assert_array(_selection.snapshot().legal_cells).not_contains([_cell(CENTRAL_CELL)])
	_selection.press_cell(_cell(CENTRAL_CELL))
	assert_array(_emitted).is_empty()
	_selection.press_cell(_cell(DEPLOY_CELL))
	assert_object(_emitted[0]).is_instanceof(DeployCard)
	assert_int(_selection.snapshot().selection_state).is_equal(SELECTION.IDLE)


func test_decision_0024_pressing_the_chosen_card_again_cancels() -> void:
	var card_id := _builder.add_to_hand(A, UNIT)
	_builder.with_essence_reserve(A, UNIT_COST)
	_start(A)
	_selection.press_card(card_id)
	_selection.press_card(card_id)
	assert_int(_selection.snapshot().selection_state).is_equal(SELECTION.IDLE)


func test_decision_0024_piece_moves_to_a_legal_cell() -> void:
	var piece_id := _builder.place_piece(A, Piece.PieceKind.UNIT, _cell(UNIT_CELL), UNIT)
	_start(A)
	assert_array(_selection.snapshot().legal_piece_ids).contains([piece_id])
	_selection.press_piece(piece_id)
	assert_int(_selection.snapshot().selection_state).is_equal(SELECTION.PIECE_CHOSEN)
	_selection.press_cell(_cell(MOVE_CELL))
	var action := _emitted[0] as TakeNormalAction
	assert_int(action.piece_id).is_equal(piece_id)
	assert_object(action.cell).is_equal(_cell(MOVE_CELL))


func test_decision_0030_pressing_an_occupied_cell_chooses_its_piece() -> void:
	var piece_id := _builder.place_piece(A, Piece.PieceKind.UNIT, _cell(UNIT_CELL), UNIT)
	_start(A)
	_selection.press_cell(_cell(UNIT_CELL))
	var shown := _selection.snapshot()
	assert_int(shown.selection_state).is_equal(SELECTION.PIECE_CHOSEN)
	assert_int(shown.chosen_piece_id).is_equal(piece_id)


func test_decision_0030_pressing_an_enemy_piece_cell_attacks_it() -> void:
	var piece_id := _builder.place_piece(A, Piece.PieceKind.UNIT, _cell(UNIT_CELL), UNIT)
	_builder.place_piece(B, Piece.PieceKind.UNIT, _cell(MOVE_CELL), UNIT)
	_start(A)
	_selection.press_piece(piece_id)
	assert_array(_selection.snapshot().legal_cells).contains([_cell(MOVE_CELL)])
	_selection.press_cell(_cell(MOVE_CELL))
	assert_object(_emitted[0]).is_instanceof(TakeNormalAction)
	assert_int((_emitted[0] as TakeNormalAction).piece_id).is_equal(piece_id)


func test_decision_0031_targeted_spell_is_announced_once_its_target_is_chosen() -> void:
	var piece_id := _builder.place_piece(A, Piece.PieceKind.UNIT, _cell(UNIT_CELL), UNIT)
	var card_id := _builder.add_to_hand(A, TARGETED_SPELL)
	_builder.with_essence_reserve(A, 1)
	_start(A)
	_selection.press_card(card_id)
	assert_int(_selection.snapshot().selection_state).is_equal(SELECTION.TARGET_PENDING)
	assert_array(_selection.snapshot().legal_piece_ids).contains([piece_id])
	_selection.press_piece(piece_id)
	assert_array((_emitted[0] as CastSpell).target_piece_ids).contains_exactly([piece_id])
	assert_int(_selection.snapshot().selection_state).is_equal(SELECTION.IDLE)


func test_decision_0031_spell_without_target_is_announced_at_once() -> void:
	var card_id := _builder.add_to_hand(A, PLAIN_SPELL)
	_builder.with_essence_reserve(A, 1)
	_start(A)
	_selection.press_card(card_id)
	assert_object(_emitted[0]).is_instanceof(CastSpell)
	assert_bool(_selection.snapshot().can_confirm).is_false()


func test_decision_0031_confirm_is_available_during_the_mulligan() -> void:
	_builder.add_to_hand(A, UNIT)
	_await(PendingDecision.DecisionKind.MULLIGAN, [A, B], [])
	_builder.with_phase(DuelState.DuelPhase.PREPARATION)
	_start(A)
	assert_bool(_selection.snapshot().can_confirm).is_true()


func test_decision_0023_draft_payment_pays_a_response_in_the_opponent_turn() -> void:
	var card_id := _builder.add_to_hand(B, PLAIN_SPELL)
	_builder.push_spell(_builder.make_card_instance(A, PLAIN_SPELL))
	_builder.with_priority_player(B)
	_start(B)
	assert_array(_selection.snapshot().playable_card_ids).is_empty()
	_selection.press_source(false)
	var shown := _selection.snapshot()
	_assert_payment(shown.draft_payment, 1, 0)
	assert_int(shown.shown_upright_sources).is_equal(1)
	assert_array(shown.playable_card_ids).contains_exactly([card_id])
	_selection.press_card(card_id)
	_assert_payment((_emitted[0] as CastSpell).payment, 1, 0)
	_assert_payment(_selection.snapshot().draft_payment, 0, 0)


func test_decision_0023_draft_payment_uses_only_shown_sources() -> void:
	_builder.with_sources_in_play(B, 2, 0)
	_builder.push_spell(_builder.make_card_instance(A, PLAIN_SPELL))
	_builder.with_priority_player(B)
	_start(B)
	for press: int in 3:
		_selection.press_source(false)
	_selection.press_source(true)
	_selection.press_source(true)
	_selection.press_source(true)
	_assert_payment(_selection.snapshot().draft_payment, 2, 2)
	_selection.press_cancel()
	_assert_payment(_selection.snapshot().draft_payment, 0, 0)


func test_decision_0024_mulligan_toggles_cards_then_confirms() -> void:
	var first_id := _builder.add_to_hand(A, UNIT)
	var second_id := _builder.add_to_hand(A, UNIT)
	_await(PendingDecision.DecisionKind.MULLIGAN, [A, B], [])
	_builder.with_phase(DuelState.DuelPhase.PREPARATION)
	_start(A)
	assert_array(_selection.snapshot().playable_card_ids).contains_exactly([first_id, second_id])
	_selection.press_card(first_id)
	_selection.press_card(second_id)
	_selection.press_card(first_id)
	assert_array(_selection.snapshot().set_aside_card_ids).contains_exactly([second_id])
	_selection.press_confirm()
	assert_array((_emitted[0] as ChooseMulligan).set_aside_card_ids).contains_exactly([second_id])


func test_decision_0024_triggers_are_ordered_by_successive_presses() -> void:
	var first_id := _builder.push_spell(_builder.make_card_instance(A, PLAIN_SPELL))
	var second_id := _builder.push_spell(_builder.make_card_instance(A, PLAIN_SPELL))
	_await(PendingDecision.DecisionKind.ORDER_TRIGGERS, [A], [first_id, second_id])
	_start(A)
	_selection.press_stack_entry(second_id)
	assert_array(_selection.snapshot().legal_stack_entry_ids).contains_exactly([first_id])
	_selection.press_stack_entry(first_id)
	var order := _emitted[0] as OrderTriggers
	assert_array(order.ordered_stack_entry_ids).contains_exactly([second_id, first_id])


func test_decision_0024_pass_and_end_turn_only_when_legal() -> void:
	_start(A)
	assert_bool(_selection.snapshot().can_pass).is_false()
	_selection.press_pass()
	assert_array(_emitted).is_empty()
	assert_bool(_selection.snapshot().can_end_turn).is_true()
	_selection.press_end_turn()
	assert_object(_emitted[0]).is_instanceof(EndTurn)


func test_decision_0024_gestures_never_change_the_engine_state() -> void:
	var card_id := _builder.add_to_hand(A, UNIT)
	var piece_id := _builder.place_piece(A, Piece.PieceKind.UNIT, _cell(UNIT_CELL), UNIT)
	_builder.with_essence_reserve(A, UNIT_COST)
	_start(A)
	var snapshot := _engine.get_state().clone()
	_selection.press_card(card_id)
	_selection.snapshot()
	_selection.press_piece(piece_id)
	_selection.press_cell(_cell(MOVE_CELL))
	_selection.press_source(false)
	assert_array(DeepCompare.find_clone_defects(snapshot, _engine.get_state())).is_empty()
	for intent: DuelIntent in _emitted:
		assert_int(_engine.validate(intent)).is_equal(IntentRejected.RejectReason.NONE)


func test_208_6_5_reaction_card_chosen_starts_the_response() -> void:
	var card_id := _builder.add_to_hand(B, FREE_SPELL)
	_answer_spell_of_a()
	_selection.press_card(card_id)
	assert_object(_emitted[0]).is_instanceof(CastSpell)
	assert_int(_response_start_count).is_equal(1)


func test_208_6_5_response_signal_comes_before_the_answer() -> void:
	var card_id := _builder.add_to_hand(B, FREE_SPELL)
	_answer_spell_of_a()
	_selection.press_card(card_id)
	assert_array(_signal_order).contains_exactly(["response_started", "intent_chosen"])


func test_208_6_5_targeted_reaction_starts_the_response() -> void:
	var unit_id := _builder.place_piece(B, Piece.PieceKind.UNIT, _cell(UNIT_CELL), UNIT)
	var card_id := _builder.add_to_hand(B, FREE_TARGETED_SPELL)
	_answer_spell_of_a()
	_selection.press_card(card_id)
	assert_int(_selection.snapshot().selection_state).is_equal(SELECTION.TARGET_PENDING)
	assert_array(_selection.snapshot().legal_piece_ids).contains([unit_id])
	assert_int(_response_start_count).is_equal(1)
	assert_array(_emitted).is_empty()


func test_208_6_5_unplayable_card_starts_nothing() -> void:
	var unit_id := _builder.add_to_hand(B, UNIT)  # un déploiement n'est pas une Réaction
	var dear_id := _builder.add_to_hand(B, PLAIN_SPELL)  # coût 1, aucune Source payée
	_answer_spell_of_a()
	_selection.press_card(unit_id)
	_selection.press_card(dear_id)
	assert_int(_response_start_count).is_equal(0)
	assert_array(_emitted).is_empty()
	assert_int(_selection.snapshot().selection_state).is_equal(SELECTION.IDLE)


func test_208_6_5_source_pressed_starts_the_response() -> void:
	_answer_spell_of_a()
	_selection.press_source(false)
	assert_int(_response_start_count).is_equal(1)


func test_208_6_5a_cancel_does_not_restart_anything() -> void:
	_answer_spell_of_a()
	_selection.press_source(false)
	_selection.press_cancel()
	assert_int(_response_start_count).is_equal(1)


func test_decision_0029_no_response_outside_an_answer() -> void:
	var card_id := _builder.add_to_hand(A, UNIT)
	_builder.with_sources_in_play(A, 1, 0)
	_builder.with_essence_reserve(A, UNIT_COST)
	_start(A)
	_selection.press_card(card_id)
	_selection.press_source(false)
	assert_int(_response_start_count).is_equal(0)


# 208.2.4 : A a annoncé un Spell ; B, devant l'écran, peut répondre ou passer.
func _answer_spell_of_a() -> void:
	_builder.push_spell(_builder.make_card_instance(A, PLAIN_SPELL))
	_builder.with_priority_player(B)
	_start(B)


func _start(side: DuelState.PlayerSide) -> void:
	_engine.start_from_state(_builder.build())
	_selection.setup(_engine, side)


func _await(
	kind: PendingDecision.DecisionKind,
	sides: Array[DuelState.PlayerSide],
	candidate_ids: Array[int]
) -> void:
	var decision := PendingDecision.new()
	decision.kind = kind
	decision.awaited_players.assign(sides)
	decision.candidate_ids.assign(candidate_ids)
	_builder.with_pending_decision(decision)


func _cell(cell_name: String) -> Vector2i:
	return DuelStateBuilder.cell(cell_name)


func _assert_payment(payment: EssencePayment, inclined: int, recycled: int) -> void:
	assert_int(payment.incline_count).is_equal(inclined)
	assert_int(payment.recycle_count).is_equal(recycled)
