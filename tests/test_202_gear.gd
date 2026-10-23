# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## Gear (ruleset 0.42, section 202.2 ; 208.1.5 à 208.1.7 ; décision de design 0207 : l'annonce
## d'un Gear est sans réponse, 208.7.6, donc résolue dans la même soumission ; décision de
## design 0208 : le Hero n'a pas de pouvoir).

const UNIT_ID: StringName = &"gear_unit"
const BUILDING_ID: StringName = &"gear_building"
const GEAR_ID: StringName = &"sample_gear"
const SPELL_ID: StringName = &"sample_spell"
const UNIT_FORCE: int = 3
const GEAR_BONUS: int = 1  # CatalogSamples.gear()
const GEAR_COST: int = 1
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
	_builder = DuelStateBuilder.new(DuelConfig.new(), catalog)
	_builder.with_sources_in_play(A, 4, 0)
	_engine = DuelEngine.new(catalog)


func test_208_1_5_gear_is_announced_on_the_stack() -> void:
	var unit_id := _place(A, "B2")
	var gear_id := _builder.add_to_hand(A, GEAR_ID)
	_start()
	var events := _engine.submit(_attach(gear_id, unit_id))
	assert_array(EventLog.describe(events)).contains_exactly(
		[
			"SourceInclined:A",
			"GearAnnounced:A",
			"StackEntryAdded:A",
			"GearAttached:A",
			"StackEntryResolved:A"
		]
	)
	assert_array(_engine.get_state().stack).is_empty()


func test_202_2_22_unit_chosen_when_gear_is_announced() -> void:
	var unit_id := _place(A, "B2")
	var gear_id := _builder.add_to_hand(A, GEAR_ID)
	_start()
	var events := _engine.submit(_attach(gear_id, unit_id))
	assert_int((events[1] as GearAnnounced).piece_id).is_equal(unit_id)
	assert_int(_engine.get_state().find_piece(unit_id).attached_gear.card_instance_id).is_equal(
		gear_id
	)


func test_202_2_6_gear_attaches_to_its_unit() -> void:
	var unit_id := _place(A, "B2")
	var gear_id := _builder.add_to_hand(A, GEAR_ID)
	_start()
	var events := _engine.submit(_attach(gear_id, unit_id))
	assert_array(EventLog.describe(events)).contains(["GearAttached:A"])
	var unit := _engine.get_state().find_piece(unit_id)
	assert_int(unit.attached_gear.card_instance_id).is_equal(gear_id)


func test_207_2_3a_gear_effect_starts_when_attached() -> void:
	var unit_id := _place(A, "B2")
	var gear_id := _builder.add_to_hand(A, GEAR_ID)
	_start()
	assert_int(_force(unit_id)).is_equal(UNIT_FORCE)
	_engine.submit(_attach(gear_id, unit_id))
	assert_int(_force(unit_id)).is_equal(UNIT_FORCE + GEAR_BONUS)


func test_202_2_11_new_gear_replaces_the_old_one() -> void:
	var unit_id := _place(A, "B2")
	var old_gear_id := _builder.attach_gear(unit_id, GEAR_ID)
	var gear_id := _builder.add_to_hand(A, GEAR_ID)
	_start()
	_engine.submit(_attach(gear_id, unit_id))
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
	var events := _engine.submit(_attach(gear_id, unit_id))
	assert_array(EventLog.describe(events)).contains(["CardDiscarded:A", "GearAttached:A"])


func test_202_2_10_unit_carries_at_most_one_gear() -> void:
	var unit_id := _place(A, "B2")
	_builder.attach_gear(unit_id, GEAR_ID)
	var gear_id := _builder.add_to_hand(A, GEAR_ID)
	_start()
	_engine.submit(_attach(gear_id, unit_id))
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
	_push_gear(unit_id)
	_start()
	var state := _engine.get_state()
	state.pieces.erase(state.find_piece(unit_id))
	assert_array(_resolve_stack()).not_contains(["GearAttached:A"])


func test_202_2_24a_gear_not_attached_returns_to_hand() -> void:
	var unit_id := _place(A, "B2")
	var gear_id := _push_gear(unit_id)
	_start()
	var state := _engine.get_state()
	state.pieces.erase(state.find_piece(unit_id))
	assert_array(_resolve_stack()).contains(["CardReturnedToHand:A"])
	assert_object(state.get_player(A).find_card_in_hand(gear_id)).is_not_null()


func test_202_2_24b_gear_goes_to_discard_when_hand_is_full() -> void:
	var unit_id := _place(A, "B2")
	_push_gear(unit_id)
	_start()
	var state := _engine.get_state()
	state.pieces.erase(state.find_piece(unit_id))
	for index: int in HAND_LIMIT:
		state.get_player(A).hand.append(_builder.make_card_instance(A, SPELL_ID))
	assert_array(_resolve_stack()).contains(["CardDiscarded:A"])


func test_202_2_24c_essence_of_unattached_gear_stays_spent() -> void:
	_builder.with_sources_in_play(A, 3, GEAR_COST)
	var unit_id := _place(A, "B2")
	_push_gear(unit_id)
	_start()
	var state := _engine.get_state()
	state.pieces.erase(state.find_piece(unit_id))
	_resolve_stack()
	assert_int(state.get_player(A).sources_tilted).is_equal(GEAR_COST)


func _start() -> void:
	_engine.start_from_state(_builder.build())


func _attach(gear_id: int, unit_id: int) -> AttachGear:
	return AttachGear.new(A, gear_id, unit_id, EssencePayment.new(GEAR_COST))


## Gear annoncé et payé à la main, puis posé sur la pile : une entrée construite ainsi garde
## l'étiquette par défaut, avec réponse, et se résout par la passe du joueur qui a la priorité.
func _push_gear(unit_id: int) -> int:
	var entry := StackEntry.new()
	entry.kind = StackEntry.StackEntryKind.ATTACH_GEAR
	entry.owner = A
	entry.card = _builder.make_card_instance(A, GEAR_ID)
	entry.target_piece_ids.append(unit_id)
	_builder.push_stack_entry(entry)
	return entry.card.card_instance_id


## Le joueur qui a la priorité passe : la pile construite à la main se résout. Renvoie les
## événements décrits.
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
