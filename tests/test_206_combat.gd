# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## CombatRules : comparaison, issue, égalité, Hero défenseur (ruleset 0.31, chapitre 206).

const STRONG_ID: StringName = &"strong_unit"
const WEAK_ID: StringName = &"weak_unit"
const EQUAL_ID: StringName = &"equal_unit"
const WALL_ID: StringName = &"wall_building"
const GEAR_ID: StringName = &"sample_gear"
const STRONG_FORCE: int = 5
const WEAK_FORCE: int = 2
const HERO_HEALTH: int = DuelStateBuilder.DEFAULT_HERO_HEALTH
const HERO_COUNT: int = 2

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B

var _builder: DuelStateBuilder
var _events: Array[DuelEvent]
var _last_attacker_id: int = DuelState.NO_ID


func before_test() -> void:
	var catalog := Catalog.new()
	SetupSamples.add_unit(catalog, STRONG_ID, STRONG_FORCE)
	SetupSamples.add_unit(catalog, WEAK_ID, WEAK_FORCE)
	SetupSamples.add_unit(catalog, EQUAL_ID, STRONG_FORCE)
	SetupSamples.add_building(catalog, WALL_ID, STRONG_FORCE)
	catalog.add_card(CardDefinition.from_dict(CatalogSamples.gear()))
	_builder = DuelStateBuilder.new(DuelConfig.new(), catalog)
	_events = []


func test_206_2_1_combat_compares_both_forces() -> void:
	var state := _fight(STRONG_ID, WEAK_ID)
	var combat := _events[0] as CombatResolved
	assert_int(combat.attacker_force).is_equal(STRONG_FORCE)
	assert_int(combat.defender_force).is_equal(WEAK_FORCE)
	assert_int(state.pieces.size()).is_equal(HERO_COUNT + 1)


func test_206_3_1_weaker_defender_destroyed() -> void:
	_fight(STRONG_ID, WEAK_ID)
	assert_array(EventLog.describe(_events)).contains_exactly(
		["CombatResolved", "PieceDestroyed:B", "PieceMoved:A"]
	)


func test_206_3_3_attacker_takes_destroyed_defender_cell() -> void:
	var state := _fight(STRONG_ID, WEAK_ID)
	var attacker := state.find_piece(_last_attacker_id)
	assert_str(BoardGeometry.cell_name(attacker.cell)).is_equal("B4")
	assert_object(state.piece_at(DuelStateBuilder.cell("B3"))).is_null()


func test_206_3_4_weaker_attacker_destroyed_and_defender_stays() -> void:
	var state := _fight(WEAK_ID, STRONG_ID)
	assert_array(EventLog.describe(_events)).contains_exactly(
		["CombatResolved", "PieceDestroyed:A"]
	)
	assert_object(state.piece_at(DuelStateBuilder.cell("B4"))).is_not_null()


func test_206_3_6_tie_destroys_both() -> void:
	var state := _fight(STRONG_ID, EQUAL_ID)
	assert_array(EventLog.describe(_events)).contains_exactly(
		["CombatResolved", "PieceDestroyed:B", "PieceDestroyed:A"]
	)
	assert_int(state.pieces.size()).is_equal(HERO_COUNT)


func test_206_3_3a_tie_attacker_does_not_take_cell() -> void:
	var state := _fight(STRONG_ID, EQUAL_ID)
	assert_object(state.piece_at(DuelStateBuilder.cell("B4"))).is_null()
	assert_array(EventLog.describe(_events)).not_contains(["PieceMoved:A"])


func test_206_3_4a_tie_defender_does_not_stay() -> void:
	var state := _fight(STRONG_ID, EQUAL_ID)
	assert_object(state.piece_at(DuelStateBuilder.cell("B4"))).is_null()


func test_206_3_2_destroyed_piece_goes_to_owner_discard() -> void:
	var state := _fight(STRONG_ID, WEAK_ID)
	var discard := state.get_player(B).discard
	assert_int(discard.size()).is_equal(1)
	assert_str(discard[0].definition_id).is_equal(WEAK_ID)
	assert_array(state.get_player(A).discard).is_empty()


func test_206_3_2a_destroyed_token_goes_nowhere() -> void:
	var attacker_id := _place(A, STRONG_ID, "B3")
	var token_id := _builder.place_token(B, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B4"), 1)
	var state := _attack(attacker_id, token_id)
	assert_object(state.find_piece(token_id)).is_null()
	assert_array(state.get_player(B).discard).is_empty()


func test_202_2_13_gear_of_destroyed_unit_goes_to_discard() -> void:
	var attacker_id := _place(A, STRONG_ID, "B3")
	var defender_id := _place(B, WEAK_ID, "B4")
	_builder.attach_gear(defender_id, GEAR_ID)
	var state := _attack(attacker_id, defender_id)
	var discarded: Array[StringName] = []
	for card: CardInstance in state.get_player(B).discard:
		discarded.append(card.definition_id)
	assert_array(discarded).contains_exactly_in_any_order([WEAK_ID, GEAR_ID])


func test_202_2_18_building_defends_its_cell_with_its_force() -> void:
	var attacker_id := _place(A, WEAK_ID, "B3")
	var wall_id := _builder.place_piece(
		B, Piece.PieceKind.BUILDING, DuelStateBuilder.cell("B4"), WALL_ID
	)
	var state := _attack(attacker_id, wall_id)
	assert_object(state.find_piece(attacker_id)).is_null()
	assert_object(state.find_piece(wall_id)).is_not_null()


func test_206_2_3_force_at_combat_includes_modifiers() -> void:
	var attacker_id := _place(A, WEAK_ID, "B3")
	var defender_id := _place(B, STRONG_ID, "B4")
	_add_modifier(attacker_id, STRONG_FORCE)
	var state := _attack(attacker_id, defender_id)
	assert_int((_events[0] as CombatResolved).attacker_force).is_equal(WEAK_FORCE + STRONG_FORCE)
	assert_object(state.find_piece(defender_id)).is_null()


func test_206_3_5_surviving_piece_keeps_its_force() -> void:
	var state := _fight(STRONG_ID, WEAK_ID)
	var attacker := state.find_piece(_last_attacker_id)
	assert_int(ForceRules.current_force(state, attacker)).is_equal(STRONG_FORCE)


func test_206_0_1_no_damage_persists_after_combat() -> void:
	var state := _fight(WEAK_ID, STRONG_ID)
	var defender := state.piece_at(DuelStateBuilder.cell("B4"))
	assert_int(ForceRules.current_force(state, defender)).is_equal(STRONG_FORCE)


func test_206_4_2_attacked_hero_loses_attacker_force() -> void:
	var state := _attack_hero_of_b()
	assert_int(state.find_hero(B).health).is_equal(HERO_HEALTH - STRONG_FORCE)
	assert_array(EventLog.describe(_events)).contains_exactly(
		["HeroAttacked:B", "HeroLostHealth:B"]
	)


func test_206_2_1a_hero_defender_compares_no_force() -> void:
	_attack_hero_of_b()
	assert_array(EventLog.describe(_events)).not_contains(["CombatResolved"])


func test_206_4_3_attacked_hero_not_destroyed() -> void:
	var state := _attack_hero_of_b()
	assert_object(state.find_hero(B)).is_not_null()


func test_206_4_4_hero_attacker_not_destroyed() -> void:
	var state := _attack_hero_of_b()
	assert_object(state.find_piece(_last_attacker_id)).is_not_null()


func test_206_4_5_hero_attacker_stays_on_its_cell() -> void:
	var state := _attack_hero_of_b()
	assert_str(BoardGeometry.cell_name(state.find_piece(_last_attacker_id).cell)).is_equal("C4")


func test_206_4_6_player_loses_when_attacked_hero_reaches_zero() -> void:
	_builder.with_hero_health(B, STRONG_FORCE - 1)
	var state := _attack_hero_of_b()
	assert_int(state.find_hero(B).health).is_equal(0)
	assert_int(state.result).is_equal(DuelState.DuelResult.PLAYER_A_WINS)
	assert_str(EventLog.describe(_events).back()).is_equal("DuelEnded")


func _fight(attacker_definition: StringName, defender_definition: StringName) -> DuelState:
	var attacker_id := _place(A, attacker_definition, "B3")
	var defender_id := _place(B, defender_definition, "B4")
	return _attack(attacker_id, defender_id)


func _attack_hero_of_b() -> DuelState:
	var attacker_id := _place(A, STRONG_ID, "C4")
	var state := _builder.build()
	_last_attacker_id = attacker_id
	CombatRules.resolve_attack(state, state.find_piece(attacker_id), state.find_hero(B), _events)
	return state


func _attack(attacker_id: int, defender_id: int) -> DuelState:
	var state := _builder.build()
	_last_attacker_id = attacker_id
	CombatRules.resolve_attack(
		state, state.find_piece(attacker_id), state.find_piece(defender_id), _events
	)
	return state


func _place(side: DuelState.PlayerSide, definition_id: StringName, cell_name: String) -> int:
	return _builder.place_piece(
		side, Piece.PieceKind.UNIT, DuelStateBuilder.cell(cell_name), definition_id
	)


func _add_modifier(piece_id: int, amount: int) -> void:
	var effect := ActiveEffect.new()
	effect.affected_piece_id = piece_id
	effect.effect_kind = EffectDefinition.kind_id(EffectDefinition.EffectKind.MODIFY_FORCE)
	effect.amount = amount
	_builder.add_active_effect(effect)
