extends GdUnitTestSuite
## Mots-clés Assaut, Rempart et Avant-poste (ruleset 0.33, sections 210.2 et 210.4 ; 205.1.2a,
## 205.1.2b ; décision de design 0186). Arrivée et Dernier souffle : test_207_3_triggered.gd.

const SOLDIER: StringName = &"keyword_soldier"
const RAIDER: StringName = &"keyword_raider"
const GUARD: StringName = &"keyword_guard"
const CAMP: StringName = &"keyword_camp"
const PALISADE: StringName = &"keyword_palisade"
const FORCE: int = 2  # Pillard et Gardien des decks de test
const KEYWORD_VALUE: int = 1  # Assaut 1, Rempart 1
const UNIT_COST: int = 2  # CatalogSamples.unit()

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const REASON := IntentRejected.RejectReason
const ROLE := ForceRules.CombatRole

var _builder: DuelStateBuilder
var _events: Array[DuelEvent]


func before_test() -> void:
	var catalog := Catalog.new()
	SetupSamples.add_unit(catalog, SOLDIER, FORCE)
	SetupSamples.add_building(catalog, PALISADE, FORCE)
	_add_with_keyword(
		catalog, CatalogSamples.unit(), RAIDER, {"keyword": "assault", "value": KEYWORD_VALUE}
	)
	_add_with_keyword(
		catalog, CatalogSamples.unit(), GUARD, {"keyword": "rampart", "value": KEYWORD_VALUE}
	)
	_add_with_keyword(catalog, CatalogSamples.building(), CAMP, {"keyword": "outpost"})
	_builder = DuelStateBuilder.new(DuelConfig.new(), catalog)
	_events = []


func test_210_4_1_assault_adds_force_when_attacking() -> void:
	var raider_id := _place(A, RAIDER, "B2")
	var soldier_id := _place(B, SOLDIER, "B3")
	_attack(raider_id, soldier_id)
	var combat := _events[0] as CombatResolved
	assert_int(combat.attacker_force).is_equal(FORCE + KEYWORD_VALUE)
	assert_object(_builder.build().find_piece(soldier_id)).is_null()
	assert_object(_builder.build().find_piece(raider_id)).is_not_null()


func test_210_4_1_assault_does_not_apply_when_defending() -> void:
	var raider_id := _place(A, RAIDER, "B2")
	var state := _builder.build()
	var raider := state.find_piece(raider_id)
	assert_int(ForceRules.combat_force(state, raider, ROLE.DEFENDER)).is_equal(FORCE)


func test_210_4_1_assault_counts_against_a_hero() -> void:
	var raider_id := _place(A, RAIDER, "C4")
	var state := _builder.build()
	var health_before := state.find_hero(B).health
	_attack(raider_id, state.find_hero(B).piece_id)
	assert_int(state.find_hero(B).health).is_equal(health_before - FORCE - KEYWORD_VALUE)


func test_210_4_1a_assault_adds_to_other_modifiers_before_the_floor() -> void:
	var raider_id := _place(A, RAIDER, "B2")
	_add_modifier(raider_id, -FORCE - 1)
	var state := _builder.build()
	var raider := state.find_piece(raider_id)
	assert_int(ForceRules.combat_force(state, raider, ROLE.ATTACKER)).is_equal(0)


func test_210_4_1b_assault_is_read_only_during_combat() -> void:
	var raider_id := _place(A, RAIDER, "B2")
	var state := _builder.build()
	assert_int(ForceRules.current_force(state, state.find_piece(raider_id))).is_equal(FORCE)


func test_210_4_2_rampart_adds_force_when_defending() -> void:
	var soldier_id := _place(B, SOLDIER, "B3")
	var guard_id := _place(A, GUARD, "B2")
	_attack(soldier_id, guard_id)
	var combat := _events[0] as CombatResolved
	assert_int(combat.defender_force).is_equal(FORCE + KEYWORD_VALUE)
	assert_object(_builder.build().find_piece(guard_id)).is_not_null()
	assert_object(_builder.build().find_piece(soldier_id)).is_null()


func test_210_4_2_rampart_does_not_apply_when_attacking() -> void:
	var guard_id := _place(A, GUARD, "B2")
	var state := _builder.build()
	var guard := state.find_piece(guard_id)
	assert_int(ForceRules.combat_force(state, guard, ROLE.ATTACKER)).is_equal(FORCE)


func test_210_4_2a_rampart_adds_to_other_modifiers() -> void:
	var guard_id := _place(A, GUARD, "B2")
	_add_modifier(guard_id, 1)
	var state := _builder.build()
	var guard := state.find_piece(guard_id)
	var expected := FORCE + 1 + KEYWORD_VALUE
	assert_int(ForceRules.combat_force(state, guard, ROLE.DEFENDER)).is_equal(expected)


func test_210_4_2b_rampart_is_read_only_during_combat() -> void:
	var guard_id := _place(A, GUARD, "B2")
	var state := _builder.build()
	assert_int(ForceRules.current_force(state, state.find_piece(guard_id))).is_equal(FORCE)


func test_210_3_2c_only_a_unit_or_a_building_carries_last_breath() -> void:
	var last_breath := [{"keyword": "last_breath"}]
	var effects := [CatalogSamples.triggered("destroyed")]
	for base: Dictionary in [CatalogSamples.unit(), CatalogSamples.building()]:
		var carrier := CatalogSamples.with_field(base, "keywords", last_breath)
		carrier = CatalogSamples.with_field(carrier, "effects", effects)
		assert_array(Array(_errors_of(carrier))).is_empty()
	for base: Dictionary in [CatalogSamples.spell(), CatalogSamples.gear()]:
		var refused := CatalogSamples.with_field(base, "keywords", last_breath)
		(
			assert_bool(CatalogSamples.mentions(_errors_of(refused), "LAST_BREATH est refusé"))
			. is_true()
		)


func test_210_4_2c_only_a_unit_carries_rampart() -> void:
	var rampart := [{"keyword": "rampart", "value": KEYWORD_VALUE}]
	var unit := CatalogSamples.with_field(CatalogSamples.unit(), "keywords", rampart)
	assert_array(Array(_errors_of(unit))).is_empty()
	for base: Dictionary in [
		CatalogSamples.building(), CatalogSamples.spell(), CatalogSamples.gear()
	]:
		var refused := CatalogSamples.with_field(base, "keywords", rampart)
		assert_bool(CatalogSamples.mentions(_errors_of(refused), "RAMPART est refusé")).is_true()


func test_210_2_1_outpost_allows_a_free_adjacent_cell() -> void:
	_place_building(A, CAMP, "B2")
	assert_int(_validate_deploy("A2")).is_equal(REASON.NONE)


func test_205_1_2a_outpost_cell_is_an_extra_deploy_zone() -> void:
	_place_building(A, CAMP, "B2")
	assert_int(_validate_deploy("D1")).is_equal(REASON.NONE)
	assert_int(_validate_deploy("D2")).is_equal(REASON.CELL_NOT_IN_DEPLOY_ZONE)


func test_210_2_1_outpost_cell_must_be_free() -> void:
	_place_building(A, CAMP, "B2")
	_place(A, SOLDIER, "A2")
	assert_int(_validate_deploy("A2")).is_equal(REASON.CELL_NOT_FREE)


func test_210_2_1_only_own_buildings_with_outpost_count() -> void:
	_place_building(A, PALISADE, "B2")
	_place_building(B, CAMP, "D2")
	assert_int(_validate_deploy("A2")).is_equal(REASON.CELL_NOT_IN_DEPLOY_ZONE)
	assert_int(_validate_deploy("E2")).is_equal(REASON.CELL_NOT_IN_DEPLOY_ZONE)


func test_210_2_1a_outpost_never_allows_the_central_row() -> void:
	_place_building(A, CAMP, "B2")
	assert_int(_validate_deploy("B3")).is_equal(REASON.CELL_NOT_IN_DEPLOY_ZONE)


func test_205_1_2b_deploy_resolves_after_the_outpost_building_left() -> void:
	var card := _builder.make_card_instance(A, SOLDIER)
	_builder.push_deploy(card, DuelStateBuilder.cell("A2"))
	var engine := DuelEngine.new(_builder.build().catalog)
	engine.start_from_state(_builder.build())
	var state := engine.get_state()
	var labels := EventLog.describe(engine.submit(PassPriority.new(state.priority_player)))
	assert_bool(labels.has("PieceDeployed:A")).is_true()
	assert_object(state.piece_at(DuelStateBuilder.cell("A2"))).is_not_null()


func test_205_1_2b_outpost_deploy_on_an_enemy_attacks_it() -> void:
	var card := _builder.make_card_instance(A, RAIDER)
	_place(B, SOLDIER, "A2")
	_builder.push_deploy(card, DuelStateBuilder.cell("A2"))
	var engine := DuelEngine.new(_builder.build().catalog)
	engine.start_from_state(_builder.build())
	var state := engine.get_state()
	engine.submit(PassPriority.new(state.priority_player))
	var labels := EventLog.describe(engine.submit(PassPriority.new(state.priority_player)))
	assert_bool(labels.has("PieceEnteredAttacking:A")).is_true()
	assert_int(state.piece_at(DuelStateBuilder.cell("A2")).owner).is_equal(A)


func _add_with_keyword(
	catalog: Catalog, base: Dictionary, id: StringName, keyword: Dictionary
) -> void:
	var data := CatalogSamples.with_field(base, "id", String(id))
	data = CatalogSamples.with_field(data, "name", "Carte %s" % id)
	data = CatalogSamples.with_field(data, "force", FORCE)
	data = CatalogSamples.with_field(data, "keywords", [keyword])
	var definition := CardDefinition.from_dict(data)
	assert_array(Array(definition.find_errors())).is_empty()
	catalog.add_card(definition)


func _errors_of(data: Dictionary) -> PackedStringArray:
	return CardDefinition.from_dict(data).find_errors()


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


func _attack(attacker_id: int, defender_id: int) -> void:
	var state := _builder.build()
	CombatRules.resolve_attack(
		state, state.find_piece(attacker_id), state.find_piece(defender_id), _events
	)


func _add_modifier(piece_id: int, amount: int) -> void:
	var effect := ActiveEffect.new()
	effect.affected_piece_id = piece_id
	effect.effect_kind = EffectDefinition.kind_id(EffectDefinition.EffectKind.MODIFY_FORCE)
	effect.amount = amount
	_builder.add_active_effect(effect)


func _validate_deploy(cell_name: String) -> IntentRejected.RejectReason:
	var card_id := _builder.add_to_hand(A, SOLDIER)
	var engine := DuelEngine.new(_builder.build().catalog)
	engine.start_from_state(_builder.build())
	var deploy := DeployCard.new(
		A, card_id, DuelStateBuilder.cell(cell_name), EssencePayment.new(UNIT_COST)
	)
	return engine.validate(deploy)
