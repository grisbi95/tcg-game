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


func test_decision_0071_turn_number_label_is_the_light_text_color_faded() -> void:
	var color := _theme.get_color(FONT_COLOR, &"TurnNumberLabel")
	assert_bool(Color(color, 1.0).is_equal_approx(DuelPalette.TEXT_COLOR)).is_true()
	assert_float(color.a).is_less(1.0)


func test_decision_0071_big_button_labels_are_white() -> void:
	_assert_color(&"BigButtonLabel", FONT_COLOR, DuelPalette.BUTTON_TEXT_COLOR)
	var help := _theme.get_color(FONT_COLOR, &"BigButtonHelpLabel")
	assert_bool(Color(help, 1.0).is_equal_approx(DuelPalette.BUTTON_TEXT_COLOR)).is_true()


func test_decision_0053_stack_caption_uses_the_muted_color() -> void:
	_assert_color(&"StackCaptionLabel", FONT_COLOR, DuelPalette.MUTED_COLOR)


func test_decision_0071_column_rule_is_a_faint_line_of_the_light_text_color() -> void:
	var rule := _flat_style(&"ColumnRule", &"separator")
	var expected := Color(DuelPalette.TEXT_COLOR, rule.bg_color.a)
	assert_bool(rule.bg_color.is_equal_approx(expected)).is_true()
	assert_float(rule.bg_color.a).is_less(0.5)


func test_decision_0071_stack_area_is_a_hole_with_an_inner_shadow() -> void:
	_assert_style_fill(&"StackArea", &"panel", DuelPalette.HOLE_COLOR)
	_assert_style_border(&"StackArea", &"panel", DuelPalette.HOLE_SHADOW_COLOR)
	assert_int(_flat_style(&"StackArea", &"panel").border_width_top).is_greater(0)


func test_decision_0027_countdown_label_uses_the_ink_color() -> void:
	_assert_color(&"CountdownLabel", FONT_COLOR, DuelPalette.TEXT_COLOR)


func test_decision_0027_concede_button_texts_use_muted_then_ink_colors() -> void:
	_assert_color(&"ConcedeButton", FONT_COLOR, DuelPalette.MUTED_COLOR)
	_assert_color(&"ConcedeButton", FONT_HOVER_COLOR, DuelPalette.TEXT_COLOR)
	_assert_color(&"ConcedeButton", FONT_PRESSED_COLOR, DuelPalette.TEXT_COLOR)


func test_decision_0071_concede_button_frame_uses_the_light_text_color() -> void:
	_assert_style_border(&"ConcedeButton", &"normal", DuelPalette.TEXT_COLOR)
	_assert_style_border(&"ConcedeButton", &"hover", DuelPalette.TEXT_COLOR)
	_assert_style_border(&"ConcedeButton", &"pressed", DuelPalette.TEXT_COLOR)


func test_decision_0071_concede_button_background_goes_from_panel_to_socket_to_hole() -> void:
	_assert_style_fill(&"ConcedeButton", &"normal", DuelPalette.PANEL_COLOR)
	_assert_style_fill(&"ConcedeButton", &"hover", DuelPalette.SOCKET_COLOR)
	_assert_style_fill(&"ConcedeButton", &"pressed", DuelPalette.HOLE_COLOR)


func test_decision_0027_countdown_bar_track_uses_the_bar_track_color() -> void:
	_assert_style_fill(&"CountdownBar", &"background", DuelPalette.BAR_TRACK_COLOR)


func test_decision_0053_timer_bar_fills_use_the_player_colors_then_the_alert_color() -> void:
	_assert_style_fill(&"TimerBarA", &"fill", DuelPalette.PLAYER_A_COLOR)
	_assert_style_fill(&"TimerBarB", &"fill", DuelPalette.PLAYER_B_COLOR)
	_assert_style_fill(&"TimerBarAlert", &"fill", DuelPalette.ALERT_COLOR)


func test_decision_0053_timer_bar_tracks_use_the_bar_track_color() -> void:
	for variation: StringName in [&"TimerBarA", &"TimerBarB", &"TimerBarAlert"]:
		_assert_style_fill(variation, &"background", DuelPalette.BAR_TRACK_COLOR)


func test_decision_0071_column_panel_uses_the_panel_color_and_an_ink_line() -> void:
	_assert_style_fill(&"ColumnPanel", &"panel", DuelPalette.PANEL_COLOR)
	_assert_style_border(&"ColumnPanel", &"panel", DuelPalette.INK_COLOR)


func test_decision_0071_info_bubble_is_paper_with_an_ink_line_and_a_flat_shadow() -> void:
	_assert_style_fill(&"InfoBubblePanel", &"panel", DuelPalette.BUBBLE_BACKGROUND)
	_assert_style_border(&"InfoBubblePanel", &"panel", DuelPalette.BUBBLE_BORDER_COLOR)
	var panel := _flat_style(&"InfoBubblePanel", &"panel")
	assert_bool(panel.shadow_color.is_equal_approx(DuelPalette.BUBBLE_SHADOW_COLOR)).is_true()
	assert_int(panel.shadow_size).is_equal(DuelPalette.SHADOW_SIZE)
	assert_vector(panel.shadow_offset).is_equal(Vector2.ONE * DuelPalette.SHADOW_OFFSET)
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
