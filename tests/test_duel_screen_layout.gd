extends GdUnitTestSuite
## DuelScreenLayout sans scène : cotes de l'écran de duel dans le repère 1920×1080 (décision 0030
## modifiée par 0035) et ancrage d'une zone à ces cotes. Les cotes sont recopiées des décisions.
##
## Les zones d'essai sont des `Control` nus, jamais ajoutés à l'arbre : leurs ancres et décalages
## se lisent sans parent ni scène.

const VIEWPORT_WIDTH: float = 1920.0  # 0030 : repère 1920×1080
const VIEWPORT_HEIGHT: float = 1080.0
const MARGIN: float = 16.0  # 0030 : marges de 16 px
const GRID_TOP: float = 88.0  # 0035 : plateau et colonne à y 88 (94 en 0030)
const OLD_GRID_TOP: float = 94.0  # 0030, remplacé par 0035
const BOARD_GRID_LEFT: float = 595.0  # 0030 point 1 : grille du plateau à x 595
const BOARD_GRID_SIZE: float = 731.0  # 0030 point 1 : 731×731
const COLUMN_LEFT: float = 1342.0  # 0030 point 6 : colonne de duel à x 1342
const HAND_LEFT: float = 424.0  # 0030 point 2 : main du bas à x 424, y 844
const HAND_TOP: float = 844.0
const CARD_HEIGHT: float = 220.0  # 0030 point 2 : cartes de la main 158×220
const PREVIEW_LEFT: float = 120.0  # 0030 point 7 : aperçu vers x 120, y 301
const PREVIEW_TOP: float = 301.0
const PREVIEW_WIDTH: float = 348.0  # 0030 point 7 : 348×484 pour une carte seule
const PREVIEW_HEIGHT: float = 484.0

const ARBITRARY_POSITION := Vector2(40.0, 60.0)  # point quelconque, hors cotes

const GROW_BEGIN: Control.GrowDirection = Control.GROW_DIRECTION_BEGIN
const GROW_END: Control.GrowDirection = Control.GROW_DIRECTION_END

# --- Cotes ---


func test_decision_0030_viewport_is_1920_by_1080_with_16_px_margins() -> void:
	assert_vector(DuelScreenLayout.VIEWPORT_SIZE).is_equal(Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT))
	assert_float(DuelScreenLayout.MARGIN).is_equal(MARGIN)


func test_decision_0030_corners_are_one_margin_from_each_edge() -> void:
	assert_vector(DuelScreenLayout.TOP_LEFT_CORNER).is_equal(Vector2(MARGIN, MARGIN))
	assert_vector(DuelScreenLayout.TOP_RIGHT_CORNER).is_equal(
		Vector2(VIEWPORT_WIDTH - MARGIN, MARGIN)
	)
	assert_vector(DuelScreenLayout.BOTTOM_LEFT_CORNER).is_equal(
		Vector2(MARGIN, VIEWPORT_HEIGHT - MARGIN)
	)
	assert_vector(DuelScreenLayout.BOTTOM_RIGHT_CORNER).is_equal(
		Vector2(VIEWPORT_WIDTH - MARGIN, VIEWPORT_HEIGHT - MARGIN)
	)


func test_decision_0035_grid_top_is_88_not_94() -> void:
	assert_float(DuelScreenLayout.GRID_TOP).is_equal(GRID_TOP)
	assert_float(DuelScreenLayout.GRID_TOP).is_not_equal(OLD_GRID_TOP)


func test_decision_0035_board_grid_starts_at_x_595_y_88() -> void:
	var grid_corner := DuelScreenLayout.BOARD_POSITION + BoardView.GRID_OFFSET
	assert_vector(grid_corner).is_equal(Vector2(BOARD_GRID_LEFT, GRID_TOP))


func test_decision_0030_board_overhangs_its_grid_by_the_coordinate_margin() -> void:
	var overhang := Vector2(BOARD_GRID_LEFT, GRID_TOP) - DuelScreenLayout.BOARD_POSITION
	assert_vector(overhang).is_equal(BoardView.GRID_OFFSET)
	assert_float(overhang.x).is_greater(0.0)
	assert_float(overhang.y).is_equal(0.0)


func test_decision_0035_duel_column_is_at_x_1342_y_88() -> void:
	assert_vector(DuelScreenLayout.COLUMN_POSITION).is_equal(Vector2(COLUMN_LEFT, GRID_TOP))


func test_decision_0035_duel_column_is_aligned_on_the_board_grid() -> void:
	var grid_corner := DuelScreenLayout.BOARD_POSITION + BoardView.GRID_OFFSET
	assert_float(DuelScreenLayout.COLUMN_POSITION.y).is_equal(grid_corner.y)


func test_decision_0030_duel_column_is_one_margin_right_of_the_board() -> void:
	var board_right := BOARD_GRID_LEFT + BOARD_GRID_SIZE
	assert_float(DuelScreenLayout.COLUMN_POSITION.x - board_right).is_equal(MARGIN)


func test_decision_0030_bottom_hand_sits_at_x_424_with_its_bottom_edge_at_y_1064() -> void:
	assert_vector(DuelScreenLayout.HAND_BOTTOM_LEFT).is_equal(
		Vector2(HAND_LEFT, HAND_TOP + CARD_HEIGHT)
	)
	assert_float(DuelScreenLayout.HAND_BOTTOM_LEFT.y).is_equal(VIEWPORT_HEIGHT - MARGIN)


func test_decision_0030_opponent_hand_is_centered_at_the_top() -> void:
	assert_vector(DuelScreenLayout.OPPONENT_HAND_POSITION).is_equal(
		Vector2(VIEWPORT_WIDTH / 2.0, MARGIN)
	)


func test_decision_0030_preview_is_centered_on_its_348_by_484_card() -> void:
	var expected := Vector2(PREVIEW_LEFT + PREVIEW_WIDTH / 2.0, PREVIEW_TOP + PREVIEW_HEIGHT / 2.0)
	assert_vector(DuelScreenLayout.PREVIEW_CENTER).is_equal(expected)


# --- Ancrage (pin) ---


func test_decision_0030_pin_top_left_corner_glues_the_zone_to_its_corner() -> void:
	var zone := _pinned(Control.PRESET_TOP_LEFT, DuelScreenLayout.TOP_LEFT_CORNER)
	_assert_offsets(zone, Vector2(MARGIN, MARGIN))
	_assert_grow(zone, GROW_END, GROW_END)


func test_decision_0030_pin_bottom_left_corner_grows_upward() -> void:
	var zone := _pinned(Control.PRESET_BOTTOM_LEFT, DuelScreenLayout.BOTTOM_LEFT_CORNER)
	_assert_offsets(zone, Vector2(MARGIN, -MARGIN))
	_assert_grow(zone, GROW_END, GROW_BEGIN)


func test_decision_0030_pin_top_right_corner_grows_leftward() -> void:
	var zone := _pinned(Control.PRESET_TOP_RIGHT, DuelScreenLayout.TOP_RIGHT_CORNER)
	_assert_offsets(zone, Vector2(-MARGIN, MARGIN))
	_assert_grow(zone, GROW_BEGIN, GROW_END)


func test_decision_0030_pin_bottom_right_corner_grows_toward_the_screen() -> void:
	var zone := _pinned(Control.PRESET_BOTTOM_RIGHT, DuelScreenLayout.BOTTOM_RIGHT_CORNER)
	_assert_offsets(zone, Vector2(-MARGIN, -MARGIN))
	_assert_grow(zone, GROW_BEGIN, GROW_BEGIN)


func test_decision_0035_pin_board_below_the_top_edge_at_the_grid_top() -> void:
	var zone := _pinned(Control.PRESET_CENTER_TOP, DuelScreenLayout.BOARD_POSITION)
	var board_left := BOARD_GRID_LEFT - BoardView.GRID_OFFSET.x
	_assert_offsets(zone, Vector2(board_left - VIEWPORT_WIDTH / 2.0, GRID_TOP))
	_assert_grow(zone, GROW_END, GROW_END)


func test_decision_0035_pin_column_at_the_grid_top() -> void:
	var zone := _pinned(Control.PRESET_CENTER_TOP, DuelScreenLayout.COLUMN_POSITION)
	_assert_offsets(zone, Vector2(COLUMN_LEFT - VIEWPORT_WIDTH / 2.0, GRID_TOP))


func test_decision_0030_pin_bottom_hand_keeps_its_bottom_edge_on_the_margin() -> void:
	var zone := _pinned(Control.PRESET_CENTER_BOTTOM, DuelScreenLayout.HAND_BOTTOM_LEFT)
	_assert_offsets(zone, Vector2(HAND_LEFT - VIEWPORT_WIDTH / 2.0, -MARGIN))
	_assert_grow(zone, GROW_END, GROW_BEGIN)


func test_decision_0030_pin_preview_by_its_center() -> void:
	var zone := _pinned(Control.PRESET_CENTER, DuelScreenLayout.PREVIEW_CENTER)
	var center := DuelScreenLayout.PREVIEW_CENTER
	_assert_offsets(zone, center - DuelScreenLayout.VIEWPORT_SIZE / 2.0)


func test_decision_0030_pin_sets_the_four_offsets_to_one_point() -> void:
	var zone := _pinned(Control.PRESET_TOP_LEFT, ARBITRARY_POSITION)
	assert_float(zone.offset_left).is_equal(zone.offset_right)
	assert_float(zone.offset_top).is_equal(zone.offset_bottom)


func _pinned(preset: Control.LayoutPreset, position: Vector2) -> Control:
	var zone: Control = auto_free(Control.new())
	DuelScreenLayout.pin(zone, preset, position)
	return zone


func _assert_offsets(zone: Control, expected: Vector2) -> void:
	assert_vector(Vector2(zone.offset_left, zone.offset_top)).is_equal(expected)
	assert_vector(Vector2(zone.offset_right, zone.offset_bottom)).is_equal(expected)


func _assert_grow(
	zone: Control, horizontal: Control.GrowDirection, vertical: Control.GrowDirection
) -> void:
	assert_int(zone.grow_horizontal).is_equal(horizontal)
	assert_int(zone.grow_vertical).is_equal(vertical)
