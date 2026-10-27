# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## Déplacer une Unit par un effet (ruleset 0.52, chapitre 215 ; 207.5.4, 200.4.2 ; décision de
## design 0233 du ruleset ; décision 0056 : la case de destination est une seconde cible, jugée
## par rapport à la pièce ciblée). Le Spell et l'Unit à Arrivée viennent de MovementSamples.

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


func test_215_1_1_effect_moves_a_unit_onto_the_free_cell_it_targets() -> void:
	var enemy_id := _place(B, "B4")
	var card_id := _builder.add_to_hand(A, MovementSamples.MOVE_SPELL)
	MovementSamples.start(_engine, _builder)
	var announced := _engine.submit(_cast(card_id, enemy_id, "C4"))
	assert_array(EventLog.describe(announced)).contains_exactly(
		["SourceInclined:A", "SpellAnnounced:A", "StackEntryAdded:A"]
	)
	var entry := _engine.get_state().stack[0]
	assert_array(entry.target_piece_ids).contains_exactly([enemy_id])
	assert_array(entry.target_cells).contains_exactly([DuelStateBuilder.cell("C4")])
	assert_array(MovementSamples.resolve(_engine)).contains_exactly(
		["PriorityPassed:B", "PieceMoved:B", "CardDiscarded:A", "StackEntryResolved:A"]
	)
	assert_vector(MovementSamples.cell_of(_engine, enemy_id)).is_equal(DuelStateBuilder.cell("C4"))


func test_215_1_1_destination_must_be_a_free_cell_next_to_the_targeted_unit() -> void:
	var enemy_id := _place(B, "B4")
	_place(A, "C4")
	var card_id := _builder.add_to_hand(A, MovementSamples.MOVE_SPELL)
	MovementSamples.start(_engine, _builder)
	_assert_rejected(_cast(card_id, enemy_id, "C4"), REASON.ILLEGAL_TARGET)
	_assert_rejected(_cast(card_id, enemy_id, "C3"), REASON.ILLEGAL_TARGET)
	_assert_rejected(_cast(card_id, enemy_id, "D4"), REASON.ILLEGAL_TARGET)
	_assert_rejected(_cast(card_id, enemy_id, "B4"), REASON.ILLEGAL_TARGET)


func test_215_1_1_destination_is_a_target_the_spell_must_name() -> void:
	var enemy_id := _place(B, "B4")
	var card_id := _builder.add_to_hand(A, MovementSamples.MOVE_SPELL)
	MovementSamples.start(_engine, _builder)
	var without_cell := MovementSamples.cast(A, card_id, [enemy_id])
	_assert_rejected(without_cell, REASON.WRONG_TARGET_COUNT)
	var two_cells := _cast(card_id, enemy_id, "A4")
	two_cells.target_cells.append(DuelStateBuilder.cell("C4"))
	_assert_rejected(two_cells, REASON.WRONG_TARGET_COUNT)
	var without_unit := MovementSamples.cast(A, card_id, [], [DuelStateBuilder.cell("C4")])
	_assert_rejected(without_unit, REASON.WRONG_TARGET_COUNT)


func test_215_1_1_cell_taken_at_resolution_moves_nothing() -> void:
	var enemy_id := _place(B, "B4")
	var card_id := _builder.add_to_hand(A, MovementSamples.MOVE_SPELL)
	MovementSamples.start(_engine, _builder)
	_engine.submit(_cast(card_id, enemy_id, "C4"))
	DuelStateBuilder.place_unit_in(_engine.get_state(), A, TriggerSamples.SOLDIER, "C4")
	assert_array(MovementSamples.resolve(_engine)).contains_exactly(
		["PriorityPassed:B", "CardDiscarded:A", "StackEntryResolved:A"]
	)
	assert_vector(MovementSamples.cell_of(_engine, enemy_id)).is_equal(DuelStateBuilder.cell("B4"))


func test_215_1_1_unit_gone_at_resolution_loses_the_effect() -> void:
	var enemy_id := _place(B, "B4")
	var card_id := _builder.add_to_hand(A, MovementSamples.MOVE_SPELL)
	MovementSamples.start(_engine, _builder)
	_engine.submit(_cast(card_id, enemy_id, "C4"))
	var state := _engine.get_state()
	state.pieces.erase(state.find_piece(enemy_id))
	assert_array(MovementSamples.resolve(_engine)).contains_exactly(
		["PriorityPassed:B", "EffectLostAllTargets:A", "CardDiscarded:A", "StackEntryResolved:A"]
	)


func test_215_1_1_cell_no_longer_next_to_the_unit_is_invalid_at_resolution() -> void:
	var enemy_id := _place(B, "B4")
	var card_id := _builder.add_to_hand(A, MovementSamples.MOVE_SPELL)
	MovementSamples.start(_engine, _builder)
	_engine.submit(_cast(card_id, enemy_id, "C4"))
	_engine.get_state().find_piece(enemy_id).cell = DuelStateBuilder.cell("A2")
	assert_bool(MovementSamples.resolve(_engine).has("PieceMoved:B")).is_false()
	assert_vector(MovementSamples.cell_of(_engine, enemy_id)).is_equal(DuelStateBuilder.cell("A2"))


func test_215_1_2_move_by_an_effect_is_a_move() -> void:
	var enemy_id := _place(B, "B4")
	var events := _cast_and_resolve(enemy_id, "C4")
	var found := events.filter(func(event: DuelEvent) -> bool: return event is PieceMoved)
	var moved: PieceMoved = found[0]
	assert_int(moved.piece_id).is_equal(enemy_id)
	assert_vector(moved.from_cell).is_equal(DuelStateBuilder.cell("B4"))
	assert_vector(moved.to_cell).is_equal(DuelStateBuilder.cell("C4"))


func test_215_2_1_move_does_not_put_the_unit_to_sleep() -> void:
	var enemy_id := _place(B, "B4")
	_cast_and_resolve(enemy_id, "C4")
	assert_bool(_engine.get_state().find_piece(enemy_id).is_awake).is_true()


func test_215_2_2_move_does_not_wake_the_unit() -> void:
	var enemy_id := _place(B, "B4")
	_builder.with_piece_awake(enemy_id, false)
	_cast_and_resolve(enemy_id, "C4")
	assert_bool(_engine.get_state().find_piece(enemy_id).is_awake).is_false()


func test_215_2_3_move_is_not_a_normal_action() -> void:
	var enemy_id := _place(B, "B4")
	var labels := EventLog.describe(_cast_and_resolve(enemy_id, "C4"))
	assert_bool(labels.has("NormalActionAnnounced:B")).is_false()
	assert_bool(labels.has("NormalActionFailed:B")).is_false()
	assert_bool(_engine.get_state().find_piece(enemy_id).is_awake).is_true()


func test_215_2_4_moved_unit_does_not_arrive() -> void:
	var enemy_id := _place(B, "B4")
	var labels := EventLog.describe(_cast_and_resolve(enemy_id, "C4"))
	assert_bool(labels.has("PieceDeployed:B")).is_false()
	assert_bool(labels.has("PieceEnteredAttacking:B")).is_false()


func test_215_2_5_no_arrival_effect_triggers_for_the_moved_unit() -> void:
	var herald_id := _builder.place_piece(
		B, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B4"), TriggerSamples.HERALD
	)
	_place(A, "D2")
	var labels := EventLog.describe(_cast_and_resolve(herald_id, "C4"))
	assert_bool(labels.has("EffectTriggered:B")).is_false()
	assert_array(_engine.get_state().stack).is_empty()
	assert_array(_engine.get_state().waiting_triggers).is_empty()


func test_215_2_6_move_is_not_a_combat() -> void:
	var enemy_id := _place(B, "B2")
	var hero_health := _builder.build().find_hero(A).health
	var labels := EventLog.describe(_cast_and_resolve(enemy_id, "C2"))
	assert_bool(labels.has("CombatResolved")).is_false()
	assert_bool(labels.has("HeroAttacked:A")).is_false()
	assert_bool(labels.has("PieceDestroyed:B")).is_false()
	assert_int(_engine.get_state().find_hero(A).health).is_equal(hero_health)
	assert_vector(MovementSamples.cell_of(_engine, enemy_id)).is_equal(DuelStateBuilder.cell("C2"))


func test_decision_0056_move_arrival_asks_for_a_unit_and_a_cell() -> void:
	var first_id := _place(B, "B4")
	var second_id := _place(B, "D4")
	_push_arrival(MovementSamples.SHIFTER)
	MovementSamples.start(_engine, _builder)
	var labels := EventLog.describe(DuelChecks.pass_once(_engine, B))
	assert_str(labels[labels.size() - 1]).is_equal("DecisionRequested:A")
	var decision := _engine.get_state().pending_decision
	assert_array(decision.candidate_ids).contains_exactly([first_id, second_id])
	assert_int(decision.candidate_cells.size()).is_equal(7)
	_assert_rejected(MovementSamples.choose(A, [first_id]), REASON.WRONG_TARGET_COUNT)
	_assert_rejected(_choose(first_id, "D3"), REASON.ILLEGAL_TARGET)
	var chosen := _engine.submit(_choose(first_id, "C4"))
	assert_array(EventLog.describe(chosen)).contains_exactly(
		["TargetsChosen:A", "StackEntryAdded:A"]
	)
	assert_array(EventLog.describe(DuelChecks.pass_once(_engine, B))).contains(["PieceMoved:B"])
	assert_vector(MovementSamples.cell_of(_engine, first_id)).is_equal(DuelStateBuilder.cell("C4"))


func test_decision_0056_move_arrival_only_proposes_units_that_have_a_free_cell() -> void:
	var enclosed_id := _place(B, "A5")
	_place(A, "A4")
	_place(A, "B5")
	var free_id := _place(B, "D4")
	_push_arrival(MovementSamples.SHIFTER)
	MovementSamples.start(_engine, _builder)
	DuelChecks.pass_once(_engine, B)
	var decision := _engine.get_state().pending_decision
	assert_array(decision.candidate_ids).contains_exactly([free_id])
	assert_bool(decision.candidate_ids.has(enclosed_id)).is_false()


func test_decision_0056_move_arrival_with_a_single_unit_and_cell_chooses_for_the_player() -> void:
	var enemy_id := _place(B, "A5")
	_place(A, "A4")
	_push_arrival(MovementSamples.SHIFTER)
	MovementSamples.start(_engine, _builder)
	var labels := EventLog.describe(DuelChecks.pass_once(_engine, B))
	assert_bool(labels.has("DecisionResolvedAutomatically:A")).is_true()
	var entry := _engine.get_state().stack[0]
	assert_array(entry.target_piece_ids).contains_exactly([enemy_id])
	assert_array(entry.target_cells).contains_exactly([DuelStateBuilder.cell("B5")])


func test_decision_0056_move_arrival_without_a_legal_pair_is_not_added() -> void:
	_place(B, "A5")
	_place(A, "A4")
	_place(A, "B5")
	_push_arrival(MovementSamples.SHIFTER)
	MovementSamples.start(_engine, _builder)
	var labels := EventLog.describe(DuelChecks.pass_once(_engine, B))
	assert_str(labels[labels.size() - 1]).is_equal("TriggerSkipped:A")
	assert_array(_engine.get_state().stack).is_empty()


func test_decision_0019_agent_casts_a_move_with_a_unit_and_a_cell() -> void:
	_place(B, "B4")
	_builder.add_to_hand(A, MovementSamples.MOVE_SPELL)
	MovementSamples.start(_engine, _builder)
	var legal_casts := RandomLegalAgent.candidates(_engine.get_state(), A).filter(
		func(intent: DuelIntent) -> bool:
			return intent is CastSpell and _engine.validate(intent) == REASON.NONE
	)
	assert_bool(legal_casts.is_empty()).is_false()


func test_decision_0019_agent_answers_the_choice_of_a_unit_and_a_cell() -> void:
	_place(B, "B4")
	_push_arrival(MovementSamples.SHIFTER)
	MovementSamples.start(_engine, _builder)
	DuelChecks.pass_once(_engine, B)
	var intent := RandomLegalAgent.new(1).choose_intent(_engine)
	assert_object(intent).is_instanceof(ChooseTargets)
	var choice: ChooseTargets = intent
	assert_int(choice.target_piece_ids.size()).is_equal(1)
	assert_int(choice.target_cells.size()).is_equal(1)


func test_215_1_1_move_names_a_destination_cell_and_a_single_unit() -> void:
	var move := CatalogSamples.move_unit_effect()
	assert_array(Array(MovementSamples.effect_errors(move))).is_empty()
	(
		assert_bool(
			CatalogSamples.mentions(
				MovementSamples.effect_errors(CatalogSamples.without_field(move, "destination")),
				"215.1.1"
			)
		)
		. is_true()
	)
	var piece_destination := CatalogSamples.with_field(move, "destination", {"what": "piece"})
	(
		assert_bool(
			CatalogSamples.mentions(
				MovementSamples.effect_errors(piece_destination), "la destination de move_unit"
			)
		)
		. is_true()
	)
	var two_units := CatalogSamples.move_unit_effect()
	two_units["target"]["count_max"] = 2
	(
		assert_bool(
			CatalogSamples.mentions(MovementSamples.effect_errors(two_units), "une seule Unit")
		)
		. is_true()
	)
	var hero := CatalogSamples.move_unit_effect()
	hero["target"]["filter"]["piece_kinds"] = ["hero"]
	(
		assert_bool(
			CatalogSamples.mentions(
				MovementSamples.effect_errors(hero), "215.1.1 : move_unit ne cible que"
			)
		)
		. is_true()
	)


func test_215_1_1_destination_is_refused_for_other_kinds() -> void:
	var destination := {"what": "cell"}
	for effect: Dictionary in [
		CatalogSamples.swap_cells_effect(),
		CatalogSamples.return_to_hand_effect(),
		CatalogSamples.destroy_effect(),
		CatalogSamples.modify_force_resolve(),
	]:
		var with_destination := CatalogSamples.with_field(effect, "destination", destination)
		(
			assert_bool(
				CatalogSamples.mentions(
					MovementSamples.effect_errors(with_destination), "destination ne vaut que"
				)
			)
			. is_true()
		)


func test_decision_0056_movement_kinds_take_resolve_and_triggered_timings() -> void:
	for effect: Dictionary in [
		CatalogSamples.swap_cells_effect(),
		CatalogSamples.move_unit_effect(),
		CatalogSamples.return_to_hand_effect(),
	]:
		var triggered := CatalogSamples.with_field(effect, "timing", "triggered")
		triggered = CatalogSamples.with_field(triggered, "trigger", "arrival")
		assert_array(Array(MovementSamples.effect_errors(triggered))).is_empty()
		var static_effect := CatalogSamples.with_field(effect, "timing", "static")
		(
			assert_bool(
				CatalogSamples.mentions(
					MovementSamples.effect_errors(static_effect), "n'admet pas le timing"
				)
			)
			. is_true()
		)


func test_decision_0056_destination_is_read_from_the_json() -> void:
	var effect := CatalogSamples.effect_from(CatalogSamples.move_unit_effect())
	assert_int(effect.destination.what).is_equal(TargetSpec.TargetWhat.CELL)
	assert_int(effect.destination.adjacent_to).is_equal(TargetSpec.AdjacentTo.TARGET_PIECE)
	assert_object(CatalogSamples.effect_from(CatalogSamples.destroy_effect()).destination).is_null()


func test_decision_0056_adjacency_filters_fit_the_kind_of_target() -> void:
	var target_piece_piece := CatalogSamples.ally_unit_target()
	target_piece_piece["adjacent_to"] = "target_piece"
	(
		assert_bool(
			CatalogSamples.mentions(MovementSamples.target_errors(target_piece_piece), "215.1.1")
		)
		. is_true()
	)
	(
		assert_array(
			Array(MovementSamples.target_errors({"what": "cell", "adjacent_to": "target_piece"}))
		)
		. is_empty()
	)
	(
		assert_array(
			Array(MovementSamples.target_errors({"what": "cell", "adjacent_to": "own_hero"}))
		)
		. is_empty()
	)
	var spell := {"what": "spell_on_stack", "adjacent_to": "target_piece"}
	assert_bool(CatalogSamples.mentions(MovementSamples.target_errors(spell), "207.5.14")).is_true()


func test_decision_0056_relative_filter_belongs_to_the_destination_only() -> void:
	var token := CatalogSamples.create_token_effect()
	token["target"]["adjacent_to"] = "target_piece"
	(
		assert_bool(
			CatalogSamples.mentions(
				MovementSamples.effect_errors(token), "ne vaut que pour la destination"
			)
		)
		. is_true()
	)


func _place(side: DuelState.PlayerSide, cell_name: String) -> int:
	return _builder.place_piece(
		side, Piece.PieceKind.UNIT, DuelStateBuilder.cell(cell_name), TriggerSamples.SOLDIER
	)


func _cast(card_id: int, piece_id: int, cell_name: String) -> CastSpell:
	return MovementSamples.cast(A, card_id, [piece_id], [DuelStateBuilder.cell(cell_name)])


func _choose(piece_id: int, cell_name: String) -> ChooseTargets:
	return MovementSamples.choose(A, [piece_id], [DuelStateBuilder.cell(cell_name)])


# Déploiement de A déjà annoncé que B laisse se résoudre : l'Arrivée attend ses cibles.
func _push_arrival(definition_id: StringName) -> void:
	var card := _builder.make_card_instance(A, definition_id)
	_builder.push_deploy(card, DuelStateBuilder.cell("B1"))
	_builder.with_priority_player(B)


# A annonce le déplacement de `piece_id` vers `cell_name`, B passe : la pile se résout.
func _cast_and_resolve(piece_id: int, cell_name: String) -> Array[DuelEvent]:
	var card_id := _builder.add_to_hand(A, MovementSamples.MOVE_SPELL)
	MovementSamples.start(_engine, _builder)
	_engine.submit(_cast(card_id, piece_id, cell_name))
	return DuelChecks.pass_once(_engine, B)


func _assert_rejected(intent: DuelIntent, expected: IntentRejected.RejectReason) -> void:
	assert_array(DuelChecks.rejection_defects(_engine, intent, expected)).is_empty()
