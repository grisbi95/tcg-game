# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## Suite d'effets d'un texte (ruleset 0.55 ; 207.7.1 à 207.7.8, 211.1.5, 207.3.12, 200.4.2 ;
## décisions 0057 et 0064) : condition « si » lue dans l'ordre du texte, ordre des effets, « puis »,
## « si vous le faites », coût dépensé et carte en défausse. Les cartes viennent de TextSamples
## (Chantier, Grimoire, Étude de HandEffectSamples) ; elles ne sont pas celles de c.6.

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const SOLDIER: StringName = TriggerSamples.SOLDIER
const GIANT: StringName = TriggerSamples.GIANT
const DECK_SIZE: int = 8
const SPELL_COST: int = 1
const SOURCES_IN_PLAY: int = 4  # HandEffectSamples.builder
const DECISION := PendingDecision.DecisionKind

var _catalog: Catalog
var _builder: DuelStateBuilder
var _engine: DuelEngine


func before_test() -> void:
	_catalog = TextSamples.catalog()
	_builder = HandEffectSamples.builder(_catalog)
	_engine = DuelEngine.new(_catalog)
	for index: int in DECK_SIZE:
		_builder.add_to_deck(A, SOLDIER)
		_builder.add_to_deck(B, SOLDIER)


func test_207_7_1_if_condition_of_a_spell_is_read_when_it_resolves() -> void:
	var spell_id := _hand_with(TextSamples.IF_FEW, TextSamples.HAND_LIMIT + 1)
	_start()
	_engine.submit(HandEffectSamples.cast(A, spell_id))
	var hand := _engine.get_state().get_player(A).hand
	assert_int(hand.size()).is_greater(TextSamples.HAND_LIMIT)  # fausse à l'annonce
	hand.pop_back()  # la main change avant la résolution : vraie à la résolution
	var events := HandEffectSamples.resolve(_engine)
	assert_array(EventLog.describe(events)).contains_exactly(
		[
			"PriorityPassed:B",
			"CardDrawn:A",
			"CardDrawn:A",
			"CardDiscarded:A",
			"StackEntryResolved:A"
		]
	)


func test_207_7_1a_if_condition_is_read_when_its_effect_comes_in_the_text() -> void:
	var spell_id := _hand_with(TextSamples.MIDDLE, 1)
	_start()
	_engine.submit(HandEffectSamples.cast(A, spell_id))
	var events := HandEffectSamples.resolve(_engine)
	var draws := EventLog.describe(events).filter(
		func(label: String) -> bool: return label == "CardDrawn:A"
	)
	assert_int(draws.size()).is_equal(3)  # la main compte 2 cartes quand le second effet vient


func test_207_7_1b_if_condition_sees_what_the_previous_effects_changed() -> void:
	var spell_id := _hand_with(TextSamples.MIDDLE, TextSamples.HAND_LIMIT)
	_start()
	_engine.submit(HandEffectSamples.cast(A, spell_id))
	var hand_before := _engine.get_state().get_player(A).hand.size()
	assert_int(hand_before).is_equal(TextSamples.HAND_LIMIT)  # vraie avant le premier effet
	var events := HandEffectSamples.resolve(_engine)
	assert_array(EventLog.describe(events)).contains_exactly(
		[
			"PriorityPassed:B",
			"CardDrawn:A",
			"CardDrawn:A",
			"CardDiscarded:A",
			"StackEntryResolved:A"
		]
	)  # fausse après le premier piochez : le second effet n'a pas lieu


func test_207_7_2_effect_with_a_false_condition_does_not_happen() -> void:
	var spell_id := _hand_with(TextSamples.IF_FEW, TextSamples.HAND_LIMIT + 1)
	_start()
	_engine.submit(HandEffectSamples.cast(A, spell_id))
	var hand_size := _engine.get_state().get_player(A).hand.size()
	var events := HandEffectSamples.resolve(_engine)
	assert_array(EventLog.describe(events)).contains_exactly(
		["PriorityPassed:B", "CardDiscarded:A", "StackEntryResolved:A"]
	)
	assert_int(_engine.get_state().get_player(A).hand.size()).is_equal(hand_size)


func test_207_7_3_the_other_effects_happen_when_a_condition_is_false() -> void:
	var spell_id := _hand_with(TextSamples.MIDDLE, TextSamples.HAND_LIMIT)
	_start()
	_engine.submit(HandEffectSamples.cast(A, spell_id))
	var deck := _engine.get_state().get_player(A).deck
	var top_two := [deck[deck.size() - 1].card_instance_id, deck[deck.size() - 2].card_instance_id]
	HandEffectSamples.resolve(_engine)
	# Le premier et le troisième effet ont eu lieu (deux cartes), le deuxième non (condition fausse).
	var hand := _engine.get_state().get_player(A).hand
	assert_int(hand.size()).is_equal(TextSamples.HAND_LIMIT + 2)
	for card_id: int in top_two:
		assert_bool(DuelChecks.card_ids(hand).has(card_id)).is_true()


func test_207_7_4_effects_apply_in_the_order_of_the_text() -> void:
	var spell_id := _hand_with(HandEffectSamples.STUDY, 0)
	_start()
	_engine.submit(HandEffectSamples.cast(A, spell_id))
	var events := HandEffectSamples.resolve(_engine)
	assert_array(EventLog.describe(events)).contains_exactly(
		["PriorityPassed:B", "CardDrawn:A", "CardDrawn:A", "DecisionRequested:A"]
	)
	assert_int(_engine.get_state().pending_decision.kind).is_equal(DECISION.CHOOSE_DISCARD)


func test_207_7_4_worksite_creates_its_token_then_destroys_itself_in_one_entry() -> void:
	var worksite_id := _place_building(A, TextSamples.WORKSITE, "B2")
	_start()
	var turn_events := _engine.submit(EndTurn.new(A))
	turn_events.append_array(_engine.submit(EndTurn.new(B)))
	var state := _engine.get_state()
	assert_int(state.pending_decision.kind).is_equal(DECISION.CHOOSE_TARGETS)  # une case à choisir
	var choose := ChooseTargets.new(A)
	choose.target_cells.append(DuelStateBuilder.cell("C2"))
	var events := _engine.submit(choose)
	(
		assert_array(EventLog.describe(events))
		. contains_exactly(
			[
				"TargetsChosen:A",
				"StackEntryAdded:A",
				"TokenCreated:A",
				"PieceDestroyed:A",
				"StackEntryResolved:A",
			]
		)
	)
	assert_object(state.find_piece(worksite_id)).is_null()
	var token := state.piece_at(DuelStateBuilder.cell("C2"))
	assert_int(token.token_force).is_equal(TextSamples.TOKEN_FORCE)
	assert_bool(state.stack.is_empty()).is_true()


func test_207_7_4_grimoire_draws_then_discards_and_resumes_after_the_choice() -> void:
	var attacker_id := _place_unit(A, GIANT, "B2")
	_builder.attach_gear(attacker_id, TextSamples.GRIMOIRE)
	var defender_id := _place_unit(B, SOLDIER, "B3")
	var kept_id := _builder.add_to_hand(A, SOLDIER)
	var state := _builder.build()
	var events: Array[DuelEvent] = []
	CombatRules.resolve_attack(
		state, state.find_piece(attacker_id), state.find_piece(defender_id), events
	)
	_engine.start_from_state(state)
	assert_int(state.waiting_triggers.size()).is_equal(1)  # un seul texte, une seule entrée
	TriggerRules.add_waiting_triggers(state, events)
	var resolved := HandEffectSamples.resolve(_engine)
	assert_array(EventLog.describe(resolved)).contains_exactly(
		["PriorityPassed:B", "CardDrawn:A", "DecisionRequested:A"]
	)
	var candidates := state.pending_decision.candidate_ids.duplicate()
	candidates.erase(kept_id)
	var drawn_id: int = candidates[0]
	var answered := _engine.submit(HandEffectSamples.discard(A, [drawn_id]))
	assert_array(EventLog.describe(answered)).contains_exactly(
		["CardDiscardedFromHand:A", "StackEntryResolved:A"]
	)
	assert_array(DuelChecks.card_ids(state.get_player(A).hand)).contains_exactly([kept_id])


func test_207_7_5_then_creates_no_dependency_between_two_effects() -> void:
	var ally_id := _place_unit(A, SOLDIER, "B2")
	var spell_id := _hand_with(TextSamples.THEN_DRAW, 0)
	_start()
	_engine.submit(HandEffectSamples.cast(A, spell_id, [ally_id]))
	_remove_piece(ally_id)  # la cible est perdue avant la résolution
	var events := HandEffectSamples.resolve(_engine)
	(
		assert_array(EventLog.describe(events))
		. contains_exactly(
			[
				"PriorityPassed:B",
				"EffectLostAllTargets:A",
				"CardDrawn:A",
				"CardDiscarded:A",
				"StackEntryResolved:A",
			]
		)
	)


func test_207_7_5a_each_effect_happens_according_to_its_own_targets() -> void:
	var first_id := _place_unit(A, SOLDIER, "B2")
	var second_id := _place_unit(A, SOLDIER, "B3")
	var spell_id := _hand_with(TextSamples.THEN_DRAW, 0)
	_start()
	_engine.submit(HandEffectSamples.cast(A, spell_id, [first_id, second_id]))
	_remove_piece(first_id)
	var events := HandEffectSamples.resolve(_engine)
	(
		assert_array(EventLog.describe(events))
		. contains_exactly(
			[
				"PriorityPassed:B",
				"PieceDestroyed:A",
				"CardDrawn:A",
				"CardDiscarded:A",
				"StackEntryResolved:A",
			]
		)
	)


func test_207_7_6_if_you_do_depends_on_the_effect_that_precedes_it() -> void:
	var ally_id := _place_unit(A, SOLDIER, "B2")
	var spell_id := _hand_with(TextSamples.SACRIFICE, 0)
	_start()
	_engine.submit(HandEffectSamples.cast(A, spell_id, [ally_id]))
	var events := HandEffectSamples.resolve(_engine)
	(
		assert_array(EventLog.describe(events))
		. contains_exactly(
			[
				"PriorityPassed:B",
				"PieceDestroyed:A",
				"CardDrawn:A",
				"CardDiscarded:A",
				"StackEntryResolved:A",
			]
		)
	)


func test_207_7_6_if_you_do_survives_a_wait_for_a_choice() -> void:
	var spell_id := _hand_with(TextSamples.REPLACE, 2)
	_start()
	_engine.submit(HandEffectSamples.cast(A, spell_id))
	var hand := DuelChecks.card_ids(_engine.get_state().get_player(A).hand)
	var requested := HandEffectSamples.resolve(_engine)
	assert_array(EventLog.describe(requested)).contains_exactly(
		["PriorityPassed:B", "DecisionRequested:A"]
	)
	var answered := _engine.submit(HandEffectSamples.discard(A, [hand[0]]))
	assert_array(EventLog.describe(answered)).contains_exactly(
		["CardDiscardedFromHand:A", "CardDrawn:A", "CardDiscarded:A", "StackEntryResolved:A"]
	)


func test_207_7_6a_if_you_do_happens_when_the_preceding_effect_happened_in_part() -> void:
	var first_id := _place_unit(A, SOLDIER, "B2")
	var second_id := _place_unit(A, SOLDIER, "B3")
	var spell_id := _hand_with(TextSamples.SACRIFICE, 0)
	_start()
	_engine.submit(HandEffectSamples.cast(A, spell_id, [first_id, second_id]))
	_remove_piece(second_id)  # une seule des deux cibles reste : l'effet a lieu en partie (200.4.2)
	var events := HandEffectSamples.resolve(_engine)
	(
		assert_array(EventLog.describe(events))
		. contains_exactly(
			[
				"PriorityPassed:B",
				"PieceDestroyed:A",
				"CardDrawn:A",
				"CardDiscarded:A",
				"StackEntryResolved:A",
			]
		)
	)


func test_207_7_6a_if_you_do_does_not_happen_when_the_preceding_effect_did_not() -> void:
	var ally_id := _place_unit(A, SOLDIER, "B2")
	var spell_id := _hand_with(TextSamples.SACRIFICE, 0)
	_start()
	_engine.submit(HandEffectSamples.cast(A, spell_id, [ally_id]))
	_remove_piece(ally_id)
	var events := HandEffectSamples.resolve(_engine)
	assert_array(EventLog.describe(events)).contains_exactly(
		["PriorityPassed:B", "EffectLostAllTargets:A", "CardDiscarded:A", "StackEntryResolved:A"]
	)


func test_207_7_6a_if_you_do_does_not_happen_when_nothing_could_be_discarded() -> void:
	var spell_id := _hand_with(TextSamples.REPLACE, 0)
	_start()
	_engine.submit(HandEffectSamples.cast(A, spell_id))
	var events := HandEffectSamples.resolve(_engine)  # la main est vide : défausser n'a pas lieu
	assert_array(EventLog.describe(events)).contains_exactly(
		["PriorityPassed:B", "CardDiscarded:A", "StackEntryResolved:A"]
	)


func test_207_7_6b_if_you_do_is_not_an_if_condition() -> void:
	# Main pleine de cartes : une condition « si votre main compte 2 cartes ou moins » serait fausse,
	# « si vous le faites » ne lit aucune condition.
	var ally_id := _place_unit(A, SOLDIER, "B2")
	var spell_id := _hand_with(TextSamples.SACRIFICE, TextSamples.HAND_LIMIT + 2)
	_start()
	_engine.submit(HandEffectSamples.cast(A, spell_id, [ally_id]))
	var events := HandEffectSamples.resolve(_engine)
	assert_bool(EventLog.describe(events).has("CardDrawn:A")).is_true()


func test_207_7_7_the_cost_stays_spent_when_a_condition_is_false() -> void:
	var spell_id := _hand_with(TextSamples.IF_FEW, TextSamples.HAND_LIMIT + 1)
	_start()
	var player := _engine.get_state().get_player(A)
	var upright_before := player.sources_upright
	_engine.submit(HandEffectSamples.cast(A, spell_id))
	HandEffectSamples.resolve(_engine)
	assert_int(player.sources_upright).is_equal(upright_before - SPELL_COST)
	assert_int(player.sources_tilted).is_equal(SPELL_COST)


func test_207_7_8_the_spell_card_goes_to_the_discard_when_a_condition_is_false() -> void:
	var spell_id := _hand_with(TextSamples.IF_FEW, TextSamples.HAND_LIMIT + 1)
	_start()
	_engine.submit(HandEffectSamples.cast(A, spell_id))
	HandEffectSamples.resolve(_engine)
	var player := _engine.get_state().get_player(A)
	assert_array(DuelChecks.card_ids(player.discard)).contains_exactly([spell_id])
	assert_object(_engine.get_state().resolving_entry).is_null()


func test_211_1_5_condition_of_an_order_is_read_when_it_resolves() -> void:
	var true_events := _announce_order(0)
	assert_array(EventLog.describe(true_events)).contains_exactly(
		["PriorityPassed:B", "CardDrawn:A", "StackEntryResolved:A"]
	)


func test_211_1_5_order_with_a_false_condition_has_no_effect_and_its_cost_stays_spent() -> void:
	var events := _announce_order(TextSamples.HAND_LIMIT + 1)
	assert_array(EventLog.describe(events)).contains_exactly(
		["PriorityPassed:B", "StackEntryResolved:A"]
	)
	var player := _engine.get_state().get_player(A)
	assert_int(player.sources_tilted).is_equal(TextSamples.COST)  # 207.7.7, 211.3.2
	assert_array(player.discard).is_empty()  # 211.1.4 : un Ordre n'est pas un Spell


# Ajoute le Spell `spell` à la main de A avec `fillers` cartes de plus ; renvoie l'identifiant.
func _hand_with(spell: StringName, fillers: int) -> int:
	HandEffectSamples.fill_hand(_builder, A, fillers)
	return _builder.add_to_hand(A, spell)


func _announce_order(fillers: int) -> Array[DuelEvent]:
	_builder.with_hero_definition(A, TextSamples.HERO)
	HandEffectSamples.fill_hand(_builder, A, fillers)
	_start()
	var order := AnnounceOrder.new(A, TextSamples.ORDER_INDEX, EssencePayment.new(TextSamples.COST))
	_engine.submit(order)
	return HandEffectSamples.resolve(_engine)


func _start() -> void:
	_engine.start_from_state(_builder.build())


func _place_unit(side: DuelState.PlayerSide, definition_id: StringName, cell: String) -> int:
	return NamedTriggerSamples.place(_builder, side, Piece.PieceKind.UNIT, definition_id, cell)


func _place_building(side: DuelState.PlayerSide, definition_id: StringName, cell: String) -> int:
	return NamedTriggerSamples.place(_builder, side, Piece.PieceKind.BUILDING, definition_id, cell)


func _remove_piece(piece_id: int) -> void:
	var state := _engine.get_state()
	state.pieces.erase(state.find_piece(piece_id))
