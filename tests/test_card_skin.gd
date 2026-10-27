extends GdUnitTestSuite
## Habillage des cartes et des pièces (décisions 0027, 0051 et 0071) : cadre dessiné par défaut,
## image de `assets/cards/frames/` en remplacement (9-patch), dos, recadrage de l'illustration,
## Les images sont imposées en mémoire par `DuelAssets`,
## aucun fichier n'est déposé dans `assets/`.

const CARD_SCENE: PackedScene = preload("res://ui/components/card_view.tscn")
const PIECE_SCENE: PackedScene = preload("res://ui/components/piece_view.tscn")
const IMAGE_SIDE: int = 8
const PREVIEW_SCALE: float = 2.2
const FRAME_DIRECTORY: String = "res://assets/cards/frames/"
const FRAME_EXTENSION: String = ".png"
const UNIT: DuelPalette.Tint = DuelPalette.Tint.UNIT


func before_test() -> void:
	DuelAssets.forget_textures()


func after_test() -> void:
	DuelAssets.forget_textures()


func test_decision_0071_card_without_frame_image_is_drawn_with_ink_cut_corners_and_shadow() -> void:
	_force_missing("card_unit")
	var style := DuelFrames.card_style(UNIT, 1.0)
	assert_bool(DuelFrames.is_drawn(style)).is_true()
	var flat := style as StyleBoxFlat
	assert_bool(flat.bg_color.is_equal_approx(DuelPalette.TINT_BACKGROUNDS[UNIT])).is_true()
	assert_bool(flat.border_color.is_equal_approx(DuelPalette.INK_COLOR)).is_true()
	assert_int(flat.corner_detail).is_equal(DuelPalette.CUT_DETAIL)
	assert_int(flat.shadow_size).is_equal(DuelPalette.SHADOW_SIZE)


func test_decision_0071_card_frame_image_replaces_the_drawn_frame_with_a_nine_patch() -> void:
	_force_image("card_unit")
	var style := DuelFrames.card_style(UNIT, 1.0) as StyleBoxTexture
	assert_object(style).is_not_null()
	assert_float(style.texture_margin_left).is_equal(float(DuelAssets.CARD_FRAME_MARGIN))
	var drawn := DuelFrames.card_style(DuelPalette.Tint.SPELL, 1.0)
	assert_float(style.content_margin_left).is_greater(0.0)
	assert_bool(DuelFrames.is_drawn(drawn)).is_true()


func test_decision_0071_removed_card_frame_image_gives_back_the_drawn_frame() -> void:
	_force_image("card_unit")
	assert_bool(DuelFrames.is_drawn(DuelFrames.card_style(UNIT, 1.0))).is_false()
	DuelAssets.forget_textures()
	_force_missing("card_unit")
	assert_bool(DuelFrames.is_drawn(DuelFrames.card_style(UNIT, 1.0))).is_true()


func test_decision_0027_preview_takes_the_2x_frame_with_doubled_margins() -> void:
	_force_image("card_unit")
	_force_image("card_unit_2x")
	var style := DuelFrames.card_style(UNIT, PREVIEW_SCALE) as StyleBoxTexture
	assert_float(style.texture_margin_top).is_equal(
		float(DuelAssets.CARD_FRAME_MARGIN * DuelAssets.LARGE_FRAME_RATIO)
	)
	var hand_style := DuelFrames.card_style(UNIT, 1.0) as StyleBoxTexture
	assert_float(hand_style.texture_margin_top).is_equal(float(DuelAssets.CARD_FRAME_MARGIN))


func test_decision_0027_preview_without_2x_frame_keeps_the_1x_frame() -> void:
	_force_image("card_unit")
	_force_missing("card_unit_2x")
	var style := DuelFrames.card_style(UNIT, PREVIEW_SCALE) as StyleBoxTexture
	assert_float(style.texture_margin_top).is_equal(float(DuelAssets.CARD_FRAME_MARGIN))


func test_decision_0071_piece_frame_image_replaces_the_player_ring_frame() -> void:
	_force_missing("piece_unit")
	var drawn := DuelFrames.piece_style(UNIT, DuelPalette.PLAYER_A_COLOR) as StyleBoxFlat
	assert_object(drawn).is_not_null()
	assert_bool(drawn.bg_color.is_equal_approx(DuelPalette.PLAYER_A_COLOR)).is_true()
	_force_image("piece_unit")
	var image := DuelFrames.piece_style(UNIT, DuelPalette.PLAYER_A_COLOR) as StyleBoxTexture
	assert_object(image).is_not_null()
	assert_float(image.texture_margin_left).is_equal(float(DuelAssets.PIECE_FRAME_MARGIN))


func test_decision_0071_card_view_follows_the_frame_image_and_gives_back_the_drawing() -> void:
	_force_image("card_unit")
	var card: CardView = auto_free(CARD_SCENE.instantiate())
	add_child(card)
	card.show_card(1, _unit())
	assert_object(card.get_theme_stylebox(&"panel")).is_instanceof(StyleBoxTexture)
	DuelAssets.forget_textures()
	_force_missing("card_unit")
	card.show_card(1, _unit())
	assert_object(card.get_theme_stylebox(&"panel")).is_instanceof(StyleBoxFlat)


func test_decision_0071_piece_view_follows_the_frame_image_and_gives_back_the_drawing() -> void:
	_force_image("piece_unit")
	var piece: PieceView = auto_free(PIECE_SCENE.instantiate())
	add_child(piece)
	piece.show_card_piece(1, _unit(), DuelState.PlayerSide.A)
	var mini_card: PanelContainer = piece.get_node("%MiniCard")
	assert_object(mini_card.get_theme_stylebox(&"panel")).is_instanceof(StyleBoxTexture)
	DuelAssets.forget_textures()
	_force_missing("piece_unit")
	piece.show_card_piece(1, _unit(), DuelState.PlayerSide.A)
	assert_object(mini_card.get_theme_stylebox(&"panel")).is_instanceof(StyleBoxFlat)


func test_decision_0071_card_back_images_replace_the_drawn_backs() -> void:
	_force_missing("card_back")
	_force_missing("card_back_small")
	assert_object(DuelAssets.card_back(false)).is_null()
	assert_object(DuelAssets.card_back(true)).is_null()
	_force_image("card_back")
	assert_object(DuelAssets.card_back(false)).is_not_null()
	assert_object(DuelAssets.card_back(true)).is_null()
	_force_image("card_back_small")
	assert_object(DuelAssets.card_back(true)).is_not_null()


func test_decision_0071_tint_names_are_the_frame_file_names() -> void:
	assert_str(DuelPalette.tint_name(DuelPalette.Tint.UNIT)).is_equal("unit")
	assert_str(DuelPalette.tint_name(DuelPalette.Tint.HERO)).is_equal("hero")


func test_decision_0074_name_banner_is_ink_lined_paper_with_square_corners() -> void:
	var banner := DuelFrames.banner_style(1.0)
	assert_bool(banner.bg_color.is_equal_approx(DuelPalette.PAPER_COLOR)).is_true()
	assert_bool(banner.border_color.is_equal_approx(DuelPalette.INK_COLOR)).is_true()
	assert_int(banner.corner_radius_top_left).is_equal(0)


func test_decision_0073_hand_card_and_piece_show_the_same_square_whole_image() -> void:
	var card: CardView = auto_free(CARD_SCENE.instantiate())
	var piece: PieceView = auto_free(PIECE_SCENE.instantiate())
	add_child(card)
	add_child(piece)
	card.show_card(1, _unit())
	piece.show_card_piece(2, _unit(), DuelState.PlayerSide.A)
	var card_frame: Control = card.get_node("%ArtFrame")
	var piece_art: PanelContainer = piece.get_node("%Art")
	assert_float(card_frame.custom_minimum_size.x).is_equal(card_frame.custom_minimum_size.y)
	assert_float(piece_art.custom_minimum_size.x).is_equal(piece_art.custom_minimum_size.y)
	var card_image: TextureRect = card.get_node("%ArtImage")
	var piece_image: TextureRect = piece.get_node("%ArtImage")
	assert_int(card_image.stretch_mode).is_equal(piece_image.stretch_mode)
	assert_int(card_image.expand_mode).is_equal(piece_image.expand_mode)
	assert_int(card_image.stretch_mode).is_equal(TextureRect.STRETCH_KEEP_ASPECT_COVERED)


func test_decision_0073_preview_keeps_the_square_at_double_size() -> void:
	var card: CardView = auto_free(CARD_SCENE.instantiate())
	add_child(card)
	card.set_card_scale(2.0)
	var frame: Control = card.get_node("%ArtFrame")
	assert_vector(frame.custom_minimum_size).is_equal(Vector2.ONE * CardScaler.ART_SIDE * 2.0)


func test_decision_0074_hand_card_has_no_type_band_and_names_the_token_only() -> void:
	var card: CardView = auto_free(CARD_SCENE.instantiate())
	add_child(card)
	assert_object(card.get_node_or_null("%TypeLabel")).is_null()
	assert_object(card.get_node_or_null("%Band")).is_null()
	card.show_token(CardDefinition.CardType.UNIT, 2)
	var name_label: Label = card.get_node("%NameLabel")
	assert_str(name_label.text).is_equal(CardText.TOKEN_NAME)


func test_decision_0074_spell_speed_and_keywords_lead_the_text() -> void:
	var card: CardView = auto_free(CARD_SCENE.instantiate())
	add_child(card)
	var spell := CardDefinition.from_dict(CatalogSamples.spell())
	card.show_card(1, spell)
	var text_label: RichTextLabel = card.get_node("%TextLabel")
	assert_bool(text_label.get_parsed_text().strip_edges().begins_with("RÉACTION")).is_true()


func test_decision_0073_piece_shows_no_name_type_or_keyword() -> void:
	var piece: PieceView = auto_free(PIECE_SCENE.instantiate())
	add_child(piece)
	assert_object(piece.get_node_or_null("%NameLabel")).is_null()
	assert_object(piece.get_node_or_null("%TypeLabel")).is_null()
	assert_object(piece.get_node_or_null("%KeywordRow")).is_null()


func _unit() -> CardDefinition:
	return CardDefinition.from_dict(CatalogSamples.unit())


func _force_image(file_name: String) -> void:
	DuelAssets.use_texture(_frame_path(file_name), _make_texture())


func _force_missing(file_name: String) -> void:
	DuelAssets.use_texture(_frame_path(file_name), null)


func _frame_path(file_name: String) -> String:
	return FRAME_DIRECTORY + file_name + FRAME_EXTENSION


func _make_texture() -> Texture2D:
	var image := Image.create(IMAGE_SIDE, IMAGE_SIDE, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	return ImageTexture.create_from_image(image)
