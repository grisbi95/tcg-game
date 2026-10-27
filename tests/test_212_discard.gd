# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## Défausser (ruleset 0.53, chapitre 212 ; 201.3.2, 201.3.3, 201.3.6a, 202.2.12, 202.2.13, 206.3.1,
## 207.1.7, 207.6.5 ; décision de design 0214 du ruleset ; décisions 0004 et 0057). Les Spells
## viennent de HandEffectSamples. 212.2.5 (déclencheur de défausse) est codée à l'étape c.5.

const HAND_LIMIT: int = 7  # 201.3.4
const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const REASON := IntentRejected.RejectReason
const DECISION := PendingDecision.DecisionKind

var _builder: DuelStateBuilder
var _engine: DuelEngine


func before_test() -> void:
	var catalog := HandEffectSamples.catalog()
	_builder = HandEffectSamples.builder(catalog)
	_engine = DuelEngine.new(catalog)


func test_212_1_1_discarding_moves_the_card_from_hand_to_discard() -> void:
	var hand_ids := HandEffectSamples.fill_hand(_builder, A, 3)
	_cast_and_resolve(HandEffectSamples.DISCARD_ONE)
	var events := _engine.submit(HandEffectSamples.discard(A, [hand_ids[1]]))
	assert_array(EventLog.describe(events)).contains_exactly(
		["CardDiscardedFromHand:A", "CardDiscarded:A", "StackEntryResolved:A"]
	)
	var player := _engine.get_state().get_player(A)
	assert_array(DuelChecks.card_ids(player.hand)).contains_exactly([hand_ids[0], hand_ids[2]])
	assert_bool(DuelChecks.card_ids(player.discard).has(hand_ids[1])).is_true()


func test_212_1_2_the_owner_of_the_entry_discards() -> void:
	var own_ids := HandEffectSamples.fill_hand(_builder, B, 3)
	var other_ids := HandEffectSamples.fill_hand(_builder, A, 2)
	_builder.push_spell(_builder.make_card_instance(B, HandEffectSamples.DISCARD_ONE))
	_builder.with_priority_player(A)
	_engine.start_from_state(_builder.build())
	var resolved := DuelChecks.pass_once(_engine, A)
	assert_array(EventLog.describe(resolved)).contains_exactly(
		["PriorityPassed:A", "DecisionRequested:B"]
	)
	assert_array(_engine.awaited_players()).contains_exactly([B])
	var snapshot := _engine.get_state().clone()
	var refused := _engine.submit(HandEffectSamples.discard(A, [other_ids[0]]))
	assert_int(EventLog.rejection_reason(refused)).is_equal(REASON.PLAYER_NOT_AWAITED)
	assert_array(DeepCompare.find_clone_defects(snapshot, _engine.get_state())).is_empty()
	_engine.submit(HandEffectSamples.discard(B, [own_ids[2]]))
	var state := _engine.get_state()
	assert_array(DuelChecks.card_ids(state.get_player(B).hand)).contains_exactly(
		[own_ids[0], own_ids[1]]
	)
	assert_array(DuelChecks.card_ids(state.get_player(A).hand)).contains_exactly(other_ids)


func test_212_1_3_the_player_chooses_the_card_when_the_effect_resolves() -> void:
	var hand_ids := HandEffectSamples.fill_hand(_builder, A, 3)
	var card_id := _builder.add_to_hand(A, HandEffectSamples.DISCARD_ONE)
	_engine.start_from_state(_builder.build())
	var announced := _engine.submit(HandEffectSamples.cast(A, card_id))
	assert_array(EventLog.describe(announced)).contains_exactly(
		["SourceInclined:A", "SpellAnnounced:A", "StackEntryAdded:A"]
	)
	assert_object(_engine.get_state().pending_decision).is_null()
	assert_int(_engine.get_state().get_player(A).hand.size()).is_equal(hand_ids.size())
	var resolved := HandEffectSamples.resolve(_engine)
	assert_array(EventLog.describe(resolved)).contains_exactly(
		["PriorityPassed:B", "DecisionRequested:A"]
	)
	var decision := _engine.get_state().pending_decision
	assert_int(decision.kind).is_equal(DECISION.CHOOSE_DISCARD)
	assert_array(decision.awaited_players).contains_exactly([A])
	assert_int(decision.required_count).is_equal(1)
	assert_array(decision.candidate_ids).contains_exactly(hand_ids)


func test_212_1_4_the_choice_of_a_card_is_not_a_target() -> void:
	HandEffectSamples.fill_hand(_builder, A, 3)
	var piece_id := _builder.place_piece(
		B, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B4"), TriggerSamples.SOLDIER
	)
	var card_id := _builder.add_to_hand(A, HandEffectSamples.DISCARD_ONE)
	_engine.start_from_state(_builder.build())
	var with_target := HandEffectSamples.cast(A, card_id, [piece_id])
	assert_int(_engine.validate(with_target)).is_equal(REASON.WRONG_TARGET_COUNT)
	_engine.submit(HandEffectSamples.cast(A, card_id))
	HandEffectSamples.resolve(_engine)
	var answer := ChooseTargets.new(A)
	answer.target_piece_ids.append(piece_id)
	assert_int(_engine.validate(answer)).is_equal(REASON.NOT_THE_PENDING_DECISION)


func test_212_1_5_discarding_is_never_a_cost() -> void:
	var hand_ids := HandEffectSamples.fill_hand(_builder, A, 3)
	var card_id := _builder.add_to_hand(A, HandEffectSamples.DISCARD_TWO)
	_engine.start_from_state(_builder.build())
	var announced := _engine.submit(HandEffectSamples.cast(A, card_id))
	assert_bool(EventLog.describe(announced).has("CardDiscardedFromHand:A")).is_false()
	var player := _engine.get_state().get_player(A)
	assert_array(DuelChecks.card_ids(player.hand)).contains_exactly(hand_ids)
	assert_array(player.discard).is_empty()
	var wrong_payment := CastSpell.new(A, card_id, EssencePayment.new(0, 0))
	assert_int(_engine.validate(wrong_payment)).is_not_equal(REASON.NONE)


func test_212_1_6_empty_hand_the_effect_does_not_happen() -> void:
	var labels := EventLog.describe(_cast_and_resolve(HandEffectSamples.DISCARD_ONE))
	assert_array(labels).contains_exactly(
		["PriorityPassed:B", "CardDiscarded:A", "StackEntryResolved:A"]
	)
	assert_object(_engine.get_state().pending_decision).is_null()


func test_212_1_7_fewer_cards_than_asked_all_the_hand_is_discarded() -> void:
	var hand_ids := HandEffectSamples.fill_hand(_builder, A, 1)
	var labels := EventLog.describe(_cast_and_resolve(HandEffectSamples.DISCARD_TWO))
	assert_array(labels).contains_exactly(
		[
			"PriorityPassed:B",
			"DecisionResolvedAutomatically:A",
			"CardDiscardedFromHand:A",
			"CardDiscarded:A",
			"StackEntryResolved:A"
		]
	)
	var player := _engine.get_state().get_player(A)
	assert_array(player.hand).is_empty()
	assert_bool(DuelChecks.card_ids(player.discard).has(hand_ids[0])).is_true()


func test_212_1_7_as_many_cards_as_asked_is_a_single_choice_taken_for_the_player() -> void:
	HandEffectSamples.fill_hand(_builder, A, 2)
	var labels := EventLog.describe(_cast_and_resolve(HandEffectSamples.DISCARD_TWO))
	assert_array(labels).contains_exactly(
		[
			"PriorityPassed:B",
			"DecisionResolvedAutomatically:A",
			"CardDiscardedFromHand:A",
			"CardDiscardedFromHand:A",
			"CardDiscarded:A",
			"StackEntryResolved:A"
		]
	)


func test_212_1_7_more_cards_than_asked_the_player_chooses() -> void:
	HandEffectSamples.fill_hand(_builder, A, 3)
	_cast_and_resolve(HandEffectSamples.DISCARD_TWO)
	var decision := _engine.get_state().pending_decision
	assert_int(decision.required_count).is_equal(2)
	var one_card: Array[int] = [decision.candidate_ids[0]]
	assert_int(_engine.validate(HandEffectSamples.discard(A, one_card))).is_equal(
		REASON.WRONG_DISCARD_COUNT
	)


func test_212_2_1_a_discard_by_an_effect_is_a_card_discarded_from_hand() -> void:
	var hand_ids := HandEffectSamples.fill_hand(_builder, A, 3)
	_cast_and_resolve(HandEffectSamples.DISCARD_ONE)
	var events := _engine.submit(HandEffectSamples.discard(A, [hand_ids[0]]))
	var discards := events.filter(func(e: DuelEvent) -> bool: return e is CardDiscardedFromHand)
	assert_int(discards.size()).is_equal(1)
	var discarded: CardDiscardedFromHand = discards[0]
	assert_int(discarded.card_instance_id).is_equal(hand_ids[0])
	assert_int(discarded.player).is_equal(A)


func test_212_2_2_other_passages_to_the_discard_are_not_discards() -> void:
	var soldier_id := _builder.place_piece(
		B, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B4"), TriggerSamples.SOLDIER
	)
	var events := _cast_and_resolve(HandEffectSamples.DESTROYER, [soldier_id])
	var labels := EventLog.describe(events)
	assert_bool(labels.has("PieceDestroyed:B")).is_true()
	assert_bool(labels.has("CardDiscarded:A")).is_true()
	assert_bool(_has_hand_discard(events)).is_false()


func test_212_2_2a_a_resolved_spell_is_not_discarded() -> void:
	var events := _cast_and_resolve(HandEffectSamples.DRAW_ONE)
	assert_bool(EventLog.describe(events).has("CardDiscarded:A")).is_true()
	assert_bool(_has_hand_discard(events)).is_false()


func test_212_2_2a_a_countered_spell_is_not_discarded() -> void:
	var spell_id := _builder.add_to_hand(A, HandEffectSamples.DRAW_ONE)
	var counter_id := _builder.add_to_hand(B, HandEffectSamples.COUNTER)
	_engine.start_from_state(_builder.build())
	var announced := _engine.submit(HandEffectSamples.cast(A, spell_id))
	var counter := HandEffectSamples.cast(B, counter_id)
	counter.target_stack_entry_ids.append(_stack_entry_id(announced))
	var events := _engine.submit(counter)
	events.append_array(DuelChecks.pass_once(_engine, A))
	var labels := EventLog.describe(events)
	assert_bool(labels.has("SpellCountered:A")).is_true()
	assert_bool(labels.has("CardDiscarded:A")).is_true()
	assert_bool(_has_hand_discard(events)).is_false()


func test_212_2_2b_a_destroyed_piece_is_not_discarded() -> void:
	var soldier_id := _builder.place_piece(
		B, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B4"), TriggerSamples.SOLDIER
	)
	var soldier_card_id := _builder.build().find_piece(soldier_id).card.card_instance_id
	var events := _cast_and_resolve(HandEffectSamples.DESTROYER, [soldier_id])
	assert_bool(_has_hand_discard(events)).is_false()
	var discard := _engine.get_state().get_player(B).discard
	assert_array(DuelChecks.card_ids(discard)).contains_exactly([soldier_card_id])


func test_212_2_2c_a_detached_gear_is_not_discarded() -> void:
	var soldier_id := _builder.place_piece(
		B, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B4"), TriggerSamples.SOLDIER
	)
	var gear_id := _builder.attach_gear(soldier_id, HandEffectSamples.GEAR)
	var events := _cast_and_resolve(HandEffectSamples.DESTROYER, [soldier_id])
	assert_bool(EventLog.describe(events).has("CardDiscarded:B")).is_true()
	assert_bool(_has_hand_discard(events)).is_false()
	var discard := _engine.get_state().get_player(B).discard
	assert_bool(DuelChecks.card_ids(discard).has(gear_id)).is_true()


func test_212_2_2c_a_replaced_gear_is_not_discarded() -> void:
	var soldier_id := _builder.place_piece(
		A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B2"), TriggerSamples.SOLDIER
	)
	var old_gear_id := _builder.attach_gear(soldier_id, HandEffectSamples.GEAR)
	var new_gear_id := _builder.add_to_hand(A, HandEffectSamples.GEAR)
	_engine.start_from_state(_builder.build())
	var intent := AttachGear.new(A, new_gear_id, soldier_id, EssencePayment.new(1))
	var events := _engine.submit(intent)
	assert_bool(EventLog.describe(events).has("CardDiscarded:A")).is_true()
	assert_bool(_has_hand_discard(events)).is_false()
	var discard := _engine.get_state().get_player(A).discard
	assert_array(DuelChecks.card_ids(discard)).contains_exactly([old_gear_id])


func test_212_2_2d_a_card_refused_by_a_full_hand_is_not_discarded() -> void:
	var soldier_id := _builder.place_piece(
		B, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B4"), TriggerSamples.SOLDIER
	)
	HandEffectSamples.fill_hand(_builder, B, HAND_LIMIT)
	var events := _cast_and_resolve(HandEffectSamples.RETURNER, [soldier_id])
	assert_bool(EventLog.describe(events).has("CardDiscarded:B")).is_true()
	assert_bool(_has_hand_discard(events)).is_false()


func test_212_2_3_the_player_chooses_all_the_cards_at_the_same_time() -> void:
	var hand_ids := HandEffectSamples.fill_hand(_builder, A, 4)
	_cast_and_resolve(HandEffectSamples.DISCARD_TWO)
	var snapshot := _engine.get_state().clone()
	var one_card: Array[int] = [hand_ids[0]]
	(
		assert_array(
			DuelChecks.rejection_defects(
				_engine, HandEffectSamples.discard(A, one_card), REASON.WRONG_DISCARD_COUNT
			)
		)
		. is_empty()
	)
	var three_cards: Array[int] = [hand_ids[0], hand_ids[1], hand_ids[2]]
	(
		assert_array(
			DuelChecks.rejection_defects(
				_engine, HandEffectSamples.discard(A, three_cards), REASON.WRONG_DISCARD_COUNT
			)
		)
		. is_empty()
	)
	assert_array(DeepCompare.find_clone_defects(snapshot, _engine.get_state())).is_empty()
	var both: Array[int] = [hand_ids[1], hand_ids[3]]
	var events := _engine.submit(HandEffectSamples.discard(A, both))
	assert_object(_engine.get_state().pending_decision).is_null()
	assert_bool(_has_hand_discard(events)).is_true()


func test_212_2_3_a_choice_that_is_not_in_the_hand_or_repeats_a_card_is_refused() -> void:
	var hand_ids := HandEffectSamples.fill_hand(_builder, A, 4)
	var in_deck_id := _builder.add_to_deck(A, TriggerSamples.SOLDIER)
	var enemy_id := _builder.add_to_hand(B, TriggerSamples.SOLDIER)
	_cast_and_resolve(HandEffectSamples.DISCARD_TWO)
	var from_deck: Array[int] = [hand_ids[0], in_deck_id]
	var from_enemy: Array[int] = [hand_ids[0], enemy_id]
	var twice: Array[int] = [hand_ids[0], hand_ids[0]]
	for ids: Array[int] in [from_deck, from_enemy]:
		var intent := HandEffectSamples.discard(A, ids)
		(
			assert_array(DuelChecks.rejection_defects(_engine, intent, REASON.CARD_NOT_IN_HAND))
			. is_empty()
		)
	var repeated := HandEffectSamples.discard(A, twice)
	assert_array(DuelChecks.rejection_defects(_engine, repeated, REASON.DUPLICATE_CARD)).is_empty()


func test_212_2_3_while_the_choice_is_pending_other_intents_are_refused() -> void:
	HandEffectSamples.fill_hand(_builder, A, 3)
	_cast_and_resolve(HandEffectSamples.DISCARD_ONE)
	var snapshot := _engine.get_state().clone()
	var refused := _engine.submit(EndTurn.new(A))
	assert_int(EventLog.rejection_reason(refused)).is_equal(REASON.DECISION_PENDING)
	var not_pending := _engine.submit(HandEffectSamples.place(A, true))
	assert_int(EventLog.rejection_reason(not_pending)).is_equal(REASON.NOT_THE_PENDING_DECISION)
	assert_array(DeepCompare.find_clone_defects(snapshot, _engine.get_state())).is_empty()


func test_212_2_4_each_discarded_card_is_a_distinct_event() -> void:
	var hand_ids := HandEffectSamples.fill_hand(_builder, A, 4)
	_cast_and_resolve(HandEffectSamples.DISCARD_TWO)
	var both: Array[int] = [hand_ids[3], hand_ids[0]]
	var events := _engine.submit(HandEffectSamples.discard(A, both))
	assert_array(EventLog.describe(events)).contains_exactly(
		[
			"CardDiscardedFromHand:A",
			"CardDiscardedFromHand:A",
			"CardDiscarded:A",
			"StackEntryResolved:A"
		]
	)
	var discards := events.filter(func(e: DuelEvent) -> bool: return e is CardDiscardedFromHand)
	var identifiers: Array[int] = []
	for event: DuelEvent in discards:
		identifiers.append((event as CardDiscardedFromHand).card_instance_id)
	assert_array(identifiers).contains_exactly([hand_ids[3], hand_ids[0]])


# Annonce `spell_id` de A, que B laisse se résoudre ; renvoie les événements de la résolution.
func _cast_and_resolve(spell_id: StringName, piece_ids: Array[int] = []) -> Array[DuelEvent]:
	var card_id := _builder.add_to_hand(A, spell_id)
	_engine.start_from_state(_builder.build())
	_engine.submit(HandEffectSamples.cast(A, card_id, piece_ids))
	return HandEffectSamples.resolve(_engine)


func _has_hand_discard(events: Array[DuelEvent]) -> bool:
	return events.any(func(event: DuelEvent) -> bool: return event is CardDiscardedFromHand)


func _stack_entry_id(events: Array[DuelEvent]) -> int:
	for event: DuelEvent in events:
		if event is StackEntryAdded:
			return (event as StackEntryAdded).stack_entry_id
	return DuelState.NO_ID
