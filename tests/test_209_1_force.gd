extends GdUnitTestSuite
## ForceRules : Force actuelle d'une pièce (ruleset 0.31, sections 209.1 et 206.5 ; décision
## 0016).

const UNIT_ID: StringName = &"force_unit"
const BUILDING_ID: StringName = &"force_building"
const UNIT_FORCE: int = 3
const BUILDING_FORCE: int = 4

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B

var _builder: DuelStateBuilder


func before_test() -> void:
	var catalog := Catalog.new()
	SetupSamples.add_unit(catalog, UNIT_ID, UNIT_FORCE)
	SetupSamples.add_building(catalog, BUILDING_ID, BUILDING_FORCE)
	_builder = DuelStateBuilder.new(DuelConfig.new(), catalog)


func test_202_1_5_unit_has_its_printed_force() -> void:
	var piece_id := _place(Piece.PieceKind.UNIT, UNIT_ID)
	assert_int(_force_of(piece_id)).is_equal(UNIT_FORCE)


func test_202_1_6_building_has_its_printed_force() -> void:
	var piece_id := _place(Piece.PieceKind.BUILDING, BUILDING_ID)
	assert_int(_force_of(piece_id)).is_equal(BUILDING_FORCE)


func test_209_1_1a_token_force_given_by_its_effect() -> void:
	var piece_id := _builder.place_token(A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B3"), 2)
	assert_int(_force_of(piece_id)).is_equal(2)


func test_209_1_1_force_adds_modifiers_to_printed_force() -> void:
	var piece_id := _place(Piece.PieceKind.UNIT, UNIT_ID)
	_add_modifier(piece_id, 2)
	assert_int(_force_of(piece_id)).is_equal(UNIT_FORCE + 2)


func test_206_5_1_modifiers_on_same_piece_add_up() -> void:
	var piece_id := _place(Piece.PieceKind.UNIT, UNIT_ID)
	_add_modifier(piece_id, 2)
	_add_modifier(piece_id, -1)
	assert_int(_force_of(piece_id)).is_equal(UNIT_FORCE + 2 - 1)


func test_modifiers_of_other_pieces_ignored() -> void:
	var piece_id := _place(Piece.PieceKind.UNIT, UNIT_ID)
	var other_id := _builder.place_piece(
		B, Piece.PieceKind.UNIT, DuelStateBuilder.cell("D3"), UNIT_ID
	)
	_add_modifier(other_id, 5)
	assert_int(_force_of(piece_id)).is_equal(UNIT_FORCE)


func test_209_1_2_negative_sum_gives_force_zero() -> void:
	var piece_id := _place(Piece.PieceKind.UNIT, UNIT_ID)
	_add_modifier(piece_id, -UNIT_FORCE - 2)
	assert_int(_force_of(piece_id)).is_equal(0)


func test_209_1_3_piece_at_force_zero_stays_in_play() -> void:
	var piece_id := _place(Piece.PieceKind.UNIT, UNIT_ID)
	_add_modifier(piece_id, -UNIT_FORCE)
	var state := _builder.build()
	assert_int(ForceRules.current_force(state, state.find_piece(piece_id))).is_equal(0)
	assert_object(state.find_piece(piece_id)).is_not_null()


func test_202_3_9_hero_has_no_force() -> void:
	var state := _builder.build()
	assert_int(ForceRules.current_force(state, state.find_hero(A))).is_equal(0)


func _place(kind: Piece.PieceKind, definition_id: StringName) -> int:
	return _builder.place_piece(A, kind, DuelStateBuilder.cell("B3"), definition_id)


func _add_modifier(piece_id: int, amount: int) -> void:
	var effect := ActiveEffect.new()
	effect.affected_piece_id = piece_id
	effect.effect_kind = EffectDefinition.kind_id(EffectDefinition.EffectKind.MODIFY_FORCE)
	effect.amount = amount
	_builder.add_active_effect(effect)


func _force_of(piece_id: int) -> int:
	var state := _builder.build()
	return ForceRules.current_force(state, state.find_piece(piece_id))
