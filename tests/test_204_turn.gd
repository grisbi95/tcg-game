# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## Début, phase principale et fin du tour par DuelEngine (ruleset 0.41, sections 204.3 à 204.5 ;
## décision de design 0200 : réveil au début du tour ; décision 0207 : une annonce sans réponse se
## résout aussitôt).

const CARDS_PER_TURN: int = 1  # 204.3.6
const SOURCES_IN_PLAY: int = 2  # 204.1.12
const SOURCES_IN_RESERVE: int = 8  # 204.1.13
const OPENING_HAND_SIZE: int = 4  # 204.1.15
const CARD: StringName = &"CARD_TEST"
const CARD_FORCE: int = 3
const CARD_COST: int = 2  # CatalogSamples.unit()
const GEAR_ID: StringName = &"sample_gear"
const GEAR_COST: int = 1  # CatalogSamples.gear()
const SPELL_ID: StringName = &"main_phase_spell"
const SPELL_COST: int = 1  # CatalogSamples.spell()

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const REASON := IntentRejected.RejectReason

var _builder: DuelStateBuilder
var _engine: DuelEngine


func before_test() -> void:
	var catalog := Catalog.new()
	SetupSamples.add_unit(catalog, CARD, CARD_FORCE)
	catalog.add_card(CardDefinition.from_dict(CatalogSamples.gear()))
	var action_spell := CatalogSamples.with_field(CatalogSamples.spell(), "id", String(SPELL_ID))
	action_spell = CatalogSamples.with_field(action_spell, "speed", "action")
	catalog.add_card(CardDefinition.from_dict(action_spell))
	_builder = DuelStateBuilder.new(DuelConfig.new(), catalog)
	_engine = DuelEngine.new(SetupSamples.catalog())
	for side: DuelState.PlayerSide in [A, B]:
		for index: int in CARDS_PER_TURN:
			_builder.add_to_deck(side, CARD)


func test_204_4_2_active_player_chooses_the_order_of_his_actions() -> void:
	var unit_id := _builder.place_piece(A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B2"), CARD)
	var card_id := _builder.add_to_hand(A, CARD)
	var state := _builder.build()
	var deploy := DeployCard.new(
		A, card_id, DuelStateBuilder.cell("A1"), EssencePayment.new(CARD_COST)
	)
	var move := TakeNormalAction.new(A, unit_id, DuelStateBuilder.cell("B3"))
	var deploy_first := _engine_from(state.clone())
	var move_first := _engine_from(state.clone())
	deploy_first.submit(deploy)
	assert_int(deploy_first.validate(move)).is_equal(REASON.NONE)
	deploy_first.submit(move)
	assert_int(move_first.validate(deploy)).is_equal(REASON.NONE)
	move_first.submit(move)
	assert_int(move_first.validate(deploy)).is_equal(REASON.NONE)
	move_first.submit(deploy)
	for engine: DuelEngine in [deploy_first, move_first]:
		assert_object(engine.get_state().piece_at(DuelStateBuilder.cell("B3"))).is_not_null()
		assert_object(engine.get_state().piece_at(DuelStateBuilder.cell("A1"))).is_not_null()


func test_204_4_3_active_player_plays_cards_in_main_phase() -> void:
	var unit_id := _builder.place_piece(A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B2"), CARD)
	var unit_card_id := _builder.add_to_hand(A, CARD)
	var gear_card_id := _builder.add_to_hand(A, GEAR_ID)
	var spell_card_id := _builder.add_to_hand(A, SPELL_ID)
	var state := _builder.build()
	var deploy := DeployCard.new(
		A, unit_card_id, DuelStateBuilder.cell("A1"), EssencePayment.new(CARD_COST)
	)
	var attach := AttachGear.new(A, gear_card_id, unit_id, EssencePayment.new(GEAR_COST))
	var cast := CastSpell.new(A, spell_card_id, EssencePayment.new(SPELL_COST))
	cast.target_piece_ids.append(unit_id)
	var expected_announcements: Dictionary[DuelIntent, String] = {
		deploy: "DeployAnnounced:A", attach: "GearAnnounced:A", cast: "SpellAnnounced:A"
	}
	for intent: DuelIntent in expected_announcements:
		var events := _engine_from(state.clone()).submit(intent)
		assert_array(EventLog.describe(events)).contains(
			[expected_announcements[intent], "StackEntryAdded:A"]
		)


func test_204_4_7_active_player_ends_turn() -> void:
	var events := _end_turn_of_a()
	var expected: Array[String] = ["TurnEnded:A", "TurnStarted:B", "SourceReceived:B"]
	expected.append_array(EventLog.repeat("CardDrawn:B", CARDS_PER_TURN))
	assert_array(EventLog.describe(events)).contains_exactly(expected)


func test_204_5_2_opponent_starts_next_turn() -> void:
	var events := _end_turn_of_a()
	var state := _engine.get_state()
	assert_int(state.active_player).is_equal(B)
	assert_int(state.priority_player).is_equal(B)
	assert_int(state.turn_number).is_equal(TurnRules.FIRST_TURN + 1)
	assert_int((events[1] as TurnStarted).turn_number).is_equal(TurnRules.FIRST_TURN + 1)


func test_204_3_9_turn_start_runs_in_one_block() -> void:
	var events := _end_turn_of_a()
	for event: DuelEvent in events:
		assert_bool(event is IntentRejected).is_false()
	assert_int(_engine.get_state().phase).is_equal(DuelState.DuelPhase.MAIN)
	assert_int(_engine.validate(EndTurn.new(A))).is_equal(REASON.NOT_YOUR_TURN)


func test_204_4_1_main_phase_follows_turn_start() -> void:
	_end_turn_of_a()
	assert_int(_engine.get_state().phase).is_equal(DuelState.DuelPhase.MAIN)


func test_204_3_2_turn_start_untaps_sources() -> void:
	_builder.with_sources_in_play(B, 1, 3)
	var events := _end_turn_of_a()
	var untapped := _first_event_of(events, "SourcesUntapped:B") as SourcesUntapped
	assert_int(untapped.count).is_equal(3)
	var player := _engine.get_state().get_player(B)
	assert_int(player.sources_tilted).is_equal(0)
	assert_int(player.sources_upright).is_equal(1 + 3 + 1)


func test_204_3_1_player_receives_one_source() -> void:
	_end_turn_of_a()
	var player := _engine.get_state().get_player(B)
	assert_int(player.sources_upright).is_equal(SOURCES_IN_PLAY + 1)


func test_204_3_3_received_source_arrives_upright() -> void:
	_builder.with_sources_in_play(B, 0, 0)
	_end_turn_of_a()
	var player := _engine.get_state().get_player(B)
	assert_int(player.sources_upright).is_equal(1)
	assert_int(player.sources_tilted).is_equal(0)


func test_204_3_5_received_source_comes_from_reserve() -> void:
	_end_turn_of_a()
	assert_int(_engine.get_state().get_player(B).sources_in_reserve).is_equal(
		SOURCES_IN_RESERVE - 1
	)


func test_200_4_1_empty_reserve_gives_no_source() -> void:
	_builder.with_sources_in_reserve(B, 0)
	var labels := EventLog.describe(_end_turn_of_a())
	assert_array(labels).not_contains(["SourceReceived:B"])
	assert_int(_engine.get_state().get_player(B).sources_upright).is_equal(SOURCES_IN_PLAY)


func test_204_3_4_first_player_receives_no_source_on_first_turn() -> void:
	_start_full_duel(A)
	var player := _engine.get_state().get_player(A)
	assert_int(player.sources_upright).is_equal(SOURCES_IN_PLAY)
	assert_int(player.sources_in_reserve).is_equal(SOURCES_IN_RESERVE)


func test_204_3_4_second_player_receives_source_on_first_turn() -> void:
	_start_full_duel(A)
	_engine.submit(EndTurn.new(A))
	assert_int(_engine.get_state().get_player(B).sources_upright).is_equal(SOURCES_IN_PLAY + 1)


func test_204_3_6_player_draws_one_card() -> void:
	_end_turn_of_a()
	var player := _engine.get_state().get_player(B)
	assert_int(player.hand.size()).is_equal(CARDS_PER_TURN)
	assert_array(player.deck).is_empty()


func test_204_3_7_first_player_draws_on_first_turn() -> void:
	_start_full_duel(B)
	var hand_size := _engine.get_state().get_player(B).hand.size()
	assert_int(hand_size).is_equal(OPENING_HAND_SIZE + CARDS_PER_TURN)


func test_204_3_8_turn_start_steps_in_order() -> void:
	_builder.with_sources_in_play(B, 0, 2)
	_builder.with_piece_awake(_builder.build().find_hero(B).piece_id, false)
	var expected: Array[String] = [
		"TurnStarted:B", "PiecesAwakened:B", "SourcesUntapped:B", "SourceReceived:B"
	]
	expected.append_array(EventLog.repeat("CardDrawn:B", CARDS_PER_TURN))
	assert_array(EventLog.describe(_end_turn_of_a()).slice(1)).contains_exactly(expected)


func test_204_3_10_turn_start_wakes_the_units_of_the_active_player() -> void:
	var own_id := _place_asleep_unit(B, "B4")
	var other_own_id := _place_asleep_unit(B, "D4")
	var enemy_id := _place_asleep_unit(A, "B2")
	_builder.with_piece_awake(_builder.build().find_hero(B).piece_id, false)
	var events := _end_turn_of_a()
	var state := _engine.get_state()
	assert_bool(state.find_piece(own_id).is_awake).is_true()
	assert_bool(state.find_piece(other_own_id).is_awake).is_true()
	assert_bool(state.find_piece(enemy_id).is_awake).is_false()
	var awakened := _first_event_of(events, "PiecesAwakened:B") as PiecesAwakened
	assert_array(awakened.piece_ids).contains_exactly(
		[state.find_hero(B).piece_id, own_id, other_own_id]
	)


func test_204_3_10_already_awake_unit_is_not_listed() -> void:
	var asleep_id := _place_asleep_unit(B, "B4")
	var awake_id := _builder.place_piece(B, Piece.PieceKind.UNIT, DuelStateBuilder.cell("D4"), CARD)
	var hero_id := _builder.build().find_hero(B).piece_id
	var events := _end_turn_of_a()
	var state := _engine.get_state()
	assert_bool(state.find_piece(awake_id).is_awake).is_true()
	var awakened := _first_event_of(events, "PiecesAwakened:B") as PiecesAwakened
	assert_array(awakened.piece_ids).contains_exactly([asleep_id])
	assert_array(awakened.piece_ids).not_contains([awake_id, hero_id])


func test_204_3_10_no_event_when_no_piece_sleeps() -> void:
	_builder.place_piece(B, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B4"), CARD)
	_place_asleep_unit(A, "B2")
	var labels := EventLog.describe(_end_turn_of_a())
	assert_array(labels).not_contains(["PiecesAwakened:B"])
	var expected: Array[String] = ["TurnEnded:A", "TurnStarted:B", "SourceReceived:B"]
	expected.append_array(EventLog.repeat("CardDrawn:B", CARDS_PER_TURN))
	assert_array(labels).contains_exactly(expected)


func test_204_3_11_turn_start_wakes_the_hero_of_the_active_player() -> void:
	_builder.with_piece_awake(_builder.build().find_hero(B).piece_id, false)
	_builder.with_piece_awake(_builder.build().find_hero(A).piece_id, false)
	_end_turn_of_a()
	var state := _engine.get_state()
	assert_bool(state.find_hero(B).is_awake).is_true()
	assert_bool(state.find_hero(A).is_awake).is_false()


func test_205_5_6_turn_start_does_not_wake_buildings() -> void:
	var building_id := _builder.place_piece(
		B, Piece.PieceKind.BUILDING, DuelStateBuilder.cell("B5"), CARD
	)
	_builder.with_piece_awake(_builder.build().find_hero(B).piece_id, false)
	var events := _end_turn_of_a()
	var state := _engine.get_state()
	assert_bool(state.find_piece(building_id).is_awake).is_false()
	var awakened := _first_event_of(events, "PiecesAwakened:B") as PiecesAwakened
	assert_array(awakened.piece_ids).not_contains([building_id])


func test_turn_start_resets_turn_counters_of_both_players() -> void:
	for side: DuelState.PlayerSide in [A, B]:
		_builder.with_recycled_this_turn(side, 2)
	_end_turn_of_a()
	for player: PlayerState in _engine.get_state().players:
		assert_int(player.sources_recycled_this_turn).is_equal(0)


func test_204_5_7_until_end_of_turn_effects_end() -> void:
	var piece_id := _builder.place_piece(A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B2"), CARD)
	var ending_id := _builder.add_active_effect(
		_make_effect(piece_id, ActiveEffect.EffectDuration.UNTIL_END_OF_TURN)
	)
	var lasting_id := _builder.add_active_effect(
		_make_effect(piece_id, ActiveEffect.EffectDuration.WHILE_PIECE_IN_PLAY)
	)
	var events := _end_turn_of_a()
	var ended := _first_event_of(events, "ActiveEffectEnded") as ActiveEffectEnded
	assert_int(ended.effect_id).is_equal(ending_id)
	var effects := _engine.get_state().active_effects
	assert_int(effects.size()).is_equal(1)
	assert_int(effects[0].effect_id).is_equal(lasting_id)


func test_204_4_7_only_active_player_ends_turn() -> void:
	_engine.start_from_state(_builder.build())
	_assert_rejected(EndTurn.new(B), REASON.NOT_YOUR_TURN)


func test_204_4_7_end_turn_outside_main_phase_rejected() -> void:
	_builder.with_phase(DuelState.DuelPhase.TURN_END)
	_engine.start_from_state(_builder.build())
	_assert_rejected(EndTurn.new(A), REASON.WRONG_PHASE)


func test_end_turn_requires_empty_stack() -> void:
	_builder.push_spell(_builder.make_card_instance(B, CARD))
	_engine.start_from_state(_builder.build())
	_assert_rejected(EndTurn.new(A), REASON.STACK_NOT_EMPTY)


func test_end_turn_while_decision_pending_rejected() -> void:
	var decision := PendingDecision.new()
	decision.kind = PendingDecision.DecisionKind.ORDER_TRIGGERS
	decision.awaited_players.append(A)
	_builder.with_pending_decision(decision)
	_engine.start_from_state(_builder.build())
	_assert_rejected(EndTurn.new(A), REASON.DECISION_PENDING)


func _place_asleep_unit(side: DuelState.PlayerSide, cell_name: String) -> int:
	var piece_id := _builder.place_piece(
		side, Piece.PieceKind.UNIT, DuelStateBuilder.cell(cell_name), CARD
	)
	_builder.with_piece_awake(piece_id, false)
	return piece_id


func _end_turn_of_a() -> Array[DuelEvent]:
	_engine.start_from_state(_builder.build())
	return _engine.submit(EndTurn.new(A))


func _engine_from(state: DuelState) -> DuelEngine:
	var engine := DuelEngine.new(state.catalog)
	engine.start_from_state(state)
	return engine


func _first_event_of(events: Array[DuelEvent], description: String) -> DuelEvent:
	return events[EventLog.describe(events).find(description)]


func _start_full_duel(first_player: DuelState.PlayerSide) -> void:
	var setup := SetupSamples.setup()
	setup.impose_first_player(first_player)
	_engine.start_new_duel(setup)
	_engine.submit(ChooseMulligan.new(A))
	_engine.submit(ChooseMulligan.new(B))


func _make_effect(piece_id: int, duration: ActiveEffect.EffectDuration) -> ActiveEffect:
	var effect := ActiveEffect.new()
	effect.duration = duration
	effect.affected_piece_id = piece_id
	return effect


func _assert_rejected(intent: DuelIntent, expected: IntentRejected.RejectReason) -> void:
	assert_array(DuelChecks.rejection_defects(_engine, intent, expected)).is_empty()
