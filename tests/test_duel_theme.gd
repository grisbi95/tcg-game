extends GdUnitTestSuite
## Thème unique de l'écran de duel, lu sans scène : les couleurs fixes de ses variations égalent
## les constantes de `DuelPalette` (décision 0027, `ui/CLAUDE.md` « Style »).

const THEME_PATH: String = "res://ui/theme/duel_theme.tres"
const FONT_COLOR: StringName = &"font_color"
const FONT_HOVER_COLOR: StringName = &"font_hover_color"
const FONT_PRESSED_COLOR: StringName = &"font_pressed_color"

var _theme: Theme


func before_test() -> void:
	_theme = load(THEME_PATH)


func test_decision_0027_theme_loads() -> void:
	assert_object(_theme).is_not_null()


func test_decision_0027_column_muted_label_uses_the_muted_color() -> void:
	_assert_color(&"ColumnMutedLabel", FONT_COLOR, DuelPalette.MUTED_COLOR)


func test_decision_0027_turn_number_label_uses_the_muted_color() -> void:
	_assert_color(&"TurnNumberLabel", FONT_COLOR, DuelPalette.MUTED_COLOR)


func test_decision_0027_column_hint_label_uses_the_ink_color() -> void:
	_assert_color(&"ColumnHintLabel", FONT_COLOR, DuelPalette.INK_COLOR)


func test_decision_0027_countdown_label_uses_the_ink_color() -> void:
	_assert_color(&"CountdownLabel", FONT_COLOR, DuelPalette.INK_COLOR)


func test_decision_0027_concede_button_texts_use_muted_then_ink_colors() -> void:
	_assert_color(&"ConcedeButton", FONT_COLOR, DuelPalette.MUTED_COLOR)
	_assert_color(&"ConcedeButton", FONT_HOVER_COLOR, DuelPalette.INK_COLOR)
	_assert_color(&"ConcedeButton", FONT_PRESSED_COLOR, DuelPalette.INK_COLOR)


func test_decision_0027_concede_button_frame_uses_the_cell_line_color() -> void:
	_assert_style_border(&"ConcedeButton", &"normal", DuelPalette.CELL_LINE_COLOR)
	_assert_style_border(&"ConcedeButton", &"hover", DuelPalette.CELL_LINE_COLOR)
	_assert_style_border(&"ConcedeButton", &"pressed", DuelPalette.CELL_LINE_COLOR)


func test_decision_0027_concede_button_background_is_clear_then_darker_when_used() -> void:
	var normal := _flat_style(&"ConcedeButton", &"normal")
	assert_float(normal.bg_color.a).is_equal(0.0)
	_assert_style_fill(&"ConcedeButton", &"hover", DuelPalette.HINT_COLOR)
	_assert_style_fill(&"ConcedeButton", &"pressed", DuelPalette.TABLE_COLOR)


func test_decision_0027_countdown_bar_track_uses_the_bar_track_color() -> void:
	_assert_style_fill(&"CountdownBar", &"background", DuelPalette.BAR_TRACK_COLOR)


func test_decision_0027_column_panel_uses_the_panel_color_and_cell_line() -> void:
	_assert_style_fill(&"ColumnPanel", &"panel", DuelPalette.PANEL_COLOR)
	_assert_style_border(&"ColumnPanel", &"panel", DuelPalette.CELL_LINE_COLOR)


func test_decision_0027_column_hint_panel_uses_the_hint_color_and_cell_line() -> void:
	_assert_style_fill(&"ColumnHintPanel", &"panel", DuelPalette.HINT_COLOR)
	_assert_style_border(&"ColumnHintPanel", &"panel", DuelPalette.CELL_LINE_COLOR)


func _assert_color(variation: StringName, color_name: StringName, expected: Color) -> void:
	(
		assert_bool(_theme.has_color(color_name, variation))
		. override_failure_message("%s/%s absente du thème" % [variation, color_name])
		. is_true()
	)
	var actual := _theme.get_color(color_name, variation)
	(
		assert_bool(actual.is_equal_approx(expected))
		. override_failure_message(
			"%s/%s : %s au lieu de %s" % [variation, color_name, actual, expected]
		)
		. is_true()
	)


func _assert_style_fill(variation: StringName, style_name: StringName, expected: Color) -> void:
	var style := _flat_style(variation, style_name)
	if style == null:
		return
	(
		assert_bool(style.bg_color.is_equal_approx(expected))
		. override_failure_message(
			"%s/%s : fond %s au lieu de %s" % [variation, style_name, style.bg_color, expected]
		)
		. is_true()
	)


func _assert_style_border(variation: StringName, style_name: StringName, expected: Color) -> void:
	var style := _flat_style(variation, style_name)
	if style == null:
		return
	(
		assert_bool(style.border_color.is_equal_approx(expected))
		. override_failure_message(
			(
				"%s/%s : bordure %s au lieu de %s"
				% [variation, style_name, style.border_color, expected]
			)
		)
		. is_true()
	)


func _flat_style(variation: StringName, style_name: StringName) -> StyleBoxFlat:
	var found := _theme.has_stylebox(style_name, variation)
	(
		assert_bool(found)
		. override_failure_message("%s/%s absent du thème" % [variation, style_name])
		. is_true()
	)
	if not found:
		return null
	return _theme.get_stylebox(style_name, variation) as StyleBoxFlat
