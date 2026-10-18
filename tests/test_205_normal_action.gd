# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## Action normale d'une Unit, déplacement du Hero et échecs (ruleset 0.31, sections 205.2 à
## 205.4 ; 204.4.5, 204.4.6, 208.1.2, 208.1.10, 208.1.11).

const UNIT_ID: StringName = &"acting_unit"
const WEAK_ID: StringName = &"weak_unit"
const BUILDING_ID: StringName = &"still_building"
const SPELL_ID: StringName = &"sample_spell"
const UNIT_FORCE: int = 4
const HERO_HEALTH: int = DuelStateBuilder.DEFAULT_HERO_HEALTH
const MISSING_PIECE_ID: int = 9999

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const REASON := IntentRejected.RejectReason

var _builder: DuelStateBuilder
var _engine: DuelEngine


func before_test() -> void:
	var catalog := Catalog.new()
	SetupSamples.add_unit(catalog, UNIT_ID, UNIT_FORCE)
	SetupSamples.add_unit(catalog, WEAK_ID, 1)
	SetupSamples.add_building(catalog, BUILDING_ID, 3)
	catalog.add_card(CardDefinition.from_dict(CatalogSamples.spell()))
	_builder = DuelStateBuilder.new(DuelConfig.new(), catalog)
	_engine = DuelEngine.new(catalog)


func test_208_1_2_normal_action_is_announced_on_the_stack() -> void:
	var unit_id := _place(A, UNIT_ID, "B2")
	_start()
	var events := _engine.submit(_act(unit_id, "B3"))
	assert_array(EventLog.describe(events)).contains_exactly(
		["NormalActionAnnounced:A", "StackEntryAdded:A"]
	)
	var state := _engine.get_state()
	assert_int(state.stack[0].kind).is_equal(StackEntry.StackEntryKind.NORMAL_ACTION)
	assert_int(state.priority_player).is_equal(B)


func test_205_2_4_normal_action_costs_no_essence() -> void:
	var unit_id := _place(A, UNIT_ID, "B2")
	_start()
	var before := _engine.get_state().get_player(A).clone()
	_engine.submit(_act(unit_id, "B3"))
	var player := _engine.get_state().get_player(A)
	assert_int(player.sources_upright).is_equal(before.sources_upright)
	assert_int(player.sources_tilted).is_equal(before.sources_tilted)


func test_205_2_2_unit_moves_to_free_target_cell() -> void:
	var unit_id := _place(A, UNIT_ID, "B2")
	_start()
	_engine.submit(_act(unit_id, "B3"))
	assert_array(_resolve_stack()).contains(["PieceMoved:A"])
	assert_str(_cell_of(unit_id)).is_equal("B3")


func test_205_2_3_unit_attacks_enemy_on_target_cell() -> void:
	var unit_id := _place(A, UNIT_ID, "B2")
	var enemy_id := _place(B, WEAK_ID, "B3")
	_start()
	_engine.submit(_act(unit_id, "B3"))
	assert_array(_resolve_stack()).contains(["CombatResolved", "PieceDestroyed:B", "PieceMoved:A"])
	assert_object(_engine.get_state().find_piece(enemy_id)).is_null()
	assert_str(_cell_of(unit_id)).is_equal("B3")


func test_206_4_1_unit_attacks_enemy_hero() -> void:
	var unit_id := _place(A, UNIT_ID, "C4")
	_start()
	_engine.submit(_act(unit_id, "C5"))
	assert_array(_resolve_stack()).contains(["HeroAttacked:B", "HeroLostHealth:B"])
	assert_int(_engine.get_state().find_hero(B).health).is_equal(HERO_HEALTH - UNIT_FORCE)
	assert_str(_cell_of(unit_id)).is_equal("C4")


func test_209_2_2_lethal_attack_through_stack_ends_duel_once() -> void:
	_builder.with_hero_health(B, UNIT_FORCE)
	var unit_id := _place(A, UNIT_ID, "C4")
	_start()
	_engine.submit(_act(unit_id, "C5"))
	var labels := _resolve_stack()
	assert_int(labels.count("DuelEnded")).is_equal(1)
	assert_str(labels.back()).is_equal("DuelEnded")
	assert_array(labels).not_contains(["StackEntryResolved:A"])
	assert_int(_engine.get_state().result).is_equal(DuelState.DuelResult.PLAYER_A_WINS)


func test_205_2_5_target_must_be_adjacent() -> void:
	var unit_id := _place(A, UNIT_ID, "B2")
	_start()
	_assert_rejected(_act(unit_id, "B4"), REASON.CELL_NOT_ADJACENT)
	_assert_rejected(_act(unit_id, "C3"), REASON.CELL_NOT_ADJACENT)


func test_205_2_6_ally_cell_rejected_at_announcement() -> void:
	var unit_id := _place(A, UNIT_ID, "B2")
	_place(A, WEAK_ID, "B3")
	_start()
	_assert_rejected(_act(unit_id, "B3"), REASON.CELL_OCCUPIED_BY_ALLY)


func test_205_4_7_action_counts_from_announcement() -> void:
	var unit_id := _place(A, UNIT_ID, "B2")
	var other_id := _place(A, WEAK_ID, "D2")
	_start()
	_engine.submit(_act(unit_id, "B3"))
	assert_bool(_engine.get_state().get_player(A).normal_action_used_this_turn).is_true()
	_resolve_stack()
	_assert_rejected(_act(other_id, "D3"), REASON.NORMAL_ACTION_ALREADY_USED)


func test_204_4_6_one_normal_action_per_turn_even_after_failure() -> void:
	var unit_id := _place(A, UNIT_ID, "B2")
	var other_id := _place(A, WEAK_ID, "D2")
	_start()
	_engine.submit(_act(unit_id, "B3"))
	DuelStateBuilder.place_unit_in(_engine.get_state(), A, WEAK_ID, "B3")
	assert_array(_resolve_stack()).contains(["NormalActionFailed:A"])
	_assert_rejected(_act(other_id, "D3"), REASON.NORMAL_ACTION_ALREADY_USED)


func test_205_4_5_ally_on_target_at_resolution_makes_action_fail() -> void:
	var unit_id := _place(A, UNIT_ID, "B2")
	_start()
	_engine.submit(_act(unit_id, "B3"))
	DuelStateBuilder.place_unit_in(_engine.get_state(), A, WEAK_ID, "B3")
	assert_array(_resolve_stack()).contains(["NormalActionFailed:A"])
	assert_str(_cell_of(unit_id)).is_equal("B2")


func test_205_4_3_unit_gone_at_resolution_makes_action_fail() -> void:
	var unit_id := _place(A, UNIT_ID, "B2")
	_start()
	_engine.submit(_act(unit_id, "B3"))
	var state := _engine.get_state()
	state.pieces.erase(state.find_piece(unit_id))
	assert_array(_resolve_stack()).contains(["NormalActionFailed:A"])


func test_205_4_4_target_no_longer_adjacent_makes_action_fail() -> void:
	var unit_id := _place(A, UNIT_ID, "B2")
	_start()
	_engine.submit(_act(unit_id, "B3"))
	_engine.get_state().find_piece(unit_id).cell = DuelStateBuilder.cell("D2")
	assert_array(_resolve_stack()).contains(["NormalActionFailed:A"])
	assert_str(_cell_of(unit_id)).is_equal("D2")


func test_205_4_6_failed_action_does_not_happen() -> void:
	var unit_id := _place(A, UNIT_ID, "B2")
	_start()
	_engine.submit(_act(unit_id, "B3"))
	DuelStateBuilder.place_unit_in(_engine.get_state(), A, WEAK_ID, "B3")
	var labels := _resolve_stack()
	assert_array(labels).not_contains(["PieceMoved:A", "CombatResolved"])


func test_205_4_1_action_resolves_on_board_at_resolution() -> void:
	var unit_id := _place(A, UNIT_ID, "B2")
	_start()
	_engine.submit(_act(unit_id, "B3"))
	DuelStateBuilder.place_unit_in(_engine.get_state(), B, WEAK_ID, "B3")
	assert_array(_resolve_stack()).contains(["CombatResolved", "PieceDestroyed:B"])
	assert_str(_cell_of(unit_id)).is_equal("B3")


func test_205_4_2_action_targets_cell_not_piece() -> void:
	var unit_id := _place(A, UNIT_ID, "B2")
	var enemy_id := _place(B, WEAK_ID, "B3")
	_start()
	_engine.submit(_act(unit_id, "B3"))
	var state := _engine.get_state()
	state.find_piece(enemy_id).cell = DuelStateBuilder.cell("D4")
	assert_array(_resolve_stack()).contains(["PieceMoved:A"])
	assert_object(state.find_piece(enemy_id)).is_not_null()


func test_202_2_17_building_has_no_normal_action() -> void:
	var building_id := _builder.place_piece(
		A, Piece.PieceKind.BUILDING, DuelStateBuilder.cell("B2"), BUILDING_ID
	)
	_start()
	_assert_rejected(_act(building_id, "B3"), REASON.NO_NORMAL_ACTION)


func test_204_4_5_player_acts_only_with_own_piece() -> void:
	var enemy_id := _place(B, WEAK_ID, "B3")
	_start()
	_assert_rejected(_act(enemy_id, "B2"), REASON.PIECE_NOT_YOURS)
	_assert_rejected(_act(MISSING_PIECE_ID, "B2"), REASON.PIECE_NOT_YOURS)


func test_202_4_10_unit_token_takes_normal_action() -> void:
	var token_id := _builder.place_token(A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B2"), 1)
	_start()
	_engine.submit(_act(token_id, "B3"))
	_resolve_stack()
	assert_str(_cell_of(token_id)).is_equal("B3")


func test_205_3_1_hero_moves_to_free_adjacent_cell() -> void:
	_start()
	var hero_id := _engine.get_state().find_hero(A).piece_id
	_engine.submit(_act(hero_id, "C2"))
	assert_array(_resolve_stack()).contains(["PieceMoved:A"])
	assert_str(_cell_of(hero_id)).is_equal("C2")


func test_205_3_2_hero_never_leaves_its_near_rows() -> void:
	_start()
	var hero := _engine.get_state().find_hero(A)
	hero.cell = DuelStateBuilder.cell("C2")
	_assert_rejected(_act(hero.piece_id, "C3"), REASON.CELL_OUTSIDE_HERO_ROWS)


func test_205_3_3_hero_target_must_be_free_at_announcement() -> void:
	_place(A, WEAK_ID, "B1")
	_start()
	var hero_id := _engine.get_state().find_hero(A).piece_id
	_assert_rejected(_act(hero_id, "B1"), REASON.CELL_NOT_FREE)


func test_202_3_10_hero_never_attacks() -> void:
	_place(B, WEAK_ID, "B1")
	_start()
	var hero_id := _engine.get_state().find_hero(A).piece_id
	_assert_rejected(_act(hero_id, "B1"), REASON.CELL_NOT_FREE)
	_engine.submit(_act(hero_id, "D1"))
	DuelStateBuilder.place_unit_in(_engine.get_state(), B, WEAK_ID, "D1")
	var labels := _resolve_stack()
	assert_array(labels).contains(["NormalActionFailed:A"])
	assert_array(labels).not_contains(["CombatResolved"])


func test_208_1_10_normal_action_only_during_own_main_phase() -> void:
	var unit_id := _place(A, UNIT_ID, "B2")
	var enemy_id := _place(B, WEAK_ID, "D4")
	_start()
	_assert_rejected(
		TakeNormalAction.new(B, enemy_id, DuelStateBuilder.cell("D3")), REASON.NOT_YOUR_TURN
	)
	_engine.get_state().phase = DuelState.DuelPhase.TURN_END
	_assert_rejected(_act(unit_id, "B3"), REASON.WRONG_PHASE)


func test_208_1_11_normal_action_only_with_empty_stack() -> void:
	var unit_id := _place(A, UNIT_ID, "B2")
	_builder.push_spell(_builder.make_card_instance(B, SPELL_ID))
	_start()
	_assert_rejected(_act(unit_id, "B3"), REASON.STACK_NOT_EMPTY)


func _start() -> void:
	_engine.start_from_state(_builder.build())


func _act(piece_id: int, cell_name: String) -> TakeNormalAction:
	return TakeNormalAction.new(A, piece_id, DuelStateBuilder.cell(cell_name))


## Le joueur qui a la priorité passe : la pile se résout. Renvoie les événements décrits.
func _resolve_stack() -> Array[String]:
	var first := _engine.get_state().priority_player
	var events := DuelChecks.pass_once(_engine, first)
	return EventLog.describe(events)


func _place(side: DuelState.PlayerSide, definition_id: StringName, cell_name: String) -> int:
	return _builder.place_piece(
		side, Piece.PieceKind.UNIT, DuelStateBuilder.cell(cell_name), definition_id
	)


func _cell_of(piece_id: int) -> String:
	return BoardGeometry.cell_name(_engine.get_state().find_piece(piece_id).cell)


func _assert_rejected(intent: DuelIntent, expected: IntentRejected.RejectReason) -> void:
	assert_array(DuelChecks.rejection_defects(_engine, intent, expected)).is_empty()
