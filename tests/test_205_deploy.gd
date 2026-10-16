# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## Déploiement : annonce, paiement et résolution (ruleset 0.31, section 205.1 ; 208.1.1,
## 208.1.8, 208.1.9, 203.3.2, 203.3.3).

const UNIT_ID: StringName = &"deploy_unit"
const STRONG_ENEMY_ID: StringName = &"strong_enemy"
const WEAK_ENEMY_ID: StringName = &"weak_enemy"
const BUILDING_ID: StringName = &"deploy_building"
const SPELL_ID: StringName = &"sample_spell"
const UNIT_COST: int = 2  # CatalogSamples.unit()
const BUILDING_COST: int = 3  # CatalogSamples.building()
const UNIT_FORCE: int = 3
const HAND_LIMIT: int = 7  # 201.3.4

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const REASON := IntentRejected.RejectReason

var _builder: DuelStateBuilder
var _engine: DuelEngine


func before_test() -> void:
	var catalog := Catalog.new()
	SetupSamples.add_unit(catalog, UNIT_ID, UNIT_FORCE)
	SetupSamples.add_unit(catalog, STRONG_ENEMY_ID, UNIT_FORCE + 2)
	SetupSamples.add_unit(catalog, WEAK_ENEMY_ID, UNIT_FORCE - 2)
	SetupSamples.add_building(catalog, BUILDING_ID, 4)
	catalog.add_card(CardDefinition.from_dict(CatalogSamples.spell()))
	_builder = DuelStateBuilder.new(DuelConfig.new(), catalog)
	_builder.with_sources_in_play(A, BUILDING_COST, 0)
	_engine = DuelEngine.new(catalog)


func test_208_1_1_deploy_is_announced_on_the_stack() -> void:
	var card_id := _builder.add_to_hand(A, UNIT_ID)
	_start()
	var events := _engine.submit(_deploy(card_id, "B1"))
	var expected := EventLog.repeat("SourceInclined:A", UNIT_COST)
	expected.append_array(["DeployAnnounced:A", "StackEntryAdded:A"])
	assert_array(EventLog.describe(events)).contains_exactly(expected)
	var state := _engine.get_state()
	assert_int(state.stack.size()).is_equal(1)
	assert_int(state.stack[0].kind).is_equal(StackEntry.StackEntryKind.DEPLOY)
	assert_int(state.priority_player).is_equal(B)


func test_201_3_8_announced_card_is_on_the_stack_until_resolution() -> void:
	var card_id := _builder.add_to_hand(A, UNIT_ID)
	_start()
	_engine.submit(_deploy(card_id, "B1"))
	var state := _engine.get_state()
	assert_object(state.get_player(A).find_card_in_hand(card_id)).is_null()
	assert_int(state.stack[0].card.card_instance_id).is_equal(card_id)


func test_205_1_5_cell_chosen_at_announcement() -> void:
	var card_id := _builder.add_to_hand(A, UNIT_ID)
	_start()
	_engine.submit(_deploy(card_id, "D1"))
	assert_array(_engine.get_state().stack[0].target_cells).contains_exactly(
		[DuelStateBuilder.cell("D1")]
	)


func test_203_3_2_cost_paid_at_announcement() -> void:
	var card_id := _builder.add_to_hand(A, UNIT_ID)
	_start()
	_engine.submit(_deploy(card_id, "B1"))
	var player := _engine.get_state().get_player(A)
	assert_int(player.sources_tilted).is_equal(UNIT_COST)
	assert_int(player.sources_upright).is_equal(BUILDING_COST - UNIT_COST)


func test_205_1_2_unit_enters_play_on_free_first_row_cell() -> void:
	var card_id := _builder.add_to_hand(A, UNIT_ID)
	_start()
	_engine.submit(_deploy(card_id, "B1"))
	var labels := _resolve_stack()
	assert_array(labels).contains_exactly(
		["PriorityPassed:B", "PriorityPassed:A", "PieceDeployed:A", "StackEntryResolved:A"]
	)
	var piece := _engine.get_state().piece_at(DuelStateBuilder.cell("B1"))
	assert_int(piece.kind).is_equal(Piece.PieceKind.UNIT)
	assert_int(piece.owner).is_equal(A)
	assert_int(piece.card.card_instance_id).is_equal(card_id)
	assert_array(_engine.get_state().stack).is_empty()


func test_205_1_2_unit_outside_first_row_rejected() -> void:
	var card_id := _builder.add_to_hand(A, UNIT_ID)
	_start()
	_assert_rejected(_deploy(card_id, "B2"), REASON.CELL_NOT_IN_DEPLOY_ZONE)


func test_205_1_2_occupied_cell_rejected_at_announcement() -> void:
	var card_id := _builder.add_to_hand(A, UNIT_ID)
	_start()
	_assert_rejected(_deploy(card_id, "C1"), REASON.CELL_NOT_FREE)


func test_205_1_3_building_enters_play_in_second_row() -> void:
	var card_id := _builder.add_to_hand(A, BUILDING_ID)
	_start()
	_engine.submit(_deploy(card_id, "D2", BUILDING_COST))
	_resolve_stack()
	var piece := _engine.get_state().piece_at(DuelStateBuilder.cell("D2"))
	assert_int(piece.kind).is_equal(Piece.PieceKind.BUILDING)


func test_205_1_4_no_deploy_in_central_row() -> void:
	var building_id := _builder.add_to_hand(A, BUILDING_ID)
	var unit_id := _builder.add_to_hand(A, UNIT_ID)
	_start()
	_assert_rejected(_deploy(building_id, "C3", BUILDING_COST), REASON.CELL_NOT_IN_DEPLOY_ZONE)
	_assert_rejected(_deploy(unit_id, "A3"), REASON.CELL_NOT_IN_DEPLOY_ZONE)


func test_205_1_6_unit_enters_attacking_enemy_on_its_cell() -> void:
	var card := _builder.make_card_instance(A, UNIT_ID)
	var enemy_id := _place(B, WEAK_ENEMY_ID, "B1")
	_builder.push_deploy(card, DuelStateBuilder.cell("B1"))
	_start()
	var labels := _resolve_stack()
	assert_array(labels).contains(["PieceEnteredAttacking:A", "CombatResolved", "PieceDestroyed:B"])
	var state := _engine.get_state()
	assert_object(state.find_piece(enemy_id)).is_null()
	assert_int(state.piece_at(DuelStateBuilder.cell("B1")).owner).is_equal(A)


func test_205_1_6_unit_entering_against_stronger_enemy_is_destroyed() -> void:
	var card := _builder.make_card_instance(A, UNIT_ID)
	_place(B, STRONG_ENEMY_ID, "B1")
	_builder.push_deploy(card, DuelStateBuilder.cell("B1"))
	_start()
	_resolve_stack()
	var state := _engine.get_state()
	assert_int(state.piece_at(DuelStateBuilder.cell("B1")).owner).is_equal(B)
	assert_int(state.get_player(A).discard[0].card_instance_id).is_equal(card.card_instance_id)


func test_205_1_7_allied_piece_on_cell_returns_card_to_hand() -> void:
	var card := _builder.make_card_instance(A, UNIT_ID)
	_place(A, WEAK_ENEMY_ID, "B1")
	_builder.push_deploy(card, DuelStateBuilder.cell("B1"))
	_start()
	assert_array(_resolve_stack()).contains(["CardReturnedToHand:A"])
	(
		assert_object(_engine.get_state().get_player(A).find_card_in_hand(card.card_instance_id))
		. is_not_null()
	)


func test_205_1_8_occupied_building_cell_returns_card_to_hand() -> void:
	var card := _builder.make_card_instance(A, BUILDING_ID)
	_place(B, WEAK_ENEMY_ID, "B2")
	_builder.push_deploy(card, DuelStateBuilder.cell("B2"))
	_start()
	assert_array(_resolve_stack()).contains(["CardReturnedToHand:A"])


func test_205_1_9_essence_of_returned_deploy_is_lost() -> void:
	var card_id := _builder.add_to_hand(A, UNIT_ID)
	_start()
	_engine.submit(_deploy(card_id, "B1"))
	_place_on_live_state(A, WEAK_ENEMY_ID, "B1")
	_resolve_stack()
	var player := _engine.get_state().get_player(A)
	assert_object(player.find_card_in_hand(card_id)).is_not_null()
	assert_int(player.sources_tilted).is_equal(UNIT_COST)


func test_203_3_3_essence_stays_spent_when_deploy_does_not_happen() -> void:
	var card_id := _builder.add_to_hand(A, BUILDING_ID)
	_start()
	_engine.submit(_deploy(card_id, "B2", BUILDING_COST))
	_place_on_live_state(B, WEAK_ENEMY_ID, "B2")
	_resolve_stack()
	assert_int(_engine.get_state().get_player(A).sources_upright).is_equal(0)


func test_205_1_10_returning_card_goes_to_discard_when_hand_is_full() -> void:
	for index: int in HAND_LIMIT:
		_builder.add_to_hand(A, SPELL_ID)
	var card := _builder.make_card_instance(A, UNIT_ID)
	_place(A, WEAK_ENEMY_ID, "B1")
	_builder.push_deploy(card, DuelStateBuilder.cell("B1"))
	_start()
	assert_array(_resolve_stack()).contains(["CardDiscarded:A"])
	var discard := _engine.get_state().get_player(A).discard
	assert_int(discard[discard.size() - 1].card_instance_id).is_equal(card.card_instance_id)


func test_205_1_1_player_deploys_as_many_cards_as_he_can_pay() -> void:
	_builder.with_sources_in_play(A, UNIT_COST * 2, 0)
	var first_id := _builder.add_to_hand(A, UNIT_ID)
	var second_id := _builder.add_to_hand(A, UNIT_ID)
	_start()
	_engine.submit(_deploy(first_id, "A1"))
	_resolve_stack()
	assert_int(_engine.validate(_deploy(second_id, "B1"))).is_equal(REASON.NONE)
	_engine.submit(_deploy(second_id, "B1"))
	_resolve_stack()
	assert_int(_engine.get_state().pieces.size()).is_equal(4)


func test_208_1_8_deploy_only_during_own_main_phase() -> void:
	var card_id := _builder.add_to_hand(B, UNIT_ID)
	var own_card_id := _builder.add_to_hand(A, UNIT_ID)
	_start()
	_assert_rejected(DeployCard.new(B, card_id, DuelStateBuilder.cell("B5")), REASON.NOT_YOUR_TURN)
	_engine.get_state().phase = DuelState.DuelPhase.TURN_END
	_assert_rejected(_deploy(own_card_id, "B1"), REASON.WRONG_PHASE)


func test_208_1_9_deploy_only_with_empty_stack() -> void:
	var card_id := _builder.add_to_hand(A, UNIT_ID)
	_builder.push_spell(_builder.make_card_instance(B, SPELL_ID))
	_start()
	_assert_rejected(_deploy(card_id, "B1"), REASON.STACK_NOT_EMPTY)


func test_deploy_card_must_be_in_hand() -> void:
	_builder.add_to_deck(A, UNIT_ID)
	_start()
	var deck_card_id := _engine.get_state().get_player(A).deck[0].card_instance_id
	_assert_rejected(_deploy(deck_card_id, "B1"), REASON.CARD_NOT_IN_HAND)


func test_202_2_5_spell_cannot_be_deployed() -> void:
	var card_id := _builder.add_to_hand(A, SPELL_ID)
	_start()
	_assert_rejected(_deploy(card_id, "B1", 1), REASON.NOT_DEPLOYABLE)


func test_203_3_1_deploy_payment_must_match_cost() -> void:
	var card_id := _builder.add_to_hand(A, UNIT_ID)
	_start()
	_assert_rejected(_deploy(card_id, "B1", UNIT_COST - 1), REASON.PAYMENT_DOES_NOT_MATCH_COST)


func _start() -> void:
	_engine.start_from_state(_builder.build())


func _deploy(card_id: int, cell_name: String, cost: int = UNIT_COST) -> DeployCard:
	return DeployCard.new(A, card_id, DuelStateBuilder.cell(cell_name), EssencePayment.new(cost))


## Les deux joueurs passent : la pile se résout. Renvoie les événements décrits.
func _resolve_stack() -> Array[String]:
	var state := _engine.get_state()
	var first := state.priority_player
	var events := _engine.submit(PassPriority.new(first))
	events.append_array(_engine.submit(PassPriority.new(DuelState.opponent_of(first))))
	return EventLog.describe(events)


func _place(side: DuelState.PlayerSide, definition_id: StringName, cell_name: String) -> int:
	return _builder.place_piece(
		side, Piece.PieceKind.UNIT, DuelStateBuilder.cell(cell_name), definition_id
	)


## Simule une pièce arrivée entre l'annonce et la résolution (Spell de l'étape 1.6).
func _place_on_live_state(
	side: DuelState.PlayerSide, definition_id: StringName, cell_name: String
) -> void:
	var state := _engine.get_state()
	var card := CardInstance.new()
	card.card_instance_id = state.allocate_card_instance_id()
	card.definition_id = definition_id
	card.owner = side
	var piece := Piece.new()
	piece.piece_id = state.allocate_piece_id()
	piece.kind = Piece.PieceKind.UNIT
	piece.owner = side
	piece.cell = DuelStateBuilder.cell(cell_name)
	piece.card = card
	state.pieces.append(piece)


func _assert_rejected(intent: DuelIntent, expected: IntentRejected.RejectReason) -> void:
	assert_array(DuelChecks.rejection_defects(_engine, intent, expected)).is_empty()
