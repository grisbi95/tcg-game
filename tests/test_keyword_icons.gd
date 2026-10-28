extends GdUnitTestSuite
## Icônes et étiquettes des mots-clés, noms de cartes à la police condensée (décisions 0027 et
## 0071) : une icône par mot-clé sur la grille de 24, remplaçable par un SVG ; un nom trop long
## rapetisse au lieu d'être coupé.

const CARD_SCENE: PackedScene = preload("res://ui/components/card_view.tscn")
const THEME: Theme = preload("res://ui/theme/duel_theme.tres")
const IMAGE_SIDE: int = 8
const GRID_SIZE: float = 24.0
## Étiquette OpenType de l'axe de largeur (`wdth`) d'Archivo.
const WIDTH_AXIS: int = 2003072104


func before_test() -> void:
	DuelAssets.forget_textures()


func after_test() -> void:
	DuelAssets.forget_textures()


func test_decision_0027_keywords_have_their_own_icon_added_at_the_end_of_the_enum() -> void:
	var seen: Array[DuelIcons.Icon] = []
	for keyword: CardDefinition.Keyword in CardDefinition.Keyword.values():
		var icon := DuelIcons.keyword_icon(keyword)
		assert_bool(seen.has(icon)).is_false()
		seen.append(icon)
		assert_int(icon).is_greater(DuelIcons.Icon.ESSENCE)
	assert_str(DuelIcons.asset_name(DuelIcons.Icon.LAST_BREATH)).is_equal("last_breath")
	assert_str(DuelIcons.asset_name(DuelIcons.Icon.OUTPOST)).is_equal("outpost")


func test_decision_0027_keyword_icons_are_drawn_on_the_24_grid() -> void:
	for keyword: CardDefinition.Keyword in CardDefinition.Keyword.values():
		var strokes := DuelIcons.strokes_of(DuelIcons.keyword_icon(keyword))
		assert_int(strokes.size()).is_greater(0)
		for stroke: PackedVector2Array in strokes:
			assert_int(stroke.size()).is_greater(1)
			for point: Vector2 in stroke:
				assert_bool(Rect2(Vector2.ZERO, Vector2.ONE * GRID_SIZE).has_point(point)).is_true()


func test_decision_0071_keyword_icon_asset_replaces_the_drawn_icon() -> void:
	var asset := DuelIcons.asset_name(DuelIcons.Icon.ASSAULT)
	DuelAssets.use_texture(DuelAssets.ICON_DIRECTORY + asset + DuelAssets.ICON_EXTENSION, null)
	assert_object(DuelAssets.icon(asset)).is_null()
	DuelAssets.use_texture(
		DuelAssets.ICON_DIRECTORY + asset + DuelAssets.ICON_EXTENSION, _make_texture()
	)
	assert_object(DuelAssets.icon(asset)).is_not_null()


func test_decision_0027_card_text_starts_with_one_chip_per_keyword() -> void:
	var card: CardView = auto_free(CARD_SCENE.instantiate())
	add_child(card)
	var definition := _unit()
	definition.keywords[CardDefinition.Keyword.ASSAULT] = 1
	definition.keywords[CardDefinition.Keyword.ARRIVAL] = CardDefinition.NO_KEYWORD_VALUE
	card.show_card(1, definition)
	var text_label: RichTextLabel = card.get_node("%TextLabel")
	var shown := text_label.get_parsed_text()
	assert_bool(shown.contains("ASSAUT 1")).is_true()
	assert_bool(shown.contains("ARRIVÉE")).is_true()


func test_decision_0027_chip_icon_is_an_opaque_square_of_the_asked_size() -> void:
	var texture := DuelIcons.chip_texture(
		DuelIcons.Icon.ASSAULT, 24, DuelPalette.KEYWORD_BACKGROUND, DuelPalette.KEYWORD_INK
	)
	assert_vector(texture.get_size()).is_equal(Vector2(24.0, 24.0))
	var corner := texture.get_image().get_pixel(0, 0)
	assert_bool(corner.is_equal_approx(DuelPalette.KEYWORD_BACKGROUND)).is_true()


func test_decision_0027_long_card_names_shrink_instead_of_being_cut() -> void:
	var label := Label.new()
	label.theme = THEME
	label.theme_type_variation = &"CardNameLabel"
	label.text = "Une Longue Appellation De Carte"
	label.clip_text = true
	auto_free(label)
	add_child(label)
	label.size = Vector2(70.0, 20.0)
	LabelFit.fit_to_width(label, 1.0, 10)
	var fitted := label.get_theme_font_size(&"font_size")
	label.remove_theme_font_size_override(&"font_size")
	assert_int(fitted).is_less(label.get_theme_font_size(&"font_size"))
	assert_int(fitted).is_greater_equal(10)


func test_decision_0027_name_font_is_the_condensed_variable_width_of_archivo() -> void:
	var font := THEME.get_font(&"font", &"CardNameLabel") as FontVariation
	assert_object(font).is_not_null()
	assert_int(font.variation_opentype.get(WIDTH_AXIS, 100)).is_less(100)


func _unit() -> CardDefinition:
	return CardDefinition.from_dict(CatalogSamples.unit())


func _make_texture() -> Texture2D:
	var image := Image.create(IMAGE_SIDE, IMAGE_SIDE, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	return ImageTexture.create_from_image(image)
