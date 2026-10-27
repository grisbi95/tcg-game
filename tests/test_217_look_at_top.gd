extends GdUnitTestSuite
## Regarder le dessus du deck (ruleset 0.53, chapitre 217 ; 201.4.1, 201.4.1a, 201.3.1, 207.5.13 ;
## décision de design 0235 du ruleset ; décision 0057). Le Spell et l'Unit viennent de
## HandEffectSamples. 217.1.5 et 201.4.1a (ce que voit chaque joueur) relèvent de la vue : le
## moteur est omniscient (0043), voir RULES_WITHOUT_OWN_TEST.

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const REASON := IntentRejected.RejectReason
const DECISION := PendingDecision.DecisionKind
const PLACE := ChooseTopCardPlace.TopCardPlace
const DECK_SIZE: int = 3
const NOT_A_PLACE: int = 7

var _builder: DuelStateBuilder
var _engine: DuelEngine


func before_test() -> void:
	var catalog := HandEffectSamples.catalog()
	_builder = HandEffectSamples.builder(catalog)
	_engine = DuelEngine.new(catalog)


func test_217_1_1_only_the_owner_of_the_deck_looks_at_its_top_card() -> void:
	var deck_ids := _fill_deck(A)
	var labels := EventLog.describe(_cast_and_resolve())
	assert_array(labels).contains_exactly(
		["PriorityPassed:B", "TopCardLooked:A", "DecisionRequested:A"]
	)
	var state := _engine.get_state()
	assert_int(state.pending_decision.kind).is_equal(DECISION.CHOOSE_TOP_CARD_PLACE)
	assert_array(state.pending_decision.awaited_players).contains_exactly([A])
	assert_array(_engine.awaited_players()).contains_exactly([A])
	assert_array(state.pending_decision.candidate_ids).contains_exactly([deck_ids.back()])


func test_217_1_1_the_looked_card_is_the_top_card_of_the_deck_of_the_owner() -> void:
	var deck_ids := _fill_deck(A)
	var enemy_ids := _fill_deck(B)
	var events := _cast_and_resolve()
	var looked := events.filter(func(event: DuelEvent) -> bool: return event is TopCardLooked)
	assert_int(looked.size()).is_equal(1)
	var first_look: TopCardLooked = looked[0]
	assert_int(first_look.card_instance_id).is_equal(deck_ids.back())
	assert_int(first_look.player).is_equal(A)
	var enemy_deck := _engine.get_state().get_player(B).deck
	assert_array(DuelChecks.card_ids(enemy_deck)).contains_exactly(enemy_ids)


func test_217_1_8_the_effect_looks_at_the_top_card_only() -> void:
	var deck_ids := _fill_deck(A)
	var events := _cast_and_resolve()
	var looked := events.filter(func(event: DuelEvent) -> bool: return event is TopCardLooked)
	assert_int(looked.size()).is_equal(1)
	var state := _engine.get_state()
	assert_array(state.pending_decision.candidate_ids).contains_exactly([deck_ids.back()])
	assert_int(state.pending_decision.required_count).is_equal(0)  # aucune autre carte à choisir
	assert_array(DuelChecks.card_ids(state.get_player(A).deck)).contains_exactly(deck_ids)


func test_217_1_8_the_other_cards_of_the_deck_keep_their_order() -> void:
	var deck_ids := _fill_deck(A)
	_cast_and_resolve()
	_engine.submit(HandEffectSamples.place(A, true))
	var expected: Array[int] = [deck_ids.back()]
	expected.append_array(deck_ids.slice(0, deck_ids.size() - 1))
	var deck := _engine.get_state().get_player(A).deck
	assert_array(DuelChecks.card_ids(deck)).contains_exactly(expected)


func test_217_1_8_a_look_effect_names_no_number_of_cards() -> void:
	var look := HandEffectSamples.look_effect()
	assert_array(Array(CatalogSamples.effect_errors(look))).is_empty()
	look["amount"] = 2
	assert_bool(CatalogSamples.mentions(CatalogSamples.effect_errors(look), "206.5.1")).is_true()
	look["amount"] = "X"
	look["x_from"] = {"kind": "hand_size"}
	(
		assert_bool(CatalogSamples.mentions(CatalogSamples.effect_errors(look), "amount « X »"))
		. is_true()
	)


func test_217_1_2_the_player_leaves_the_card_on_top() -> void:
	var deck_ids := _fill_deck(A)
	_cast_and_resolve()
	var events := _engine.submit(HandEffectSamples.place(A, false))
	assert_array(EventLog.describe(events)).contains_exactly(
		["TopCardPlaceChosen:A", "CardDiscarded:A", "StackEntryResolved:A"]
	)
	assert_int((events[0] as TopCardPlaceChosen).place).is_equal(PLACE.ON_TOP)
	var deck := _engine.get_state().get_player(A).deck
	assert_array(DuelChecks.card_ids(deck)).contains_exactly(deck_ids)
	assert_object(_engine.get_state().pending_decision).is_null()


func test_217_1_3_the_player_puts_the_card_below_the_deck() -> void:
	var deck_ids := _fill_deck(A)
	_cast_and_resolve()
	var events := _engine.submit(HandEffectSamples.place(A, true))
	assert_int((events[0] as TopCardPlaceChosen).place).is_equal(PLACE.BELOW)
	var deck := _engine.get_state().get_player(A).deck
	var top_id: int = deck_ids.back()
	var expected: Array[int] = [top_id]
	expected.append_array(deck_ids.slice(0, DECK_SIZE - 1))
	assert_array(DuelChecks.card_ids(deck)).contains_exactly(expected)
	assert_int(deck.back().card_instance_id).is_equal(deck_ids[DECK_SIZE - 2])


func test_217_1_4_the_opponent_sees_the_choice_but_not_the_card() -> void:
	_fill_deck(A)
	_fill_deck(B)
	_cast_and_resolve()
	var events := _engine.submit(HandEffectSamples.place(A, true))
	var chosen: TopCardPlaceChosen = events[0]
	assert_int(chosen.place).is_equal(PLACE.BELOW)
	assert_bool(ScriptFields.of(chosen).has("card_instance_id")).is_false()


func test_217_1_6_the_choice_is_not_a_target() -> void:
	_fill_deck(A)
	_fill_deck(B)
	var piece_id := _builder.place_piece(
		B, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B4"), TriggerSamples.SOLDIER
	)
	var card_id := _builder.add_to_hand(A, HandEffectSamples.LOOK)
	_engine.start_from_state(_builder.build())
	assert_int(_engine.validate(HandEffectSamples.cast(A, card_id, [piece_id]))).is_equal(
		REASON.WRONG_TARGET_COUNT
	)
	_engine.submit(HandEffectSamples.cast(A, card_id))
	HandEffectSamples.resolve(_engine)
	var answer := ChooseTargets.new(A)
	answer.target_piece_ids.append(piece_id)
	assert_int(_engine.validate(answer)).is_equal(REASON.NOT_THE_PENDING_DECISION)


func test_217_1_7_empty_deck_the_effect_does_not_happen() -> void:
	var labels := EventLog.describe(_cast_and_resolve())
	assert_array(labels).contains_exactly(
		["PriorityPassed:B", "CardDiscarded:A", "StackEntryResolved:A"]
	)
	assert_object(_engine.get_state().pending_decision).is_null()
	assert_int(_engine.get_state().get_player(A).fatigue_counter).is_equal(0)


func test_217_1_2_a_deck_of_one_card_still_asks_for_the_choice() -> void:
	_builder.add_to_deck(A, TriggerSamples.SOLDIER)
	_cast_and_resolve()
	assert_object(_engine.get_state().pending_decision).is_not_null()
	_engine.submit(HandEffectSamples.place(A, true))
	assert_int(_engine.get_state().get_player(A).deck.size()).is_equal(1)


func test_217_1_3_an_answer_that_is_neither_on_top_nor_below_is_refused() -> void:
	_fill_deck(A)
	_fill_deck(B)
	_cast_and_resolve()
	var unknown := ChooseTopCardPlace.new(A, NOT_A_PLACE as PLACE)
	(
		assert_array(DuelChecks.rejection_defects(_engine, unknown, REASON.UNKNOWN_CARD_PLACE))
		. is_empty()
	)


func test_217_1_1_only_the_awaited_player_answers() -> void:
	_fill_deck(A)
	_fill_deck(B)
	_cast_and_resolve()
	var enemy_answer := HandEffectSamples.place(B, true)
	(
		assert_array(DuelChecks.rejection_defects(_engine, enemy_answer, REASON.PLAYER_NOT_AWAITED))
		. is_empty()
	)
	var discard_answer := HandEffectSamples.discard(A, [])
	(
		assert_array(
			DuelChecks.rejection_defects(_engine, discard_answer, REASON.NOT_THE_PENDING_DECISION)
		)
		. is_empty()
	)


func test_217_1_1_a_triggered_effect_looks_at_the_top_card_of_its_owner() -> void:
	var deck_ids := _fill_deck(A)
	var deploy_card := _builder.make_card_instance(A, HandEffectSamples.LOOKOUT)
	_builder.push_deploy(deploy_card, DuelStateBuilder.cell("B1"))
	_builder.with_priority_player(B)
	_engine.start_from_state(_builder.build())
	DuelChecks.pass_once(_engine, B)
	var labels := EventLog.describe(DuelChecks.pass_once(_engine, B))
	assert_bool(labels.has("TopCardLooked:A")).is_true()
	assert_int(_engine.get_state().pending_decision.kind).is_equal(DECISION.CHOOSE_TOP_CARD_PLACE)
	assert_array(_engine.get_state().pending_decision.candidate_ids).contains_exactly(
		[deck_ids.back()]
	)


# Chaque deck reçoit DECK_SIZE cartes ; renvoie les identifiants de celui de `side`, dessous en
# premier.
func _fill_deck(side: DuelState.PlayerSide) -> Array[int]:
	var card_ids: Array[int] = []
	for index: int in DECK_SIZE:
		card_ids.append(_builder.add_to_deck(side, TriggerSamples.SOLDIER))
	return card_ids


func _cast_and_resolve() -> Array[DuelEvent]:
	var card_id := _builder.add_to_hand(A, HandEffectSamples.LOOK)
	_engine.start_from_state(_builder.build())
	_engine.submit(HandEffectSamples.cast(A, card_id))
	return HandEffectSamples.resolve(_engine)
