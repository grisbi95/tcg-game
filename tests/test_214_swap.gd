# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## Échanger les cases de deux Units (ruleset 0.52, chapitre 214 ; 200.4.2a, 207.5.4a ; décisions
## de design 0217 et 0227 du ruleset ; décision 0056). Le Spell et l'Unit à Arrivée viennent de
## MovementSamples.

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const REASON := IntentRejected.RejectReason
const SOURCES_IN_PLAY: int = 4

var _builder: DuelStateBuilder
var _engine: DuelEngine


func before_test() -> void:
	var catalog := MovementSamples.catalog()
	_builder = DuelStateBuilder.new(DuelConfig.new(), catalog)
	for side: DuelState.PlayerSide in [A, B]:
		_builder.with_sources_in_play(side, SOURCES_IN_PLAY, 0)
	_engine = DuelEngine.new(catalog)


func test_decision_0056_movement_samples_are_valid() -> void:
	for data: Dictionary in MovementSamples.card_data():
		assert_array(CardDefinition.from_dict(data).find_errors()).is_empty()


func test_214_1_1_swap_makes_each_piece_occupy_the_cell_of_the_other() -> void:
	var first_id := _place(A, "B2")
	var second_id := _place(A, "D3")
	var card_id := _builder.add_to_hand(A, MovementSamples.SWAP_SPELL)
	MovementSamples.start(_engine, _builder)
	var announced := _engine.submit(MovementSamples.cast(A, card_id, [first_id, second_id]))
	assert_array(EventLog.describe(announced)).contains_exactly(
		["SourceInclined:A", "SpellAnnounced:A", "StackEntryAdded:A"]
	)
	var resolved := MovementSamples.resolve(_engine)
	assert_array(resolved).contains_exactly(
		["PriorityPassed:B", "PiecesSwapped:A", "CardDiscarded:A", "StackEntryResolved:A"]
	)
	assert_vector(MovementSamples.cell_of(_engine, first_id)).is_equal(DuelStateBuilder.cell("D3"))
	assert_vector(MovementSamples.cell_of(_engine, second_id)).is_equal(DuelStateBuilder.cell("B2"))


func test_214_1_2_swap_is_simultaneous() -> void:
	var first_id := _place(A, "B2")
	var second_id := _place(A, "D3")
	_cast_and_resolve([first_id, second_id])
	var state := _engine.get_state()
	assert_object(state.piece_at(DuelStateBuilder.cell("B2"))).is_same(state.find_piece(second_id))
	assert_object(state.piece_at(DuelStateBuilder.cell("D3"))).is_same(state.find_piece(first_id))
	for piece: Piece in state.pieces:
		assert_bool(BoardGeometry.is_on_board(piece.cell)).is_true()


func test_214_1_2_swap_is_one_fact_that_names_both_previous_cells() -> void:
	var first_id := _place(A, "B2")
	var second_id := _place(A, "D3")
	var events := _cast_and_resolve([first_id, second_id])
	var swaps := events.filter(func(event: DuelEvent) -> bool: return event is PiecesSwapped)
	assert_int(swaps.size()).is_equal(1)
	var swapped: PiecesSwapped = swaps[0]
	assert_int(swapped.first_piece_id).is_equal(first_id)
	assert_int(swapped.second_piece_id).is_equal(second_id)
	assert_vector(swapped.first_cell).is_equal(DuelStateBuilder.cell("B2"))
	assert_vector(swapped.second_cell).is_equal(DuelStateBuilder.cell("D3"))


func test_214_1_3_only_two_allied_units_are_swapped() -> void:
	var first_id := _place(A, "B2")
	var second_id := _place(A, "D3")
	var enemy_id := _place(B, "B4")
	var building_id := _builder.place_piece(
		A, Piece.PieceKind.BUILDING, DuelStateBuilder.cell("D2"), TriggerSamples.BEACON
	)
	var hero_id := _builder.build().find_hero(A).piece_id
	var card_id := _builder.add_to_hand(A, MovementSamples.SWAP_SPELL)
	MovementSamples.start(_engine, _builder)
	for other_id: int in [enemy_id, building_id, hero_id]:
		_assert_rejected(
			MovementSamples.cast(A, card_id, [first_id, other_id]), REASON.ILLEGAL_TARGET
		)
	_assert_rejected(MovementSamples.cast(A, card_id, [first_id]), REASON.WRONG_TARGET_COUNT)
	_assert_rejected(
		MovementSamples.cast(A, card_id, [first_id, second_id, second_id]),
		REASON.WRONG_TARGET_COUNT
	)


func test_214_1_3_a_token_unit_can_be_swapped() -> void:
	var token_id := _builder.place_token(A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B2"), 1)
	var unit_id := _place(A, "D3")
	_cast_and_resolve([token_id, unit_id])
	assert_vector(MovementSamples.cell_of(_engine, token_id)).is_equal(DuelStateBuilder.cell("D3"))


func test_214_1_3_the_two_swapped_units_are_distinct() -> void:
	var unit_id := _place(A, "B2")
	_place(A, "D3")
	var card_id := _builder.add_to_hand(A, MovementSamples.SWAP_SPELL)
	MovementSamples.start(_engine, _builder)
	_assert_rejected(MovementSamples.cast(A, card_id, [unit_id, unit_id]), REASON.ILLEGAL_TARGET)


func test_214_1_4_the_two_swapped_units_are_the_targets_of_the_effect() -> void:
	var first_id := _place(A, "B2")
	var second_id := _place(A, "D3")
	var card_id := _builder.add_to_hand(A, MovementSamples.SWAP_SPELL)
	MovementSamples.start(_engine, _builder)
	_engine.submit(MovementSamples.cast(A, card_id, [first_id, second_id]))
	var entry := _engine.get_state().stack[0]
	assert_array(entry.target_piece_ids).contains_exactly([first_id, second_id])
	assert_array(entry.target_cells).is_empty()


func test_214_2_1_swap_needs_both_targets_valid() -> void:
	var first_id := _place(A, "B2")
	var second_id := _place(A, "D3")
	var card_id := _builder.add_to_hand(A, MovementSamples.SWAP_SPELL)
	MovementSamples.start(_engine, _builder)
	_engine.submit(MovementSamples.cast(A, card_id, [first_id, second_id]))
	var state := _engine.get_state()
	state.pieces.erase(state.find_piece(second_id))
	var resolved := MovementSamples.resolve(_engine)
	assert_array(resolved).contains_exactly(
		["PriorityPassed:B", "CardDiscarded:A", "StackEntryResolved:A"]
	)
	assert_vector(MovementSamples.cell_of(_engine, first_id)).is_equal(DuelStateBuilder.cell("B2"))


func test_214_2_1_swap_with_no_valid_target_is_lost() -> void:
	var first_id := _place(A, "B2")
	var second_id := _place(A, "D3")
	var card_id := _builder.add_to_hand(A, MovementSamples.SWAP_SPELL)
	MovementSamples.start(_engine, _builder)
	_engine.submit(MovementSamples.cast(A, card_id, [first_id, second_id]))
	var state := _engine.get_state()
	state.pieces.erase(state.find_piece(first_id))
	state.pieces.erase(state.find_piece(second_id))
	assert_array(MovementSamples.resolve(_engine)).contains_exactly(
		["PriorityPassed:B", "EffectLostAllTargets:A", "CardDiscarded:A", "StackEntryResolved:A"]
	)


func test_200_4_2a_partial_swap_does_not_happen() -> void:
	var first_id := _place(A, "B2")
	var second_id := _place(A, "D3")
	var card_id := _builder.add_to_hand(A, MovementSamples.SWAP_SPELL)
	MovementSamples.start(_engine, _builder)
	_engine.submit(MovementSamples.cast(A, card_id, [first_id, second_id]))
	var state := _engine.get_state()
	state.find_piece(first_id).owner = B
	var labels := MovementSamples.resolve(_engine)
	assert_bool(labels.has("PiecesSwapped:A")).is_false()
	assert_vector(MovementSamples.cell_of(_engine, first_id)).is_equal(DuelStateBuilder.cell("B2"))
	assert_vector(MovementSamples.cell_of(_engine, second_id)).is_equal(DuelStateBuilder.cell("D3"))


func test_207_5_4a_swap_applies_only_if_both_targets_stayed_valid() -> void:
	var first_id := _place(A, "B2")
	var second_id := _place(A, "D3")
	var card_id := _builder.add_to_hand(A, MovementSamples.SWAP_SPELL)
	MovementSamples.start(_engine, _builder)
	_engine.submit(MovementSamples.cast(A, card_id, [first_id, second_id]))
	var state := _engine.get_state()
	state.pieces.erase(state.find_piece(first_id))
	assert_array(MovementSamples.resolve(_engine)).contains_exactly(
		["PriorityPassed:B", "CardDiscarded:A", "StackEntryResolved:A"]
	)
	assert_vector(MovementSamples.cell_of(_engine, second_id)).is_equal(DuelStateBuilder.cell("D3"))


func test_214_2_2_swap_neither_sleeps_nor_wakes() -> void:
	var awake_id := _place(A, "B2")
	var asleep_id := _place(A, "D3")
	_builder.with_piece_awake(asleep_id, false)
	_cast_and_resolve([awake_id, asleep_id])
	var state := _engine.get_state()
	assert_bool(state.find_piece(awake_id).is_awake).is_true()
	assert_bool(state.find_piece(asleep_id).is_awake).is_false()


func test_214_2_3_swap_is_not_a_normal_action() -> void:
	var first_id := _place(A, "B2")
	var second_id := _place(A, "D3")
	var events := _cast_and_resolve([first_id, second_id])
	var labels := EventLog.describe(events)
	assert_bool(labels.has("NormalActionAnnounced:A")).is_false()
	var normal_action := TakeNormalAction.new(A, first_id, DuelStateBuilder.cell("D4"))
	assert_int(_engine.validate(normal_action)).is_equal(REASON.NONE)


func test_214_2_4_swapped_piece_does_not_arrive() -> void:
	var herald_id := _builder.place_piece(
		A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B2"), TriggerSamples.HERALD
	)
	var soldier_id := _place(A, "D3")
	_place(B, "B4")
	var events := _cast_and_resolve([herald_id, soldier_id])
	var labels := EventLog.describe(events)
	assert_bool(labels.has("EffectTriggered:A")).is_false()
	assert_bool(labels.has("PieceDeployed:A")).is_false()
	assert_array(_engine.get_state().stack).is_empty()
	assert_array(_engine.get_state().waiting_triggers).is_empty()


func test_214_2_5_swap_is_not_a_move() -> void:
	var first_id := _place(A, "B2")
	var second_id := _place(A, "D3")
	var labels := EventLog.describe(_cast_and_resolve([first_id, second_id]))
	assert_bool(labels.has("PieceMoved:A")).is_false()
	assert_bool(labels.has("PiecesSwapped:A")).is_true()


func test_decision_0056_swap_arrival_asks_for_two_targets_among_three_units() -> void:
	var first_id := _place(A, "B2")
	var second_id := _place(A, "D3")
	var deploy_card := _builder.make_card_instance(A, MovementSamples.SWAPPER)
	_builder.push_deploy(deploy_card, DuelStateBuilder.cell("B1"))
	_builder.with_priority_player(B)
	MovementSamples.start(_engine, _builder)
	var labels := EventLog.describe(DuelChecks.pass_once(_engine, B))
	assert_str(labels[labels.size() - 1]).is_equal("DecisionRequested:A")
	var decision := _engine.get_state().pending_decision
	assert_int(decision.kind).is_equal(PendingDecision.DecisionKind.CHOOSE_TARGETS)
	assert_int(decision.candidate_ids.size()).is_equal(3)
	assert_array(decision.candidate_cells).is_empty()
	_assert_rejected(MovementSamples.choose(A, [first_id]), REASON.WRONG_TARGET_COUNT)
	_assert_rejected(MovementSamples.choose(A, [first_id, first_id]), REASON.ILLEGAL_TARGET)
	var chosen := _engine.submit(MovementSamples.choose(A, [first_id, second_id]))
	assert_array(EventLog.describe(chosen)).contains_exactly(
		["TargetsChosen:A", "StackEntryAdded:A"]
	)
	assert_array(DuelChecks.pass_once(_engine, B)).is_not_empty()
	assert_vector(MovementSamples.cell_of(_engine, first_id)).is_equal(DuelStateBuilder.cell("D3"))


func test_decision_0056_swap_arrival_with_exactly_two_units_chooses_for_the_player() -> void:
	var other_id := _place(A, "D3")
	var deploy_card := _builder.make_card_instance(A, MovementSamples.SWAPPER)
	_builder.push_deploy(deploy_card, DuelStateBuilder.cell("B1"))
	_builder.with_priority_player(B)
	MovementSamples.start(_engine, _builder)
	var labels := EventLog.describe(DuelChecks.pass_once(_engine, B))
	assert_bool(labels.has("DecisionResolvedAutomatically:A")).is_true()
	var entry := _engine.get_state().stack[0]
	assert_int(entry.target_piece_ids.size()).is_equal(2)
	assert_bool(entry.target_piece_ids.has(other_id)).is_true()


func test_decision_0056_swap_arrival_alone_is_not_added() -> void:
	var deploy_card := _builder.make_card_instance(A, MovementSamples.SWAPPER)
	_builder.push_deploy(deploy_card, DuelStateBuilder.cell("B1"))
	_builder.with_priority_player(B)
	MovementSamples.start(_engine, _builder)
	var labels := EventLog.describe(DuelChecks.pass_once(_engine, B))
	assert_str(labels[labels.size() - 1]).is_equal("TriggerSkipped:A")
	assert_array(_engine.get_state().stack).is_empty()


func test_decision_0056_near_hero_swap_needs_units_next_to_the_hero() -> void:
	var near_id := _place(A, "B1")
	var other_near_id := _place(A, "C2")
	var far_id := _place(A, "D4")
	var card_id := _builder.add_to_hand(A, MovementSamples.NEAR_HERO_SWAP_SPELL)
	MovementSamples.start(_engine, _builder)
	_assert_rejected(MovementSamples.cast(A, card_id, [near_id, far_id]), REASON.ILLEGAL_TARGET)
	_engine.submit(MovementSamples.cast(A, card_id, [near_id, other_near_id]))
	assert_array(MovementSamples.resolve(_engine)).contains(["PiecesSwapped:A"])
	assert_vector(MovementSamples.cell_of(_engine, near_id)).is_equal(DuelStateBuilder.cell("C2"))


func test_decision_0019_agent_casts_a_swap_with_two_units() -> void:
	_place(A, "B2")
	_place(A, "D3")
	_builder.add_to_hand(A, MovementSamples.SWAP_SPELL)
	MovementSamples.start(_engine, _builder)
	var legal_casts := RandomLegalAgent.candidates(_engine.get_state(), A).filter(
		func(intent: DuelIntent) -> bool:
			return intent is CastSpell and _engine.validate(intent) == REASON.NONE
	)
	assert_bool(legal_casts.is_empty()).is_false()


func test_decision_0019_agent_answers_the_choice_of_two_units() -> void:
	_place(A, "B2")
	_place(A, "D3")
	var deploy_card := _builder.make_card_instance(A, MovementSamples.SWAPPER)
	_builder.push_deploy(deploy_card, DuelStateBuilder.cell("B1"))
	_builder.with_priority_player(B)
	MovementSamples.start(_engine, _builder)
	DuelChecks.pass_once(_engine, B)
	var intent := RandomLegalAgent.new(1).choose_intent(_engine)
	assert_object(intent).is_instanceof(ChooseTargets)
	assert_int((intent as ChooseTargets).target_piece_ids.size()).is_equal(2)


func test_214_1_4_swap_targets_exactly_two_allied_units() -> void:
	var swap := CatalogSamples.swap_cells_effect()
	assert_array(Array(MovementSamples.effect_errors(swap))).is_empty()
	var one := CatalogSamples.swap_cells_effect()
	one["target"]["count_min"] = 1
	one["target"]["count_max"] = 1
	var three := CatalogSamples.swap_cells_effect()
	three["target"]["count_max"] = 3
	for wrong_count: Dictionary in [one, three]:
		(
			assert_bool(
				CatalogSamples.mentions(MovementSamples.effect_errors(wrong_count), "214.1.4")
			)
			. is_true()
		)
	var enemy := CatalogSamples.swap_cells_effect()
	enemy["target"]["side"] = "enemy"
	assert_bool(CatalogSamples.mentions(MovementSamples.effect_errors(enemy), "214.1.3")).is_true()
	var any_side := CatalogSamples.swap_cells_effect()
	any_side["target"]["side"] = "any"
	(
		assert_bool(CatalogSamples.mentions(MovementSamples.effect_errors(any_side), "214.1.3"))
		. is_true()
	)


func test_214_1_3_swap_targets_only_units() -> void:
	for kinds: Array in [["hero"], ["building"], ["unit", "hero"]]:
		var swap := CatalogSamples.swap_cells_effect()
		swap["target"]["piece_kinds"] = kinds
		(
			assert_bool(
				CatalogSamples.mentions(
					MovementSamples.effect_errors(swap), "214.1.4 : swap_cells ne cible que"
				)
			)
			. is_true()
		)


func _place(side: DuelState.PlayerSide, cell_name: String) -> int:
	return _builder.place_piece(
		side, Piece.PieceKind.UNIT, DuelStateBuilder.cell(cell_name), TriggerSamples.SOLDIER
	)


# A annonce l'échange des cibles données, B passe : la pile se résout. Renvoie les événements.
func _cast_and_resolve(target_ids: Array[int]) -> Array[DuelEvent]:
	var card_id := _builder.add_to_hand(A, MovementSamples.SWAP_SPELL)
	MovementSamples.start(_engine, _builder)
	_engine.submit(MovementSamples.cast(A, card_id, target_ids))
	return DuelChecks.pass_once(_engine, B)


func _assert_rejected(intent: DuelIntent, expected: IntentRejected.RejectReason) -> void:
	assert_array(DuelChecks.rejection_defects(_engine, intent, expected)).is_empty()
