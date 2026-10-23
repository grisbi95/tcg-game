# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## Combat en attente (ruleset 0.41, section 205.6 ; 205.1.6, 205.2.3a, 208.3.2b, 208.7.14 ;
## décision de design 0207 du ruleset, décision 0046).
##
## Aucun effet n'est déclenché par une annonce : une case libre à l'annonce ne se remplit pas avant
## la résolution. Les annonces sans réponse dont la case est occupée à la résolution se posent donc
## à la main sur la pile, avec leur étiquette (`push_deploy`, `push_normal_action`), et le moteur
## les résout à la soumission qui suit (`_settle`).

const UNIT_ID: StringName = &"pending_unit"
const WEAK_ID: StringName = &"pending_weak"
const UNIT_FORCE: int = 4
const WEAK_FORCE: int = 1
const REACTION_ID: StringName = ResponseWindowSamples.REACTION_ID
const REACTION_COST: int = ResponseWindowSamples.REACTION_COST

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const REASON := IntentRejected.RejectReason
const KIND := StackEntry.StackEntryKind

var _builder: DuelStateBuilder
var _engine: DuelEngine


func before_test() -> void:
	var catalog := ResponseWindowSamples.catalog_with_reaction(REACTION_ID)
	SetupSamples.add_unit(catalog, UNIT_ID, UNIT_FORCE)
	SetupSamples.add_unit(catalog, WEAK_ID, WEAK_FORCE)
	_builder = DuelStateBuilder.new(DuelConfig.new(), catalog)
	_engine = DuelEngine.new(catalog)


func test_205_6_1_action_announced_to_a_free_cell_then_occupied_is_a_pending_combat() -> void:
	_push_action("B2", "B3")
	_start()
	(
		assert_array(EventLog.describe(_settle()))
		. contains_exactly(
			[
				"SourceInclined:A",
				"EssenceProduced:A",
				"CombatPutOnHold:A",
				"StackEntryResolved:A",
				"DecisionResolvedAutomatically:A",
				"StackEntryAdded:A",
			]
		)
	)


func test_205_6_1_deploy_on_an_occupied_cell_is_a_pending_combat() -> void:
	_push_deploy("B1")
	_start()
	(
		assert_array(EventLog.describe(_settle()))
		. contains_exactly(
			[
				"SourceInclined:A",
				"EssenceProduced:A",
				"CombatPutOnHold:A",
				"StackEntryResolved:A",
				"DecisionResolvedAutomatically:A",
				"StackEntryAdded:A",
			]
		)
	)


func test_205_2_3a_attack_on_a_cell_announced_free_is_a_pending_combat() -> void:
	var unit_id := _push_action("B2", "B3")
	_start()
	var events := _settle()
	var held := _first_of(events, CombatPutOnHold) as CombatPutOnHold
	assert_int(held.piece_id).is_equal(unit_id)
	assert_object(_engine.get_state().stack[0]).is_not_null()
	assert_int(_engine.get_state().stack[0].kind).is_equal(KIND.PENDING_COMBAT)
	assert_bool(EventLog.describe(events).has("CombatResolved")).is_false()


func test_205_6_2_pending_combat_does_not_happen_during_the_resolution() -> void:
	var unit_id := _push_action("B2", "B3")
	var enemy_id := _enemy_id()
	_start()
	var labels := EventLog.describe(_settle())
	assert_array(labels).not_contains(["CombatResolved", "PieceDestroyed:B", "PieceMoved:A"])
	assert_str(_cell_of(unit_id)).is_equal("B2")
	assert_object(_engine.get_state().find_piece(enemy_id)).is_not_null()


func test_205_6_3_pending_combat_waits_for_the_end_of_the_resolution() -> void:
	_push_action("B2", "B3")
	_start()
	var state := _engine.get_state()
	var entry: StackEntry = state.stack.pop_back()
	var events: Array[DuelEvent] = []
	ActionRules.resolve_normal_action(state, entry, events)
	assert_array(state.stack).is_empty()
	assert_int(state.waiting_triggers.size()).is_equal(1)
	assert_int(state.waiting_triggers[0].kind).is_equal(KIND.PENDING_COMBAT)


func test_205_6_4_pending_combat_goes_on_the_stack_before_the_active_player_acts() -> void:
	_push_action("B2", "B3")
	_start()
	_settle()
	var state := _engine.get_state()
	assert_int(state.stack.size()).is_equal(1)
	assert_int(state.stack[0].kind).is_equal(KIND.PENDING_COMBAT)
	assert_int(state.priority_player).is_equal(B)
	assert_int(_engine.validate(EndTurn.new(A))).is_equal(REASON.STACK_NOT_EMPTY)


func test_205_6_5_pending_combat_belongs_to_the_player_of_the_attacker() -> void:
	_push_action("B2", "B3")
	_start()
	_settle()
	assert_int(_engine.get_state().stack[0].owner).is_equal(A)
	assert_int(_engine.get_state().priority_player).is_equal(B)


func test_205_6_6_pending_combats_of_one_player_are_ordered_like_triggered_effects() -> void:
	_push_action("B2", "B3")
	_push_action("D2", "D3")
	_start()
	var events := _settle()
	var state := _engine.get_state()
	assert_array(EventLog.describe(events).slice(-2)).contains_exactly(
		["StackEntryResolved:A", "DecisionRequested:A"]
	)
	assert_int(state.pending_decision.kind).is_equal(PendingDecision.DecisionKind.ORDER_TRIGGERS)
	assert_int(state.pending_decision.candidate_ids.size()).is_equal(2)
	var second_id := state.pending_decision.candidate_ids[1]
	var first_id := state.pending_decision.candidate_ids[0]
	var ordered := _engine.submit(OrderTriggers.new(A, [second_id, first_id]))
	(
		assert_array(EventLog.describe(ordered))
		. contains_exactly(
			[
				"TriggersOrdered:A",
				"StackEntryAdded:A",
				"StackEntryAdded:A",
			]
		)
	)
	assert_int(state.stack[0].stack_entry_id).is_equal(second_id)
	assert_int(state.stack[1].stack_entry_id).is_equal(first_id)


func test_208_3_2b_pending_combats_resolve_last_added_first_opponent_first() -> void:
	var a_unit := _push_action("B2", "B3")
	var b_unit := _place(B, UNIT_ID, "D4")
	_place(A, WEAK_ID, "D3")
	_builder.with_active_player(A)
	_builder.push_normal_action(b_unit, DuelStateBuilder.cell("D3"), false)
	_start()
	var state := _engine.get_state()
	_settle()
	assert_int(state.stack.size()).is_equal(2)
	assert_int(state.stack[0].owner).is_equal(A)
	assert_int(state.stack[1].owner).is_equal(B)
	var labels := EventLog.describe(_engine.submit(PassPriority.new(state.priority_player)))
	var resolved := labels.filter(
		func(label: String) -> bool: return label.begins_with("StackEntryResolved")
	)
	assert_array(resolved).contains_exactly(["StackEntryResolved:B", "StackEntryResolved:A"])
	assert_str(_cell_of(a_unit)).is_equal("B3")
	assert_array(state.stack).is_empty()


func test_205_6_7_unit_stays_on_its_cell_while_the_combat_waits() -> void:
	var unit_id := _push_action("B2", "B3")
	_start()
	_settle()
	assert_str(_cell_of(unit_id)).is_equal("B2")
	assert_int(_engine.get_state().stack[0].source_piece_id).is_equal(unit_id)


func test_205_6_8_deploying_card_stays_on_the_stack_with_the_combat() -> void:
	var card := _push_deploy("B1")
	_start()
	_settle()
	var state := _engine.get_state()
	assert_int(state.stack[0].card.card_instance_id).is_equal(card.card_instance_id)
	assert_object(state.get_player(A).find_card_in_hand(card.card_instance_id)).is_null()
	assert_array(state.get_player(A).discard).is_empty()
	assert_int(state.pieces.size()).is_equal(3)  # deux Heroes, la pièce ennemie


func test_205_6_9_pending_combat_resolves_on_the_board_of_its_resolution() -> void:
	var unit_id := _push_action("B2", "B3")
	var enemy_id := _enemy_id()
	_start()
	_settle()
	var state := _engine.get_state()
	state.pieces.erase(state.find_piece(enemy_id))
	var labels := EventLog.describe(_engine.submit(PassPriority.new(B)))
	assert_array(labels).not_contains(["CombatResolved"])
	assert_array(labels).contains(["PieceMoved:A"])
	assert_str(_cell_of(unit_id)).is_equal("B3")


func test_205_6_10_unit_gone_at_resolution_cancels_the_combat() -> void:
	var unit_id := _push_action("B2", "B3")
	_start()
	_settle()
	var state := _engine.get_state()
	state.pieces.erase(state.find_piece(unit_id))
	var labels := EventLog.describe(_engine.submit(PassPriority.new(B)))
	assert_array(labels).contains_exactly(["PriorityPassed:B", "StackEntryResolved:A"])


func test_205_6_11_free_cell_at_resolution_moves_the_unit() -> void:
	var unit_id := _push_action("B2", "B3")
	var enemy_id := _enemy_id()
	_start()
	_settle()
	var state := _engine.get_state()
	state.pieces.erase(state.find_piece(enemy_id))
	var labels := EventLog.describe(_engine.submit(PassPriority.new(B)))
	assert_array(labels).contains_exactly(
		["PriorityPassed:B", "PieceMoved:A", "StackEntryResolved:A"]
	)
	assert_str(_cell_of(unit_id)).is_equal("B3")


func test_205_6_12_free_cell_at_resolution_deploys_the_unit() -> void:
	var card := _push_deploy("B1")
	_start()
	_settle()
	var state := _engine.get_state()
	state.pieces.erase(state.piece_at(DuelStateBuilder.cell("B1")))
	var labels := EventLog.describe(_engine.submit(PassPriority.new(B)))
	assert_array(labels).contains_exactly(
		["PriorityPassed:B", "PieceDeployed:A", "StackEntryResolved:A"]
	)
	assert_int(state.piece_at(DuelStateBuilder.cell("B1")).card.card_instance_id).is_equal(
		card.card_instance_id
	)


func test_205_6_13_ally_on_the_cell_at_resolution_fails_the_action() -> void:
	var unit_id := _push_action("B2", "B3")
	var enemy_id := _enemy_id()
	_start()
	_settle()
	var state := _engine.get_state()
	state.pieces.erase(state.find_piece(enemy_id))
	DuelStateBuilder.place_unit_in(state, A, WEAK_ID, "B3")
	var labels := EventLog.describe(_engine.submit(PassPriority.new(B)))
	assert_array(labels).contains_exactly(
		["PriorityPassed:B", "NormalActionFailed:A", "StackEntryResolved:A"]
	)
	assert_str(_cell_of(unit_id)).is_equal("B2")


func test_205_6_14_ally_on_the_cell_at_resolution_returns_the_card_to_hand() -> void:
	var card := _push_deploy("B1")
	_start()
	_settle()
	var state := _engine.get_state()
	state.pieces.erase(state.piece_at(DuelStateBuilder.cell("B1")))
	DuelStateBuilder.place_unit_in(state, A, WEAK_ID, "B1")
	var labels := EventLog.describe(_engine.submit(PassPriority.new(B)))
	assert_array(labels).contains_exactly(
		["PriorityPassed:B", "CardReturnedToHand:A", "StackEntryResolved:A"]
	)
	assert_object(state.get_player(A).find_card_in_hand(card.card_instance_id)).is_not_null()


func test_205_6_15_enemy_on_the_cell_at_resolution_triggers_the_combat() -> void:
	var unit_id := _push_action("B2", "B3")
	var enemy_id := _enemy_id()
	_start()
	_settle()
	var labels := EventLog.describe(_engine.submit(PassPriority.new(B)))
	(
		assert_array(labels)
		. contains_exactly(
			[
				"PriorityPassed:B",
				"CombatResolved",
				"PieceDestroyed:B",
				"PieceMoved:A",
				"StackEntryResolved:A",
			]
		)
	)
	assert_object(_engine.get_state().find_piece(enemy_id)).is_null()
	assert_str(_cell_of(unit_id)).is_equal("B3")


func test_205_6_15_deploying_unit_enters_attacking_the_enemy() -> void:
	var card := _push_deploy("B1")
	_start()
	_settle()
	var labels := EventLog.describe(_engine.submit(PassPriority.new(B)))
	(
		assert_array(labels)
		. contains_exactly(
			[
				"PriorityPassed:B",
				"PieceEnteredAttacking:A",
				"CombatResolved",
				"PieceDestroyed:B",
				"PieceMoved:A",
				"StackEntryResolved:A",
			]
		)
	)
	var piece := _engine.get_state().piece_at(DuelStateBuilder.cell("B1"))
	assert_int(piece.card.card_instance_id).is_equal(card.card_instance_id)
	assert_bool(piece.is_awake).is_false()


func test_205_6_17_cell_no_longer_adjacent_fails_the_action() -> void:
	var unit_id := _push_action("B2", "B3")
	_start()
	_settle()
	_engine.get_state().find_piece(unit_id).cell = DuelStateBuilder.cell("D2")
	var labels := EventLog.describe(_engine.submit(PassPriority.new(B)))
	assert_array(labels).contains_exactly(
		["PriorityPassed:B", "NormalActionFailed:A", "StackEntryResolved:A"]
	)
	assert_str(_cell_of(unit_id)).is_equal("D2")


func test_208_7_14_player_can_answer_a_pending_combat() -> void:
	_push_action("B2", "B3")
	var reaction_id := _builder.add_to_hand(B, REACTION_ID)
	_start()
	_settle()
	var state := _engine.get_state()
	assert_int(_engine.validate(PassPriority.new(B))).is_equal(REASON.NONE)
	var cast := CastSpell.new(B, reaction_id, EssencePayment.new(REACTION_COST))
	assert_int(_engine.validate(cast)).is_equal(REASON.NONE)
	var labels := EventLog.describe(_engine.submit(cast))
	assert_array(labels).contains(["SpellAnnounced:B", "StackEntryAdded:B"])
	assert_int(state.stack.size()).is_equal(2)
	assert_int(state.priority_player).is_equal(A)


# Une Unit de A en `from` annoncée vers une case libre, qu'une Unit ennemie occupe à la résolution
# (en `to`) ; renvoie l'identifiant de l'Unit de A.
func _push_action(from: String, to: String) -> int:
	var unit_id := _place(A, UNIT_ID, from)
	_place(B, WEAK_ID, to)
	_builder.push_normal_action(unit_id, DuelStateBuilder.cell(to), false)
	return unit_id


# Un déploiement de A vers une case libre à l'annonce, qu'une Unit ennemie occupe à la résolution.
func _push_deploy(cell_name: String) -> CardInstance:
	var card := _builder.make_card_instance(A, UNIT_ID)
	_place(B, WEAK_ID, cell_name)
	_builder.push_deploy(card, DuelStateBuilder.cell(cell_name), false)
	return card


func _start() -> void:
	_engine.start_from_state(_builder.build())


# Toute soumission légale résout une pile sans réponse (208.7.13) : A produit de l'Essence.
func _settle() -> Array[DuelEvent]:
	return _engine.submit(ProduceEssence.new(A, EssencePayment.new(1)))


func _enemy_id() -> int:
	for piece: Piece in _builder.build().pieces:
		if piece.owner == B and piece.kind == Piece.PieceKind.UNIT:
			return piece.piece_id
	return DuelState.NO_ID


func _place(side: DuelState.PlayerSide, definition_id: StringName, cell_name: String) -> int:
	return _builder.place_piece(
		side, Piece.PieceKind.UNIT, DuelStateBuilder.cell(cell_name), definition_id
	)


func _cell_of(piece_id: int) -> String:
	return BoardGeometry.cell_name(_engine.get_state().find_piece(piece_id).cell)


func _first_of(events: Array[DuelEvent], event_class: GDScript) -> DuelEvent:
	for event: DuelEvent in events:
		if is_instance_of(event, event_class):
			return event
	return null
