# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## Pièces issues des cartes et des effets (ruleset 0.39, sections 202.2, 202.3 et 202.4) : Unit,
## Building, Gear sans case, Hero sur le plateau, jetons. Gear : test_202_gear.gd.

const SOLDIER: StringName = &"piece_soldier"
const WEAK: StringName = &"piece_weak"
const WALL: StringName = &"piece_wall"
const GEAR: StringName = &"sample_gear"
const TOKEN_SPELL: StringName = &"piece_token_spell"
const SOLDIER_FORCE: int = 3
const WEAK_FORCE: int = 1
const WALL_FORCE: int = 4
const TOKEN_FORCE: int = 2  # CatalogSamples.create_token_effect()
const SOLDIER_COST: int = 2  # CatalogSamples.unit()
const WALL_COST: int = 3  # CatalogSamples.building()
const GEAR_COST: int = 1  # CatalogSamples.gear()
const TOKEN_SPELL_COST: int = 2
const HERO_COUNT: int = 2  # 202.3.1

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const REASON := IntentRejected.RejectReason

var _catalog: Catalog
var _builder: DuelStateBuilder
var _engine: DuelEngine


func before_test() -> void:
	_catalog = SetupSamples.catalog()
	SetupSamples.add_unit(_catalog, SOLDIER, SOLDIER_FORCE)
	SetupSamples.add_unit(_catalog, WEAK, WEAK_FORCE)
	SetupSamples.add_building(_catalog, WALL, WALL_FORCE)
	_catalog.add_card(CardDefinition.from_dict(CatalogSamples.gear()))
	_catalog.add_card(CatalogSamples.token_spell(TOKEN_SPELL, TOKEN_SPELL_COST))
	_builder = DuelStateBuilder.new(DuelConfig.new(), _catalog)
	_builder.with_sources_in_play(A, WALL_COST, 0)
	_engine = DuelEngine.new(_catalog)


func test_202_2_2_deployed_unit_is_a_piece_that_moves() -> void:
	var card_id := _builder.add_to_hand(A, SOLDIER)
	_start()
	_engine.submit(_deploy(card_id, "B1", SOLDIER_COST))
	_resolve_stack()
	var piece := _engine.get_state().piece_at(DuelStateBuilder.cell("B1"))
	assert_int(piece.kind).is_equal(Piece.PieceKind.UNIT)
	# 205.5.4, 204.3.10 : déployée, elle dort jusqu'au prochain tour de A.
	_engine.submit(EndTurn.new(A))
	_engine.submit(EndTurn.new(B))
	_engine.submit(TakeNormalAction.new(A, piece.piece_id, DuelStateBuilder.cell("B2")))
	_resolve_stack()
	assert_str(BoardGeometry.cell_name(piece.cell)).is_equal("B2")
	assert_object(_engine.get_state().piece_at(DuelStateBuilder.cell("B1"))).is_null()


func test_202_2_3_deployed_building_is_a_piece_that_stays_in_place() -> void:
	var card_id := _builder.add_to_hand(A, WALL)
	_start()
	_engine.submit(_deploy(card_id, "D2", WALL_COST))
	_resolve_stack()
	var piece := _engine.get_state().piece_at(DuelStateBuilder.cell("D2"))
	assert_int(piece.kind).is_equal(Piece.PieceKind.BUILDING)
	var action := TakeNormalAction.new(A, piece.piece_id, DuelStateBuilder.cell("D3"))
	_assert_rejected(action, REASON.NO_NORMAL_ACTION)


func test_202_2_7_gear_occupies_no_cell() -> void:
	var unit_id := _place(A, SOLDIER, "B2")
	var gear_id := _builder.add_to_hand(A, GEAR)
	_start()
	var piece_count := _engine.get_state().pieces.size()
	var attach := AttachGear.new(A, gear_id, unit_id, EssencePayment.new(GEAR_COST))
	_engine.submit(attach)
	_resolve_stack()
	var state := _engine.get_state()
	assert_int(state.find_piece(unit_id).attached_gear.card_instance_id).is_equal(gear_id)
	assert_int(state.pieces.size()).is_equal(piece_count)


func test_202_2_7_gear_cannot_be_deployed_on_a_cell() -> void:
	var gear_id := _builder.add_to_hand(A, GEAR)
	_start()
	var deploy := _deploy(gear_id, "B1", GEAR_COST)
	_assert_rejected(deploy, REASON.NOT_DEPLOYABLE)


func test_202_2_15_building_never_moves() -> void:
	var wall_id := _place_building(A, WALL, "B2")
	_start()
	var action := TakeNormalAction.new(A, wall_id, DuelStateBuilder.cell("B3"))
	_assert_rejected(action, REASON.NO_NORMAL_ACTION)


func test_202_2_15_building_that_wins_a_combat_stays_on_its_cell() -> void:
	var wall_id := _place_building(B, WALL, "B3")
	var attacker_id := _place(A, WEAK, "B2")
	var state := _builder.build()
	var events: Array[DuelEvent] = []
	CombatRules.resolve_attack(
		state, state.find_piece(attacker_id), state.find_piece(wall_id), events
	)
	assert_array(EventLog.describe(events)).contains_exactly(["CombatResolved", "PieceDestroyed:A"])
	assert_str(BoardGeometry.cell_name(state.find_piece(wall_id).cell)).is_equal("B3")


func test_202_2_16_building_never_attacks() -> void:
	var wall_id := _place_building(A, WALL, "B2")
	_place(B, WEAK, "B3")
	_start()
	var action := TakeNormalAction.new(A, wall_id, DuelStateBuilder.cell("B3"))
	_assert_rejected(action, REASON.NO_NORMAL_ACTION)


func test_202_3_1_each_player_has_a_hero() -> void:
	_engine.start_new_duel(SetupSamples.setup())
	var state := _engine.get_state()
	for side: DuelState.PlayerSide in DuelState.SIDES:
		assert_object(state.find_hero(side)).is_not_null()
		assert_int(state.find_hero(side).owner).is_equal(side)


func test_202_3_2_hero_is_a_piece_of_the_board() -> void:
	_engine.start_new_duel(SetupSamples.setup())
	var state := _engine.get_state()
	for side: DuelState.PlayerSide in DuelState.SIDES:
		var hero := state.find_hero(side)
		assert_bool(state.pieces.has(hero)).is_true()
		assert_int(hero.kind).is_equal(Piece.PieceKind.HERO)
		assert_bool(BoardGeometry.is_on_board(hero.cell)).is_true()
		assert_object(state.piece_at(hero.cell)).is_same(hero)


func test_202_3_3_hero_is_on_the_board_from_the_start_of_the_game() -> void:
	var events := _engine.start_new_duel(SetupSamples.setup())
	var state := _engine.get_state()
	assert_int(state.phase).is_equal(DuelState.DuelPhase.PREPARATION)
	assert_int(state.turn_number).is_equal(DuelState.NO_TURN)
	assert_int(state.pieces.size()).is_equal(HERO_COUNT)
	assert_array(EventLog.describe(events).filter(DuelChecks.is_hero_placed)).has_size(HERO_COUNT)


func test_202_4_3_token_leaving_the_board_ceases_to_exist() -> void:
	var token_id := _builder.place_token(B, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B3"), 1)
	var attacker_id := _place(A, SOLDIER, "B2")
	var state := _builder.build()
	var events: Array[DuelEvent] = []
	CombatRules.resolve_attack(
		state, state.find_piece(attacker_id), state.find_piece(token_id), events
	)
	assert_array(EventLog.describe(events)).contains(["PieceDestroyed:B"])
	assert_object(state.find_piece(token_id)).is_null()


func test_202_4_4_token_never_goes_to_a_zone_outside_the_board() -> void:
	var token_id := _builder.place_token(B, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B3"), 1)
	var attacker_id := _place(A, SOLDIER, "B2")
	var state := _builder.build()
	var events: Array[DuelEvent] = []
	CombatRules.destroy_piece(state, state.find_piece(token_id), events)
	for side: DuelState.PlayerSide in DuelState.SIDES:
		var player := state.get_player(side)
		for zone: Array[CardInstance] in [
			player.deck, player.hand, player.discard, player.set_aside
		]:
			assert_array(zone).is_empty()
	assert_array(state.stack).is_empty()
	assert_object(state.find_piece(attacker_id)).is_not_null()


func test_202_4_5_token_carries_no_effect() -> void:
	var token_id := _builder.place_token(
		B, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B3"), TOKEN_FORCE
	)
	var state := _builder.build()
	var token := state.find_piece(token_id)
	var events: Array[DuelEvent] = []
	for trigger_event: EffectDefinition.TriggerEvent in [
		EffectDefinition.TriggerEvent.ARRIVAL, EffectDefinition.TriggerEvent.DESTROYED
	]:
		TriggerRules.trigger(state, token, trigger_event, events)
	TurnRules.trigger_end_of_turn(state, events)
	assert_array(events).is_empty()
	assert_array(state.waiting_triggers).is_empty()
	assert_int(ForceRules.current_force(state, token)).is_equal(TOKEN_FORCE)


func test_202_4_11_token_building_follows_the_building_rules() -> void:
	var token_id := _builder.place_token(
		A, Piece.PieceKind.BUILDING, DuelStateBuilder.cell("B2"), WALL_FORCE
	)
	var attacker_id := _place(B, WEAK, "B3")
	var state := _builder.build()
	var events: Array[DuelEvent] = []
	_start()
	_assert_rejected(
		TakeNormalAction.new(A, token_id, DuelStateBuilder.cell("B3")), REASON.NO_NORMAL_ACTION
	)
	CombatRules.resolve_attack(
		state, state.find_piece(attacker_id), state.find_piece(token_id), events
	)
	assert_array(EventLog.describe(events)).contains_exactly(["CombatResolved", "PieceDestroyed:B"])
	assert_str(BoardGeometry.cell_name(state.find_piece(token_id).cell)).is_equal("B2")


func test_202_4_12a_cell_of_the_token_is_chosen_when_the_spell_is_announced() -> void:
	var card_id := _builder.add_to_hand(A, TOKEN_SPELL)
	_builder.with_sources_in_play(A, TOKEN_SPELL_COST, 0)
	_start()
	var cell := DuelStateBuilder.cell("B1")
	_engine.submit(_token_cast(card_id, [cell] as Array[Vector2i]))
	var state := _engine.get_state()
	assert_array(state.stack[0].target_cells).contains_exactly([cell])
	assert_object(state.piece_at(cell)).is_null()


func test_202_4_12a_token_spell_without_a_cell_is_refused() -> void:
	var card_id := _builder.add_to_hand(A, TOKEN_SPELL)
	_builder.with_sources_in_play(A, TOKEN_SPELL_COST, 0)
	_start()
	_assert_rejected(_token_cast(card_id, [] as Array[Vector2i]), REASON.WRONG_TARGET_COUNT)


func test_202_4_12b_cell_taken_before_resolution_is_an_invalid_target() -> void:
	var card_id := _builder.add_to_hand(A, TOKEN_SPELL)
	_builder.with_sources_in_play(A, TOKEN_SPELL_COST, 0)
	_start()
	var cell := DuelStateBuilder.cell("B1")
	_engine.submit(_token_cast(card_id, [cell] as Array[Vector2i]))
	var state := _engine.get_state()
	var occupant_id := DuelStateBuilder.place_unit_in(state, B, SOLDIER, "B1")
	var labels := _resolve_stack()
	assert_array(labels).contains(["EffectLostAllTargets:A"])
	assert_array(labels).not_contains(["TokenCreated:A"])
	assert_int(state.piece_at(cell).piece_id).is_equal(occupant_id)


func test_202_4_13_token_carries_no_keyword() -> void:
	var token_id := _builder.place_token(
		A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B2"), TOKEN_FORCE
	)
	var state := _builder.build()
	var token := state.find_piece(token_id)
	assert_int(KeywordRules.assault_value(state, token)).is_equal(0)
	assert_int(KeywordRules.rampart_value(state, token)).is_equal(0)


func test_202_4_13_building_token_gives_no_outpost_cell() -> void:
	_builder.place_token(A, Piece.PieceKind.BUILDING, DuelStateBuilder.cell("D2"), TOKEN_FORCE)
	var state := _builder.build()
	assert_bool(KeywordRules.is_outpost_cell(state, A, DuelStateBuilder.cell("E2"))).is_false()


func _start() -> void:
	_engine.start_from_state(_builder.build())


func _deploy(card_id: int, cell_name: String, cost: int) -> DeployCard:
	return DeployCard.new(A, card_id, DuelStateBuilder.cell(cell_name), EssencePayment.new(cost))


func _token_cast(card_id: int, cells: Array[Vector2i]) -> CastSpell:
	var intent := CastSpell.new(A, card_id, EssencePayment.new(TOKEN_SPELL_COST))
	intent.target_cells.assign(cells)
	return intent


## Le joueur qui a la priorité passe : la pile se résout. Renvoie les événements décrits.
func _resolve_stack() -> Array[String]:
	var first := _engine.get_state().priority_player
	return EventLog.describe(DuelChecks.pass_once(_engine, first))


func _place(side: DuelState.PlayerSide, definition_id: StringName, cell_name: String) -> int:
	return _builder.place_piece(
		side, Piece.PieceKind.UNIT, DuelStateBuilder.cell(cell_name), definition_id
	)


func _place_building(
	side: DuelState.PlayerSide, definition_id: StringName, cell_name: String
) -> int:
	return _builder.place_piece(
		side, Piece.PieceKind.BUILDING, DuelStateBuilder.cell(cell_name), definition_id
	)


func _assert_rejected(intent: DuelIntent, expected: IntentRejected.RejectReason) -> void:
	assert_array(DuelChecks.rejection_defects(_engine, intent, expected)).is_empty()
