extends GdUnitTestSuite
## Habillage de l'écran de duel (décision 0071) : une image de `assets/ui/` remplace le dessin du
## thème ; sans elle le dessin reste. Les images sont imposées en mémoire par `DuelAssets`, aucun
## fichier n'est déposé dans `assets/`.

const THEME_PATH: String = "res://ui/theme/duel_theme.tres"
const IMAGE_NAME: String = "column_panel"
const IMAGE_SIDE: int = 8
const IMAGE_MARGIN: int = 16
const FALLBACK_MARGIN: float = 10.0

var _theme: Theme


func before_test() -> void:
	DuelAssets.forget_textures()
	_theme = (load(THEME_PATH) as Theme).duplicate(true)


func after_test() -> void:
	DuelAssets.forget_textures()


func test_decision_0071_missing_image_keeps_the_drawn_style() -> void:
	_force_missing(IMAGE_NAME)
	var drawn := DuelPalette.panel_style(DuelPalette.INK_COLOR)
	assert_object(DuelAssets.ui_style(IMAGE_NAME, drawn, IMAGE_MARGIN)).is_same(drawn)


func test_decision_0071_present_image_replaces_the_style_with_a_nine_patch() -> void:
	_force_image(IMAGE_NAME)
	var drawn := DuelPalette.framed_style(Color.RED, Color.BLACK, 2, FALLBACK_MARGIN)
	var tint := Color.CORNFLOWER_BLUE
	var style := DuelAssets.ui_style(IMAGE_NAME, drawn, IMAGE_MARGIN, tint) as StyleBoxTexture
	assert_object(style).is_not_null()
	assert_float(style.texture_margin_left).is_equal(float(IMAGE_MARGIN))
	assert_float(style.texture_margin_bottom).is_equal(float(IMAGE_MARGIN))
	assert_float(style.content_margin_top).is_equal(FALLBACK_MARGIN)
	assert_bool(style.modulate_color.is_equal_approx(tint)).is_true()


func test_decision_0071_theme_without_images_stays_drawn() -> void:
	for file_name: String in _slot_files():
		_force_missing(file_name)
	var classes_before := _style_classes()
	DuelAssets.skin_theme(_theme)
	assert_dict(_style_classes()).is_equal(classes_before)
	assert_object(_theme.get_stylebox(&"panel", &"ColumnPanel")).is_instanceof(StyleBoxFlat)


func test_decision_0071_theme_takes_only_the_images_that_exist() -> void:
	for file_name: String in _slot_files():
		_force_missing(file_name)
	_force_image(IMAGE_NAME)
	DuelAssets.skin_theme(_theme)
	assert_object(_theme.get_stylebox(&"panel", &"ColumnPanel")).is_instanceof(StyleBoxTexture)
	assert_object(_theme.get_stylebox(&"panel", &"StackArea")).is_instanceof(StyleBoxFlat)


func test_decision_0071_removed_image_gives_back_the_drawn_style() -> void:
	_force_image(IMAGE_NAME)
	DuelAssets.skin_theme(_theme)
	DuelAssets.forget_textures()
	_force_missing(IMAGE_NAME)
	var fresh: Theme = (load(THEME_PATH) as Theme).duplicate(true)
	DuelAssets.skin_theme(fresh)
	assert_object(fresh.get_stylebox(&"panel", &"ColumnPanel")).is_instanceof(StyleBoxFlat)


func test_decision_0071_time_bar_image_is_tinted_by_the_drawn_fill() -> void:
	_force_image("time_bar_fill")
	DuelAssets.skin_theme(_theme)
	var style := _theme.get_stylebox(&"fill", &"TimerBarB") as StyleBoxTexture
	assert_object(style).is_not_null()
	assert_bool(style.modulate_color.is_equal_approx(DuelPalette.PLAYER_B_COLOR)).is_true()


func test_decision_0071_skinning_twice_keeps_the_tint_of_the_drawn_fill() -> void:
	_force_image("time_bar_fill")
	DuelAssets.skin_theme(_theme)
	DuelAssets.skin_theme(_theme)
	var style := _theme.get_stylebox(&"fill", &"TimerBarB") as StyleBoxTexture
	assert_object(style).is_not_null()
	assert_bool(style.modulate_color.is_equal_approx(DuelPalette.PLAYER_B_COLOR)).is_true()


func test_decision_0071_big_button_image_is_tinted_to_the_player_color() -> void:
	_force_image("button_big_normal")
	var style := DuelPalette.player_button_style(
		DuelState.PlayerSide.A, DuelPalette.ButtonState.NORMAL
	)
	assert_object(style).is_instanceof(StyleBoxTexture)
	var tinted := style as StyleBoxTexture
	assert_bool(tinted.modulate_color.is_equal_approx(DuelPalette.PLAYER_A_COLOR)).is_true()


func test_decision_0071_big_button_without_image_is_a_cut_flat_plate_with_ink_and_shadow() -> void:
	_force_missing("button_big_normal")
	var style := DuelPalette.player_button_style(
		DuelState.PlayerSide.B, DuelPalette.ButtonState.NORMAL
	)
	var flat := style as StyleBoxFlat
	assert_object(flat).is_not_null()
	assert_int(flat.corner_detail).is_equal(DuelPalette.CUT_DETAIL)
	assert_bool(flat.border_color.is_equal_approx(DuelPalette.INK_COLOR)).is_true()
	assert_int(flat.shadow_size).is_equal(DuelPalette.SHADOW_SIZE)
	assert_vector(flat.shadow_offset).is_equal(Vector2.ONE * DuelPalette.SHADOW_OFFSET)


func test_decision_0071_missing_table_image_shows_the_table_color() -> void:
	_force_missing_table()
	var image := TextureRect.new()
	var color_table := ColorRect.new()
	auto_free(image)
	auto_free(color_table)
	DuelAssets.show_table(image, color_table)
	assert_bool(image.visible).is_false()
	assert_bool(color_table.visible).is_true()


func test_decision_0071_present_table_image_replaces_the_table_color() -> void:
	DuelAssets.use_texture(DuelAssets.table_path(), _make_texture())
	var image := TextureRect.new()
	var color_table := ColorRect.new()
	auto_free(image)
	auto_free(color_table)
	DuelAssets.show_table(image, color_table)
	assert_bool(image.visible).is_true()
	assert_object(image.texture).is_not_null()
	assert_bool(color_table.visible).is_false()


func test_decision_0071_empty_stack_is_a_hole_without_dashes() -> void:
	var hole := DuelPalette.hole_style(0.0)
	assert_bool(hole.bg_color.is_equal_approx(DuelPalette.HOLE_COLOR)).is_true()
	assert_int(hole.border_width_left).is_greater(0)
	assert_int(hole.border_width_right).is_equal(0)


func test_decision_0071_marks_use_the_bible_yellow_and_green() -> void:
	assert_str(DuelPalette.HIGHLIGHT_COLOR.to_html(false)).is_equal("f4c542")
	assert_str(DuelPalette.SELECTED_COLOR.to_html(false)).is_equal("57c77a")


func test_decision_0071_every_flat_style_has_cut_corners_never_rounded() -> void:
	for variation: StringName in _theme.get_type_list():
		for style_name: StringName in _theme.get_stylebox_list(variation):
			var flat := _theme.get_stylebox(style_name, variation) as StyleBoxFlat
			if flat == null or flat.corner_radius_top_left == 0:
				continue
			(
				assert_int(flat.corner_detail)
				. override_failure_message("%s/%s arrondi" % [variation, style_name])
				. is_equal(DuelPalette.CUT_DETAIL)
			)


func test_decision_0071_shadows_are_flat_and_ink() -> void:
	for variation: StringName in _theme.get_type_list():
		for style_name: StringName in _theme.get_stylebox_list(variation):
			var flat := _theme.get_stylebox(style_name, variation) as StyleBoxFlat
			if flat == null or flat.shadow_size == 0:
				continue
			assert_int(flat.shadow_size).is_equal(DuelPalette.SHADOW_SIZE)
			assert_bool(flat.shadow_color.is_equal_approx(DuelPalette.INK_COLOR)).is_true()


func test_decision_0071_theme_fonts_are_the_bundled_families() -> void:
	var font := _theme.default_font as FontVariation
	assert_object(font).is_not_null()
	var base := font.base_font as FontFile
	assert_str(base.resource_path).is_equal("res://assets/fonts/archivo.ttf")
	var body := _theme.get_font(&"normal_font", &"CardBodyText") as FontVariation
	assert_str((body.base_font as FontFile).resource_path).is_equal(
		"res://assets/fonts/source_serif_4.ttf"
	)


func test_decision_0071_option_button_and_its_list_share_the_drawn_button_skin() -> void:
	for style_name: StringName in [&"normal", &"hover", &"pressed", &"disabled"]:
		assert_object(_theme.get_stylebox(style_name, &"OptionButton")).is_same(
			_theme.get_stylebox(style_name, &"Button")
		)
	assert_object(_theme.get_stylebox(&"panel", &"PopupMenu")).is_same(
		_theme.get_stylebox(&"panel", &"ColumnPanel")
	)
	assert_object(_theme.get_stylebox(&"hover", &"PopupMenu")).is_same(
		_theme.get_stylebox(&"hover", &"Button")
	)


func _force_image(image_name: String) -> void:
	DuelAssets.use_texture(_image_path(image_name), _make_texture())


func _force_missing(image_name: String) -> void:
	DuelAssets.use_texture(_image_path(image_name), null)


func _image_path(image_name: String) -> String:
	return DuelAssets.UI_DIRECTORY + image_name + DuelAssets.UI_EXTENSION


func _force_missing_table() -> void:
	DuelAssets.use_texture(DuelAssets.table_path(), null)


func _make_texture() -> Texture2D:
	var image := Image.create(IMAGE_SIDE, IMAGE_SIDE, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	return ImageTexture.create_from_image(image)


func _slot_files() -> Array[String]:
	var files: Array[String] = []
	for slot: DuelAssets.ThemeSlot in DuelAssets.theme_slots():
		files.append(slot.file_name)
	return files


# Classe de chaque cadre du thème, pour constater qu'aucun n'a changé.
func _style_classes() -> Dictionary:
	var classes := {}
	for theme_type: StringName in _theme.get_type_list():
		for style_name: StringName in _theme.get_stylebox_list(theme_type):
			var key := "%s/%s" % [theme_type, style_name]
			classes[key] = _theme.get_stylebox(style_name, theme_type).get_class()
	return classes
