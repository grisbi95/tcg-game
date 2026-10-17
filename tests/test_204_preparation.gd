# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## Préparation et mulligan par DuelEngine (ruleset 0.33, sections 204.1 et 204.2 ; décisions
## 0012, 0013 et 0015).

const SOURCES_IN_PLAY: int = 2  # 204.1.2, 204.1.12
const SOURCES_IN_RESERVE: int = 8  # 204.1.13
const OPENING_HAND_SIZE: int = 5  # 204.1.15
const CARDS_PER_TURN: int = 2  # 204.3.6
const SEEDS_TRIED: int = 20

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const REASON := IntentRejected.RejectReason

var _catalog: Catalog
var _engine: DuelEngine


func before() -> void:
	_catalog = SetupSamples.catalog()


func before_test() -> void:
	_engine = DuelEngine.new(_catalog)


func test_204_1_9_duel_starts_with_preparation() -> void:
	_start()
	var state := _engine.get_state()
	assert_int(state.phase).is_equal(DuelState.DuelPhase.PREPARATION)
	assert_int(state.turn_number).is_equal(DuelState.NO_TURN)


func test_204_1_10_mulligan_is_part_of_preparation() -> void:
	_start()
	var state := _engine.get_state()
	assert_int(state.pending_decision.kind).is_equal(PendingDecision.DecisionKind.MULLIGAN)
	assert_int(state.phase).is_equal(DuelState.DuelPhase.PREPARATION)
	_engine.submit(ChooseMulligan.new(A))
	assert_int(state.phase).is_equal(DuelState.DuelPhase.PREPARATION)
	assert_int(state.turn_number).is_equal(DuelState.NO_TURN)
	_engine.submit(ChooseMulligan.new(B))
	assert_object(state.pending_decision).is_null()
	assert_int(state.phase).is_equal(DuelState.DuelPhase.MAIN)


func test_204_1_1_heroes_start_on_c1_and_c5() -> void:
	_start()
	var state := _engine.get_state()
	assert_str(BoardGeometry.cell_name(state.find_hero(A).cell)).is_equal("C1")
	assert_str(BoardGeometry.cell_name(state.find_hero(B).cell)).is_equal("C5")
	assert_int(state.find_hero(B).card.owner).is_equal(B)


func test_204_1_8_heroes_start_with_health_of_their_card() -> void:
	_start()
	for side: DuelState.PlayerSide in [A, B]:
		assert_int(_engine.get_state().find_hero(side).health).is_equal(SetupSamples.HERO_HEALTH)


func test_204_1_12_each_player_puts_two_sources_into_play() -> void:
	_start()
	for side: DuelState.PlayerSide in [A, B]:
		var player := _engine.get_state().get_player(side)
		assert_int(player.sources_upright + player.sources_tilted).is_equal(SOURCES_IN_PLAY)


func test_204_1_13_each_player_keeps_eight_sources_in_reserve() -> void:
	_start()
	for side: DuelState.PlayerSide in [A, B]:
		var player := _engine.get_state().get_player(side)
		assert_int(player.sources_in_reserve).is_equal(SOURCES_IN_RESERVE)


func test_204_1_17_setup_sources_arrive_upright() -> void:
	_start()
	for side: DuelState.PlayerSide in [A, B]:
		var player := _engine.get_state().get_player(side)
		assert_int(player.sources_upright).is_equal(SOURCES_IN_PLAY)
		assert_int(player.sources_tilted).is_equal(0)


func test_204_1_6_decks_are_shuffled_before_first_draw() -> void:
	var events := _start()
	var labels := EventLog.describe(events)
	assert_int(labels.find("DeckShuffled:A")).is_less(labels.find("CardDrawn:A"))
	assert_int(labels.find("DeckShuffled:B")).is_less(labels.find("CardDrawn:B"))
	var unshuffled := SetupSamples.deck()
	var dealt := _definition_ids(_engine.get_state().get_player(A).deck)
	dealt.append_array(_definition_ids(_engine.get_state().get_player(A).hand))
	assert_array(dealt).is_not_equal(unshuffled)
	assert_array(dealt).contains_exactly_in_any_order(unshuffled)


func test_204_1_15_each_player_draws_five_cards() -> void:
	_start()
	for side: DuelState.PlayerSide in [A, B]:
		assert_int(_engine.get_state().get_player(side).hand.size()).is_equal(OPENING_HAND_SIZE)


func test_204_1_16_preparation_steps_in_order() -> void:
	var expected: Array[String] = ["HeroPlaced:A", "HeroPlaced:B"]
	expected.append_array(["SourcesPutIntoPlay:A", "SourcesPutIntoPlay:B"])
	expected.append_array(["DeckShuffled:A", "DeckShuffled:B"])
	expected.append_array(EventLog.repeat("CardDrawn:A", OPENING_HAND_SIZE))
	expected.append_array(EventLog.repeat("CardDrawn:B", OPENING_HAND_SIZE))
	expected.append_array(["DecisionRequested:A", "DecisionRequested:B"])
	assert_array(EventLog.describe(_start())).contains_exactly(expected)


func test_204_2_2_mulligan_requested_from_both_players() -> void:
	for event: DuelEvent in _start().slice(-2):
		var request := event as DecisionRequested
		assert_int(request.kind).is_equal(PendingDecision.DecisionKind.MULLIGAN)


func test_204_1_16_first_player_designated_after_mulligan() -> void:
	var setup := SetupSamples.setup()
	setup.impose_first_player(A)
	_start(setup)
	_engine.submit(ChooseMulligan.new(A))
	var events := _engine.submit(ChooseMulligan.new(B))
	var expected: Array[String] = ["MulliganDecided:B", "FirstPlayerChosen:A", "TurnStarted:A"]
	expected.append_array(EventLog.repeat("CardDrawn:A", CARDS_PER_TURN))
	assert_array(EventLog.describe(events)).contains_exactly(expected)


func test_204_1_16_first_player_drawn_after_mulligan_shuffles() -> void:
	_start()
	_engine.submit(ChooseMulligan.new(A, _hand_ids(A, 1)))
	var labels := EventLog.describe(_engine.submit(ChooseMulligan.new(B, _hand_ids(B, 1))))
	var chosen_index := labels.find("FirstPlayerChosen:A")
	if chosen_index < 0:
		chosen_index = labels.find("FirstPlayerChosen:B")
	assert_int(chosen_index).is_greater(labels.rfind("DeckShuffled:B"))
	assert_int(labels.rfind("DeckShuffled:B")).is_greater(labels.rfind("DeckShuffled:A"))


func test_204_1_11_first_turn_follows_preparation() -> void:
	_start()
	_keep_both_hands()
	var state := _engine.get_state()
	assert_int(state.phase).is_equal(DuelState.DuelPhase.MAIN)
	assert_int(state.turn_number).is_equal(TurnRules.FIRST_TURN)
	assert_int(state.active_player).is_equal(state.first_player)
	assert_object(state.pending_decision).is_null()


func test_204_1_14_first_player_drawn_by_lot_reaches_both_players() -> void:
	var first_players: Array[DuelState.PlayerSide] = []
	for rng_seed: int in SEEDS_TRIED:
		_engine = DuelEngine.new(_catalog)
		_start(SetupSamples.setup(rng_seed))
		_keep_both_hands()
		first_players.append(_engine.get_state().first_player)
	assert_array(first_players).contains([A, B])


func test_204_1_14_first_player_drawn_by_lot_is_deterministic() -> void:
	var first_players: Array[DuelState.PlayerSide] = []
	for attempt: int in 2:
		_engine = DuelEngine.new(_catalog)
		_start()
		_keep_both_hands()
		first_players.append(_engine.get_state().first_player)
	assert_int(first_players[0]).is_equal(first_players[1])


func test_imposed_first_player_a_or_b() -> void:
	for side: DuelState.PlayerSide in [A, B]:
		_engine = DuelEngine.new(_catalog)
		var setup := SetupSamples.setup()
		setup.impose_first_player(side)
		_start(setup)
		_keep_both_hands()
		assert_int(_engine.get_state().first_player).is_equal(side)
		assert_int(_engine.get_state().active_player).is_equal(side)


func test_inconsistent_config_does_not_start_duel() -> void:
	var config := DuelConfig.new()
	config.setup_sources_in_reserve += 1
	_engine = DuelEngine.new(_catalog, config)
	var events := _start()
	assert_array(EventLog.describe(events)).contains_exactly(["DuelSetupRejected"])
	assert_object(_engine.get_state()).is_null()


func test_invalid_setup_does_not_start_duel() -> void:
	var setup := SetupSamples.setup()
	setup.deck_b.pop_back()
	setup.hero_a = &"missing_hero"
	var events := _engine.start_new_duel(setup)
	assert_array(EventLog.describe(events)).contains_exactly(["DuelSetupRejected"])
	assert_int((events[0] as DuelSetupRejected).errors.size()).is_equal(2)
	assert_object(_engine.get_state()).is_null()
	var submitted := _engine.submit(ChooseMulligan.new(A))
	assert_int(EventLog.rejection_reason(submitted)).is_equal(REASON.DUEL_NOT_STARTED)


func test_204_2_2_both_players_awaited_at_once() -> void:
	_start()
	var decision := _engine.get_state().pending_decision
	assert_int(decision.kind).is_equal(PendingDecision.DecisionKind.MULLIGAN)
	assert_array(decision.awaited_players).contains_exactly_in_any_order([A, B])


func test_204_2_3_first_answer_moves_no_card_and_draws_nothing() -> void:
	_start()
	var snapshot := _engine.get_state().clone()
	var events := _engine.submit(ChooseMulligan.new(A, _hand_ids(A, 2)))
	assert_array(EventLog.describe(events)).contains_exactly(["MulliganDecided:A"])
	var state := _engine.get_state()
	assert_array(_hand_ids(A, OPENING_HAND_SIZE)).is_equal(_ids(snapshot.get_player(A).hand))
	assert_int(state.rng.state).is_equal(snapshot.rng.state)
	assert_array(state.pending_decision.awaited_players).contains_exactly([B])


func test_204_2_1_second_answer_of_same_player_rejected() -> void:
	_start()
	_engine.submit(ChooseMulligan.new(A))
	_assert_rejected(ChooseMulligan.new(A, _hand_ids(A, 1)), REASON.PLAYER_NOT_AWAITED)


func test_204_2_4_card_outside_own_hand_rejected() -> void:
	_start()
	_assert_rejected(ChooseMulligan.new(A, _hand_ids(B, 1)), REASON.CARD_NOT_IN_HAND)
	var deck_card_id := _engine.get_state().get_player(A).deck[0].card_instance_id
	_assert_rejected(ChooseMulligan.new(A, [deck_card_id] as Array[int]), REASON.CARD_NOT_IN_HAND)


func test_same_card_twice_rejected() -> void:
	_start()
	var card_id := _hand_ids(A, 1)[0]
	_assert_rejected(ChooseMulligan.new(A, [card_id, card_id] as Array[int]), REASON.DUPLICATE_CARD)


func test_end_turn_during_mulligan_rejected() -> void:
	_start()
	_assert_rejected(EndTurn.new(A), REASON.DECISION_PENDING)


func test_mulligan_answer_without_pending_mulligan_rejected() -> void:
	_start()
	_keep_both_hands()
	_assert_rejected(ChooseMulligan.new(A), REASON.NOT_THE_PENDING_DECISION)


func test_204_2_9_mulligan_steps_in_order() -> void:
	_start()
	_engine.submit(ChooseMulligan.new(A, _hand_ids(A, 2)))
	var events := _engine.submit(ChooseMulligan.new(B))
	var expected: Array[String] = ["MulliganDecided:B"]
	expected.append_array(EventLog.repeat("CardSetAside:A", 2))
	expected.append_array(EventLog.repeat("CardDrawn:A", 2))
	expected.append_array(EventLog.repeat("CardReturnedToDeck:A", 2))
	expected.append("DeckShuffled:A")
	assert_array(EventLog.describe(events).slice(0, expected.size())).contains_exactly(expected)


func test_204_2_5_draws_as_many_cards_as_set_aside() -> void:
	var setup := SetupSamples.setup()
	setup.impose_first_player(B)
	_start(setup)
	var events := _engine.submit(ChooseMulligan.new(A, _hand_ids(A, 3)))
	events.append_array(_engine.submit(ChooseMulligan.new(B)))
	assert_int(EventLog.describe(events).count("CardDrawn:A")).is_equal(3)
	assert_int(_engine.get_state().get_player(A).hand.size()).is_equal(OPENING_HAND_SIZE)


func test_204_2_6_set_aside_cards_return_to_deck() -> void:
	_start()
	var set_aside_ids := _hand_ids(A, 2)
	_engine.submit(ChooseMulligan.new(A, set_aside_ids))
	_engine.submit(ChooseMulligan.new(B))
	var player := _engine.get_state().get_player(A)
	for card_id: int in set_aside_ids:
		assert_object(player.find_card_in_hand(card_id)).is_null()
	assert_array(_ids(player.deck)).contains(set_aside_ids)


func test_204_2_7_player_who_mulligans_shuffles_deck() -> void:
	_start()
	_engine.submit(ChooseMulligan.new(A, _hand_ids(A, 1)))
	var events := _engine.submit(ChooseMulligan.new(B))
	assert_array(EventLog.describe(events)).contains(["DeckShuffled:A"])


func test_204_2_8_set_aside_cards_leave_hand_before_replacements() -> void:
	_start()
	_engine.submit(ChooseMulligan.new(A, _hand_ids(A, 1)))
	var labels := EventLog.describe(_engine.submit(ChooseMulligan.new(B)))
	assert_int(labels.find("CardSetAside:A")).is_less(labels.find("CardDrawn:A"))


func test_204_2_10_set_aside_card_goes_to_set_aside_zone() -> void:
	_start()
	var card_id := _hand_ids(A, 1)[0]
	_engine.submit(ChooseMulligan.new(A, [card_id] as Array[int]))
	var events := _engine.submit(ChooseMulligan.new(B))
	var set_aside := _first_event_of(events, "CardSetAside:A") as CardSetAside
	assert_int(set_aside.card_instance_id).is_equal(card_id)


func test_204_2_11_set_aside_empty_after_mulligan() -> void:
	_start()
	_engine.submit(ChooseMulligan.new(A, _hand_ids(A, 2)))
	_engine.submit(ChooseMulligan.new(B, _hand_ids(B, 1)))
	for side: DuelState.PlayerSide in [A, B]:
		assert_array(_engine.get_state().get_player(side).set_aside).is_empty()


func test_204_2_12_empty_answer_keeps_hand() -> void:
	_start()
	var hand_before := _hand_ids(A, OPENING_HAND_SIZE)
	_engine.submit(ChooseMulligan.new(A))
	_engine.submit(ChooseMulligan.new(B))
	var hand_after := _ids(_engine.get_state().get_player(A).hand)
	assert_array(hand_after.slice(0, OPENING_HAND_SIZE)).is_equal(hand_before)


func test_204_2_13_keeping_hand_is_not_a_mulligan() -> void:
	var setup := SetupSamples.setup()
	setup.impose_first_player(A)
	_start(setup)
	_engine.submit(ChooseMulligan.new(A))
	var labels := EventLog.describe(_engine.submit(ChooseMulligan.new(B)))
	for label: String in ["CardSetAside:A", "CardReturnedToDeck:A", "DeckShuffled:A"]:
		assert_array(labels).not_contains([label])
	assert_int(labels.find("CardDrawn:A")).is_greater(labels.find("TurnStarted:A"))


func test_204_2_14_player_who_keeps_hand_does_not_shuffle() -> void:
	_start()
	_engine.submit(ChooseMulligan.new(A))
	var events := _engine.submit(ChooseMulligan.new(B, _hand_ids(B, 1)))
	var labels := EventLog.describe(events)
	assert_array(labels).not_contains(["DeckShuffled:A", "CardSetAside:A"])
	assert_array(labels).contains(["DeckShuffled:B"])


func test_mulligans_executed_player_a_then_b() -> void:
	_start()
	_engine.submit(ChooseMulligan.new(B, _hand_ids(B, 1)))
	var events := _engine.submit(ChooseMulligan.new(A, _hand_ids(A, 1)))
	var labels := EventLog.describe(events)
	assert_int(labels.find("DeckShuffled:A")).is_less(labels.find("CardSetAside:B"))


func test_mulligan_outcome_independent_of_answer_order() -> void:
	var states: Array[DuelState] = []
	var shared_config := DuelConfig.new()
	for a_answers_first: bool in [true, false]:
		_engine = DuelEngine.new(_catalog, shared_config)
		_start()
		var answers: Array[ChooseMulligan] = [
			ChooseMulligan.new(A, _hand_ids(A, 2)), ChooseMulligan.new(B, _hand_ids(B, 3))
		]
		if not a_answers_first:
			answers.reverse()
		for answer: ChooseMulligan in answers:
			_engine.submit(answer)
		states.append(_engine.get_state())
	assert_array(DeepCompare.find_clone_defects(states[0], states[1])).is_empty()


func _start(setup: DuelSetup = SetupSamples.setup()) -> Array[DuelEvent]:
	return _engine.start_new_duel(setup)


func _keep_both_hands() -> void:
	_engine.submit(ChooseMulligan.new(A))
	_engine.submit(ChooseMulligan.new(B))


func _assert_rejected(intent: DuelIntent, expected: IntentRejected.RejectReason) -> void:
	assert_array(DuelChecks.rejection_defects(_engine, intent, expected)).is_empty()


func _hand_ids(side: DuelState.PlayerSide, count: int) -> Array[int]:
	return _ids(_engine.get_state().get_player(side).hand).slice(0, count)


func _ids(cards: Array[CardInstance]) -> Array[int]:
	return DuelChecks.card_ids(cards)


func _definition_ids(cards: Array[CardInstance]) -> Array[StringName]:
	var identifiers: Array[StringName] = []
	for card: CardInstance in cards:
		identifiers.append(card.definition_id)
	return identifiers


func _first_event_of(events: Array[DuelEvent], description: String) -> DuelEvent:
	var labels := EventLog.describe(events)
	return events[labels.find(description)]
