extends GdUnitTestSuite
## Dernière case d'une pièce partie du plateau (ruleset 0.54, 207.3.14, 210.3.2b ; décision 0060) :
## un effet qui parle de la case d'une pièce qui a quitté le plateau lit la dernière case qu'elle a
## occupée. La Poudrière de NamedTriggerSamples détruit une Unit ennemie de Force 4 ou moins
## adjacente à la case de ce Building.

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const SOLDIER: StringName = TriggerSamples.SOLDIER  # Force 2
const GIANT: StringName = TriggerSamples.GIANT  # Force 5
const POWDER_KEG: StringName = NamedTriggerSamples.POWDER_KEG  # Force 3

var _catalog: Catalog
var _builder: DuelStateBuilder
var _events: Array[DuelEvent] = []


func before_test() -> void:
	_catalog = NamedTriggerSamples.catalog()
	_builder = HandEffectSamples.builder(_catalog)
	_events.clear()


func test_207_3_14_last_breath_reads_the_last_cell_of_the_destroyed_piece() -> void:
	var keg_id := _place(A, Piece.PieceKind.BUILDING, POWDER_KEG, "B2")
	var giant_id := _place(B, Piece.PieceKind.UNIT, GIANT, "B3")
	var near_id := _place(B, Piece.PieceKind.UNIT, SOLDIER, "C2")
	var far_id := _place(B, Piece.PieceKind.UNIT, SOLDIER, "D4")
	var state := _builder.build()
	CombatRules.resolve_attack(state, state.find_piece(giant_id), state.find_piece(keg_id), _events)
	assert_object(state.find_piece(keg_id)).is_null()
	assert_vector(state.find_piece(giant_id).cell).is_equal(DuelStateBuilder.cell("B2"))
	_events.clear()
	TriggerRules.add_waiting_triggers(state, _events)
	assert_array(EventLog.describe(_events)).contains_exactly(
		["DecisionResolvedAutomatically:A", "DecisionResolvedAutomatically:A", "StackEntryAdded:A"]
	)
	assert_array(state.stack[0].target_piece_ids).contains_exactly([near_id])
	var engine := DuelEngine.new(_catalog)
	engine.start_from_state(state)
	assert_array(EventLog.describe(DuelChecks.pass_once(engine, B))).contains_exactly(
		["PriorityPassed:B", "PieceDestroyed:B", "StackEntryResolved:A"]
	)
	assert_object(state.find_piece(near_id)).is_null()
	assert_object(state.find_piece(far_id)).is_not_null()


func test_207_3_14_cell_of_a_piece_on_the_board_is_its_current_cell() -> void:
	var unit_id := _place(A, Piece.PieceKind.UNIT, SOLDIER, "B2")
	var state := _builder.build()
	assert_vector(state.cell_of_piece(unit_id)).is_equal(DuelStateBuilder.cell("B2"))
	state.find_piece(unit_id).cell = DuelStateBuilder.cell("C3")
	assert_vector(state.cell_of_piece(unit_id)).is_equal(DuelStateBuilder.cell("C3"))


func test_207_3_14_cell_of_a_destroyed_piece_is_the_last_one_it_occupied() -> void:
	var unit_id := _place(A, Piece.PieceKind.UNIT, SOLDIER, "B2")
	var state := _builder.build()
	CombatRules.destroy_piece(state, state.find_piece(unit_id), _events)
	assert_vector(state.cell_of_piece(unit_id)).is_equal(DuelStateBuilder.cell("B2"))


func test_207_3_14_cell_of_a_piece_returned_to_the_hand_is_the_last_one_it_occupied() -> void:
	var unit_id := _place(A, Piece.PieceKind.UNIT, SOLDIER, "D4")
	var state := _builder.build()
	ReturnRules.return_to_hand(state, state.find_piece(unit_id), _events)
	assert_vector(state.cell_of_piece(unit_id)).is_equal(DuelStateBuilder.cell("D4"))


func test_207_3_14_unknown_piece_has_no_cell() -> void:
	var state := _builder.build()
	assert_vector(state.cell_of_piece(DuelState.NO_ID)).is_equal(BoardGeometry.NO_CELL)


func test_207_3_14_adjacency_to_the_source_is_unresolved_without_a_cell() -> void:
	var spec := TargetSpec.from_dict(
		{
			"what": "piece",
			"filter": {"side": "enemy", "piece_kinds": ["unit"], "relation": "adjacent"}
		}
	)
	var unit_id := _place(B, Piece.PieceKind.UNIT, SOLDIER, "C2")
	var state := _builder.build()
	var unit := state.find_piece(unit_id)
	assert_bool(EffectRules.is_legal_piece(state, A, spec, unit)).is_false()
	var next_to_b2 := spec.with_source(DuelState.NO_ID, DuelStateBuilder.cell("B2"))
	assert_bool(EffectRules.is_legal_piece(state, A, next_to_b2, unit)).is_true()
	var next_to_e5 := spec.with_source(DuelState.NO_ID, DuelStateBuilder.cell("E5"))
	assert_bool(EffectRules.is_legal_piece(state, A, next_to_e5, unit)).is_false()


func test_207_3_14_source_piece_adjacency_is_only_for_triggered_effects() -> void:
	var data := CatalogSamples.destroy_effect()
	var target: Dictionary = data["target"]
	target["filter"]["relation"] = "adjacent"
	var errors := CatalogSamples.effect_errors(data)
	assert_bool(CatalogSamples.mentions(errors, "207.3.14")).is_true()
	var triggered := CatalogSamples.with_field(data, "timing", "triggered")
	triggered = CatalogSamples.with_field(triggered, "trigger", "destroyed")
	assert_array(Array(CatalogSamples.effect_errors(triggered))).is_empty()


func _place(
	side: DuelState.PlayerSide, piece_kind: Piece.PieceKind, definition_id: StringName, cell: String
) -> int:
	return NamedTriggerSamples.place(_builder, side, piece_kind, definition_id, cell)
