extends GdUnitTestSuite
## Temps de réponse pendant le choix des cartes à défausser et pendant le regard sur le dessus du
## deck (ruleset 0.53, 209.4.6, 209.4.7c, 209.4.7d, 209.4.13, 209.4.14 ; décisions de design 0219
## et 0242 du ruleset ; décisions 0018 et 0057). À l'expiration, le choix se tire au sort par
## `state.rng` seulement.

const RESPONSE_MSEC: int = 30_000  # 209.4.6
const TURN_MSEC: int = 90_000  # 209.4.3
const SEED_COUNT: int = 24
const DECK_SIZE: int = 3
const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const KIND := DuelState.ClockKind
const CONSEQUENCE := TimeExpired.Consequence
const PLACE := ChooseTopCardPlace.TopCardPlace

var _catalog: Catalog


func before_test() -> void:
	_catalog = HandEffectSamples.catalog()


func test_209_4_7c_the_response_time_of_the_player_who_discards_runs() -> void:
	var engine := _waiting_for_discard(1, 3, A)
	assert_array(engine.awaited_players()).contains_exactly([A])
	assert_array(engine.clock_owners()).contains_exactly([A])
	assert_int(engine.clock_kind(A)).is_equal(KIND.RESPONSE)
	assert_int(engine.running_time_remaining_msec(A)).is_equal(RESPONSE_MSEC)
	var state := engine.get_state()
	assert_int(state.get_player(A).response_time_remaining_msec).is_equal(RESPONSE_MSEC)


func test_209_4_7c_the_turn_time_of_the_active_player_stays_paused_during_the_choice() -> void:
	var engine := _waiting_for_discard(1, 3, A)
	var turn_before := engine.get_state().get_player(A).turn_time_remaining_msec
	assert_bool(engine.is_turn_time_paused(A)).is_true()
	assert_array(engine.advance_clock(RESPONSE_MSEC - 1)).is_empty()
	var state := engine.get_state()
	assert_int(state.get_player(A).turn_time_remaining_msec).is_equal(turn_before)
	assert_int(state.get_player(A).response_time_remaining_msec).is_equal(1)
	assert_int(turn_before).is_equal(TURN_MSEC)


func test_209_4_7c_the_response_time_of_a_player_who_is_not_active_runs_too() -> void:
	var engine := _waiting_for_discard(1, 3, B)
	assert_array(engine.clock_owners()).contains_exactly([B])
	assert_int(engine.clock_kind(B)).is_equal(KIND.RESPONSE)
	assert_int(engine.running_time_remaining_msec(B)).is_equal(RESPONSE_MSEC)


func test_209_4_7d_the_response_time_of_the_player_who_looks_runs() -> void:
	var engine := _waiting_for_look(1)
	assert_array(engine.awaited_players()).contains_exactly([A])
	assert_array(engine.clock_owners()).contains_exactly([A])
	assert_int(engine.clock_kind(A)).is_equal(KIND.RESPONSE)
	assert_int(engine.running_time_remaining_msec(A)).is_equal(RESPONSE_MSEC)
	assert_bool(engine.is_turn_time_paused(A)).is_true()


func test_209_4_13_expiry_discards_cards_drawn_from_the_hand() -> void:
	var engine := _waiting_for_discard(1, 4, A)
	var state := engine.get_state()
	var hand_before := DuelChecks.card_ids(state.get_player(A).hand)
	var rng_before := state.rng.state
	var events := engine.advance_clock(RESPONSE_MSEC)
	assert_array(EventLog.describe(events)).contains_exactly(
		[
			"TimeExpired:A",
			"CardDiscardedFromHand:A",
			"CardDiscardedFromHand:A",
			"CardDiscarded:A",
			"StackEntryResolved:A"
		]
	)
	var expired: TimeExpired = events[0]
	assert_int(expired.kind).is_equal(KIND.RESPONSE)
	assert_int(expired.consequence).is_equal(CONSEQUENCE.CARDS_DISCARDED_AT_RANDOM)
	var discarded: Array[int] = []
	for event: DuelEvent in events:
		if event is CardDiscardedFromHand:
			discarded.append((event as CardDiscardedFromHand).card_instance_id)
	assert_int(discarded.size()).is_equal(2)
	assert_int(discarded[0]).is_not_equal(discarded[1])
	for card_id: int in discarded:
		assert_bool(hand_before.has(card_id)).is_true()
	assert_int(state.get_player(A).hand.size()).is_equal(hand_before.size() - 2)
	assert_int(state.rng.state).is_not_equal(rng_before)
	assert_object(state.pending_decision).is_null()


func test_209_4_13_same_seed_same_draw() -> void:
	for rng_seed: int in SEED_COUNT:
		var first := _expired_discards(rng_seed)
		var second := _expired_discards(rng_seed)
		assert_array(first).is_equal(second)


func test_209_4_13_the_draw_reaches_different_cards_across_seeds() -> void:
	var distinct: Dictionary[Array, bool] = {}
	for rng_seed: int in SEED_COUNT:
		var picked := _expired_discards(rng_seed)
		picked.sort()
		distinct[picked] = true
	assert_int(distinct.size()).is_greater(1)


func test_209_4_13_the_block_resumes_after_the_drawn_discard() -> void:
	var engine := _waiting_for_discard(1, 3, A, true)
	var events := engine.advance_clock(RESPONSE_MSEC)
	assert_array(EventLog.describe(events)).contains_exactly(
		[
			"TimeExpired:A",
			"CardDiscardedFromHand:A",
			"CardDiscarded:A",
			"StackEntryResolved:A",
			"CardDrawn:A",
			"CardDiscarded:A",
			"StackEntryResolved:A"
		]
	)
	assert_array(engine.get_state().stack).is_empty()


func test_209_4_14_expiry_places_the_card_by_a_draw_between_the_two_possibilities() -> void:
	var engine := _waiting_for_look(1)
	var events := engine.advance_clock(RESPONSE_MSEC)
	assert_array(EventLog.describe(events)).contains_exactly(
		["TimeExpired:A", "TopCardPlaceChosen:A", "CardDiscarded:A", "StackEntryResolved:A"]
	)
	var expired: TimeExpired = events[0]
	assert_int(expired.kind).is_equal(KIND.RESPONSE)
	assert_int(expired.consequence).is_equal(CONSEQUENCE.TOP_CARD_PLACE_DRAWN_AT_RANDOM)
	assert_object(engine.get_state().pending_decision).is_null()


func test_209_4_14_same_seed_same_draw_and_both_places_come_up() -> void:
	var places: Dictionary[int, bool] = {}
	for rng_seed: int in SEED_COUNT:
		var first := _expired_place(rng_seed)
		assert_int(_expired_place(rng_seed)).is_equal(first)
		places[first] = true
	assert_bool(places.has(PLACE.ON_TOP)).is_true()
	assert_bool(places.has(PLACE.BELOW)).is_true()


func test_209_4_14_the_drawn_place_moves_the_card_like_the_chosen_one() -> void:
	for rng_seed: int in SEED_COUNT:
		var engine := _waiting_for_look(rng_seed)
		var deck_before := DuelChecks.card_ids(engine.get_state().get_player(A).deck)
		var events := engine.advance_clock(RESPONSE_MSEC)
		var chosen: TopCardPlaceChosen = events[1]
		var deck_after := DuelChecks.card_ids(engine.get_state().get_player(A).deck)
		if chosen.place == PLACE.ON_TOP:
			assert_array(deck_after).is_equal(deck_before)
		else:
			var rotated: Array[int] = [deck_before.back()]
			rotated.append_array(deck_before.slice(0, deck_before.size() - 1))
			assert_array(deck_after).is_equal(rotated)


func _expired_discards(rng_seed: int) -> Array[int]:
	var engine := _waiting_for_discard(rng_seed, 5, A)
	var discarded: Array[int] = []
	for event: DuelEvent in engine.advance_clock(RESPONSE_MSEC):
		if event is CardDiscardedFromHand:
			discarded.append((event as CardDiscardedFromHand).card_instance_id)
	return discarded


func _expired_place(rng_seed: int) -> int:
	var engine := _waiting_for_look(rng_seed)
	return (engine.advance_clock(RESPONSE_MSEC)[1] as TopCardPlaceChosen).place


# Un Spell « défaussez deux » (ou « défaussez une » si `hand_count` est 3) de `owner_side` s'est
# résolu ; sa main contient `hand_count` cartes. Avec `with_block`, une entrée « piochez une »
# attend dessous.
func _waiting_for_discard(
	rng_seed: int, hand_count: int, owner_side: DuelState.PlayerSide, with_block: bool = false
) -> DuelEngine:
	var builder := HandEffectSamples.builder(_catalog)
	builder.with_seed(rng_seed)
	HandEffectSamples.fill_hand(builder, owner_side, hand_count)
	builder.add_to_deck(owner_side, TriggerSamples.SOLDIER)
	if with_block:
		builder.push_spell(builder.make_card_instance(owner_side, HandEffectSamples.DRAW_ONE))
	var spell_id := (
		HandEffectSamples.DISCARD_TWO if hand_count > 3 else HandEffectSamples.DISCARD_ONE
	)
	builder.push_spell(builder.make_card_instance(owner_side, spell_id))
	builder.with_priority_player(DuelState.opponent_of(owner_side))
	var engine := DuelEngine.new(_catalog)
	engine.start_from_state(builder.build())
	DuelChecks.pass_once(engine, DuelState.opponent_of(owner_side))
	return engine


func _waiting_for_look(rng_seed: int) -> DuelEngine:
	var builder := HandEffectSamples.builder(_catalog)
	builder.with_seed(rng_seed)
	for index: int in DECK_SIZE:
		builder.add_to_deck(A, TriggerSamples.SOLDIER)
	builder.push_spell(builder.make_card_instance(A, HandEffectSamples.LOOK))
	builder.with_priority_player(B)
	var engine := DuelEngine.new(_catalog)
	engine.start_from_state(builder.build())
	DuelChecks.pass_once(engine, B)
	return engine
