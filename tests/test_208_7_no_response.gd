# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## Annonces sans réponse (ruleset 0.41, section 208.7 ; 208.2.4, 204.5.3, 204.5.6 ; décision de
## design 0207 du ruleset, décision 0046). Un Spell et une attaque laissent répondre ; toute autre
## annonce, et les effets qu'elle fait naître, se résolvent dans la même soumission, sans que
## personne puisse répondre ni passer.
##
## Le combat en attente (208.7.14) se teste dans test_205_6_pending_combat.gd.

const REACTION_ID: StringName = &"no_response_reaction"
const REACTION_COST: int = 1  # CatalogSamples.spell()
const GEAR_ID: StringName = &"sample_gear"
const GEAR_COST: int = 1  # CatalogSamples.gear()
const HERO_ID: StringName = &"sample_hero"
const POWER_COST: int = 2  # CatalogSamples.hero()
const UNIT_COST: int = 2  # CatalogSamples.unit()
const SHORT_RESPONSE_MSEC: int = 1_234

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const REASON := IntentRejected.RejectReason

var _builder: DuelStateBuilder
var _engine: DuelEngine


func before_test() -> void:
	var catalog := TriggerSamples.catalog()
	var reaction := CatalogSamples.with_field(CatalogSamples.spell(), "id", String(REACTION_ID))
	catalog.add_card(CardDefinition.from_dict(CatalogSamples.with_field(reaction, "effects", [])))
	catalog.add_card(CardDefinition.from_dict(CatalogSamples.gear()))
	catalog.add_hero(HeroDefinition.from_dict(CatalogSamples.hero()))
	_builder = DuelStateBuilder.new(DuelConfig.new(), catalog)
	_builder.with_sources_in_play(A, 5, 0)
	_builder.with_response_time_remaining(B, SHORT_RESPONSE_MSEC)
	_engine = DuelEngine.new(catalog)


func test_208_7_1_player_can_answer_a_spell() -> void:
	var card_id := _builder.add_to_hand(A, REACTION_ID)
	_start()
	var events := _engine.submit(CastSpell.new(A, card_id, EssencePayment.new(REACTION_COST)))
	assert_array(EventLog.describe(events)).contains_exactly(
		["SourceInclined:A", "SpellAnnounced:A", "StackEntryAdded:A"]
	)
	var state := _engine.get_state()
	assert_bool(state.stack[0].allows_response).is_true()
	assert_int(state.priority_player).is_equal(B)
	assert_int(_engine.validate(PassPriority.new(B))).is_equal(REASON.NONE)


func test_208_7_2_player_can_answer_an_attack() -> void:
	var unit_id := _place(A, TriggerSamples.GIANT, "B3")
	_place(B, TriggerSamples.SOLDIER, "B4")
	_start()
	var events := _engine.submit(TakeNormalAction.new(A, unit_id, DuelStateBuilder.cell("B4")))
	assert_array(EventLog.describe(events)).contains_exactly(
		["NormalActionAnnounced:A", "StackEntryAdded:A"]
	)
	var state := _engine.get_state()
	assert_bool(state.stack[0].allows_response).is_true()
	assert_int(state.priority_player).is_equal(B)
	assert_int(_engine.validate(PassPriority.new(B))).is_equal(REASON.NONE)


func test_208_7_3_deploy_announcement_is_without_response() -> void:
	var card_id := _builder.add_to_hand(A, TriggerSamples.SOLDIER)
	_start()
	var deploy := DeployCard.new(
		A, card_id, DuelStateBuilder.cell("B1"), EssencePayment.new(UNIT_COST)
	)
	var labels := EventLog.describe(_engine.submit(deploy))
	assert_array(labels.slice(-4)).contains_exactly(
		["DeployAnnounced:A", "StackEntryAdded:A", "PieceDeployed:A", "StackEntryResolved:A"]
	)
	_assert_nobody_can_answer()


func test_208_7_4_unit_action_to_a_free_cell_is_without_response() -> void:
	var unit_id := _place(A, TriggerSamples.SOLDIER, "B2")
	_start()
	var events := _engine.submit(TakeNormalAction.new(A, unit_id, DuelStateBuilder.cell("B3")))
	assert_array(EventLog.describe(events)).contains_exactly(
		["NormalActionAnnounced:A", "StackEntryAdded:A", "PieceMoved:A", "StackEntryResolved:A"]
	)
	_assert_nobody_can_answer()


func test_208_7_5_hero_action_is_without_response() -> void:
	_start()
	var hero_id := _engine.get_state().find_hero(A).piece_id
	var events := _engine.submit(TakeNormalAction.new(A, hero_id, DuelStateBuilder.cell("C2")))
	assert_array(EventLog.describe(events)).contains_exactly(
		["NormalActionAnnounced:A", "StackEntryAdded:A", "PieceMoved:A", "StackEntryResolved:A"]
	)
	_assert_nobody_can_answer()


func test_208_7_6_gear_announcement_is_without_response() -> void:
	var unit_id := _place(A, TriggerSamples.SOLDIER, "B2")
	var card_id := _builder.add_to_hand(A, GEAR_ID)
	_start()
	var attach := AttachGear.new(A, card_id, unit_id, EssencePayment.new(GEAR_COST))
	var labels := EventLog.describe(_engine.submit(attach))
	assert_array(labels.slice(-4)).contains_exactly(
		["GearAnnounced:A", "StackEntryAdded:A", "GearAttached:A", "StackEntryResolved:A"]
	)
	_assert_nobody_can_answer()


func test_208_7_7_hero_power_announcement_is_without_response() -> void:
	var unit_id := _place(A, TriggerSamples.SOLDIER, "B2")
	_builder.with_hero_definition(A, HERO_ID)
	_start()
	var power := UseHeroPower.new(A, EssencePayment.new(POWER_COST))
	power.target_piece_ids.append(unit_id)
	var labels := EventLog.describe(_engine.submit(power))
	assert_array(labels.slice(-4)).contains_exactly(
		["HeroPowerAnnounced:A", "StackEntryAdded:A", "ForceModified:A", "StackEntryResolved:A"]
	)
	_assert_nobody_can_answer()


func test_208_7_8_trigger_by_an_announcement_without_response_is_without_response() -> void:
	var waiting := _trigger_after_announcement(false)
	assert_bool(waiting.allows_response).is_false()


func test_208_7_10_trigger_by_a_spell_or_an_attack_announcement_keeps_the_response() -> void:
	var waiting := _trigger_after_announcement(true)
	assert_bool(waiting.allows_response).is_true()


func test_208_7_9_trigger_during_the_resolution_of_an_announcement_without_response() -> void:
	var enemy_id := _place(B, TriggerSamples.SOLDIER, "B4")
	var card_id := _builder.add_to_hand(A, TriggerSamples.HERALD)
	_start()
	var deploy := DeployCard.new(
		A, card_id, DuelStateBuilder.cell("B1"), EssencePayment.new(UNIT_COST)
	)
	var labels := EventLog.describe(_engine.submit(deploy))
	(
		assert_array(labels.slice(-10))
		. contains_exactly(
			[
				"DeployAnnounced:A",
				"StackEntryAdded:A",
				"PieceDeployed:A",
				"EffectTriggered:A",
				"StackEntryResolved:A",
				"DecisionResolvedAutomatically:A",
				"DecisionResolvedAutomatically:A",
				"StackEntryAdded:A",
				"ForceModified:B",
				"StackEntryResolved:A",
			]
		)
	)
	_assert_nobody_can_answer()
	assert_int(_force_of(enemy_id)).is_equal(
		TriggerSamples.SOLDIER_FORCE + TriggerSamples.HERALD_MALUS
	)


func test_208_7_11_trigger_during_the_resolution_of_an_attack_keeps_the_response() -> void:
	var giant_id := _place(A, TriggerSamples.GIANT, "B3")
	_place(B, TriggerSamples.MARTYR, "B4")
	_place(B, TriggerSamples.SOLDIER, "D5")
	_start()
	_engine.submit(TakeNormalAction.new(A, giant_id, DuelStateBuilder.cell("B4")))
	var labels := EventLog.describe(_engine.submit(PassPriority.new(B)))
	assert_array(labels).contains(["PieceDestroyed:B", "EffectTriggered:B", "StackEntryAdded:B"])
	var state := _engine.get_state()
	assert_int(state.stack.size()).is_equal(1)
	assert_bool(state.stack[0].allows_response).is_true()
	assert_int(state.priority_player).is_equal(A)


func test_208_7_12_nobody_can_answer_or_pass_after_an_entry_without_response() -> void:
	var state := _builder.build()
	var entry := StackEntry.new()
	entry.kind = StackEntry.StackEntryKind.DEPLOY
	entry.owner = A
	entry.allows_response = false
	var events: Array[DuelEvent] = []
	StackRules.add_to_stack(state, entry, events)
	assert_int(state.priority_player).is_equal(A)
	assert_int(state.get_player(B).response_time_remaining_msec).is_equal(SHORT_RESPONSE_MSEC)
	assert_array(EventLog.describe(events)).contains_exactly(["StackEntryAdded:A"])
	var reaction_id := _builder.add_to_hand(B, REACTION_ID)
	_engine.start_from_state(state)
	var cast := CastSpell.new(B, reaction_id, EssencePayment.new(REACTION_COST))
	assert_int(_engine.validate(PassPriority.new(B))).is_equal(REASON.NOT_YOUR_PRIORITY)
	assert_int(_engine.validate(cast)).is_not_equal(REASON.NONE)


func test_208_7_13_pile_with_an_entry_without_response_resolves_at_once() -> void:
	var first_id := _push_spell_without_response(A)
	var second_id := _push_spell_without_response(B)
	var third_id := _push_spell_without_response(A)
	_start()
	assert_bool(StackRules.resolves_at_once(_engine.get_state())).is_true()
	var events := _engine.submit(ProduceEssence.new(A, EssencePayment.new(1)))
	var resolved_ids: Array[int] = []
	for event: DuelEvent in events:
		if event is StackEntryResolved:
			resolved_ids.append((event as StackEntryResolved).stack_entry_id)
	assert_array(resolved_ids).is_equal([third_id, second_id, first_id])
	assert_array(_engine.get_state().stack).is_empty()
	assert_int(_engine.get_state().priority_player).is_equal(A)


func test_208_7_13_pile_of_entries_with_response_waits_for_a_pass() -> void:
	_builder.push_spell(_builder.make_card_instance(A, REACTION_ID))
	_start()
	assert_bool(StackRules.resolves_at_once(_engine.get_state())).is_false()


func test_208_7_15_effects_triggered_during_the_start_of_the_turn_are_without_response() -> void:
	# Aucun TriggerEvent ne se déclenche au début du tour aujourd'hui : le test se limite à
	# l'étiquette que recevrait un tel effet.
	var state := _builder.build()
	state.triggers_allow_response = true
	var events: Array[DuelEvent] = []
	TurnRules.start_turn(state, B, events)
	assert_bool(state.triggers_allow_response).is_false()


func test_208_7_16_effects_triggered_by_the_end_of_the_turn_are_without_response() -> void:
	var soldier_id := _place(A, TriggerSamples.SOLDIER, "D1")
	_place_building(A, TriggerSamples.BEACON, "B2")
	_start()
	var labels := EventLog.describe(_engine.submit(EndTurn.new(A)))
	(
		assert_array(labels.slice(0, 7))
		. contains_exactly(
			[
				"TurnEnded:A",
				"EffectTriggered:A",
				"DecisionResolvedAutomatically:A",
				"DecisionResolvedAutomatically:A",
				"StackEntryAdded:A",
				"ForceModified:A",
				"StackEntryResolved:A",
			]
		)
	)
	assert_bool(labels.has("TurnStarted:B")).is_true()
	var state := _engine.get_state()
	assert_int(state.active_player).is_equal(B)
	assert_array(state.stack).is_empty()
	assert_int(_force_of(soldier_id)).is_equal(TriggerSamples.SOLDIER_FORCE)


# Aucune carte ne se déclenche encore à une annonce (208.4.4) : on déclenche l'Arrivée d'une pièce
# aussitôt après l'ajout à la pile de l'annonce, pour lire l'étiquette que l'effet reçoit.
func _trigger_after_announcement(allows_response: bool) -> StackEntry:
	var piece_id := _place(A, TriggerSamples.HERALD, "B1")
	var state := _builder.build()
	var announcement := StackEntry.new()
	announcement.owner = A
	announcement.allows_response = allows_response
	var events: Array[DuelEvent] = []
	StackRules.add_to_stack(state, announcement, events)
	var arrival := EffectDefinition.TriggerEvent.ARRIVAL
	TriggerRules.trigger(state, state.find_piece(piece_id), arrival, events)
	return state.waiting_triggers[0]


# 208.7.12 : la pile est vide, la main est au joueur actif et l'adversaire n'a rien à passer.
func _assert_nobody_can_answer() -> void:
	var state := _engine.get_state()
	assert_array(state.stack).is_empty()
	assert_int(state.priority_player).is_equal(A)
	assert_int(state.get_player(B).response_time_remaining_msec).is_equal(SHORT_RESPONSE_MSEC)
	assert_int(_engine.validate(PassPriority.new(B))).is_equal(REASON.STACK_EMPTY)


func _push_spell_without_response(side: DuelState.PlayerSide) -> int:
	var entry_id := _builder.push_spell(_builder.make_card_instance(side, REACTION_ID))
	_builder.build().find_stack_entry(entry_id).allows_response = false
	return entry_id


func _start() -> void:
	_engine.start_from_state(_builder.build())


func _place(side: DuelState.PlayerSide, definition_id: StringName, cell_name: String) -> int:
	return _builder.place_piece(
		side, Piece.PieceKind.UNIT, DuelStateBuilder.cell(cell_name), definition_id
	)


func _place_building(
	side: DuelState.PlayerSide, definition_id: StringName, cell_name: String
) -> int:
	return _builder.place_piece(
		side, Piece.PieceKind.BUILDING, DuelStateBuilder.cell(cell_name), definition_id
	)


func _force_of(piece_id: int) -> int:
	var state := _engine.get_state()
	return ForceRules.current_force(state, state.find_piece(piece_id))
