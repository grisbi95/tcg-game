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


func test_decision_0053_board_coordinate_label_uses_the_muted_color() -> void:
	_assert_color(&"BoardCoordinateLabel", FONT_COLOR, DuelPalette.MUTED_COLOR)


func test_decision_0027_turn_number_label_uses_the_muted_color() -> void:
	_assert_color(&"TurnNumberLabel", FONT_COLOR, DuelPalette.MUTED_COLOR)


func test_decision_0053_big_button_labels_use_the_ink_color() -> void:
	_assert_color(&"BigButtonLabel", FONT_COLOR, DuelPalette.INK_COLOR)
	_assert_color(&"BigButtonHelpLabel", FONT_COLOR, DuelPalette.INK_COLOR)


func test_decision_0053_stack_caption_uses_the_muted_color() -> void:
	_assert_color(&"StackCaptionLabel", FONT_COLOR, DuelPalette.MUTED_COLOR)


func test_decision_0053_column_rule_uses_the_cell_line_color() -> void:
	_assert_style_fill(&"ColumnRule", &"separator", DuelPalette.CELL_LINE_COLOR)


func test_decision_0053_stack_area_uses_the_hint_color() -> void:
	_assert_style_fill(&"StackArea", &"panel", DuelPalette.HINT_COLOR)


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


func test_decision_0053_timer_bar_fills_use_the_player_colors_then_the_alert_color() -> void:
	_assert_style_fill(&"TimerBarA", &"fill", DuelPalette.PLAYER_A_COLOR)
	_assert_style_fill(&"TimerBarB", &"fill", DuelPalette.PLAYER_B_COLOR)
	_assert_style_fill(&"TimerBarAlert", &"fill", DuelPalette.ALERT_COLOR)


func test_decision_0053_timer_bar_tracks_use_the_bar_track_color() -> void:
	for variation: StringName in [&"TimerBarA", &"TimerBarB", &"TimerBarAlert"]:
		_assert_style_fill(variation, &"background", DuelPalette.BAR_TRACK_COLOR)


func test_decision_0053_timer_seconds_turn_orange_under_the_alert() -> void:
	_assert_color(&"TimerSecondsAlertLabel", FONT_COLOR, DuelPalette.ALERT_COLOR)
	_assert_color(&"TimerSecondsLabel", FONT_COLOR, DuelPalette.INK_COLOR)
	_assert_color(&"TimerPausedLabel", FONT_COLOR, DuelPalette.MUTED_COLOR)


func test_decision_0027_column_panel_uses_the_panel_color_and_cell_line() -> void:
	_assert_style_fill(&"ColumnPanel", &"panel", DuelPalette.PANEL_COLOR)
	_assert_style_border(&"ColumnPanel", &"panel", DuelPalette.CELL_LINE_COLOR)


func test_decision_0053_info_bubble_uses_the_card_colors() -> void:
	_assert_style_fill(&"InfoBubblePanel", &"panel", DuelPalette.BUBBLE_BACKGROUND)
	_assert_style_border(&"InfoBubblePanel", &"panel", DuelPalette.BUBBLE_BORDER_COLOR)
	var panel := _flat_style(&"InfoBubblePanel", &"panel")
	assert_bool(panel.shadow_color.is_equal_approx(DuelPalette.BUBBLE_SHADOW_COLOR)).is_true()
	_assert_color(&"InfoBubbleTitleLabel", FONT_COLOR, DuelPalette.CARD_TEXT_COLOR)
	_assert_color(&"InfoBubbleTextLabel", FONT_COLOR, DuelPalette.CARD_TEXT_COLOR)


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
