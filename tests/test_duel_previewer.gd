# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## DuelPreviewer sans scène : ce que l'aperçu au survol montre d'une carte, d'un Hero, d'une pièce
## ou d'une entrée de pile (décisions 0027 et 0030). `PreviewSpy` tient lieu de `HoverPreview`.

const UNIT: StringName = &"pv_unit"
const UNIT_NAME: String = "Carte pv_unit"
const BUILDING: StringName = &"pv_building"
const SPELL: StringName = &"sample_spell"
const SPELL_NAME: String = "Spell d'essai"
const GEAR: StringName = &"sample_gear"
const GEAR_NAME: String = "Gear d'essai"
const HERO_OF_A: StringName = &"sample_hero"
const HERO_OF_A_NAME: String = "Hero d'essai"
const HERO_OF_B: StringName = &"pv_second_hero"
const HERO_OF_B_NAME: String = "Hero de B"
const UNKNOWN_ID: int = 9999
const TOKEN_FORCE: int = 3  # Force donnée au jeton à sa création (202.4.9)
const FORCE_BONUS: int = 2  # 207.4.2 : effet à durée +2 Force, la Force actuelle diffère
const UNIT_FORCE: int = 3  # Force imprimée de la Unit d'essai
const BUILDING_FORCE: int = 5  # Force imprimée du Building d'essai

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B

var _catalog: Catalog
var _builder: DuelStateBuilder
var _spy: PreviewSpy
var _previewer: DuelPreviewer
var _engine: DuelEngine


func before_test() -> void:
	_catalog = Catalog.new()
	SetupSamples.add_unit(_catalog, UNIT, UNIT_FORCE)
	SetupSamples.add_building(_catalog, BUILDING, BUILDING_FORCE)
	_catalog.add_card(CardDefinition.from_dict(CatalogSamples.spell()))
	_catalog.add_card(CardDefinition.from_dict(CatalogSamples.gear()))
	_catalog.add_hero(HeroDefinition.from_dict(CatalogSamples.hero()))
	var second_hero := CatalogSamples.with_field(CatalogSamples.hero(), "id", String(HERO_OF_B))
	second_hero = CatalogSamples.with_field(second_hero, "name", HERO_OF_B_NAME)
	_catalog.add_hero(HeroDefinition.from_dict(second_hero))
	_builder = DuelStateBuilder.new(DuelConfig.new(), _catalog)
	_builder.with_hero_definition(A, HERO_OF_A).with_hero_definition(B, HERO_OF_B)
	_spy = auto_free(PreviewSpy.new())


# --- Carte survolée (main, défausse) ---


func test_decision_0030_hovered_card_of_own_hand_is_shown_alone() -> void:
	var card_id := _builder.add_to_hand(A, UNIT)
	_previewer_for(A).show_card(card_id)
	assert_array(_spy.calls).contains_exactly(["show_card"])
	assert_str(_spy.shown_card.card_name).is_equal(UNIT_NAME)
	assert_object(_spy.shown_gear).is_null()


func test_decision_0030_hovered_card_of_the_opponent_hand_stays_hidden() -> void:
	var card_id := _builder.add_to_hand(B, UNIT)
	_previewer_for(A).show_card(card_id)
	assert_array(_spy.calls).is_empty()


func test_decision_0030_hovered_card_of_a_deck_or_set_aside_stays_hidden() -> void:
	var deck_id := _builder.add_to_deck(A, UNIT)
	var set_aside_id := _builder.add_to_set_aside(A, UNIT)
	var previewer := _previewer_for(A)
	previewer.show_card(deck_id)
	previewer.show_card(set_aside_id)
	assert_array(_spy.calls).is_empty()


func test_decision_0030_hovered_discard_is_shown_whoever_owns_it() -> void:
	var own_id := _builder.add_to_discard(A, UNIT)
	var other_id := _builder.add_to_discard(B, SPELL)
	var previewer := _previewer_for(A)
	previewer.show_card(own_id)
	assert_str(_spy.shown_card.card_name).is_equal(UNIT_NAME)
	previewer.show_card(other_id)
	assert_str(_spy.shown_card.card_name).is_equal(SPELL_NAME)
	assert_array(_spy.calls).contains_exactly(["show_card", "show_card"])


func test_decision_0030_hovered_card_follows_the_device_holder() -> void:
	var card_id := _builder.add_to_hand(B, UNIT)
	_previewer_for(B).show_card(card_id)
	assert_array(_spy.calls).contains_exactly(["show_card"])


func test_decision_0030_unknown_card_shows_nothing() -> void:
	_previewer_for(A).show_card(UNKNOWN_ID)
	assert_array(_spy.calls).is_empty()


# --- Pièces du plateau ---


func test_decision_0027_hovered_hero_piece_shows_the_hero_card_of_its_owner() -> void:
	var hero_id := _hero_piece_id(B)
	_previewer_for(A).show_piece(hero_id)
	assert_array(_spy.calls).contains_exactly(["show_hero"])
	assert_str(_spy.shown_hero.hero_name).is_equal(HERO_OF_B_NAME)


func test_decision_0027_hovered_unit_shows_its_full_card_without_gear() -> void:
	var piece_id := _builder.place_piece(B, Piece.PieceKind.UNIT, DuelStateBuilder.cell("C3"), UNIT)
	_previewer_for(A).show_piece(piece_id)
	assert_array(_spy.calls).contains_exactly(["show_card"])
	assert_str(_spy.shown_card.card_name).is_equal(UNIT_NAME)
	assert_object(_spy.shown_gear).is_null()


func test_decision_0027_hovered_unit_shows_its_gear_beside_it() -> void:
	var piece_id := _builder.place_piece(A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("C3"), UNIT)
	_builder.attach_gear(piece_id, GEAR)
	_previewer_for(A).show_piece(piece_id)
	assert_str(_spy.shown_card.card_name).is_equal(UNIT_NAME)
	assert_str(_spy.shown_gear.card_name).is_equal(GEAR_NAME)


func test_decision_0027_hovered_building_is_shown_by_its_card() -> void:
	var piece_id := _builder.place_piece(
		A, Piece.PieceKind.BUILDING, DuelStateBuilder.cell("A3"), BUILDING
	)
	_previewer_for(A).show_piece(piece_id)
	assert_array(_spy.calls).contains_exactly(["show_card"])
	assert_str(_spy.shown_card.id).is_equal(BUILDING)


func test_decision_0027_hovered_card_piece_of_the_opponent_is_visible() -> void:
	var piece_id := _builder.place_piece(B, Piece.PieceKind.UNIT, DuelStateBuilder.cell("C3"), UNIT)
	_previewer_for(B).show_piece(piece_id)
	_previewer_for(A).show_piece(piece_id)
	assert_array(_spy.calls).contains_exactly(["show_card", "show_card"])


func test_decision_0027_hovered_token_shows_its_type_and_current_force() -> void:
	var unit_token := _builder.place_token(
		A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("C3"), TOKEN_FORCE
	)
	var building_token := _builder.place_token(
		A, Piece.PieceKind.BUILDING, DuelStateBuilder.cell("C4"), TOKEN_FORCE
	)
	var previewer := _previewer_for(A)
	previewer.show_piece(unit_token)
	assert_int(_spy.shown_token_type).is_equal(CardDefinition.CardType.UNIT)
	assert_int(_spy.shown_token_force).is_equal(TOKEN_FORCE)
	previewer.show_piece(building_token)
	assert_int(_spy.shown_token_type).is_equal(CardDefinition.CardType.BUILDING)
	assert_array(_spy.calls).contains_exactly(["show_token", "show_token"])


func test_decision_0027_token_force_is_read_from_the_engine_not_recomputed() -> void:
	var token_id := _builder.place_token(
		A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("C3"), TOKEN_FORCE
	)
	var bonus := ActiveEffect.new()
	bonus.affected_piece_id = token_id
	bonus.effect_kind = EffectDefinition.kind_id(EffectDefinition.EffectKind.MODIFY_FORCE)
	bonus.amount = FORCE_BONUS
	_builder.add_active_effect(bonus)
	_previewer_for(A).show_piece(token_id)
	assert_int(_spy.shown_token_force).is_equal(TOKEN_FORCE + FORCE_BONUS)


func test_decision_0027_hovered_token_shows_its_gear() -> void:
	var token_id := _builder.place_token(
		A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("C3"), TOKEN_FORCE
	)
	_builder.attach_gear(token_id, GEAR)
	_previewer_for(A).show_piece(token_id)
	assert_str(_spy.shown_gear.card_name).is_equal(GEAR_NAME)


func test_decision_0027_unknown_piece_shows_nothing() -> void:
	_previewer_for(A).show_piece(UNKNOWN_ID)
	assert_array(_spy.calls).is_empty()


# --- Entrées de pile ---


func test_decision_0030_hovered_stack_entry_shows_the_announced_card() -> void:
	var entry_id := _builder.push_spell(_builder.make_card_instance(B, SPELL))
	_previewer_for(A).show_stack_entry(entry_id)
	assert_array(_spy.calls).contains_exactly(["show_card"])
	assert_str(_spy.shown_card.card_name).is_equal(SPELL_NAME)


func test_decision_0030_hovered_triggered_effect_shows_its_source_card() -> void:
	var entry_id := _builder.push_stack_entry(_trigger_of(A, UNIT))
	_previewer_for(A).show_stack_entry(entry_id)
	assert_str(_spy.shown_card.card_name).is_equal(UNIT_NAME)


func test_decision_0030_hovered_waiting_trigger_shows_its_source_card() -> void:
	var state := _builder.build()
	var entry := _trigger_of(A, UNIT)
	entry.stack_entry_id = state.allocate_stack_entry_id()
	state.waiting_triggers.append(entry)
	_previewer_for(A).show_stack_entry(entry.stack_entry_id)
	assert_array(_spy.calls).contains_exactly(["show_card"])


func test_decision_0030_entry_without_a_card_shows_nothing() -> void:
	var piece_id := _builder.place_piece(A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B2"), UNIT)
	var action_id := _builder.push_normal_action(piece_id, DuelStateBuilder.cell("B3"))
	var vanished_id := _builder.push_stack_entry(_trigger_of(A, &"pv_vanished_source"))
	var previewer := _previewer_for(A)
	previewer.show_stack_entry(action_id)
	previewer.show_stack_entry(vanished_id)
	previewer.show_stack_entry(UNKNOWN_ID)
	assert_array(_spy.calls).is_empty()


# --- Fin du survol ---


func test_decision_0030_hide_preview_hides_the_preview() -> void:
	var previewer := _previewer_for(A)
	previewer.hide_preview()
	assert_array(_spy.calls).contains_exactly(["hide_preview"])


func test_decision_0030_hide_preview_accepts_the_id_of_any_hover_signal() -> void:
	var previewer := _previewer_for(A)
	previewer.hide_preview(UNKNOWN_ID)
	previewer.hide_preview(DuelState.NO_ID)
	assert_array(_spy.calls).contains_exactly(["hide_preview", "hide_preview"])


# Le moteur et le modèle lisent l'état construit ; la vue est celle du joueur `viewer`.
func _previewer_for(viewer: DuelState.PlayerSide) -> DuelPreviewer:
	var state := _builder.build()
	_engine = DuelEngine.new(_catalog)
	_engine.start_from_state(state)
	_previewer = DuelPreviewer.new()
	_previewer.setup(_spy, _engine)
	_previewer.use_model(DuelViewModel.new(state, _catalog, viewer))
	return _previewer


func _hero_piece_id(side: DuelState.PlayerSide) -> int:
	return _builder.build().find_hero(side).piece_id


func _trigger_of(side: DuelState.PlayerSide, source: StringName) -> StackEntry:
	var entry := StackEntry.new()
	entry.kind = StackEntry.StackEntryKind.TRIGGERED_EFFECT
	entry.owner = side
	entry.source_definition_id = source
	return entry
