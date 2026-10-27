# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## X lu sur une valeur du jeu pour piocher et défausser (ruleset 0.55, 213.1.8, 213.2.1, 213.2.2,
## 212.2.3, 200.4.1 ; décision 0065) : X choisi à l'annonce, compte de pièces, taille de la main,
## cartes défaussées par l'effet précédent. Lu une seule fois à la
## résolution. Cartes : GameValueSamples.

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const SOLDIER: StringName = TriggerSamples.SOLDIER
const DECISION := PendingDecision.DecisionKind
const DECK_SIZE: int = 8

var _catalog: Catalog
var _builder: DuelStateBuilder
var _engine: DuelEngine


func before_test() -> void:
	_catalog = GameValueSamples.catalog()
	_builder = HandEffectSamples.builder(_catalog)
	for index: int in DECK_SIZE:
		_builder.add_to_deck(A, SOLDIER)


func test_213_1_8_chosen_x_is_the_number_of_cards_drawn() -> void:
	var spell_id := _builder.add_to_hand(A, GameValueSamples.SURGE)
	_start()
	var hand_before := _hand_size(A)
	_engine.submit(ValueSamples.cast(A, spell_id, 3))
	var labels := EventLog.describe(HandEffectSamples.resolve(_engine))
	assert_int(labels.count("CardDrawn:A")).is_equal(3)
	assert_int(_hand_size(A)).is_equal(hand_before - 1 + 3)


func test_213_1_8_chosen_x_is_kept_for_every_effect_of_the_resolution() -> void:
	var spell_id := _builder.add_to_hand(A, GameValueSamples.RESERVE)
	HandEffectSamples.fill_hand(_builder, A, 2)
	_start()
	_engine.submit(ValueSamples.cast(A, spell_id, 2))
	HandEffectSamples.resolve(_engine)  # piochez X, puis défaussez X : l'attente de la défausse
	var decision := _engine.get_state().pending_decision
	assert_int(decision.kind).is_equal(DECISION.CHOOSE_DISCARD)
	assert_int(decision.required_count).is_equal(2)
	assert_int(_engine.get_state().resolving_entry.x_value).is_equal(2)


func test_213_1_8_chosen_x_defines_the_number_of_cards_discarded() -> void:
	var spell_id := _builder.add_to_hand(A, GameValueSamples.SHED)
	var hand_ids := HandEffectSamples.fill_hand(_builder, A, 3)
	_start()
	_engine.submit(ValueSamples.cast(A, spell_id, 2))
	HandEffectSamples.resolve(_engine)
	assert_int(_engine.get_state().pending_decision.required_count).is_equal(2)
	var labels := EventLog.describe(
		_engine.submit(HandEffectSamples.discard(A, [hand_ids[0], hand_ids[1]]))
	)
	assert_int(labels.count("CardDiscardedFromHand:A")).is_equal(2)


func test_213_2_1_the_count_of_pieces_is_read_when_the_entry_resolves() -> void:
	var piece_ids := _place_units(A, 3)
	var spell_id := _builder.add_to_hand(A, GameValueSamples.CENSUS)
	_start()
	_engine.submit(HandEffectSamples.cast(A, spell_id))
	var state := _engine.get_state()
	state.pieces.erase(state.find_piece(piece_ids[0]))  # lu à la résolution, non à l'annonce
	var labels := EventLog.describe(HandEffectSamples.resolve(_engine))
	assert_int(labels.count("CardDrawn:A")).is_equal(2)


func test_213_2_1_the_count_of_pieces_defines_the_number_of_cards_discarded() -> void:
	_place_units(B, 2)
	_place_units(A, 1, "A2")
	var spell_id := _builder.add_to_hand(A, GameValueSamples.TITHE)
	HandEffectSamples.fill_hand(_builder, A, 3)
	_start()
	_engine.submit(HandEffectSamples.cast(A, spell_id))
	HandEffectSamples.resolve(_engine)
	assert_int(_engine.get_state().pending_decision.required_count).is_equal(2)


func test_213_2_1_no_card_is_drawn_when_the_count_is_zero() -> void:
	var spell_id := _builder.add_to_hand(A, GameValueSamples.CENSUS)
	_start()
	_engine.submit(HandEffectSamples.cast(A, spell_id))
	var labels := EventLog.describe(HandEffectSamples.resolve(_engine))
	assert_array(labels).contains_exactly(
		["PriorityPassed:B", "CardDiscarded:A", "StackEntryResolved:A"]
	)


func test_213_2_1_as_many_cards_as_were_discarded_by_the_previous_effect() -> void:
	var spell_id := _builder.add_to_hand(A, GameValueSamples.RENEW)
	var hand_ids := HandEffectSamples.fill_hand(_builder, A, 3)
	_start()
	_engine.submit(HandEffectSamples.cast(A, spell_id))
	HandEffectSamples.resolve(_engine)
	var answer := HandEffectSamples.discard(A, [hand_ids[0], hand_ids[1]])
	var labels := EventLog.describe(_engine.submit(answer))
	assert_int(labels.count("CardDiscardedFromHand:A")).is_equal(2)
	assert_int(labels.count("CardDrawn:A")).is_equal(GameValueSamples.RENEW_DISCARDED)


func test_213_2_1_the_discarded_count_survives_the_wait_for_the_choice() -> void:
	var spell_id := _builder.add_to_hand(A, GameValueSamples.ECHOING_DISCARD)
	var hand_ids := HandEffectSamples.fill_hand(_builder, A, 4)
	_start()
	_engine.submit(HandEffectSamples.cast(A, spell_id))
	HandEffectSamples.resolve(_engine)
	assert_int(_engine.get_state().pending_decision.required_count).is_equal(1)
	_engine.submit(HandEffectSamples.discard(A, [hand_ids[0]]))
	var decision := _engine.get_state().pending_decision
	assert_int(decision.kind).is_equal(DECISION.CHOOSE_DISCARD)
	assert_int(decision.required_count).is_equal(1)  # une carte défaussée, donc X vaut 1
	assert_int(_engine.get_state().previous_effect_discarded_count).is_equal(1)


func test_213_2_1_nothing_discarded_by_the_previous_effect_draws_nothing() -> void:
	var spell_id := _builder.add_to_hand(A, GameValueSamples.RENEW)
	_start()  # la main est vide une fois le Spell annoncé
	_engine.submit(HandEffectSamples.cast(A, spell_id))
	var labels := EventLog.describe(HandEffectSamples.resolve(_engine))
	assert_array(labels).not_contains("CardDrawn:A")
	assert_int(_engine.get_state().previous_effect_discarded_count).is_equal(0)


func test_213_2_2_x_does_not_change_while_the_cards_are_drawn() -> void:
	var spell_id := _builder.add_to_hand(A, GameValueSamples.GREED)
	HandEffectSamples.fill_hand(_builder, A, 2)
	_start()
	_engine.submit(HandEffectSamples.cast(A, spell_id))
	var labels := EventLog.describe(HandEffectSamples.resolve(_engine))
	assert_int(labels.count("CardDrawn:A")).is_equal(2)  # la main compte 2 cartes à la lecture
	assert_int(_hand_size(A)).is_equal(4)


func test_decision_0065_the_discarded_count_is_cleared_at_the_end_of_the_resolution() -> void:
	var spell_id := _builder.add_to_hand(A, GameValueSamples.RENEW)
	var hand_ids := HandEffectSamples.fill_hand(_builder, A, 3)
	_start()
	_engine.submit(HandEffectSamples.cast(A, spell_id))
	HandEffectSamples.resolve(_engine)
	assert_int(_engine.get_state().current_effect_discarded_count).is_equal(0)
	_engine.submit(HandEffectSamples.discard(A, [hand_ids[0], hand_ids[1]]))
	var state := _engine.get_state()
	assert_object(state.resolving_entry).is_null()
	assert_int(state.previous_effect_discarded_count).is_equal(0)
	assert_int(state.current_effect_discarded_count).is_equal(0)


func _place_units(side: DuelState.PlayerSide, count: int, first_cell: String = "") -> Array[int]:
	var cells: Array[String] = ["B2", "C2", "D2", "B3"]
	if side == B:
		cells = ["B4", "C4", "D4", "B5"]
	if not first_cell.is_empty():
		cells[0] = first_cell
	var piece_ids: Array[int] = []
	for index: int in count:
		var cell := DuelStateBuilder.cell(cells[index])
		piece_ids.append(_builder.place_piece(side, Piece.PieceKind.UNIT, cell, SOLDIER))
	return piece_ids


func _hand_size(side: DuelState.PlayerSide) -> int:
	return _engine.get_state().get_player(side).hand.size()


func _start() -> void:
	_engine = DuelEngine.new(_catalog)
	_engine.start_from_state(_builder.build())
