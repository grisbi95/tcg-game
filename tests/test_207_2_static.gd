extends GdUnitTestSuite
## Effets statiques et auras lus par ForceRules (ruleset 0.33, sections 207.2 et 206.5 ;
## 202.3.18 pour le passif du Hero).

const UNIT_ID: StringName = &"plain_unit"
const AURA_UNIT_ID: StringName = &"aura_unit"
const ENEMY_ID: StringName = &"enemy_unit"
const BUILDING_ID: StringName = &"plain_building"
const GEAR_ID: StringName = &"sample_gear"
const AURA_GEAR_ID: StringName = &"aura_gear"
const STRONG_GEAR_ID: StringName = &"strong_gear"
const SPELL_ID: StringName = &"sample_spell"
const HERO_ID: StringName = &"sample_hero"
const UNIT_FORCE: int = 3
const AURA: int = 1  # CatalogSamples.modify_force_static()
const BUILDING_FORCE: int = 4
const TOKEN_FORCE: int = 1
const STRONG_GEAR_BONUS: int = 2
const UNIT_COST: int = 2  # CatalogSamples.unit()
const GEAR_COST: int = 1  # CatalogSamples.gear()
const SPELL_COST: int = 1  # CatalogSamples.spell()
const CARDS_PER_TURN: int = 2  # 204.3.6

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B

var _builder: DuelStateBuilder
var _engine: DuelEngine


func before_test() -> void:
	var catalog := Catalog.new()
	SetupSamples.add_unit(catalog, UNIT_ID, UNIT_FORCE)
	SetupSamples.add_unit(catalog, ENEMY_ID, UNIT_FORCE)
	SetupSamples.add_building(catalog, BUILDING_ID, BUILDING_FORCE)
	var aura_unit := CatalogSamples.with_field(CatalogSamples.unit(), "id", String(AURA_UNIT_ID))
	aura_unit = CatalogSamples.with_field(aura_unit, "name", "Unit à aura")
	aura_unit = CatalogSamples.with_field(
		aura_unit,
		"effects",
		[CatalogSamples.modify_force_static({"scope": "adjacent_allied_units"})]
	)
	catalog.add_card(CardDefinition.from_dict(aura_unit))
	catalog.add_card(CardDefinition.from_dict(CatalogSamples.gear()))
	catalog.add_card(CardDefinition.from_dict(CatalogSamples.spell()))
	catalog.add_card(
		_gear(AURA_GEAR_ID, CatalogSamples.modify_force_static({"scope": "adjacent_allied_units"}))
	)
	catalog.add_card(
		_gear(STRONG_GEAR_ID, CatalogSamples.modify_force_static({"amount": STRONG_GEAR_BONUS}))
	)
	catalog.add_hero(HeroDefinition.from_dict(CatalogSamples.hero()))
	_builder = DuelStateBuilder.new(DuelConfig.new(), catalog)
	_engine = DuelEngine.new(catalog)


func test_202_3_18_hero_passive_boosts_adjacent_allied_units() -> void:
	var near_id := _place(A, UNIT_ID, "B1")
	var far_id := _place(A, UNIT_ID, "A2")
	var state := _builder.with_hero_definition(A, HERO_ID).build()
	assert_int(_force(state, near_id)).is_equal(UNIT_FORCE + AURA)
	assert_int(_force(state, far_id)).is_equal(UNIT_FORCE)


func test_207_2_1_static_effect_applies_without_the_stack() -> void:
	var near_id := _place(A, UNIT_ID, "B1")
	var state := _builder.with_hero_definition(A, HERO_ID).build()
	assert_array(state.stack).is_empty()
	assert_int(_force(state, near_id)).is_equal(UNIT_FORCE + AURA)


func test_206_5_4_aura_of_a_unit_touches_adjacent_allied_units() -> void:
	_place(A, AURA_UNIT_ID, "B2")
	var ally_id := _place(A, UNIT_ID, "B3")
	var enemy_id := _place(B, ENEMY_ID, "C2")
	var state := _builder.build()
	assert_int(_force(state, ally_id)).is_equal(UNIT_FORCE + AURA)
	assert_int(_force(state, enemy_id)).is_equal(UNIT_FORCE)


func test_206_5_5_aura_touches_neither_its_bearer_nor_buildings() -> void:
	var bearer_id := _place(A, AURA_UNIT_ID, "B2")
	var building_id := _builder.place_piece(
		A, Piece.PieceKind.BUILDING, DuelStateBuilder.cell("B3"), BUILDING_ID
	)
	var state := _builder.build()
	assert_int(_force(state, bearer_id)).is_equal(UNIT_FORCE)
	assert_int(_force(state, building_id)).is_equal(BUILDING_FORCE)


func test_206_5_5_aura_stops_when_position_condition_fails() -> void:
	_place(A, AURA_UNIT_ID, "B2")
	var ally_id := _place(A, UNIT_ID, "B3")
	var state := _builder.build()
	state.find_piece(ally_id).cell = DuelStateBuilder.cell("D3")
	assert_int(_force(state, ally_id)).is_equal(UNIT_FORCE)


func test_207_2_3_static_effect_begins_when_the_bearer_arrives() -> void:
	var ally_id := _place(A, UNIT_ID, "B2")
	_push_aura_deploy("B1")
	_start()
	assert_int(_live_force(ally_id)).is_equal(UNIT_FORCE)
	_pass_once(B)
	assert_int(_live_force(ally_id)).is_equal(UNIT_FORCE + AURA)


func test_207_2_5_nobody_answers_a_static_effect() -> void:
	_place(A, UNIT_ID, "B2")
	_push_aura_deploy("B1")
	_start()
	var labels := EventLog.describe(_pass_once(B))
	assert_array(labels).contains_exactly(
		["PriorityPassed:B", "PieceDeployed:A", "StackEntryResolved:A"]
	)
	var state := _engine.get_state()
	assert_array(state.stack).is_empty()
	assert_int(state.priority_player).is_equal(A)


func test_207_2_6_player_answers_the_announcement_of_the_bearer() -> void:
	var ally_id := _place(A, UNIT_ID, "B2")
	var enemy_id := _place(B, ENEMY_ID, "D4")
	var aura_card_id := _builder.add_to_hand(A, AURA_UNIT_ID)
	var spell_card_id := _builder.add_to_hand(B, SPELL_ID)
	_start()
	var deploy := DeployCard.new(
		A, aura_card_id, DuelStateBuilder.cell("B1"), EssencePayment.new(UNIT_COST)
	)
	_engine.submit(deploy)
	var state := _engine.get_state()
	assert_int(state.priority_player).is_equal(B)
	assert_int(_live_force(ally_id)).is_equal(UNIT_FORCE)
	var answer := CastSpell.new(B, spell_card_id, EssencePayment.new(SPELL_COST))
	answer.target_piece_ids.append(enemy_id)
	assert_array(EventLog.describe(_engine.submit(answer))).contains(["SpellAnnounced:B"])
	assert_int(state.stack.size()).is_equal(2)


func test_207_2_7_static_effect_lasts_while_the_bearer_is_in_play() -> void:
	_place(A, AURA_UNIT_ID, "B2")
	var ally_id := _place(A, UNIT_ID, "B3")
	_fill_decks()
	_start()
	_engine.submit(EndTurn.new(A))
	_engine.submit(EndTurn.new(B))
	var state := _engine.get_state()
	assert_int(state.active_player).is_equal(A)
	assert_int(_live_force(ally_id)).is_equal(UNIT_FORCE + AURA)
	assert_array(state.active_effects).is_empty()


func test_207_2_4_static_effect_stops_when_bearer_leaves() -> void:
	var bearer_id := _place(A, AURA_UNIT_ID, "B2")
	var ally_id := _place(A, UNIT_ID, "B3")
	var state := _builder.build()
	var events: Array[DuelEvent] = []
	CombatRules.destroy_piece(state, state.find_piece(bearer_id), events)
	assert_int(_force(state, ally_id)).is_equal(UNIT_FORCE)


func test_202_4_5a_token_receives_an_aura() -> void:
	_place(A, AURA_UNIT_ID, "B2")
	var token_id := _builder.place_token(
		A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B3"), TOKEN_FORCE
	)
	var state := _builder.build()
	assert_int(_force(state, token_id)).is_equal(TOKEN_FORCE + AURA)


func test_207_2_8_gear_effect_is_carried_by_its_unit() -> void:
	var unit_id := _place(A, UNIT_ID, "B2")
	_builder.attach_gear(unit_id, GEAR_ID)
	var state := _builder.build()
	assert_int(_force(state, unit_id)).is_equal(UNIT_FORCE + AURA)


func test_207_2_9_gear_effect_applies_while_attached_to_a_piece_in_play() -> void:
	var unit_id := _place(A, UNIT_ID, "B2")
	_builder.attach_gear(unit_id, GEAR_ID)
	_fill_decks()
	_start()
	assert_int(_live_force(unit_id)).is_equal(UNIT_FORCE + AURA)
	_engine.submit(EndTurn.new(A))
	_engine.submit(EndTurn.new(B))
	assert_int(_live_force(unit_id)).is_equal(UNIT_FORCE + AURA)
	assert_array(_engine.get_state().active_effects).is_empty()


func test_207_2_9a_gear_effect_stops_when_detached() -> void:
	var unit_id := _place(A, UNIT_ID, "B2")
	_builder.attach_gear(unit_id, GEAR_ID)
	var state := _builder.build()
	state.find_piece(unit_id).attached_gear = null
	assert_int(_force(state, unit_id)).is_equal(UNIT_FORCE)


func test_207_2_9b_gear_effect_stops_when_its_piece_leaves_the_board() -> void:
	var carrier_id := _place(A, UNIT_ID, "B2")
	_builder.attach_gear(carrier_id, AURA_GEAR_ID)
	var ally_id := _place(A, UNIT_ID, "B3")
	var state := _builder.build()
	assert_int(_force(state, ally_id)).is_equal(UNIT_FORCE + AURA)
	var events: Array[DuelEvent] = []
	CombatRules.destroy_piece(state, state.find_piece(carrier_id), events)
	assert_int(_force(state, ally_id)).is_equal(UNIT_FORCE)


func test_207_4_8_effect_of_a_detached_gear_stops() -> void:
	var unit_id := _place(A, UNIT_ID, "B2")
	_builder.attach_gear(unit_id, GEAR_ID)
	var new_gear_id := _builder.add_to_hand(A, STRONG_GEAR_ID)
	_builder.with_sources_in_play(A, GEAR_COST, 0)
	_start()
	assert_int(_live_force(unit_id)).is_equal(UNIT_FORCE + AURA)
	_engine.submit(AttachGear.new(A, new_gear_id, unit_id, EssencePayment.new(GEAR_COST)))
	_pass_once(B)
	assert_int(_live_force(unit_id)).is_equal(UNIT_FORCE + STRONG_GEAR_BONUS)


func test_206_5_3_attacker_keeps_aura_it_leaves_for_the_combat() -> void:
	var attacker_id := _place(A, UNIT_ID, "B1")
	var defender_id := _place(B, ENEMY_ID, "B2")
	var state := _builder.with_hero_definition(A, HERO_ID).build()
	var events: Array[DuelEvent] = []
	var attacker := state.find_piece(attacker_id)
	CombatRules.resolve_attack(state, attacker, state.find_piece(defender_id), events)
	assert_int((events[0] as CombatResolved).attacker_force).is_equal(UNIT_FORCE + AURA)
	assert_object(state.find_piece(defender_id)).is_null()
	assert_str(BoardGeometry.cell_name(attacker.cell)).is_equal("B2")


func test_206_5_2_auras_read_before_attacker_enters_defender_cell() -> void:
	var attacker_id := _place(A, UNIT_ID, "D1")
	var defender_id := _place(B, ENEMY_ID, "D2")
	_place(A, AURA_UNIT_ID, "E2")
	var state := _builder.build()
	var events: Array[DuelEvent] = []
	CombatRules.resolve_attack(
		state, state.find_piece(attacker_id), state.find_piece(defender_id), events
	)
	assert_int((events[0] as CombatResolved).attacker_force).is_equal(UNIT_FORCE)
	assert_object(state.find_piece(attacker_id)).is_null()


func _start() -> void:
	_engine.start_from_state(_builder.build())


# Annonce déjà faite du déploiement de l'Unit à aura de A, sous la main de B.
func _push_aura_deploy(cell_name: String) -> void:
	var card := _builder.make_card_instance(A, AURA_UNIT_ID)
	_builder.push_deploy(card, DuelStateBuilder.cell(cell_name))
	_builder.with_priority_player(B)


# Deux tours complets pigent quatre cartes par joueur (204.3.6).
func _fill_decks() -> void:
	for side: DuelState.PlayerSide in [A, B]:
		for index: int in CARDS_PER_TURN * 2:
			_builder.add_to_deck(side, UNIT_ID)


# `first` passe : la pile se résout (208.3.1).
func _pass_once(first: DuelState.PlayerSide) -> Array[DuelEvent]:
	return DuelChecks.pass_once(_engine, first)


func _gear(id: StringName, effect: Dictionary) -> CardDefinition:
	var data := CatalogSamples.with_field(CatalogSamples.gear(), "id", String(id))
	data = CatalogSamples.with_field(data, "name", "Gear %s" % id)
	return CardDefinition.from_dict(CatalogSamples.with_field(data, "effects", [effect]))


func _place(side: DuelState.PlayerSide, definition_id: StringName, cell_name: String) -> int:
	return _builder.place_piece(
		side, Piece.PieceKind.UNIT, DuelStateBuilder.cell(cell_name), definition_id
	)


func _force(state: DuelState, piece_id: int) -> int:
	return ForceRules.current_force(state, state.find_piece(piece_id))


func _live_force(piece_id: int) -> int:
	return _force(_engine.get_state(), piece_id)
