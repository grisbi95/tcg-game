extends GdUnitTestSuite
## DuelSelection sans scène : marques « jouable » éteintes pendant une sélection (décisions 0024,
## 0031 et 0032). Voisine de test_duel_selection.gd.

const UNIT: StringName = &"selection_unit"
const UNIT_COST: int = 2  # SetupSamples.add_unit()
const TARGETED_SPELL: StringName = &"sample_spell"  # cible une Unit alliée, coût 1
const UNIT_CELL: String = "A1"

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const SELECTION := DuelSelection.SelectionState

var _catalog: Catalog
var _builder: DuelStateBuilder
var _engine: DuelEngine
var _selection: DuelSelection
var _emitted: Array[DuelIntent] = []


func before_test() -> void:
	_catalog = Catalog.new()
	SetupSamples.add_unit(_catalog, UNIT, 3)
	_catalog.add_card(CardDefinition.from_dict(CatalogSamples.spell()))
	_builder = DuelStateBuilder.new(DuelConfig.new(), _catalog)
	_engine = DuelEngine.new(_catalog)
	_selection = DuelSelection.new()
	_emitted = []
	_selection.intent_chosen.connect(func(intent: DuelIntent) -> void: _emitted.append(intent))


func test_decision_0024_no_playable_mark_while_a_card_is_chosen() -> void:
	var card_id := _builder.add_to_hand(A, UNIT)
	_builder.with_essence_reserve(A, UNIT_COST)
	_start(A)
	assert_array(_selection.snapshot().playable_card_ids).contains_exactly([card_id])
	_selection.press_card(card_id)
	var shown := _selection.snapshot()
	assert_int(shown.selection_state).is_equal(SELECTION.CARD_CHOSEN)
	assert_array(shown.playable_card_ids).is_empty()
	_selection.press_card(card_id)
	assert_int(_selection.snapshot().selection_state).is_equal(SELECTION.IDLE)
	assert_array(_selection.snapshot().playable_card_ids).contains_exactly([card_id])


func test_decision_0024_no_playable_mark_while_a_piece_is_chosen() -> void:
	var piece_id := _builder.place_piece(A, Piece.PieceKind.UNIT, _cell(UNIT_CELL), UNIT)
	var card_id := _builder.add_to_hand(A, UNIT)
	_builder.with_essence_reserve(A, UNIT_COST)
	_start(A)
	_selection.press_piece(piece_id)
	assert_int(_selection.snapshot().selection_state).is_equal(SELECTION.PIECE_CHOSEN)
	assert_array(_selection.snapshot().playable_card_ids).is_empty()
	_selection.press_cancel()
	assert_array(_selection.snapshot().playable_card_ids).contains_exactly([card_id])


func test_decision_0024_no_playable_mark_while_a_target_is_pending() -> void:
	_builder.place_piece(A, Piece.PieceKind.UNIT, _cell(UNIT_CELL), UNIT)
	var card_id := _builder.add_to_hand(A, TARGETED_SPELL)
	_builder.with_essence_reserve(A, 1)
	_start(A)
	assert_array(_selection.snapshot().playable_card_ids).contains_exactly([card_id])
	_selection.press_card(card_id)
	assert_array(_selection.snapshot().playable_card_ids).is_empty()


func test_decision_0032_drafting_payment_only_in_the_opponent_turn() -> void:
	_builder.with_active_player(B).with_priority_player(A)
	_builder.push_spell(_builder.make_card_instance(B, TARGETED_SPELL))
	_start(A)
	assert_bool(_selection.snapshot().is_drafting_payment).is_true()
	_builder = DuelStateBuilder.new(DuelConfig.new(), _catalog)
	_builder.with_active_player(A)
	_start(A)
	assert_bool(_selection.snapshot().is_drafting_payment).is_false()


func _start(side: DuelState.PlayerSide) -> void:
	_engine.start_from_state(_builder.build())
	_selection.setup(_engine, side)


func _cell(cell_name: String) -> Vector2i:
	return DuelStateBuilder.cell(cell_name)
