extends GdUnitTestSuite
## Bulles d'information du survol et pièce montrée endormie, sans scène (décision 0053, fiche de
## l'écran de duel E06, E07, E27 ; ruleset 0.44, chapitres 201, 205 et 210).

const SOLDIER: StringName = &"ib_unit"
const BUILDING: StringName = &"ib_building"
const GEAR: StringName = &"sample_gear"
const ASSAULT_VALUE: int = 2
const RAMPART_VALUE: int = 3
# gdlint: ignore=max-line-length
const OUTPOST_TEXT: String = "Tu peux déployer une Unit sur une case libre adjacente à ce Building, hors de la rangée centrale."

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B

var _catalog: Catalog


func before_test() -> void:
	_catalog = Catalog.new()
	SetupSamples.add_unit(_catalog, SOLDIER, 3)
	SetupSamples.add_building(_catalog, BUILDING, 4)
	_catalog.add_card(CardDefinition.from_dict(CatalogSamples.gear()))


func test_210_2_1a_outpost_bubble_reminds_deployment_outside_the_central_row() -> void:
	var bubbles := _bubbles_with(CardDefinition.Keyword.OUTPOST, CardDefinition.NO_KEYWORD_VALUE)
	assert_str(bubbles[0].title).is_equal("Avant-poste")
	assert_str(bubbles[0].text).is_equal(OUTPOST_TEXT)


func test_210_3_1_arrival_bubble_reminds_the_trigger_on_arrival() -> void:
	var bubbles := _bubbles_with(CardDefinition.Keyword.ARRIVAL, CardDefinition.NO_KEYWORD_VALUE)
	assert_str(bubbles[0].title).is_equal("Arrivée")
	assert_str(bubbles[0].text).is_equal(
		"Son effet se déclenche quand la pièce arrive sur le plateau."
	)


func test_210_3_2_last_breath_bubble_reminds_the_trigger_on_destruction() -> void:
	var bubbles := _bubbles_with(
		CardDefinition.Keyword.LAST_BREATH, CardDefinition.NO_KEYWORD_VALUE
	)
	assert_str(bubbles[0].title).is_equal("Dernier souffle")
	assert_str(bubbles[0].text).is_equal("Son effet se déclenche quand la pièce est détruite.")


func test_210_4_1_assault_bubble_gives_the_value_of_the_card() -> void:
	var bubbles := _bubbles_with(CardDefinition.Keyword.ASSAULT, ASSAULT_VALUE)
	assert_str(bubbles[0].title).is_equal("Assaut 2")
	assert_str(bubbles[0].text).is_equal("+2 Force quand la pièce attaque.")


func test_210_4_2_rampart_bubble_gives_the_value_of_the_card() -> void:
	var bubbles := _bubbles_with(CardDefinition.Keyword.RAMPART, RAMPART_VALUE)
	assert_str(bubbles[0].title).is_equal("Rempart 3")
	assert_str(bubbles[0].text).is_equal("+3 Force quand la pièce défend.")


func test_210_1_card_without_keyword_has_no_bubble() -> void:
	var bubbles := InfoBubble.list_for(_catalog.get_card(SOLDIER), null, false)
	assert_array(bubbles).is_empty()


func test_210_1_gear_keywords_come_after_those_of_the_card() -> void:
	var unit := _catalog.get_card(SOLDIER)
	unit.keywords[CardDefinition.Keyword.ARRIVAL] = CardDefinition.NO_KEYWORD_VALUE
	var gear := _catalog.get_card(GEAR)
	gear.keywords[CardDefinition.Keyword.RAMPART] = RAMPART_VALUE
	var bubbles := InfoBubble.list_for(unit, gear, false)
	assert_array(_titles(bubbles)).contains_exactly(["Arrivée", "Rempart 3"])


func test_205_5_3_asleep_piece_gets_the_asleep_bubble_last() -> void:
	var unit := _catalog.get_card(SOLDIER)
	unit.keywords[CardDefinition.Keyword.ARRIVAL] = CardDefinition.NO_KEYWORD_VALUE
	var bubbles := InfoBubble.list_for(unit, null, true)
	assert_array(_titles(bubbles)).contains_exactly(["Arrivée", "Endormie"])
	assert_str(bubbles[1].text).is_equal(
		"Ne peut pas faire d'action normale avant son prochain réveil."
	)


func test_205_5_5_hero_or_token_has_only_the_asleep_bubble() -> void:
	var bubbles := InfoBubble.list_for(null, null, true)
	assert_array(_titles(bubbles)).contains_exactly(["Endormie"])


func test_205_5_5_awake_piece_and_hand_card_have_no_asleep_bubble() -> void:
	assert_array(InfoBubble.list_for(_catalog.get_card(SOLDIER), null, false)).is_empty()


func test_201_4_11_asleep_unit_and_hero_are_shown_asleep_for_both_camps() -> void:
	for side: DuelState.PlayerSide in DuelState.SIDES:
		for kind: Piece.PieceKind in [Piece.PieceKind.UNIT, Piece.PieceKind.HERO]:
			var piece := _piece(kind, side, false)
			assert_bool(DuelViewModel.is_shown_asleep(piece)).is_true()


func test_201_4_11_awake_unit_and_hero_are_shown_awake_for_both_camps() -> void:
	for side: DuelState.PlayerSide in DuelState.SIDES:
		for kind: Piece.PieceKind in [Piece.PieceKind.UNIT, Piece.PieceKind.HERO]:
			var piece := _piece(kind, side, true)
			assert_bool(DuelViewModel.is_shown_asleep(piece)).is_false()


func test_205_5_6_building_is_never_shown_asleep() -> void:
	for side: DuelState.PlayerSide in DuelState.SIDES:
		for awake: bool in [true, false]:
			var piece := _piece(Piece.PieceKind.BUILDING, side, awake)
			assert_bool(DuelViewModel.is_shown_asleep(piece)).is_false()


func test_decision_0053_previewer_shows_the_bubbles_with_the_preview() -> void:
	var builder := DuelStateBuilder.new(DuelConfig.new(), _catalog)
	var unit := _catalog.get_card(SOLDIER)
	unit.keywords[CardDefinition.Keyword.ASSAULT] = ASSAULT_VALUE
	var piece_id := builder.place_piece(
		A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("C3"), SOLDIER
	)
	builder.with_piece_awake(piece_id, false)
	var state := builder.build()
	var engine := DuelEngine.new(_catalog)
	engine.start_from_state(state)
	var tooltips_spy: TooltipsSpy = auto_free(TooltipsSpy.new())
	var preview_spy: PreviewSpy = auto_free(PreviewSpy.new())
	var previewer := DuelPreviewer.new()
	previewer.setup(preview_spy, engine, tooltips_spy)
	previewer.use_model(DuelViewModel.new(state, _catalog, B))
	previewer.show_piece(piece_id)
	assert_array(tooltips_spy.shown_titles).contains_exactly(["Assaut 2", "Endormie"])
	assert_bool(tooltips_spy.shown_beside_pair).is_false()
	previewer.hide_preview()
	assert_array(tooltips_spy.calls).contains_exactly(["show_bubbles", "hide_bubbles"])


func _bubbles_with(keyword: CardDefinition.Keyword, value: int) -> Array[InfoBubble]:
	var definition := _catalog.get_card(SOLDIER)
	definition.keywords[keyword] = value
	return InfoBubble.list_for(definition, null, false)


func _titles(bubbles: Array[InfoBubble]) -> Array[String]:
	var titles: Array[String] = []
	for bubble: InfoBubble in bubbles:
		titles.append(bubble.title)
	return titles


func _piece(kind: Piece.PieceKind, side: DuelState.PlayerSide, awake: bool) -> Piece:
	var piece := Piece.new()
	piece.kind = kind
	piece.owner = side
	piece.is_awake = awake
	return piece
