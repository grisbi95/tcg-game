extends GdUnitTestSuite
## Portées statiques par filtre de pièces (ruleset 0.55, 206.5.4, 206.5.5, 207.2.2, 207.2.4,
## 207.2.8, 207.2.9a ; décision 0062) : Porte-enseigne, Ancien du bosquet, Obélisque et Bannière
## de FilterSamples, lus par ForceRules. Les portées « porteur » et « Units alliées adjacentes » :
## test_207_2_static.gd ; mots-clés accordés : test_keyword_grants.gd.

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const SOLDIER: StringName = TriggerSamples.SOLDIER
const SOLDIER_FORCE: int = TriggerSamples.SOLDIER_FORCE
const BONUS: int = 1  # « +1 Force »
const MALUS: int = -1  # « −1 Force »

var _builder: DuelStateBuilder


func before_test() -> void:
	_builder = HandEffectSamples.builder(FilterSamples.catalog())


func test_206_5_5_standard_bearer_touches_the_other_allied_units_next_to_it() -> void:
	var bearer_id := _unit(A, FilterSamples.STANDARD_BEARER, "C3")
	var next_id := _unit(A, SOLDIER, "D3")
	var far_id := _unit(A, SOLDIER, "A3")
	var enemy_id := _unit(B, SOLDIER, "C4")
	var state := _builder.build()
	assert_int(_force(state, next_id)).is_equal(SOLDIER_FORCE + BONUS)
	assert_int(_force(state, far_id)).is_equal(SOLDIER_FORCE)
	assert_int(_force(state, enemy_id)).is_equal(SOLDIER_FORCE)
	assert_int(_force(state, bearer_id)).is_equal(FilterSamples.UNIT_FORCE)


func test_206_5_5_standard_bearer_touches_units_only() -> void:
	_unit(A, FilterSamples.STANDARD_BEARER, "C3")
	var building_id := _builder.place_piece(
		A, Piece.PieceKind.BUILDING, DuelStateBuilder.cell("D3"), TriggerSamples.BEACON
	)
	var state := _builder.build()
	assert_int(_force(state, building_id)).is_equal(TriggerSamples.BEACON_FORCE)


func test_206_5_5_two_standard_bearers_next_to_each_other_touch_one_another() -> void:
	var first_id := _unit(A, FilterSamples.STANDARD_BEARER, "C3")
	var second_id := _unit(A, FilterSamples.STANDARD_BEARER, "D3")
	var state := _builder.build()
	assert_int(_force(state, first_id)).is_equal(FilterSamples.UNIT_FORCE + BONUS)
	assert_int(_force(state, second_id)).is_equal(FilterSamples.UNIT_FORCE + BONUS)


func test_206_5_5_elder_touches_the_other_allied_units_of_its_row() -> void:
	var elder_id := _unit(A, FilterSamples.ELDER, "C3")
	var left_id := _unit(A, SOLDIER, "A3")
	var right_id := _unit(A, SOLDIER, "E3")
	var other_row_id := _unit(A, SOLDIER, "C4")
	var enemy_id := _unit(B, SOLDIER, "B3")
	var state := _builder.build()
	assert_int(_force(state, left_id)).is_equal(SOLDIER_FORCE + BONUS)
	assert_int(_force(state, right_id)).is_equal(SOLDIER_FORCE + BONUS)
	assert_int(_force(state, other_row_id)).is_equal(SOLDIER_FORCE)
	assert_int(_force(state, enemy_id)).is_equal(SOLDIER_FORCE)
	assert_int(_force(state, elder_id)).is_equal(FilterSamples.UNIT_FORCE)


func test_206_5_5_elder_scope_follows_the_row_of_its_bearer() -> void:
	var elder_id := _unit(A, FilterSamples.ELDER, "C3")
	var ally_id := _unit(A, SOLDIER, "A3")
	var state := _builder.build()
	state.find_piece(elder_id).cell = DuelStateBuilder.cell("C4")
	assert_int(_force(state, ally_id)).is_equal(SOLDIER_FORCE)
	state.find_piece(ally_id).cell = DuelStateBuilder.cell("A4")
	assert_int(_force(state, ally_id)).is_equal(SOLDIER_FORCE + BONUS)


func test_206_5_5_obelisk_touches_the_enemy_units_next_to_it() -> void:
	_builder.place_piece(
		A, Piece.PieceKind.BUILDING, DuelStateBuilder.cell("C3"), FilterSamples.OBELISK
	)
	var enemy_next_id := _unit(B, SOLDIER, "D3")
	var enemy_far_id := _unit(B, SOLDIER, "E5")
	var ally_next_id := _unit(A, SOLDIER, "C2")
	var state := _builder.build()
	assert_int(_force(state, enemy_next_id)).is_equal(SOLDIER_FORCE + MALUS)
	assert_int(_force(state, enemy_far_id)).is_equal(SOLDIER_FORCE)
	assert_int(_force(state, ally_next_id)).is_equal(SOLDIER_FORCE)


func test_206_5_5_obelisk_reads_enemy_from_the_side_of_its_owner() -> void:
	_builder.place_piece(
		B, Piece.PieceKind.BUILDING, DuelStateBuilder.cell("C3"), FilterSamples.OBELISK
	)
	var ally_of_a_id := _unit(A, SOLDIER, "D3")
	var ally_of_b_id := _unit(B, SOLDIER, "C4")
	var state := _builder.build()
	assert_int(_force(state, ally_of_a_id)).is_equal(SOLDIER_FORCE + MALUS)
	assert_int(_force(state, ally_of_b_id)).is_equal(SOLDIER_FORCE)


func test_206_5_5_force_stays_at_zero_under_a_negative_scope() -> void:
	_builder.place_piece(
		A, Piece.PieceKind.BUILDING, DuelStateBuilder.cell("C3"), FilterSamples.OBELISK
	)
	var token_id := _builder.place_token(B, Piece.PieceKind.UNIT, DuelStateBuilder.cell("D3"), 1)
	var state := _builder.build()
	assert_int(_force(state, token_id)).is_equal(0)


func test_207_2_8_banner_touches_the_allied_units_next_to_the_unit_that_bears_it() -> void:
	var bearer_id := _unit(A, SOLDIER, "C3")
	_builder.attach_gear(bearer_id, FilterSamples.BANNER)
	var next_id := _unit(A, SOLDIER, "D3")
	var far_id := _unit(A, SOLDIER, "A3")
	var enemy_id := _unit(B, SOLDIER, "C4")
	var state := _builder.build()
	assert_int(_force(state, next_id)).is_equal(SOLDIER_FORCE + BONUS)
	assert_int(_force(state, far_id)).is_equal(SOLDIER_FORCE)
	assert_int(_force(state, enemy_id)).is_equal(SOLDIER_FORCE)
	assert_int(_force(state, bearer_id)).is_equal(SOLDIER_FORCE)


func test_207_2_8_banner_follows_the_cell_of_the_unit_that_bears_it() -> void:
	var bearer_id := _unit(A, SOLDIER, "C3")
	_builder.attach_gear(bearer_id, FilterSamples.BANNER)
	var ally_id := _unit(A, SOLDIER, "D3")
	var state := _builder.build()
	state.find_piece(bearer_id).cell = DuelStateBuilder.cell("A1")
	assert_int(_force(state, ally_id)).is_equal(SOLDIER_FORCE)
	state.find_piece(ally_id).cell = DuelStateBuilder.cell("A2")
	assert_int(_force(state, ally_id)).is_equal(SOLDIER_FORCE + BONUS)


func test_207_2_9a_banner_stops_when_the_gear_is_detached() -> void:
	var bearer_id := _unit(A, SOLDIER, "C3")
	_builder.attach_gear(bearer_id, FilterSamples.BANNER)
	var next_id := _unit(A, SOLDIER, "D3")
	var state := _builder.build()
	state.find_piece(bearer_id).attached_gear = null
	assert_int(_force(state, next_id)).is_equal(SOLDIER_FORCE)


func test_207_2_4_scope_stops_when_the_bearer_leaves_the_board() -> void:
	var bearer_id := _unit(A, FilterSamples.STANDARD_BEARER, "C3")
	var next_id := _unit(A, SOLDIER, "D3")
	var state := _builder.build()
	var events: Array[DuelEvent] = []
	CombatRules.destroy_piece(state, state.find_piece(bearer_id), events)
	assert_int(_force(state, next_id)).is_equal(SOLDIER_FORCE)


func _force(state: DuelState, piece_id: int) -> int:
	return ForceRules.current_force(state, state.find_piece(piece_id))


func _unit(side: DuelState.PlayerSide, definition_id: StringName, cell_name: String) -> int:
	return _builder.place_piece(
		side, Piece.PieceKind.UNIT, DuelStateBuilder.cell(cell_name), definition_id
	)
