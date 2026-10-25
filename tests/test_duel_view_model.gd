# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## DuelViewModel sans scène, visibilité : ce que voit le joueur qui a l'appareil, définitions des
## pièces (ruleset 0.36, 201.4 ; décision 0030).

const UNIT: StringName = &"vm_unit"
const UNIT_NAME: String = "Carte vm_unit"
const BUILDING: StringName = &"vm_building"
const BUILDING_NAME: String = "Carte vm_building"
const SPELL: StringName = &"sample_spell"
const SPELL_NAME: String = "Spell d'essai"
const GEAR: StringName = &"sample_gear"
const GEAR_NAME: String = "Gear d'essai"
const HERO: StringName = &"sample_hero"
const UNKNOWN_CARD_ID: int = 9999

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B

var _catalog: Catalog
var _builder: DuelStateBuilder


func before_test() -> void:
	_catalog = Catalog.new()
	SetupSamples.add_unit(_catalog, UNIT, 3)
	SetupSamples.add_building(_catalog, BUILDING, 5)
	_catalog.add_card(CardDefinition.from_dict(CatalogSamples.spell()))
	_catalog.add_card(CardDefinition.from_dict(CatalogSamples.gear()))
	_catalog.add_hero(HeroDefinition.from_dict(CatalogSamples.hero()))
	_builder = DuelStateBuilder.new(DuelConfig.new(), _catalog)


# --- Visibilité (201.4) ---


func test_201_4_2_own_hand_is_rendered_as_cards_in_hand_order() -> void:
	var first := _builder.add_to_hand(A, UNIT)
	var second := _builder.add_to_hand(A, SPELL)
	_builder.add_to_hand(B, BUILDING)
	var cards := _model(A).hand_cards()
	assert_int(cards.size()).is_equal(2)
	assert_int(cards[0].card_instance_id).is_equal(first)
	assert_str(cards[0].definition.card_name).is_equal(UNIT_NAME)
	assert_int(cards[1].card_instance_id).is_equal(second)
	assert_str(cards[1].definition.card_name).is_equal(SPELL_NAME)


func test_201_4_2_viewer_b_sees_the_hand_of_b_not_of_a() -> void:
	_builder.add_to_hand(A, UNIT)
	var own := _builder.add_to_hand(B, BUILDING)
	var cards := _model(B).hand_cards()
	assert_int(cards.size()).is_equal(1)
	assert_int(cards[0].card_instance_id).is_equal(own)


func test_201_4_2_opponent_hand_is_known_by_its_size_only() -> void:
	_builder.add_to_hand(A, UNIT)
	_builder.add_to_hand(B, UNIT)
	_builder.add_to_hand(B, SPELL)
	_builder.add_to_hand(B, BUILDING)
	assert_int(_model(A).opponent_hand_size()).is_equal(3)
	assert_int(_model(B).opponent_hand_size()).is_equal(1)


func test_201_4_2_opponent_hand_card_has_no_visible_definition() -> void:
	var hidden := _builder.add_to_hand(B, UNIT)
	assert_object(_model(A).visible_definition(hidden)).is_null()


func test_201_4_2_own_hand_card_has_a_visible_definition() -> void:
	var own := _builder.add_to_hand(A, UNIT)
	var definition := _model(A).visible_definition(own)
	assert_object(definition).is_not_null()
	assert_str(definition.card_name).is_equal(UNIT_NAME)


func test_201_4_1_deck_is_known_by_its_size_only() -> void:
	_builder.add_to_deck(A, UNIT)
	_builder.add_to_deck(A, SPELL)
	var hidden_own := _builder.add_to_deck(A, BUILDING)
	var hidden_opponent := _builder.add_to_deck(B, UNIT)
	var model := _model(A)
	assert_int(model.deck_size(A)).is_equal(3)
	assert_int(model.deck_size(B)).is_equal(1)
	assert_object(model.visible_definition(hidden_own)).is_null()
	assert_object(model.visible_definition(hidden_opponent)).is_null()


func test_201_4_1_empty_deck_has_size_zero() -> void:
	assert_int(_model(A).deck_size(B)).is_equal(0)


func test_201_4_3_discard_top_is_the_last_card_of_each_discard() -> void:
	_builder.add_to_discard(A, UNIT)
	var top_a := _builder.add_to_discard(A, SPELL)
	var top_b := _builder.add_to_discard(B, BUILDING)
	var model := _model(B)
	assert_int(model.discard_top(A).card_instance_id).is_equal(top_a)
	assert_str(model.discard_top(A).definition.card_name).is_equal(SPELL_NAME)
	assert_int(model.discard_top(B).card_instance_id).is_equal(top_b)


func test_201_4_3_empty_discard_has_no_top() -> void:
	_builder.add_to_discard(B, UNIT)
	assert_object(_model(A).discard_top(A)).is_null()


func test_201_4_3_both_discards_are_visible_to_both_players() -> void:
	var own := _builder.add_to_discard(A, UNIT)
	var opponent := _builder.add_to_discard(B, SPELL)
	for viewer: DuelState.PlayerSide in DuelState.SIDES:
		var model := _model(viewer)
		assert_str(model.visible_definition(own).card_name).is_equal(UNIT_NAME)
		assert_str(model.visible_definition(opponent).card_name).is_equal(SPELL_NAME)


func test_201_4_9_set_aside_cards_have_no_visible_definition() -> void:
	var own := _builder.add_to_set_aside(A, UNIT)
	var opponent := _builder.add_to_set_aside(B, UNIT)
	var model := _model(A)
	assert_object(model.visible_definition(own)).is_null()
	assert_object(model.visible_definition(opponent)).is_null()


func test_201_4_2_unknown_card_has_no_visible_definition() -> void:
	assert_object(_model(A).visible_definition(UNKNOWN_CARD_ID)).is_null()


func test_decision_0032_fatigue_is_read_per_player() -> void:
	_builder.with_fatigue(A, 0)
	_builder.with_fatigue(B, 2)
	var model := _model(A)
	assert_int(model.fatigue(A)).is_equal(0)
	assert_int(model.fatigue(B)).is_equal(2)


func test_decision_0030_viewer_and_opponent() -> void:
	assert_int(_model(A).get_viewer()).is_equal(A)
	assert_int(_model(A).get_opponent()).is_equal(B)
	assert_int(_model(B).get_viewer()).is_equal(B)
	assert_int(_model(B).get_opponent()).is_equal(A)


# --- Définitions de pièces ---


func test_decision_0030_piece_form_is_hero_token_or_card() -> void:
	var hero := _builder.build().find_hero(A)
	var token_id := _builder.place_token(A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B2"), 2)
	var card_id := _builder.place_piece(A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B3"), UNIT)
	var state := _builder.build()
	assert_int(DuelViewModel.piece_form_of(hero)).is_equal(DuelViewModel.PieceForm.HERO)
	assert_int(DuelViewModel.piece_form_of(state.find_piece(token_id))).is_equal(
		DuelViewModel.PieceForm.TOKEN
	)
	assert_int(DuelViewModel.piece_form_of(state.find_piece(card_id))).is_equal(
		DuelViewModel.PieceForm.CARD
	)


func test_decision_0030_piece_definition_only_for_card_pieces() -> void:
	var token_id := _builder.place_token(A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B2"), 2)
	var card_id := _builder.place_piece(
		A, Piece.PieceKind.BUILDING, DuelStateBuilder.cell("B3"), BUILDING
	)
	var state := _builder.build()
	var model := _model(A)
	assert_object(model.piece_definition(state.find_hero(A))).is_null()
	assert_object(model.piece_definition(state.find_piece(token_id))).is_null()
	assert_str(model.piece_definition(state.find_piece(card_id)).card_name).is_equal(BUILDING_NAME)


func test_202_4_1_token_card_type_follows_its_piece_kind() -> void:
	var unit_token := _builder.place_token(A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B2"), 1)
	var building_token := _builder.place_token(
		A, Piece.PieceKind.BUILDING, DuelStateBuilder.cell("B3"), 1
	)
	var state := _builder.build()
	var model := _model(A)
	assert_int(DuelViewModel.token_card_type(state.find_piece(unit_token))).is_equal(
		CardDefinition.CardType.UNIT
	)
	assert_int(DuelViewModel.token_card_type(state.find_piece(building_token))).is_equal(
		CardDefinition.CardType.BUILDING
	)


func test_202_2_10_gear_definition_of_a_piece() -> void:
	var with_gear := _builder.place_piece(
		A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B2"), UNIT
	)
	var without_gear := _builder.place_piece(
		A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B3"), UNIT
	)
	_builder.attach_gear(with_gear, GEAR)
	var state := _builder.build()
	var model := _model(A)
	assert_str(model.gear_definition(state.find_piece(with_gear)).card_name).is_equal(GEAR_NAME)
	assert_object(model.gear_definition(state.find_piece(without_gear))).is_null()


func test_202_3_4_hero_definition_comes_from_the_hero_piece() -> void:
	_builder.with_hero_definition(B, HERO)
	var definition := _model(A).hero_definition(B)
	assert_str(definition.hero_name).is_equal("Hero d'essai")


func test_205_6_pending_combat_is_labeled_combat_with_or_without_a_card() -> void:
	var state := _builder.build()
	var held := StackEntry.new()
	held.kind = StackEntry.StackEntryKind.PENDING_COMBAT
	held.stack_entry_id = state.allocate_stack_entry_id()
	var deploying := StackEntry.new()
	deploying.kind = StackEntry.StackEntryKind.PENDING_COMBAT
	deploying.stack_entry_id = state.allocate_stack_entry_id()
	deploying.card = _builder.make_card_instance(A, UNIT)
	state.stack.append(held)
	state.stack.append(deploying)
	var lines := _model(A).stack_lines()
	assert_int(lines.size()).is_equal(2)
	assert_str(lines[0].label).is_equal("Combat")
	assert_str(lines[1].label).is_equal("Combat")


func _model(viewer: DuelState.PlayerSide) -> DuelViewModel:
	return DuelViewModel.new(_builder.build(), _catalog, viewer)
