# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## Sommeil et réveil (ruleset 0.41, section 205.5 ; 204.1.18, 204.3.10, 204.3.11, 205.4.7 ;
## décision de design 0200 du ruleset). Le réveil au début d'un tour en cours de partie est
## vérifié sous 204.3.8, 204.3.10 et 204.3.11 dans test_204_turn.gd ; celui du premier tour, après
## la préparation (204.1.18), ici.

const UNIT_ID: StringName = &"sleeper_unit"
const WEAK_ID: StringName = &"sleeper_weak"
const BUILDING_ID: StringName = &"sleeper_building"
const TOKEN_SPELL_ID: StringName = &"sleeper_token_spell"
const UNIT_FORCE: int = 3
const UNIT_COST: int = 2  # CatalogSamples.unit()
const TOKEN_SPELL_COST: int = 2
const CARDS_PER_TURN: int = 1  # 204.3.6

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const REASON := IntentRejected.RejectReason

var _builder: DuelStateBuilder
var _engine: DuelEngine


func before_test() -> void:
	var catalog := Catalog.new()
	SetupSamples.add_unit(catalog, UNIT_ID, UNIT_FORCE)
	SetupSamples.add_unit(catalog, WEAK_ID, 1)
	SetupSamples.add_building(catalog, BUILDING_ID, 3)
	catalog.add_card(CatalogSamples.token_spell(TOKEN_SPELL_ID, TOKEN_SPELL_COST))
	_builder = DuelStateBuilder.new(DuelConfig.new(), catalog)
	_builder.with_sources_in_play(A, UNIT_COST, 0)
	for side: DuelState.PlayerSide in [A, B]:
		for index: int in CARDS_PER_TURN:
			_builder.add_to_deck(side, UNIT_ID)
	_engine = DuelEngine.new(catalog)


func test_205_5_1_unit_is_asleep_after_its_action_and_awake_after_its_wake() -> void:
	var unit_id := _builder.place_piece(
		A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B2"), UNIT_ID
	)
	_start()
	assert_bool(_engine.get_state().find_piece(unit_id).is_awake).is_true()
	_engine.submit(TakeNormalAction.new(A, unit_id, DuelStateBuilder.cell("B3")))
	assert_bool(_engine.get_state().find_piece(unit_id).is_awake).is_false()
	_end_turn(A)
	_end_turn(B)
	assert_bool(_engine.get_state().find_piece(unit_id).is_awake).is_true()


func test_205_5_2_hero_is_asleep_after_its_action_and_awake_after_its_wake() -> void:
	_start()
	var hero_id := _engine.get_state().find_hero(A).piece_id
	assert_bool(_engine.get_state().find_hero(A).is_awake).is_true()
	_engine.submit(TakeNormalAction.new(A, hero_id, DuelStateBuilder.cell("C2")))
	assert_bool(_engine.get_state().find_hero(A).is_awake).is_false()
	_end_turn(A)
	_end_turn(B)
	assert_bool(_engine.get_state().find_hero(A).is_awake).is_true()


func test_205_5_3_asleep_piece_cannot_take_a_normal_action() -> void:
	var unit_id := _builder.place_piece(
		A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B2"), UNIT_ID
	)
	_builder.with_piece_awake(unit_id, false)
	var state := _builder.build()
	var hero := state.find_hero(A)
	hero.is_awake = false
	_engine.start_from_state(state)
	var unit_action := TakeNormalAction.new(A, unit_id, DuelStateBuilder.cell("B3"))
	var hero_action := TakeNormalAction.new(A, hero.piece_id, DuelStateBuilder.cell("C2"))
	for intent: TakeNormalAction in [unit_action, hero_action]:
		assert_array(DuelChecks.rejection_defects(_engine, intent, REASON.PIECE_ASLEEP)).is_empty()


func test_205_5_4_deployed_unit_arrives_asleep() -> void:
	var card_id := _builder.add_to_hand(A, UNIT_ID)
	_start()
	var cell := DuelStateBuilder.cell("B1")
	_engine.submit(DeployCard.new(A, card_id, cell, EssencePayment.new(UNIT_COST)))
	var piece := _engine.get_state().piece_at(cell)
	assert_int(piece.kind).is_equal(Piece.PieceKind.UNIT)
	assert_bool(piece.is_awake).is_false()
	var action := TakeNormalAction.new(A, piece.piece_id, DuelStateBuilder.cell("B2"))
	assert_array(DuelChecks.rejection_defects(_engine, action, REASON.PIECE_ASLEEP)).is_empty()


func test_205_5_4a_unit_token_arrives_asleep() -> void:
	var card_id := _builder.add_to_hand(A, TOKEN_SPELL_ID)
	_start()
	var cell := DuelStateBuilder.cell("B1")
	var cast := CastSpell.new(A, card_id, EssencePayment.new(TOKEN_SPELL_COST))
	cast.target_cells.append(cell)
	_engine.submit(cast)
	_resolve_stack()
	var token := _engine.get_state().piece_at(cell)
	assert_bool(token.is_token()).is_true()
	assert_int(token.kind).is_equal(Piece.PieceKind.UNIT)
	assert_bool(token.is_awake).is_false()


func test_205_5_4b_unit_entering_attacking_arrives_asleep() -> void:
	var enemy_id := _builder.place_piece(
		B, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B1"), WEAK_ID
	)
	var card := _builder.make_card_instance(A, UNIT_ID)
	_builder.push_deploy(card, DuelStateBuilder.cell("B1"))
	_start()
	var labels := _resolve_stack()
	assert_array(labels).contains(["PieceEnteredAttacking:A", "CombatResolved"])
	assert_object(_engine.get_state().find_piece(enemy_id)).is_null()
	var piece := _engine.get_state().piece_at(DuelStateBuilder.cell("B1"))
	assert_int(piece.owner).is_equal(A)
	assert_bool(piece.is_awake).is_false()


func test_205_5_5_asleep_piece_stays_asleep_until_its_next_wake() -> void:
	var card_id := _builder.add_to_hand(A, UNIT_ID)
	_start()
	var cell := DuelStateBuilder.cell("B1")
	_engine.submit(DeployCard.new(A, card_id, cell, EssencePayment.new(UNIT_COST)))
	var piece_id := _engine.get_state().piece_at(cell).piece_id
	_end_turn(A)
	assert_bool(_engine.get_state().find_piece(piece_id).is_awake).is_false()
	_end_turn(B)
	assert_bool(_engine.get_state().find_piece(piece_id).is_awake).is_true()
	var action := TakeNormalAction.new(A, piece_id, DuelStateBuilder.cell("B2"))
	assert_int(_engine.validate(action)).is_equal(REASON.NONE)


func test_205_5_6_building_is_refused_as_no_normal_action_not_as_asleep() -> void:
	var building_id := _builder.place_piece(
		A, Piece.PieceKind.BUILDING, DuelStateBuilder.cell("B2"), BUILDING_ID
	)
	_start()
	assert_bool(_engine.get_state().find_piece(building_id).is_awake).is_false()
	var action := TakeNormalAction.new(A, building_id, DuelStateBuilder.cell("B3"))
	assert_array(DuelChecks.rejection_defects(_engine, action, REASON.NO_NORMAL_ACTION)).is_empty()
	_end_turn(A)
	_end_turn(B)
	assert_bool(_engine.get_state().find_piece(building_id).is_awake).is_false()
	assert_int(_engine.validate(action)).is_equal(REASON.NO_NORMAL_ACTION)


func test_204_1_18_heroes_are_placed_asleep() -> void:
	var full_engine := DuelEngine.new(SetupSamples.catalog())
	full_engine.start_new_duel(SetupSamples.setup())
	for side: DuelState.PlayerSide in [A, B]:
		assert_bool(full_engine.get_state().find_hero(side).is_awake).is_false()


func test_204_3_11_first_turn_wakes_only_the_hero_of_the_first_player() -> void:
	var setup := SetupSamples.setup()
	setup.impose_first_player(A)
	var full_engine := DuelEngine.new(SetupSamples.catalog())
	full_engine.start_new_duel(setup)
	full_engine.submit(ChooseMulligan.new(A))
	full_engine.submit(ChooseMulligan.new(B))
	assert_bool(full_engine.get_state().find_hero(A).is_awake).is_true()
	assert_bool(full_engine.get_state().find_hero(B).is_awake).is_false()


func _start() -> void:
	_engine.start_from_state(_builder.build())


func _end_turn(side: DuelState.PlayerSide) -> void:
	_engine.submit(EndTurn.new(side))


## L'entrée construite à la main se résout, puis le combat en attente qu'elle fait naître
## (205.6.4). Renvoie les événements décrits.
func _resolve_stack() -> Array[String]:
	return EventLog.describe(DuelChecks.pass_until_stack_empty(_engine))
