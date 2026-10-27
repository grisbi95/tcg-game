extends GdUnitTestSuite
## Filtres de pièces d'une cible (ruleset 0.55, 207.5.6, 207.5.11 ; 202.4.1, 205.1.2 à 205.1.4,
## 207.3.14, 207.4.11b ; décision 0062) : un test par axe du PieceFilter, lu par
## ModifierRules.matches_filter. Cases et Spells ciblés : test_207_5_6_cell_and_spell_filters.gd.

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const SOLDIER: StringName = TriggerSamples.SOLDIER
const BEACON: StringName = TriggerSamples.BEACON

var _builder: DuelStateBuilder


func before_test() -> void:
	_builder = HandEffectSamples.builder(FilterSamples.catalog())


func test_207_5_6_side_filter_reads_ally_and_enemy_from_the_owner_of_the_effect() -> void:
	var ally_id := _unit(A, "B2")
	var enemy_id := _unit(B, "D4")
	var state := _builder.build()
	assert_bool(_legal(state, {"side": "ally"}, ally_id)).is_true()
	assert_bool(_legal(state, {"side": "ally"}, enemy_id)).is_false()
	assert_bool(_legal(state, {"side": "enemy"}, ally_id)).is_false()
	assert_bool(_legal(state, {"side": "enemy"}, enemy_id)).is_true()
	assert_bool(_legal(state, {}, ally_id)).is_true()
	assert_bool(_legal(state, {}, enemy_id)).is_true()
	assert_bool(_legal(state, {"side": "ally"}, enemy_id, B)).is_true()


func test_207_5_6_type_filter_admits_only_the_named_kinds() -> void:
	var unit_id := _unit(A, "B2")
	var building_id := _building(A, "D2")
	var state := _builder.build()
	var hero_id := state.find_hero(A).piece_id
	assert_bool(_legal(state, {"piece_kinds": ["unit"]}, unit_id)).is_true()
	assert_bool(_legal(state, {"piece_kinds": ["unit"]}, building_id)).is_false()
	assert_bool(_legal(state, {"piece_kinds": ["unit"]}, hero_id)).is_false()
	assert_bool(_legal(state, {"piece_kinds": ["building"]}, building_id)).is_true()
	assert_bool(_legal(state, {"piece_kinds": ["unit", "hero"]}, hero_id)).is_true()


func test_207_5_6_relation_adjacent_reads_the_case_of_the_source_piece() -> void:
	var next_id := _unit(B, "C3")
	var far_id := _unit(B, "B3")
	var diagonal_id := _unit(B, "C4")
	var state := _builder.build()
	var filter := {"relation": "adjacent"}
	var source_cell := DuelStateBuilder.cell("D3")
	assert_bool(_legal_near(state, filter, source_cell, next_id)).is_true()
	assert_bool(_legal_near(state, filter, source_cell, far_id)).is_false()
	assert_bool(_legal_near(state, filter, source_cell, diagonal_id)).is_false()
	assert_bool(_legal_near(state, filter, DuelStateBuilder.cell("A1"), next_id)).is_false()


func test_207_5_6_relation_adjacent_to_the_last_cell_of_a_source_that_left() -> void:
	var next_id := _unit(B, "C3")
	var state := _builder.build()
	var spec := _spec({"relation": "adjacent"})
	var left_cell := DuelStateBuilder.cell("B3")
	assert_bool(EffectRules.is_legal_piece(state, A, spec, state.find_piece(next_id))).is_false()
	var resolved := spec.with_source(DuelState.NO_ID, left_cell)
	assert_bool(EffectRules.is_legal_piece(state, A, resolved, state.find_piece(next_id))).is_true()


func test_207_5_6_relation_same_row_reads_the_row_of_the_source_piece() -> void:
	var source_id := _unit(A, "B3")
	var same_row_id := _unit(A, "D3")
	var other_row_id := _unit(A, "D2")
	var state := _builder.build()
	var filter := {"relation": "same_row"}
	assert_bool(_legal_from(state, filter, source_id, same_row_id)).is_true()
	assert_bool(_legal_from(state, filter, source_id, other_row_id)).is_false()


func test_207_5_6_relation_self_admits_only_the_source_piece() -> void:
	var source_id := _unit(A, "B3")
	var other_id := _unit(A, "D3")
	var state := _builder.build()
	assert_bool(_legal_from(state, {"relation": "self"}, source_id, source_id)).is_true()
	assert_bool(_legal_from(state, {"relation": "self"}, source_id, other_id)).is_false()


func test_207_5_6_others_excludes_the_reference_itself() -> void:
	var source_id := _unit(A, "B3")
	var other_id := _unit(A, "D3")
	var state := _builder.build()
	var including := {"relation": "same_row"}
	var others := {"relation": "same_row", "include_reference": false}
	assert_bool(_legal_from(state, including, source_id, source_id)).is_true()
	assert_bool(_legal_from(state, others, source_id, source_id)).is_false()
	assert_bool(_legal_from(state, others, source_id, other_id)).is_true()


func test_207_4_11b_relation_adjacent_to_the_hero_of_the_owner() -> void:
	var hero_cell := DuelStateBuilder.cell("C1")
	var next_id := _unit(A, "C2")
	var far_id := _unit(A, "E2")
	var state := _builder.build()
	assert_vector(state.find_hero(A).cell).is_equal(hero_cell)
	var filter := {"relation": "adjacent", "relative_to": "own_hero"}
	assert_bool(_legal(state, filter, next_id)).is_true()
	assert_bool(_legal(state, filter, far_id)).is_false()


func test_207_4_11b_relation_adjacent_to_the_hero_is_read_for_the_owner_of_the_effect() -> void:
	var next_to_a := _unit(B, "C2")
	var state := _builder.build()
	var filter := {"relation": "adjacent", "relative_to": "own_hero"}
	assert_bool(_legal(state, filter, next_to_a, A)).is_true()
	assert_bool(_legal(state, filter, next_to_a, B)).is_false()


func test_202_4_1_non_token_filter_excludes_tokens() -> void:
	var unit_id := _unit(A, "B2")
	var token_id := _builder.place_token(A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("D2"), 1)
	var state := _builder.build()
	var non_token := {"piece_kinds": ["unit"], "tokens": "non_token"}
	assert_bool(_legal(state, non_token, unit_id)).is_true()
	assert_bool(_legal(state, non_token, token_id)).is_false()
	assert_bool(_legal(state, {"piece_kinds": ["unit"]}, token_id)).is_true()


func test_205_1_2_row_filter_own_first_row() -> void:
	var first_a := _unit(A, "B1")
	var second_a := _unit(A, "B2")
	var first_b := _unit(B, "B5")
	var state := _builder.build()
	var filter := {"row": "own_first"}
	assert_bool(_legal(state, filter, first_a)).is_true()
	assert_bool(_legal(state, filter, second_a)).is_false()
	assert_bool(_legal(state, filter, first_b)).is_false()
	assert_bool(_legal(state, filter, first_b, B)).is_true()


func test_205_1_3_row_filter_two_nearest_rows() -> void:
	var ids: Dictionary[String, int] = {}
	for cell_name: String in ["B1", "B2", "B3", "B4", "B5"]:
		ids[cell_name] = _unit(A, cell_name)
	var state := _builder.build()
	var filter := {"row": "own_near"}
	for near: String in ["B1", "B2"]:
		assert_bool(_legal(state, filter, ids[near])).is_true()
	for far: String in ["B3", "B4", "B5"]:
		assert_bool(_legal(state, filter, ids[far])).is_false()
	assert_bool(_legal(state, filter, ids["B5"], B)).is_true()
	assert_bool(_legal(state, filter, ids["B4"], B)).is_true()
	assert_bool(_legal(state, filter, ids["B2"], B)).is_false()


func test_205_1_4_row_filter_central_row_and_outside_it() -> void:
	var central_id := _unit(A, "B3")
	var outside_id := _unit(A, "B4")
	var state := _builder.build()
	assert_bool(_legal(state, {"row": "central"}, central_id)).is_true()
	assert_bool(_legal(state, {"row": "central"}, outside_id)).is_false()
	assert_bool(_legal(state, {"row": "not_central"}, central_id)).is_false()
	assert_bool(_legal(state, {"row": "not_central"}, outside_id)).is_true()


func test_207_5_6_filters_cross_side_type_relation_and_others() -> void:
	var source_id := _unit(A, "B3")
	var ally_id := _unit(A, "D3")
	var enemy_id := _unit(B, "E3")
	var building_id := _building(A, "C3")
	var state := _builder.build()
	var filter := {
		"side": "ally", "piece_kinds": ["unit"], "relation": "same_row", "include_reference": false
	}
	assert_bool(_legal_from(state, filter, source_id, ally_id)).is_true()
	assert_bool(_legal_from(state, filter, source_id, source_id)).is_false()
	assert_bool(_legal_from(state, filter, source_id, enemy_id)).is_false()
	assert_bool(_legal_from(state, filter, source_id, building_id)).is_false()


func test_207_5_6_force_limit_still_reads_the_current_force() -> void:
	var small_id := _unit(B, "B4")
	var state := _builder.build()
	var spec := _spec({"side": "enemy"}, {"max_force": TriggerSamples.SOLDIER_FORCE - 1})
	assert_bool(EffectRules.is_legal_piece(state, A, spec, state.find_piece(small_id))).is_false()
	var roomy := _spec({"side": "enemy"}, {"max_force": TriggerSamples.SOLDIER_FORCE})
	assert_bool(EffectRules.is_legal_piece(state, A, roomy, state.find_piece(small_id))).is_true()


func _spec(filter: Dictionary, extra: Dictionary = {}) -> TargetSpec:
	var data := {"what": "piece", "filter": filter}
	data.merge(extra, true)
	var spec := TargetSpec.from_dict(data)
	assert_array(Array(spec.parse_errors)).is_empty()
	return spec


func _legal(
	state: DuelState, filter: Dictionary, piece_id: int, side: DuelState.PlayerSide = A
) -> bool:
	var spec := _spec(filter)
	return EffectRules.is_legal_piece(state, side, spec, state.find_piece(piece_id))


# `piece_id` est légale pour A quand la pièce source est `source_id`, sur sa case.
func _legal_from(state: DuelState, filter: Dictionary, source_id: int, piece_id: int) -> bool:
	var spec := _spec(filter).with_source(source_id, state.cell_of_piece(source_id))
	return EffectRules.is_legal_piece(state, A, spec, state.find_piece(piece_id))


func _legal_near(state: DuelState, filter: Dictionary, cell: Vector2i, piece_id: int) -> bool:
	var spec := _spec(filter).with_source(DuelState.NO_ID, cell)
	return EffectRules.is_legal_piece(state, A, spec, state.find_piece(piece_id))


func _unit(side: DuelState.PlayerSide, cell_name: String) -> int:
	return _builder.place_piece(
		side, Piece.PieceKind.UNIT, DuelStateBuilder.cell(cell_name), SOLDIER
	)


func _building(side: DuelState.PlayerSide, cell_name: String) -> int:
	return _builder.place_piece(
		side, Piece.PieceKind.BUILDING, DuelStateBuilder.cell(cell_name), BEACON
	)
