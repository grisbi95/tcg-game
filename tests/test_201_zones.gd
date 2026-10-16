extends GdUnitTestSuite
## ZoneRules : deck, main, limite de main, Écart, appartenance (ruleset 0.30, chapitre 201).

const HAND_LIMIT: int = 7  # 201.3.4
const CARD: StringName = &"CARD_TEST"
const OTHER_CARD: StringName = &"OTHER_CARD_TEST"

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B

var _builder: DuelStateBuilder
var _events: Array[DuelEvent]


func before_test() -> void:
	_builder = DuelStateBuilder.new()
	_events = []


func test_201_3_1_create_deck_puts_cards_in_deck_in_order() -> void:
	var state := _builder.build()
	ZoneRules.create_deck(state, A, [CARD, OTHER_CARD] as Array[StringName])
	var deck := state.get_player(A).deck
	assert_int(deck.size()).is_equal(2)
	assert_str(deck[0].definition_id).is_equal(CARD)
	assert_str(deck[1].definition_id).is_equal(OTHER_CARD)
	assert_int(state.get_player(B).deck.size()).is_equal(0)


func test_201_5_1_created_cards_belong_to_deck_player() -> void:
	var state := _builder.build()
	ZoneRules.create_deck(state, B, [CARD, CARD] as Array[StringName])
	for card: CardInstance in state.get_player(B).deck:
		assert_int(card.owner).is_equal(B)


func test_create_deck_allocates_distinct_identifiers() -> void:
	var state := _builder.build()
	ZoneRules.create_deck(state, A, [CARD, CARD] as Array[StringName])
	ZoneRules.create_deck(state, B, [CARD] as Array[StringName])
	var identifiers: Array[int] = []
	for side: DuelState.PlayerSide in [A, B]:
		for card: CardInstance in state.get_player(side).deck:
			assert_array(identifiers).not_contains([card.card_instance_id])
			identifiers.append(card.card_instance_id)


func test_201_3_2_draw_moves_top_card_of_deck_to_hand() -> void:
	_builder.add_to_deck(A, OTHER_CARD)
	var top_card_id := _builder.add_to_deck(A, CARD)
	var state := _builder.build()
	var outcome := ZoneRules.draw_card(state, A, _events)
	assert_int(outcome).is_equal(ZoneRules.DrawOutcome.DRAWN)
	assert_array(EventLog.describe(_events)).contains_exactly(["CardDrawn:A"])
	assert_int((_events[0] as CardDrawn).card_instance_id).is_equal(top_card_id)
	var player := state.get_player(A)
	assert_object(player.find_card_in_hand(top_card_id)).is_not_null()
	assert_int(player.deck.size()).is_equal(1)
	assert_str(player.deck[0].definition_id).is_equal(OTHER_CARD)


func test_201_3_4_hand_holds_up_to_seven_cards() -> void:
	_fill_hand(A, HAND_LIMIT - 1)
	_builder.add_to_deck(A, CARD)
	var state := _builder.build()
	assert_bool(ZoneRules.has_room_in_hand(state, A)).is_true()
	var outcome := ZoneRules.draw_card(state, A, _events)
	assert_int(outcome).is_equal(ZoneRules.DrawOutcome.DRAWN)
	assert_int(state.get_player(A).hand.size()).is_equal(HAND_LIMIT)
	assert_bool(ZoneRules.has_room_in_hand(state, A)).is_false()


func test_201_3_5_card_does_not_enter_full_hand() -> void:
	_fill_hand(A, HAND_LIMIT)
	_builder.add_to_deck(A, CARD)
	var state := _builder.build()
	var snapshot := state.clone()
	var outcome := ZoneRules.draw_card(state, A, _events)
	assert_int(outcome).is_equal(ZoneRules.DrawOutcome.BLOCKED_BY_HAND_LIMIT)
	assert_array(EventLog.describe(_events)).contains_exactly(["DrawBlockedByHandLimit:A"])
	assert_array(DeepCompare.find_clone_defects(snapshot, state)).is_empty()


func test_201_3_6_card_not_drawn_stays_on_top_of_deck() -> void:
	_fill_hand(A, HAND_LIMIT)
	_builder.add_to_deck(A, OTHER_CARD)
	var top_card_id := _builder.add_to_deck(A, CARD)
	var state := _builder.build()
	ZoneRules.draw_card(state, A, _events)
	var deck := state.get_player(A).deck
	assert_int(deck.size()).is_equal(2)
	assert_int((deck.back() as CardInstance).card_instance_id).is_equal(top_card_id)


func test_201_3_4_hand_limit_is_per_player() -> void:
	_fill_hand(A, HAND_LIMIT)
	_builder.add_to_deck(B, CARD)
	var state := _builder.build()
	var outcome := ZoneRules.draw_card(state, B, _events)
	assert_int(outcome).is_equal(ZoneRules.DrawOutcome.DRAWN)
	assert_array(EventLog.describe(_events)).contains_exactly(["CardDrawn:B"])


func test_draw_from_empty_deck_changes_nothing() -> void:
	var state := _builder.build()
	var snapshot := state.clone()
	var outcome := ZoneRules.draw_card(state, A, _events)
	assert_int(outcome).is_equal(ZoneRules.DrawOutcome.DECK_EMPTY)
	assert_array(_events).is_empty()
	assert_array(DeepCompare.find_clone_defects(snapshot, state)).is_empty()


func test_draw_from_empty_deck_with_full_hand_reports_empty_deck() -> void:
	_fill_hand(A, HAND_LIMIT)
	var state := _builder.build()
	var outcome := ZoneRules.draw_card(state, A, _events)
	assert_int(outcome).is_equal(ZoneRules.DrawOutcome.DECK_EMPTY)
	assert_array(_events).is_empty()


func test_201_3_9_set_aside_moves_chosen_cards_from_hand() -> void:
	var kept_id := _builder.add_to_hand(A, CARD)
	var first_id := _builder.add_to_hand(A, CARD)
	var second_id := _builder.add_to_hand(A, OTHER_CARD)
	var state := _builder.build()
	ZoneRules.set_aside_cards(state, A, [second_id, first_id] as Array[int], _events)
	assert_array(EventLog.describe(_events)).contains_exactly(["CardSetAside:A", "CardSetAside:A"])
	assert_int((_events[0] as CardSetAside).card_instance_id).is_equal(second_id)
	assert_int((_events[1] as CardSetAside).card_instance_id).is_equal(first_id)
	var player := state.get_player(A)
	assert_array(_card_ids(player.hand)).contains_exactly([kept_id])
	assert_array(_card_ids(player.set_aside)).contains_exactly([second_id, first_id])


func test_201_3_9_set_aside_is_per_player() -> void:
	var card_id := _builder.add_to_hand(B, CARD)
	var state := _builder.build()
	ZoneRules.set_aside_cards(state, B, [card_id] as Array[int], _events)
	assert_array(state.get_player(A).set_aside).is_empty()
	assert_array(_card_ids(state.get_player(B).set_aside)).contains_exactly([card_id])


func test_201_3_10_return_empties_set_aside_into_deck() -> void:
	var deck_card_id := _builder.add_to_deck(A, CARD)
	var first_id := _builder.add_to_set_aside(A, CARD)
	var second_id := _builder.add_to_set_aside(A, OTHER_CARD)
	var state := _builder.build()
	ZoneRules.return_set_aside_to_deck(state, A, _events)
	assert_array(EventLog.describe(_events)).contains_exactly(
		["CardReturnedToDeck:A", "CardReturnedToDeck:A"]
	)
	var player := state.get_player(A)
	assert_array(player.set_aside).is_empty()
	assert_array(_card_ids(player.deck)).contains_exactly([deck_card_id, first_id, second_id])


func test_set_aside_then_return_keeps_card_instances() -> void:
	var card_id := _builder.add_to_hand(A, CARD)
	var state := _builder.build()
	var card := state.get_player(A).find_card_in_hand(card_id)
	ZoneRules.set_aside_cards(state, A, [card_id] as Array[int], _events)
	ZoneRules.return_set_aside_to_deck(state, A, _events)
	assert_object(state.get_player(A).deck[0]).is_same(card)


func _fill_hand(side: DuelState.PlayerSide, count: int) -> void:
	for index: int in count:
		_builder.add_to_hand(side, CARD)


func _card_ids(cards: Array[CardInstance]) -> Array[int]:
	return DuelChecks.card_ids(cards)
