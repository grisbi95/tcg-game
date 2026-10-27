extends GdUnitTestSuite
## Piocher et réveiller par un effet de carte (ruleset 0.53 ; glossaire Piocher et Réveiller ;
## 200.4.1, 201.3.2, 201.3.5, 201.3.6, 205.5.1, 205.5.4, 205.5.6, 207.3.3, 209.5.2 à 209.5.4 ;
## décisions 0010 et 0057). Étude, Inspiration, Charge et Éclaireur viennent de HandEffectSamples.
## Réveiller (glossaire) : une Unit ou un Hero, jamais un Building (205.5.6).

const HAND_LIMIT: int = 7  # 201.3.4
const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const REASON := IntentRejected.RejectReason
const DECISION := PendingDecision.DecisionKind
const FATIGUE_STEP: int = 1  # 209.5.2

var _builder: DuelStateBuilder
var _engine: DuelEngine


func before_test() -> void:
	var catalog := HandEffectSamples.catalog()
	_builder = HandEffectSamples.builder(catalog)
	_engine = DuelEngine.new(catalog)


func test_201_3_2_draw_effect_moves_the_top_cards_to_the_hand() -> void:
	var deck_ids := _fill_deck(A, 3)
	var events := _cast_and_resolve(HandEffectSamples.DRAW_ONE)
	assert_array(EventLog.describe(events)).contains_exactly(
		["PriorityPassed:B", "CardDrawn:A", "CardDiscarded:A", "StackEntryResolved:A"]
	)
	var player := _engine.get_state().get_player(A)
	assert_array(DuelChecks.card_ids(player.hand)).contains_exactly([deck_ids[2]])
	assert_array(DuelChecks.card_ids(player.deck)).contains_exactly([deck_ids[0], deck_ids[1]])


func test_201_3_2_draw_then_discard_resolves_in_the_order_of_the_card() -> void:
	var deck_ids := _fill_deck(A, 3)
	var events := _cast_and_resolve(HandEffectSamples.STUDY)
	assert_array(EventLog.describe(events)).contains_exactly(
		["PriorityPassed:B", "CardDrawn:A", "CardDrawn:A", "DecisionRequested:A"]
	)
	var decision := _engine.get_state().pending_decision
	assert_int(decision.kind).is_equal(DECISION.CHOOSE_DISCARD)
	assert_array(decision.candidate_ids).contains_exactly([deck_ids[2], deck_ids[1]])
	var answered := _engine.submit(HandEffectSamples.discard(A, [deck_ids[2]]))
	assert_array(EventLog.describe(answered)).contains_exactly(
		["CardDiscardedFromHand:A", "CardDiscarded:A", "StackEntryResolved:A"]
	)
	var hand := _engine.get_state().get_player(A).hand
	assert_array(DuelChecks.card_ids(hand)).contains_exactly([deck_ids[1]])


func test_201_3_5_draw_effect_stops_at_the_hand_limit() -> void:
	var deck_ids := _fill_deck(A, 3)
	HandEffectSamples.fill_hand(_builder, A, HAND_LIMIT - 1)
	var events := _cast_and_resolve(HandEffectSamples.STUDY)
	var labels := EventLog.describe(events)
	assert_array(labels.slice(0, 3)).contains_exactly(
		["PriorityPassed:B", "CardDrawn:A", "DrawBlockedByHandLimit:A"]
	)
	var player := _engine.get_state().get_player(A)
	assert_int(player.hand.size()).is_equal(HAND_LIMIT)
	assert_int(player.deck.back().card_instance_id).is_equal(deck_ids[1])


func test_201_3_6_card_not_drawn_stays_in_the_deck() -> void:
	var deck_ids := _fill_deck(A, 2)
	HandEffectSamples.fill_hand(_builder, A, HAND_LIMIT)
	_cast_and_resolve(HandEffectSamples.DRAW_ONE)
	var player := _engine.get_state().get_player(A)
	assert_array(DuelChecks.card_ids(player.deck)).contains_exactly(deck_ids)


func test_209_5_4_card_not_drawn_because_of_the_hand_limit_causes_no_fatigue() -> void:
	_fill_deck(A, 2)
	HandEffectSamples.fill_hand(_builder, A, HAND_LIMIT)
	var labels := EventLog.describe(_cast_and_resolve(HandEffectSamples.DRAW_ONE))
	assert_bool(labels.has("FatigueIncreased:A")).is_false()
	assert_int(_engine.get_state().get_player(A).fatigue_counter).is_equal(0)


func test_209_5_2_draw_effect_on_an_empty_deck_increases_the_fatigue() -> void:
	var events := _cast_and_resolve(HandEffectSamples.DRAW_ONE)
	assert_array(EventLog.describe(events)).contains_exactly(
		[
			"PriorityPassed:B",
			"FatigueIncreased:A",
			"HeroLostHealth:A",
			"CardDiscarded:A",
			"StackEntryResolved:A"
		]
	)
	var state := _engine.get_state()
	assert_int(state.get_player(A).fatigue_counter).is_equal(FATIGUE_STEP)
	assert_int(state.find_hero(A).health).is_equal(DuelStateBuilder.DEFAULT_HERO_HEALTH - 1)


func test_209_5_2a_draw_effect_on_an_empty_deck_with_a_full_hand_increases_the_fatigue() -> void:
	HandEffectSamples.fill_hand(_builder, A, HAND_LIMIT)
	var labels := EventLog.describe(_cast_and_resolve(HandEffectSamples.DRAW_ONE))
	assert_bool(labels.has("FatigueIncreased:A")).is_true()


func test_209_5_3_fatigue_by_a_draw_effect_can_end_the_duel() -> void:
	_builder.with_hero_health(A, 1)
	var events := _cast_and_resolve(HandEffectSamples.DRAW_ONE)
	var labels := EventLog.describe(events)
	assert_array(labels).contains_exactly(
		["PriorityPassed:B", "FatigueIncreased:A", "HeroLostHealth:A", "DuelEnded"]
	)
	assert_bool(_engine.get_state().is_ended()).is_true()


func test_207_1_5_a_reaction_draw_spell_resolves_before_the_spell_it_answers() -> void:
	var deck_ids := _fill_deck(B, 2)
	_fill_deck(A, 2)
	var first_id := _builder.add_to_hand(A, HandEffectSamples.DRAW_ONE)
	var reaction_id := _builder.add_to_hand(B, HandEffectSamples.INSPIRATION)
	_engine.start_from_state(_builder.build())
	_engine.submit(HandEffectSamples.cast(A, first_id))
	var answered := _engine.submit(HandEffectSamples.cast(B, reaction_id))
	assert_array(EventLog.describe(answered)).contains_exactly(
		["SourceInclined:B", "SpellAnnounced:B", "StackEntryAdded:B"]
	)
	var events := DuelChecks.pass_once(_engine, A)
	assert_array(EventLog.describe(events)).contains_exactly(
		[
			"PriorityPassed:A",
			"CardDrawn:B",
			"CardDiscarded:B",
			"StackEntryResolved:B",
			"CardDrawn:A",
			"CardDiscarded:A",
			"StackEntryResolved:A"
		]
	)
	var enemy_hand := _engine.get_state().get_player(B).hand
	assert_array(DuelChecks.card_ids(enemy_hand)).contains_exactly([deck_ids[1]])


func test_205_5_1_wake_effect_wakes_an_asleep_unit() -> void:
	var unit_id := _place_unit(A, "B2", false)
	var events := _cast_and_resolve(HandEffectSamples.CHARGE, [unit_id])
	assert_array(EventLog.describe(events)).contains_exactly(
		["PriorityPassed:B", "PiecesAwakened:A", "CardDiscarded:A", "StackEntryResolved:A"]
	)
	assert_bool((events[1] as PiecesAwakened).piece_ids == [unit_id]).is_true()
	assert_bool(_engine.get_state().find_piece(unit_id).is_awake).is_true()


func test_200_4_1_waking_an_awake_unit_does_not_happen() -> void:
	var unit_id := _place_unit(A, "B2", true)
	var events := _cast_and_resolve(HandEffectSamples.CHARGE, [unit_id])
	assert_array(EventLog.describe(events)).contains_exactly(
		["PriorityPassed:B", "CardDiscarded:A", "StackEntryResolved:A"]
	)


func test_205_5_6_wake_effect_does_not_target_a_building() -> void:
	var building_id := _builder.place_piece(
		A, Piece.PieceKind.BUILDING, DuelStateBuilder.cell("B3"), TriggerSamples.BEACON
	)
	var card_id := _builder.add_to_hand(A, HandEffectSamples.HERO_CHARGE)
	_engine.start_from_state(_builder.build())
	var intent := HandEffectSamples.cast(A, card_id, [building_id])
	assert_array(DuelChecks.rejection_defects(_engine, intent, REASON.ILLEGAL_TARGET)).is_empty()


func test_decision_0057_wake_effect_wakes_a_targeted_hero() -> void:
	var card_id := _builder.add_to_hand(A, HandEffectSamples.HERO_CHARGE)
	_engine.start_from_state(_builder.build())
	var hero := _engine.get_state().find_hero(A)
	hero.is_awake = false
	_engine.submit(HandEffectSamples.cast(A, card_id, [hero.piece_id]))
	var events := HandEffectSamples.resolve(_engine)
	assert_array(EventLog.describe(events)).contains_exactly(
		["PriorityPassed:B", "PiecesAwakened:A", "CardDiscarded:A", "StackEntryResolved:A"]
	)
	assert_bool(hero.is_awake).is_true()


func test_decision_0057_wake_effect_of_a_hero_wakes_that_hero() -> void:
	_builder.with_hero_definition(A, HandEffectSamples.WAKING_HERO)
	_engine.start_from_state(_builder.build())
	var hero := _engine.get_state().find_hero(A)
	hero.is_awake = false
	var events := _engine.submit(EndTurn.new(A))
	assert_bool(EventLog.describe(events).has("PiecesAwakened:A")).is_true()
	assert_bool(hero.is_awake).is_true()


func test_205_5_4_arrival_unit_enters_asleep_then_wakes_itself() -> void:
	var deploy_card := _builder.make_card_instance(A, HandEffectSamples.SCOUT)
	_builder.push_deploy(deploy_card, DuelStateBuilder.cell("B1"))
	_builder.with_priority_player(B)
	_engine.start_from_state(_builder.build())
	var deployed := EventLog.describe(DuelChecks.pass_once(_engine, B))
	assert_array(deployed).contains_exactly(
		[
			"PriorityPassed:B",
			"PieceDeployed:A",
			"EffectTriggered:A",
			"StackEntryResolved:A",
			"DecisionResolvedAutomatically:A",
			"StackEntryAdded:A"
		]
	)
	var piece := _engine.get_state().piece_at(DuelStateBuilder.cell("B1"))
	assert_bool(piece.is_awake).is_false()
	var resolved := DuelChecks.pass_once(_engine, B)
	assert_array(EventLog.describe(resolved)).contains_exactly(
		["PriorityPassed:B", "PiecesAwakened:A", "StackEntryResolved:A"]
	)
	assert_bool(piece.is_awake).is_true()


func test_207_3_3_source_wake_does_nothing_when_the_unit_has_left_the_board() -> void:
	var deploy_card := _builder.make_card_instance(A, HandEffectSamples.SCOUT)
	_builder.push_deploy(deploy_card, DuelStateBuilder.cell("B1"))
	_builder.with_priority_player(B)
	_engine.start_from_state(_builder.build())
	DuelChecks.pass_once(_engine, B)
	var state := _engine.get_state()
	state.pieces.erase(state.piece_at(DuelStateBuilder.cell("B1")))
	var resolved := DuelChecks.pass_once(_engine, B)
	assert_array(EventLog.describe(resolved)).contains_exactly(
		["PriorityPassed:B", "StackEntryResolved:A"]
	)


func _place_unit(side: DuelState.PlayerSide, cell_name: String, awake: bool) -> int:
	var piece_id := _builder.place_piece(
		side, Piece.PieceKind.UNIT, DuelStateBuilder.cell(cell_name), TriggerSamples.SOLDIER
	)
	_builder.with_piece_awake(piece_id, awake)
	return piece_id


func _fill_deck(side: DuelState.PlayerSide, count: int) -> Array[int]:
	var card_ids: Array[int] = []
	for index: int in count:
		card_ids.append(_builder.add_to_deck(side, TriggerSamples.SOLDIER))
	return card_ids


func _cast_and_resolve(spell_id: StringName, piece_ids: Array[int] = []) -> Array[DuelEvent]:
	var card_id := _builder.add_to_hand(A, spell_id)
	_engine.start_from_state(_builder.build())
	_engine.submit(HandEffectSamples.cast(A, card_id, piece_ids))
	return HandEffectSamples.resolve(_engine)
