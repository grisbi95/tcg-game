extends GdUnitTestSuite
## BoardGeometry : plateau, notation, adjacence, rangées (ruleset 0.28, chapitres 201 et 205).

const COLUMN_COUNT: int = 5  # 201.0.2
const ROW_COUNT: int = 5  # 201.0.2
const CELL_COUNT: int = 25  # 201.0.2
const NEAR_ROW_CELL_COUNT: int = 10  # 205.1.3 : deux rangées de cinq cases

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B


func test_201_0_2_board_has_25_cells_in_5_columns_and_5_rows() -> void:
	var cells := BoardGeometry.all_cells()
	assert_int(cells.size()).is_equal(CELL_COUNT)
	assert_int(BoardGeometry.COLUMN_COUNT).is_equal(COLUMN_COUNT)
	assert_int(BoardGeometry.ROW_COUNT).is_equal(ROW_COUNT)
	assert_bool(BoardGeometry.is_on_board(Vector2i(4, 4))).is_true()
	assert_bool(BoardGeometry.is_on_board(Vector2i(5, 0))).is_false()
	assert_bool(BoardGeometry.is_on_board(Vector2i(0, -1))).is_false()


func test_201_2_2_columns_a_to_e() -> void:
	var names: Array[String] = []
	for column: int in COLUMN_COUNT:
		names.append(BoardGeometry.cell_name(Vector2i(column, 0)).left(1))
	assert_array(names).contains_exactly(["A", "B", "C", "D", "E"])


func test_201_2_3_rows_1_to_5() -> void:
	var names: Array[String] = []
	for row: int in ROW_COUNT:
		names.append(BoardGeometry.cell_name(Vector2i(0, row)).right(1))
	assert_array(names).contains_exactly(["1", "2", "3", "4", "5"])


func test_201_2_4_cell_name_is_column_letter_then_row_number() -> void:
	assert_str(BoardGeometry.cell_name(Vector2i(0, 0))).is_equal("A1")
	assert_str(BoardGeometry.cell_name(Vector2i(2, 4))).is_equal("C5")
	assert_str(BoardGeometry.cell_name(Vector2i(4, 4))).is_equal("E5")


func test_201_2_4_parse_cell_inverts_cell_name_on_all_cells() -> void:
	for cell: Vector2i in BoardGeometry.all_cells():
		assert_vector(BoardGeometry.parse_cell(BoardGeometry.cell_name(cell))).is_equal(cell)


func test_201_2_4_parse_cell_rejects_notation_outside_board() -> void:
	for notation: String in ["", "A", "F1", "A0", "A6", "a1", "A11", "1A"]:
		assert_vector(BoardGeometry.parse_cell(notation)).is_equal(BoardGeometry.NO_CELL)


func test_201_2_5_first_row_is_row_1_for_one_player_and_row_5_for_the_other() -> void:
	assert_int(BoardGeometry.first_row_index(A)).is_equal(0)
	assert_int(BoardGeometry.first_row_index(B)).is_equal(4)
	assert_bool(BoardGeometry.is_in_first_row(A, BoardGeometry.parse_cell("E1"))).is_true()
	assert_bool(BoardGeometry.is_in_first_row(B, BoardGeometry.parse_cell("A5"))).is_true()
	assert_bool(BoardGeometry.is_in_first_row(A, BoardGeometry.parse_cell("A5"))).is_false()


func test_201_2_5_distance_from_first_row_counts_from_each_player() -> void:
	var cell := BoardGeometry.parse_cell("B2")
	assert_int(BoardGeometry.distance_from_first_row(A, cell)).is_equal(1)
	assert_int(BoardGeometry.distance_from_first_row(B, cell)).is_equal(3)


func test_204_1_1_hero_starts_on_center_cell_of_first_row() -> void:
	assert_str(BoardGeometry.cell_name(BoardGeometry.hero_start_cell(A))).is_equal("C1")
	assert_str(BoardGeometry.cell_name(BoardGeometry.hero_start_cell(B))).is_equal("C5")


func test_205_1_2_first_row_cells_are_the_five_cells_of_the_first_row() -> void:
	var names := _names(BoardGeometry.first_row_cells(A))
	assert_array(names).contains_exactly_in_any_order(["A1", "B1", "C1", "D1", "E1"])
	names = _names(BoardGeometry.first_row_cells(B))
	assert_array(names).contains_exactly_in_any_order(["A5", "B5", "C5", "D5", "E5"])


func test_205_1_3_near_rows_are_the_two_rows_closest_to_the_player() -> void:
	var cells := BoardGeometry.near_rows_cells(A)
	assert_int(cells.size()).is_equal(NEAR_ROW_CELL_COUNT)
	assert_array(_names(cells)).contains(["A1", "E1", "A2", "E2"])
	assert_array(_names(cells)).not_contains(["A3", "A4", "A5"])
	assert_array(_names(BoardGeometry.near_rows_cells(B))).contains(["A5", "E5", "A4", "E4"])
	assert_bool(BoardGeometry.is_in_near_rows(B, BoardGeometry.parse_cell("C3"))).is_false()


func test_205_1_4_central_row_is_row_3() -> void:
	assert_bool(BoardGeometry.is_in_central_row(BoardGeometry.parse_cell("A3"))).is_true()
	assert_bool(BoardGeometry.is_in_central_row(BoardGeometry.parse_cell("E3"))).is_true()
	assert_bool(BoardGeometry.is_in_central_row(BoardGeometry.parse_cell("C2"))).is_false()
	assert_bool(BoardGeometry.is_in_central_row(BoardGeometry.parse_cell("C4"))).is_false()


func test_205_1_4_central_row_is_in_no_near_row() -> void:
	for side: DuelState.PlayerSide in [A, B]:
		for cell: Vector2i in BoardGeometry.near_rows_cells(side):
			assert_bool(BoardGeometry.is_in_central_row(cell)).is_false()


func test_205_2_5_adjacent_shares_a_side() -> void:
	var center := BoardGeometry.parse_cell("C3")
	for neighbour: String in ["C2", "C4", "B3", "D3"]:
		(
			assert_bool(BoardGeometry.are_adjacent(center, BoardGeometry.parse_cell(neighbour)))
			. is_true()
		)


func test_205_2_5_diagonal_and_same_cell_are_not_adjacent() -> void:
	var center := BoardGeometry.parse_cell("C3")
	for other: String in ["B2", "D4", "B4", "D2", "C3", "C5", "A3"]:
		assert_bool(BoardGeometry.are_adjacent(center, BoardGeometry.parse_cell(other))).is_false()


func test_205_2_5_adjacent_cells_stay_on_the_board() -> void:
	(
		assert_array(_names(BoardGeometry.adjacent_cells(BoardGeometry.parse_cell("C3"))))
		. contains_exactly_in_any_order(["C2", "C4", "B3", "D3"])
	)
	(
		assert_array(_names(BoardGeometry.adjacent_cells(BoardGeometry.parse_cell("A1"))))
		. contains_exactly_in_any_order(["A2", "B1"])
	)
	(
		assert_array(_names(BoardGeometry.adjacent_cells(BoardGeometry.parse_cell("E5"))))
		. contains_exactly_in_any_order(["E4", "D5"])
	)


func _names(cells: Array[Vector2i]) -> Array[String]:
	var names: Array[String] = []
	for cell: Vector2i in cells:
		names.append(BoardGeometry.cell_name(cell))
	return names
