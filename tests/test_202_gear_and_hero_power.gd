# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## Gear et pouvoir du Hero (ruleset 0.32, sections 202.2 et 202.3 ; 207.5.17, 208.1.4 à
## 208.1.7).

const UNIT_ID: StringName = &"gear_unit"
const BUILDING_ID: StringName = &"gear_building"
const GEAR_ID: StringName = &"sample_gear"
const HERO_ID: StringName = &"sample_hero"
const SPELL_ID: StringName = &"sample_spell"
const UNIT_FORCE: int = 3
const GEAR_BONUS: int = 1  # CatalogSamples.gear()
const GEAR_COST: int = 1
const POWER_COST: int = 2  # CatalogSamples.hero()
const POWER_BONUS: int = 1
const HAND_LIMIT: int = 7  # 201.3.4
const BUILDING_FORCE: int = 4
const TOKEN_FORCE: int = 1

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const REASON := IntentRejected.RejectReason

var _builder: DuelStateBuilder
var _engine: DuelEngine


func before_test() -> void:
	var catalog := Catalog.new()
	SetupSamples.add_unit(catalog, UNIT_ID, UNIT_FORCE)
	SetupSamples.add_building(catalog, BUILDING_ID, BUILDING_FORCE)
	catalog.add_card(CardDefinition.from_dict(CatalogSamples.gear()))
	catalog.add_card(CardDefinition.from_dict(CatalogSamples.spell()))
	catalog.add_hero(HeroDefinition.from_dict(CatalogSamples.hero()))
	_builder = DuelStateBuilder.new(DuelConfig.new(), catalog)
	_builder.with_sources_in_play(A, 4, 0)
	_engine = DuelEngine.new(catalog)


func test_208_1_5_gear_is_announced_on_the_stack() -> void:
	var unit_id := _place(A, "B2")
	var gear_id := _builder.add_to_hand(A, GEAR_ID)
	_start()
	var events := _engine.submit(_attach(gear_id, unit_id))
	assert_array(EventLog.describe(events)).contains_exactly(
		["SourceInclined:A", "GearAnnounced:A", "StackEntryAdded:A"]
	)
	assert_int(_engine.get_state().stack[0].kind).is_equal(StackEntry.StackEntryKind.ATTACH_GEAR)


func test_202_2_22_unit_chosen_when_gear_is_announced() -> void:
	var unit_id := _place(A, "B2")
	var gear_id := _builder.add_to_hand(A, GEAR_ID)
	_start()
	_engine.submit(_attach(gear_id, unit_id))
	assert_array(_engine.get_state().stack[0].target_piece_ids).contains_exactly([unit_id])


func test_202_2_6_gear_attaches_to_its_unit() -> void:
	var unit_id := _place(A, "B2")
	var gear_id := _builder.add_to_hand(A, GEAR_ID)
	_start()
	_engine.submit(_attach(gear_id, unit_id))
	assert_array(_resolve_stack()).contains(["GearAttached:A"])
	var unit := _engine.get_state().find_piece(unit_id)
	assert_int(unit.attached_gear.card_instance_id).is_equal(gear_id)


func test_207_2_3a_gear_effect_starts_when_attached() -> void:
	var unit_id := _place(A, "B2")
	var gear_id := _builder.add_to_hand(A, GEAR_ID)
	_start()
	_engine.submit(_attach(gear_id, unit_id))
	assert_int(_force(unit_id)).is_equal(UNIT_FORCE)
	_resolve_stack()
	assert_int(_force(unit_id)).is_equal(UNIT_FORCE + GEAR_BONUS)


func test_202_2_11_new_gear_replaces_the_old_one() -> void:
	var unit_id := _place(A, "B2")
	var old_gear_id := _builder.attach_gear(unit_id, GEAR_ID)
	var gear_id := _builder.add_to_hand(A, GEAR_ID)
	_start()
	_engine.submit(_attach(gear_id, unit_id))
	_resolve_stack()
	assert_int(_engine.get_state().find_piece(unit_id).attached_gear.card_instance_id).is_equal(
		gear_id
	)
	assert_int(_force(unit_id)).is_equal(UNIT_FORCE + GEAR_BONUS)
	assert_array(DuelChecks.card_ids(_engine.get_state().get_player(A).discard)).contains(
		[old_gear_id]
	)


func test_202_2_12_replaced_gear_goes_to_discard() -> void:
	var unit_id := _place(A, "B2")
	_builder.attach_gear(unit_id, GEAR_ID)
	var gear_id := _builder.add_to_hand(A, GEAR_ID)
	_start()
	_engine.submit(_attach(gear_id, unit_id))
	assert_array(_resolve_stack()).contains(["CardDiscarded:A", "GearAttached:A"])


func test_202_2_10_unit_carries_at_most_one_gear() -> void:
	var unit_id := _place(A, "B2")
	_builder.attach_gear(unit_id, GEAR_ID)
	var gear_id := _builder.add_to_hand(A, GEAR_ID)
	_start()
	_engine.submit(_attach(gear_id, unit_id))
	_resolve_stack()
	assert_int(_force(unit_id)).is_equal(UNIT_FORCE + GEAR_BONUS)


func test_202_2_14_gear_only_on_own_unit() -> void:
	var enemy_id := _place(B, "B4")
	var gear_id := _builder.add_to_hand(A, GEAR_ID)
	_start()
	_assert_rejected(_attach(gear_id, enemy_id), REASON.ILLEGAL_TARGET)


func test_202_2_8_gear_only_on_a_unit() -> void:
	var building_id := _builder.place_piece(
		A, Piece.PieceKind.BUILDING, DuelStateBuilder.cell("B2"), BUILDING_ID
	)
	var gear_id := _builder.add_to_hand(A, GEAR_ID)
	_start()
	_assert_rejected(_attach(gear_id, building_id), REASON.ILLEGAL_TARGET)


func test_202_2_9_gear_never_on_the_hero() -> void:
	var gear_id := _builder.add_to_hand(A, GEAR_ID)
	_start()
	var hero_id := _engine.get_state().find_hero(A).piece_id
	_assert_rejected(_attach(gear_id, hero_id), REASON.ILLEGAL_TARGET)


func test_202_4_5a_gear_can_be_attached_to_a_unit_token() -> void:
	var token_id := _builder.place_token(
		A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B2"), TOKEN_FORCE
	)
	var gear_id := _builder.add_to_hand(A, GEAR_ID)
	_start()
	_engine.submit(_attach(gear_id, token_id))
	_resolve_stack()
	assert_int(_force(token_id)).is_equal(TOKEN_FORCE + GEAR_BONUS)


func test_208_1_6_gear_only_during_own_main_phase() -> void:
	var unit_id := _place(B, "B4")
	var gear_id := _builder.add_to_hand(B, GEAR_ID)
	_start()
	var intent := AttachGear.new(B, gear_id, unit_id, EssencePayment.new(GEAR_COST))
	_assert_rejected(intent, REASON.NOT_YOUR_TURN)


func test_208_1_6_gear_outside_main_phase_rejected() -> void:
	var unit_id := _place(A, "B2")
	var gear_id := _builder.add_to_hand(A, GEAR_ID)
	_builder.with_phase(DuelState.DuelPhase.TURN_END)
	_start()
	_assert_rejected(_attach(gear_id, unit_id), REASON.WRONG_PHASE)


func test_208_1_7_gear_only_with_empty_stack() -> void:
	var unit_id := _place(A, "B2")
	var gear_id := _builder.add_to_hand(A, GEAR_ID)
	_builder.push_spell(_builder.make_card_instance(B, SPELL_ID))
	_start()
	_assert_rejected(_attach(gear_id, unit_id), REASON.STACK_NOT_EMPTY)


func test_208_1_5_only_a_gear_card_is_attached() -> void:
	var unit_id := _place(A, "B2")
	var card_id := _builder.add_to_hand(A, UNIT_ID)
	_start()
	_assert_rejected(_attach(card_id, unit_id), REASON.NOT_A_GEAR)


func test_202_2_24_gear_not_attached_when_unit_is_gone() -> void:
	var unit_id := _place(A, "B2")
	var gear_id := _builder.add_to_hand(A, GEAR_ID)
	_start()
	_engine.submit(_attach(gear_id, unit_id))
	var state := _engine.get_state()
	state.pieces.erase(state.find_piece(unit_id))
	assert_array(_resolve_stack()).not_contains(["GearAttached:A"])


func test_202_2_24a_gear_not_attached_returns_to_hand() -> void:
	var unit_id := _place(A, "B2")
	var gear_id := _builder.add_to_hand(A, GEAR_ID)
	_start()
	_engine.submit(_attach(gear_id, unit_id))
	var state := _engine.get_state()
	state.pieces.erase(state.find_piece(unit_id))
	assert_array(_resolve_stack()).contains(["CardReturnedToHand:A"])
	assert_object(state.get_player(A).find_card_in_hand(gear_id)).is_not_null()


func test_202_2_24b_gear_goes_to_discard_when_hand_is_full() -> void:
	var unit_id := _place(A, "B2")
	var gear_id := _builder.add_to_hand(A, GEAR_ID)
	_start()
	_engine.submit(_attach(gear_id, unit_id))
	var state := _engine.get_state()
	state.pieces.erase(state.find_piece(unit_id))
	for index: int in HAND_LIMIT:
		state.get_player(A).hand.append(_builder.make_card_instance(A, SPELL_ID))
	assert_array(_resolve_stack()).contains(["CardDiscarded:A"])


func test_202_2_24c_essence_of_unattached_gear_stays_spent() -> void:
	var unit_id := _place(A, "B2")
	var gear_id := _builder.add_to_hand(A, GEAR_ID)
	_start()
	_engine.submit(_attach(gear_id, unit_id))
	var state := _engine.get_state()
	state.pieces.erase(state.find_piece(unit_id))
	_resolve_stack()
	assert_int(state.get_player(A).sources_tilted).is_equal(GEAR_COST)


func test_208_1_4_hero_power_is_announced_on_the_stack() -> void:
	var unit_id := _place(A, "B2")
	_start_with_sample_hero()
	var events := _engine.submit(_power([unit_id] as Array[int]))
	var expected := EventLog.repeat("SourceInclined:A", POWER_COST)
	expected.append_array(["HeroPowerAnnounced:A", "StackEntryAdded:A"])
	assert_array(EventLog.describe(events)).contains_exactly(expected)
	assert_int(_engine.get_state().stack[0].kind).is_equal(StackEntry.StackEntryKind.HERO_POWER)


func test_202_3_13_hero_power_costs_its_card_value() -> void:
	var unit_id := _place(A, "B2")
	_start_with_sample_hero()
	var cheap := UseHeroPower.new(A, EssencePayment.new(POWER_COST - 1))
	cheap.target_piece_ids.append(unit_id)
	_assert_rejected(cheap, REASON.PAYMENT_DOES_NOT_MATCH_COST)


func test_202_3_12_hero_power_applies_its_effect() -> void:
	var unit_id := _place(A, "B2")
	_start_with_sample_hero()
	_engine.submit(_power([unit_id] as Array[int]))
	assert_array(_resolve_stack()).contains(["ForceModified:A"])
	assert_int(_force(unit_id)).is_equal(UNIT_FORCE + POWER_BONUS)


func test_202_3_14_hero_power_once_per_turn() -> void:
	var unit_id := _place(A, "B2")
	_start_with_sample_hero()
	_engine.submit(_power([unit_id] as Array[int]))
	_resolve_stack()
	_assert_rejected(_power([unit_id] as Array[int]), REASON.HERO_POWER_ALREADY_USED)


func test_202_3_17_hero_power_counts_from_announcement() -> void:
	var unit_id := _place(A, "B2")
	_start_with_sample_hero()
	_engine.submit(_power([unit_id] as Array[int]))
	assert_bool(_engine.get_state().get_player(A).hero_power_used_this_turn).is_true()


func test_202_3_15_hero_power_only_during_own_main_phase() -> void:
	var unit_id := _place(B, "B4")
	_builder.with_sources_in_play(B, 4, 0)
	_start_with_sample_hero()
	var intent := UseHeroPower.new(B, EssencePayment.new(POWER_COST))
	intent.target_piece_ids.append(unit_id)
	_assert_rejected(intent, REASON.NOT_YOUR_TURN)


func test_202_3_15_hero_power_outside_main_phase_rejected() -> void:
	var unit_id := _place(A, "B2")
	_builder.with_phase(DuelState.DuelPhase.TURN_END)
	_start_with_sample_hero()
	_assert_rejected(_power([unit_id] as Array[int]), REASON.WRONG_PHASE)


func test_207_5_1_hero_power_with_target_its_effect_does_not_ask_rejected() -> void:
	var unit_id := _place(A, "B2")
	_start_with_sample_hero()
	var intent := _power([unit_id] as Array[int])
	intent.target_cells.append(DuelStateBuilder.cell("B1"))
	_assert_rejected(intent, REASON.WRONG_TARGET_COUNT)


func test_202_3_16_hero_power_only_with_empty_stack() -> void:
	var unit_id := _place(A, "B2")
	_builder.push_spell(_builder.make_card_instance(B, SPELL_ID))
	_start_with_sample_hero()
	_assert_rejected(_power([unit_id] as Array[int]), REASON.STACK_NOT_EMPTY)


func test_207_5_17_hero_power_announced_without_legal_target() -> void:
	_start_with_sample_hero()
	var events := _engine.submit(_power([] as Array[int]))
	assert_array(EventLog.describe(events)).contains(["HeroPowerAnnounced:A"])


func test_207_5_17a_hero_power_without_target_does_not_happen() -> void:
	_start_with_sample_hero()
	_engine.submit(_power([] as Array[int]))
	var labels := _resolve_stack()
	assert_array(labels).contains(["EffectLostAllTargets:A"])
	assert_array(_engine.get_state().active_effects).is_empty()


func test_207_5_17b_hero_power_cost_stays_spent() -> void:
	_start_with_sample_hero()
	_engine.submit(_power([] as Array[int]))
	_resolve_stack()
	assert_int(_engine.get_state().get_player(A).sources_tilted).is_equal(POWER_COST)


func test_207_5_17c_hero_power_without_target_counts_for_the_turn() -> void:
	var unit_id := _place(A, "B2")
	_start_with_sample_hero()
	var state := _engine.get_state()
	state.pieces.erase(state.find_piece(unit_id))
	_engine.submit(_power([] as Array[int]))
	_resolve_stack()
	DuelStateBuilder.place_unit_in(state, A, UNIT_ID, "D2")
	_assert_rejected(_power([] as Array[int]), REASON.HERO_POWER_ALREADY_USED)


func test_207_5_10_hero_power_needs_a_target_when_one_is_legal() -> void:
	_place(A, "B2")
	_start_with_sample_hero()
	_assert_rejected(_power([] as Array[int]), REASON.WRONG_TARGET_COUNT)


func _start() -> void:
	_engine.start_from_state(_builder.build())


func _start_with_sample_hero() -> void:
	for side: DuelState.PlayerSide in [A, B]:
		_builder.with_hero_definition(side, HERO_ID)
	_start()


func _attach(gear_id: int, unit_id: int) -> AttachGear:
	return AttachGear.new(A, gear_id, unit_id, EssencePayment.new(GEAR_COST))


func _power(target_ids: Array[int]) -> UseHeroPower:
	var intent := UseHeroPower.new(A, EssencePayment.new(POWER_COST))
	intent.target_piece_ids.assign(target_ids)
	return intent


## Le joueur qui a la priorité passe : la pile se résout. Renvoie les événements décrits.
func _resolve_stack() -> Array[String]:
	var first := _engine.get_state().priority_player
	var events := DuelChecks.pass_once(_engine, first)
	return EventLog.describe(events)


func _place(side: DuelState.PlayerSide, cell_name: String) -> int:
	return _builder.place_piece(
		side, Piece.PieceKind.UNIT, DuelStateBuilder.cell(cell_name), UNIT_ID
	)


func _force(piece_id: int) -> int:
	var state := _engine.get_state()
	return ForceRules.current_force(state, state.find_piece(piece_id))


func _assert_rejected(intent: DuelIntent, expected: IntentRejected.RejectReason) -> void:
	assert_array(DuelChecks.rejection_defects(_engine, intent, expected)).is_empty()
