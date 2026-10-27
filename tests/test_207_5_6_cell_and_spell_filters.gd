extends GdUnitTestSuite
## Filtres de cases et de Spells d'une cible (ruleset 0.55, 207.5.6, 207.5.10, 207.5.14 ; 202.4.12,
## 205.1.2 à 205.1.4, 207.1.2, 207.3.14, 213.1.6, 213.1.7 ; décision 0062). Q-098 reste ouverte :
## « distinctes » n'est lu que lorsque la carte l'écrit, sur les cibles d'un même genre.

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const REASON := IntentRejected.RejectReason
const EXECUTION_X: int = 5
const SMALL_X: int = 2
const MAX_COST: int = 3

var _builder: DuelStateBuilder


func before_test() -> void:
	_builder = ValueSamples.builder(ValueSamples.catalog())


func test_205_1_3_cell_row_two_nearest_rows_of_the_owner() -> void:
	var state := _builder.build()
	var spec := _cell_spec({"row": "own_near"})
	assert_bool(_cell_legal(state, spec, "B1")).is_true()
	assert_bool(_cell_legal(state, spec, "B2")).is_true()
	assert_bool(_cell_legal(state, spec, "B3")).is_false()
	assert_bool(_cell_legal(state, spec, "B4")).is_false()
	assert_bool(_cell_legal(state, spec, "B4", B)).is_true()
	assert_bool(_cell_legal(state, spec, "B2", B)).is_false()


func test_205_1_4_cell_row_central_and_outside_it() -> void:
	var state := _builder.build()
	assert_bool(_cell_legal(state, _cell_spec({"row": "central"}), "B3")).is_true()
	assert_bool(_cell_legal(state, _cell_spec({"row": "central"}), "B2")).is_false()
	assert_bool(_cell_legal(state, _cell_spec({"row": "not_central"}), "B3")).is_false()
	assert_bool(_cell_legal(state, _cell_spec({"row": "not_central"}), "B2")).is_true()


func test_205_1_2_cell_row_own_first_row_is_kept() -> void:
	var state := _builder.build()
	var spec := _cell_spec({"row": "own_first"})
	assert_bool(_cell_legal(state, spec, "B1")).is_true()
	assert_bool(_cell_legal(state, spec, "B2")).is_false()


func test_207_3_14_cell_adjacent_to_the_source_outside_the_central_row() -> void:
	var state := _builder.build()
	var spec := _cell_spec({"adjacent_to": "source_piece", "row": "not_central"})
	var worksite := spec.with_source(DuelState.NO_ID, DuelStateBuilder.cell("B3"))
	(
		assert_bool(EffectRules.is_legal_cell(state, A, worksite, DuelStateBuilder.cell("B2")))
		. is_true()
	)
	(
		assert_bool(EffectRules.is_legal_cell(state, A, worksite, DuelStateBuilder.cell("B4")))
		. is_true()
	)
	(
		assert_bool(EffectRules.is_legal_cell(state, A, worksite, DuelStateBuilder.cell("A3")))
		. is_false()
	)
	(
		assert_bool(EffectRules.is_legal_cell(state, A, worksite, DuelStateBuilder.cell("D4")))
		. is_false()
	)


func test_205_2_5_cell_adjacent_to_the_hero_of_the_owner_is_accepted() -> void:
	var state := _builder.build()
	var spec := _cell_spec({"adjacent_to": "own_hero"})
	assert_bool(_cell_legal(state, spec, "B1")).is_true()
	assert_bool(_cell_legal(state, spec, "D1")).is_true()
	assert_bool(_cell_legal(state, spec, "C2")).is_true()
	(
		assert_array(TriggerTargets.legal_cells(state, A, spec))
		. contains_exactly_in_any_order(
			[
				DuelStateBuilder.cell("B1"),
				DuelStateBuilder.cell("D1"),
				DuelStateBuilder.cell("C2"),
			]
		)
	)


func test_205_2_5_cell_not_adjacent_to_the_hero_or_occupied_is_refused() -> void:
	_unit(A, "B1")
	var state := _builder.build()
	var spec := _cell_spec({"adjacent_to": "own_hero"})
	assert_bool(_cell_legal(state, spec, "C1")).is_false()
	assert_bool(_cell_legal(state, spec, "B2")).is_false()
	assert_bool(_cell_legal(state, spec, "C3")).is_false()
	assert_bool(_cell_legal(state, spec, "B1")).is_false()
	var entry := _cells_entry(["B2"])
	var snapshot := state.clone()
	assert_int(EffectRules.validate_targets(state, entry, spec)).is_equal(REASON.ILLEGAL_TARGET)
	assert_array(DeepCompare.find_clone_defects(snapshot, state)).is_empty()


func test_205_2_5_cell_adjacent_to_the_hero_is_read_for_the_owner_of_the_effect() -> void:
	var state := _builder.build()
	var spec := _cell_spec({"adjacent_to": "own_hero"})
	assert_bool(_cell_legal(state, spec, "B1", B)).is_false()
	assert_bool(_cell_legal(state, spec, "B5", B)).is_true()


func test_207_5_6_cell_adjacent_to_the_hero_is_judged_again_after_the_hero_moves() -> void:
	var state := _builder.build()
	var spec := _cell_spec({"adjacent_to": "own_hero"})
	var entry := _cells_entry(["B1"])
	assert_int(EffectRules.validate_targets(state, entry, spec)).is_equal(REASON.NONE)
	state.find_hero(A).cell = DuelStateBuilder.cell("C2")
	assert_int(EffectRules.validate_targets(state, entry, spec)).is_equal(REASON.ILLEGAL_TARGET)
	assert_bool(_cell_legal(state, spec, "C3")).is_true()


func test_207_5_6_distinct_cells_refuse_the_same_cell_twice() -> void:
	var state := _builder.build()
	var spec := _cell_spec({"row": "own_near", "distinct": true, "count_min": 2, "count_max": 2})
	var apart := _cells_entry(["B1", "D2"])
	var twice := _cells_entry(["B1", "B1"])
	assert_int(EffectRules.validate_targets(state, apart, spec)).is_equal(REASON.NONE)
	assert_int(EffectRules.validate_targets(state, twice, spec)).is_equal(REASON.ILLEGAL_TARGET)


func test_207_5_6_distinct_cells_still_obey_the_rows() -> void:
	var state := _builder.build()
	var spec := _cell_spec({"row": "own_near", "distinct": true, "count_min": 2, "count_max": 2})
	var outside := _cells_entry(["B1", "D4"])
	assert_int(EffectRules.validate_targets(state, outside, spec)).is_equal(REASON.ILLEGAL_TARGET)


func test_207_5_6_distinct_pieces_refuse_the_same_piece_twice() -> void:
	var first_id := _unit(A, "B2")
	var second_id := _unit(A, "D2")
	var state := _builder.build()
	var spec := TargetSpec.from_dict(
		{
			"what": "piece",
			"filter": {"piece_kinds": ["unit"]},
			"distinct": true,
			"count_min": 2,
			"count_max": 2
		}
	)
	var entry := StackEntry.new()
	entry.owner = A
	entry.target_piece_ids.assign([first_id, second_id])
	assert_int(EffectRules.validate_targets(state, entry, spec)).is_equal(REASON.NONE)
	entry.target_piece_ids.assign([first_id, first_id])
	assert_int(EffectRules.validate_targets(state, entry, spec)).is_equal(REASON.ILLEGAL_TARGET)


func test_207_5_6_spell_cost_filter_reads_the_current_cost_with_x() -> void:
	var big_id := _push(ValueSamples.EXECUTION, EXECUTION_X)
	var small_id := _push(ValueSamples.EXECUTION, SMALL_X)
	var fixed_id := _push(ValueSamples.FURY, 0)
	var state := _builder.build()
	var spec := _spell_spec({"spell_max_cost": MAX_COST})
	assert_bool(_spell_legal(state, spec, big_id)).is_false()
	assert_bool(_spell_legal(state, spec, small_id)).is_true()
	assert_bool(_spell_legal(state, spec, fixed_id)).is_true()
	assert_bool(_spell_legal(state, _spell_spec({"spell_max_cost": 2}), fixed_id)).is_false()


func test_207_1_2_spell_speed_filter_admits_only_the_named_speeds() -> void:
	var action_id := _push(ValueSamples.WATCH, 0)
	var reaction_id := _push(ValueSamples.SAP, 0)
	var state := _builder.build()
	var reactions := _spell_spec({"spell_speeds": ["reaction"]})
	assert_bool(_spell_legal(state, reactions, action_id)).is_false()
	assert_bool(_spell_legal(state, reactions, reaction_id)).is_true()
	var both := _spell_spec({"spell_speeds": ["action", "reaction"]})
	assert_bool(_spell_legal(state, both, action_id)).is_true()
	assert_bool(_spell_legal(state, both, reaction_id)).is_true()


func test_207_5_6_spell_filters_cross_cost_and_speed() -> void:
	var cheap_reaction := _push(ValueSamples.SAP, 0)
	var dear_action := _push(ValueSamples.FURY, 0)
	var state := _builder.build()
	var spec := _spell_spec({"spell_max_cost": 2, "spell_speeds": ["reaction"]})
	assert_bool(_spell_legal(state, spec, cheap_reaction)).is_true()
	assert_bool(_spell_legal(state, spec, dear_action)).is_false()
	var ids := TriggerTargets.legal_target_ids(state, B, spec, DuelState.NO_ID)
	assert_array(ids).contains_exactly([cheap_reaction])


func _cell_spec(extra: Dictionary) -> TargetSpec:
	var data := {"what": "cell"}
	data.merge(extra, true)
	var spec := TargetSpec.from_dict(data)
	assert_array(Array(spec.parse_errors)).is_empty()
	return spec


func _spell_spec(extra: Dictionary) -> TargetSpec:
	var data := {"what": "spell_on_stack"}
	data.merge(extra, true)
	var spec := TargetSpec.from_dict(data)
	assert_array(Array(spec.find_errors())).is_empty()
	return spec


func _cell_legal(
	state: DuelState, spec: TargetSpec, cell_name: String, side: DuelState.PlayerSide = A
) -> bool:
	return EffectRules.is_legal_cell(state, side, spec, DuelStateBuilder.cell(cell_name))


func _spell_legal(state: DuelState, spec: TargetSpec, entry_id: int) -> bool:
	return EffectRules.is_legal_spell(
		state, spec, state.find_stack_entry(entry_id), DuelState.NO_ID
	)


func _cells_entry(cell_names: Array[String]) -> StackEntry:
	var entry := StackEntry.new()
	entry.owner = A
	for cell_name: String in cell_names:
		entry.target_cells.append(DuelStateBuilder.cell(cell_name))
	return entry


func _push(definition_id: StringName, x_value: int) -> int:
	var card := _builder.make_card_instance(A, definition_id)
	return _builder.push_spell(card, [] as Array[int], x_value)


func _unit(side: DuelState.PlayerSide, cell_name: String) -> int:
	return _builder.place_piece(
		side, Piece.PieceKind.UNIT, DuelStateBuilder.cell(cell_name), ValueSamples.SOLDIER
	)
