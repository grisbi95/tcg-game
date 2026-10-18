# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## Spells : vitesses, annonce avec cibles, résolution, défausse, Contrecarrer en jeu
## (ruleset 0.32, sections 207.1, 207.5, 207.6 ; 202.2.20, 202.2.21, 208.1.3, 208.2.3).

const UNIT_ID: StringName = &"spell_target_unit"
const BOOST_ID: StringName = &"boost_spell"
const STRIKE_ID: StringName = &"strike_spell"
const COUNTER_ID: StringName = &"counter_spell"
const TOKEN_SPELL_ID: StringName = &"token_spell"
const UNIT_FORCE: int = 3
const BOOST: int = 2  # CatalogSamples.modify_force_resolve()
const BOOST_COST: int = 1
const STRIKE_COST: int = 3
const COUNTER_COST: int = 2
const TOKEN_COST: int = 2
const UNIT_COST: int = 2  # CatalogSamples.unit()

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const REASON := IntentRejected.RejectReason

var _builder: DuelStateBuilder
var _engine: DuelEngine


func before_test() -> void:
	var catalog := Catalog.new()
	SetupSamples.add_unit(catalog, UNIT_ID, UNIT_FORCE)
	catalog.add_card(
		_spell(BOOST_ID, "reaction", BOOST_COST, CatalogSamples.modify_force_resolve())
	)
	catalog.add_card(_spell(STRIKE_ID, "action", STRIKE_COST, CatalogSamples.destroy_effect()))
	catalog.add_card(
		_spell(COUNTER_ID, "reaction", COUNTER_COST, CatalogSamples.counter_spell_effect())
	)
	catalog.add_card(
		_spell(TOKEN_SPELL_ID, "action", TOKEN_COST, CatalogSamples.create_token_effect())
	)
	_builder = DuelStateBuilder.new(DuelConfig.new(), catalog)
	for side: DuelState.PlayerSide in [A, B]:
		_builder.with_sources_in_play(side, 4, 0)
	_engine = DuelEngine.new(catalog)


func test_208_1_3_spell_is_announced_on_the_stack() -> void:
	var unit_id := _place(A, "B2")
	var card_id := _builder.add_to_hand(A, BOOST_ID)
	_start()
	var events := _engine.submit(_boost(A, card_id, unit_id))
	assert_array(EventLog.describe(events)).contains_exactly(
		["SourceInclined:A", "SpellAnnounced:A", "StackEntryAdded:A"]
	)
	var state := _engine.get_state()
	assert_int(state.stack[0].kind).is_equal(StackEntry.StackEntryKind.SPELL)
	assert_object(state.get_player(A).find_card_in_hand(card_id)).is_null()
	assert_int(state.priority_player).is_equal(B)


func test_207_5_1a_spell_targets_chosen_at_announcement() -> void:
	var unit_id := _place(A, "B2")
	var card_id := _builder.add_to_hand(A, BOOST_ID)
	_start()
	_engine.submit(_boost(A, card_id, unit_id))
	assert_array(_engine.get_state().stack[0].target_piece_ids).contains_exactly([unit_id])


func test_207_1_3_action_spell_only_in_own_main_phase() -> void:
	_place(B, "B4")
	var card_id := _builder.add_to_hand(B, STRIKE_ID)
	_start()
	_assert_rejected(_strike(B, card_id, _place_live(A, "D2")), REASON.NOT_YOUR_TURN)


func test_207_1_4_action_spell_only_with_empty_stack() -> void:
	var enemy_id := _place(B, "B4")
	var card_id := _builder.add_to_hand(A, STRIKE_ID)
	_builder.push_spell(_builder.make_card_instance(B, BOOST_ID))
	_builder.with_priority_player(A)
	_start()
	_assert_rejected(_strike(A, card_id, enemy_id), REASON.STACK_NOT_EMPTY)


func test_208_2_3_response_is_only_a_reaction_spell() -> void:
	var enemy_id := _place(B, "B4")
	var card_id := _builder.add_to_hand(A, STRIKE_ID)
	_builder.push_spell(_builder.make_card_instance(B, BOOST_ID))
	_builder.with_priority_player(A)
	_start()
	assert_int(_engine.validate(_strike(A, card_id, enemy_id))).is_equal(REASON.STACK_NOT_EMPTY)


func test_207_1_5_reaction_spell_in_own_main_phase_with_empty_stack() -> void:
	var unit_id := _place(A, "B2")
	var card_id := _builder.add_to_hand(A, BOOST_ID)
	_start()
	assert_int(_engine.validate(_boost(A, card_id, unit_id))).is_equal(REASON.NONE)


func test_207_1_6_reaction_spell_in_response_during_opponent_turn() -> void:
	var unit_id := _place(B, "B4")
	var card_id := _builder.add_to_hand(B, BOOST_ID)
	_builder.push_spell(_builder.make_card_instance(A, BOOST_ID))
	_builder.with_priority_player(B)
	_start()
	var events := _engine.submit(_boost(B, card_id, unit_id))
	assert_array(EventLog.describe(events)).contains(["SpellAnnounced:B"])
	assert_int(_engine.get_state().priority_player).is_equal(A)


func test_208_2_4_reaction_spell_without_priority_rejected() -> void:
	var unit_id := _place(B, "B4")
	var card_id := _builder.add_to_hand(B, BOOST_ID)
	_builder.push_spell(_builder.make_card_instance(A, BOOST_ID))
	_builder.with_priority_player(A)
	_start()
	_assert_rejected(_boost(B, card_id, unit_id), REASON.NOT_YOUR_PRIORITY)


func test_207_5_8_spell_without_legal_target_cannot_be_announced() -> void:
	var enemy_id := _place(B, "B4")
	var card_id := _builder.add_to_hand(A, BOOST_ID)
	_start()
	_assert_rejected(_boost(A, card_id, enemy_id), REASON.ILLEGAL_TARGET)
	var no_target := CastSpell.new(A, card_id, EssencePayment.new(BOOST_COST))
	_assert_rejected(no_target, REASON.WRONG_TARGET_COUNT)


func test_207_1_3_action_spell_outside_main_phase_rejected() -> void:
	var enemy_id := _place(B, "B4")
	var card_id := _builder.add_to_hand(A, STRIKE_ID)
	_builder.with_phase(DuelState.DuelPhase.TURN_END)
	_start()
	_assert_rejected(_strike(A, card_id, enemy_id), REASON.WRONG_PHASE)


func test_207_5_1_spell_with_target_its_effect_does_not_ask_rejected() -> void:
	var unit_id := _place(A, "B2")
	var card_id := _builder.add_to_hand(A, BOOST_ID)
	_start()
	var intent := _boost(A, card_id, unit_id)
	intent.target_cells.append(DuelStateBuilder.cell("B1"))
	_assert_rejected(intent, REASON.WRONG_TARGET_COUNT)


func test_208_1_3_only_a_spell_card_is_announced_as_spell() -> void:
	var card_id := _builder.add_to_hand(A, UNIT_ID)
	_start()
	_assert_rejected(CastSpell.new(A, card_id, EssencePayment.new(UNIT_COST)), REASON.NOT_A_SPELL)


func test_203_3_1_spell_payment_must_match_cost() -> void:
	var unit_id := _place(A, "B2")
	var card_id := _builder.add_to_hand(A, BOOST_ID)
	_start()
	var intent := _boost(A, card_id, unit_id)
	intent.payment = EssencePayment.new(BOOST_COST + 1)
	_assert_rejected(intent, REASON.PAYMENT_DOES_NOT_MATCH_COST)


func test_202_2_20_spell_resolves_once_then_goes_to_discard() -> void:
	var unit_id := _place(A, "B2")
	var card_id := _builder.add_to_hand(A, BOOST_ID)
	_start()
	_engine.submit(_boost(A, card_id, unit_id))
	var labels := _resolve_stack()
	(
		assert_array(labels)
		. contains_exactly(
			[
				"PriorityPassed:B",
				"ForceModified:A",
				"CardDiscarded:A",
				"StackEntryResolved:A",
			]
		)
	)
	assert_int(_force(unit_id)).is_equal(UNIT_FORCE + BOOST)


func test_207_1_7_resolved_spell_card_goes_to_owner_discard() -> void:
	var unit_id := _place(A, "B2")
	var card_id := _builder.add_to_hand(A, BOOST_ID)
	_start()
	_engine.submit(_boost(A, card_id, unit_id))
	_resolve_stack()
	var discard := _engine.get_state().get_player(A).discard
	assert_int(discard[0].card_instance_id).is_equal(card_id)


func test_207_1_7a_spell_without_valid_target_still_goes_to_discard() -> void:
	var unit_id := _place(A, "B2")
	var card_id := _builder.add_to_hand(A, BOOST_ID)
	_start()
	_engine.submit(_boost(A, card_id, unit_id))
	var state := _engine.get_state()
	state.pieces.erase(state.find_piece(unit_id))
	var labels := _resolve_stack()
	assert_array(labels).contains(["EffectLostAllTargets:A", "CardDiscarded:A"])
	assert_int(state.get_player(A).discard[0].card_instance_id).is_equal(card_id)


func test_207_5_7_cost_stays_spent_when_spell_has_no_valid_target() -> void:
	var unit_id := _place(A, "B2")
	var card_id := _builder.add_to_hand(A, BOOST_ID)
	_start()
	_engine.submit(_boost(A, card_id, unit_id))
	var state := _engine.get_state()
	state.pieces.erase(state.find_piece(unit_id))
	_resolve_stack()
	assert_int(state.get_player(A).sources_tilted).is_equal(BOOST_COST)


func test_202_2_21_effect_with_duration_outlives_the_spell() -> void:
	var unit_id := _place(A, "B2")
	var card_id := _builder.add_to_hand(A, BOOST_ID)
	_start()
	_engine.submit(_boost(A, card_id, unit_id))
	_resolve_stack()
	assert_array(_engine.get_state().stack).is_empty()
	assert_int(_force(unit_id)).is_equal(UNIT_FORCE + BOOST)


func test_207_4_3_until_end_of_turn_effect_ends_with_the_turn() -> void:
	var unit_id := _place(A, "B2")
	var card_id := _builder.add_to_hand(A, BOOST_ID)
	_start()
	_engine.submit(_boost(A, card_id, unit_id))
	_resolve_stack()
	assert_array(EventLog.describe(_engine.submit(EndTurn.new(A)))).contains(["ActiveEffectEnded"])
	assert_int(_force(unit_id)).is_equal(UNIT_FORCE)


func test_207_6_1_counter_spell_stops_the_targeted_spell() -> void:
	var unit_id := _place(A, "B2")
	var boost_card_id := _builder.add_to_hand(A, BOOST_ID)
	var counter_card_id := _builder.add_to_hand(B, COUNTER_ID)
	_start()
	_engine.submit(_boost(A, boost_card_id, unit_id))
	var boost_entry_id := _engine.get_state().stack[0].stack_entry_id
	var counter := CastSpell.new(B, counter_card_id, EssencePayment.new(COUNTER_COST))
	counter.target_stack_entry_ids.append(boost_entry_id)
	assert_array(EventLog.describe(_engine.submit(counter))).contains(["SpellAnnounced:B"])
	var labels := _resolve_stack()
	assert_array(labels).contains(["SpellCountered:A"])
	assert_array(labels).not_contains(["ForceModified:A"])
	assert_int(_force(unit_id)).is_equal(UNIT_FORCE)
	var discarded: Array[int] = DuelChecks.card_ids(_engine.get_state().get_player(A).discard)
	assert_array(discarded).contains([boost_card_id])


func test_207_6_2_counter_spell_targets_only_a_spell() -> void:
	var counter_card_id := _builder.add_to_hand(B, COUNTER_ID)
	var deploy_id := _builder.push_deploy(
		_builder.make_card_instance(A, UNIT_ID), DuelStateBuilder.cell("B1")
	)
	_builder.with_priority_player(B)
	_start()
	var counter := CastSpell.new(B, counter_card_id, EssencePayment.new(COUNTER_COST))
	counter.target_stack_entry_ids.append(deploy_id)
	_assert_rejected(counter, REASON.ILLEGAL_TARGET)


func test_206_3_2_strike_sends_enemy_unit_to_discard() -> void:
	var enemy_id := _place(B, "B4")
	var card_id := _builder.add_to_hand(A, STRIKE_ID)
	_start()
	_engine.submit(_strike(A, card_id, enemy_id))
	assert_array(_resolve_stack()).contains(["PieceDestroyed:B"])
	assert_object(_engine.get_state().find_piece(enemy_id)).is_null()
	assert_int(_engine.get_state().get_player(B).discard.size()).is_equal(1)


func test_202_4_6_token_created_by_a_spell() -> void:
	var card_id := _builder.add_to_hand(A, TOKEN_SPELL_ID)
	_start()
	var intent := CastSpell.new(A, card_id, EssencePayment.new(TOKEN_COST))
	intent.target_cells.append(DuelStateBuilder.cell("B1"))
	_engine.submit(intent)
	assert_array(_resolve_stack()).contains(["TokenCreated:A"])
	var token := _engine.get_state().piece_at(DuelStateBuilder.cell("B1"))
	assert_bool(token.is_token()).is_true()
	assert_int(token.owner).is_equal(A)


func _start() -> void:
	_engine.start_from_state(_builder.build())


func _spell(id: StringName, speed: String, cost: int, effect: Dictionary) -> CardDefinition:
	var data := CatalogSamples.with_field(CatalogSamples.spell(), "id", String(id))
	data = CatalogSamples.with_field(data, "name", "Spell %s" % id)
	data = CatalogSamples.with_field(data, "speed", speed)
	data = CatalogSamples.with_field(data, "cost", cost)
	return CardDefinition.from_dict(CatalogSamples.with_field(data, "effects", [effect]))


func _boost(side: DuelState.PlayerSide, card_id: int, target_id: int) -> CastSpell:
	var intent := CastSpell.new(side, card_id, EssencePayment.new(BOOST_COST))
	intent.target_piece_ids.append(target_id)
	return intent


func _strike(side: DuelState.PlayerSide, card_id: int, target_id: int) -> CastSpell:
	var intent := CastSpell.new(side, card_id, EssencePayment.new(STRIKE_COST))
	intent.target_piece_ids.append(target_id)
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


func _place_live(side: DuelState.PlayerSide, cell_name: String) -> int:
	return DuelStateBuilder.place_unit_in(_engine.get_state(), side, UNIT_ID, cell_name)


func _force(piece_id: int) -> int:
	var state := _engine.get_state()
	return ForceRules.current_force(state, state.find_piece(piece_id))


func _assert_rejected(intent: DuelIntent, expected: IntentRejected.RejectReason) -> void:
	assert_array(DuelChecks.rejection_defects(_engine, intent, expected)).is_empty()
