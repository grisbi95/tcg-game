extends GdUnitTestSuite
## Choix pendant une résolution (décision 0057, complète 0009 et 0017 ; ruleset 0.53, 208.3.2,
## 208.4.11, 209.2.2, 212.1.3, 217.1.2). Une attente posée par un effet suspend le bloc de la
## pile ; la réponse termine l'entrée, puis reprend le bloc. Les effets déclenchés attendent la
## fin du bloc.

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const REASON := IntentRejected.RejectReason
const DECISION := PendingDecision.DecisionKind
const MAX_DISCARD_CANDIDATES: int = 24  # RandomLegalAgent
const AGENT_SEEDS: Array[int] = [1, 2, 3, 4, 5, 6]
const AGENT_STEPS: int = 250
const HOST_SEED: int = 3
const HOST_TICKS: int = 300
const HOST_TICK_MSEC: int = 700
const HAND_LIMIT: int = 7  # 201.3.4

var _catalog: Catalog
## Partagée par les moteurs comparés : la configuration est en lecture seule (DeepCompare).
var _config: DuelConfig = DuelConfig.new()
var _builder: DuelStateBuilder
var _engine: DuelEngine


func before_test() -> void:
	_catalog = HandEffectSamples.catalog()
	_builder = HandEffectSamples.builder(_catalog)
	_engine = DuelEngine.new(_catalog)


func test_decision_0057_the_block_resumes_with_the_rest_of_the_stack_after_the_choice() -> void:
	var hand_ids := HandEffectSamples.fill_hand(_builder, A, 3)
	var deck_id := _builder.add_to_deck(A, TriggerSamples.SOLDIER)
	var bottom_id := _push_spell(HandEffectSamples.DRAW_ONE)
	var top_id := _push_spell(HandEffectSamples.DISCARD_ONE)
	var waiting := EventLog.describe(DuelChecks.pass_once(_engine, B))
	assert_array(waiting).contains_exactly(["PriorityPassed:B", "DecisionRequested:A"])
	var state := _engine.get_state()
	assert_int(state.resolving_entry.stack_entry_id).is_equal(top_id)
	assert_array(state.stack).has_size(1)
	assert_int(state.stack[0].stack_entry_id).is_equal(bottom_id)
	var resumed := _engine.submit(HandEffectSamples.discard(A, [hand_ids[0]]))
	assert_array(EventLog.describe(resumed)).contains_exactly(
		[
			"CardDiscardedFromHand:A",
			"CardDiscarded:A",
			"StackEntryResolved:A",
			"CardDrawn:A",
			"CardDiscarded:A",
			"StackEntryResolved:A"
		]
	)
	var resolved_ids: Array[int] = []
	for event: DuelEvent in resumed:
		if event is StackEntryResolved:
			resolved_ids.append((event as StackEntryResolved).stack_entry_id)
	assert_array(resolved_ids).contains_exactly([top_id, bottom_id])
	assert_array(state.stack).is_empty()
	assert_object(state.resolving_entry).is_null()
	assert_int(state.resolving_effect_index).is_equal(0)
	assert_bool(DuelChecks.card_ids(state.get_player(A).hand).has(deck_id)).is_true()


func test_decision_0057_the_entry_is_resolved_once_and_its_spell_card_waits_on_it() -> void:
	HandEffectSamples.fill_hand(_builder, A, 3)
	var top_id := _push_spell(HandEffectSamples.STUDY)
	var waiting := DuelChecks.pass_once(_engine, B)
	assert_bool(EventLog.describe(waiting).has("StackEntryResolved:A")).is_false()
	var state := _engine.get_state()
	var spell_card := state.resolving_entry.card
	assert_array(DuelChecks.card_ids(state.get_player(A).discard)).is_empty()
	(
		assert_bool(DuelChecks.card_ids(state.get_player(A).hand).has(spell_card.card_instance_id))
		. is_false()
	)
	var ids := state.pending_decision.candidate_ids
	var resumed := _engine.submit(HandEffectSamples.discard(A, [ids[0]]))
	var resolved := resumed.filter(
		func(event: DuelEvent) -> bool: return event is StackEntryResolved
	)
	assert_int(resolved.size()).is_equal(1)
	var only_resolved: StackEntryResolved = resolved[0]
	assert_int(only_resolved.stack_entry_id).is_equal(top_id)
	var discard_ids := DuelChecks.card_ids(state.get_player(A).discard)
	assert_int(discard_ids.count(spell_card.card_instance_id)).is_equal(1)


func test_decision_0057_a_victory_during_the_resumed_block_ends_the_duel() -> void:
	var hand_ids := HandEffectSamples.fill_hand(_builder, A, 3)
	_builder.with_hero_health(A, 1)
	_push_spell(HandEffectSamples.DRAW_ONE)
	_push_spell(HandEffectSamples.DISCARD_ONE)
	DuelChecks.pass_once(_engine, B)
	var resumed := _engine.submit(HandEffectSamples.discard(A, [hand_ids[0]]))
	assert_array(EventLog.describe(resumed)).contains_exactly(
		[
			"CardDiscardedFromHand:A",
			"CardDiscarded:A",
			"StackEntryResolved:A",
			"FatigueIncreased:A",
			"HeroLostHealth:A",
			"DuelEnded"
		]
	)
	var state := _engine.get_state()
	assert_bool(state.is_ended()).is_true()
	assert_int(state.result).is_equal(DuelState.DuelResult.PLAYER_B_WINS)
	assert_object(state.pending_decision).is_null()
	assert_array(_engine.awaited_players()).is_empty()


func test_decision_0057_a_triggered_effect_waits_for_the_end_of_the_block() -> void:
	var hand_ids := HandEffectSamples.fill_hand(_builder, A, 3)
	var martyr_id := _builder.place_piece(
		B, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B4"), TriggerSamples.MARTYR
	)
	_builder.place_piece(
		B, Piece.PieceKind.UNIT, DuelStateBuilder.cell("D4"), TriggerSamples.SOLDIER
	)
	_push_spell(HandEffectSamples.DISCARD_ONE)
	_push_spell(HandEffectSamples.DESTROYER, [martyr_id])
	var waiting := EventLog.describe(DuelChecks.pass_once(_engine, B))
	assert_array(waiting).contains_exactly(
		[
			"PriorityPassed:B",
			"PieceDestroyed:B",
			"EffectTriggered:B",
			"CardDiscarded:A",
			"StackEntryResolved:A",
			"DecisionRequested:A"
		]
	)
	var state := _engine.get_state()
	assert_array(state.stack).is_empty()
	assert_array(state.waiting_triggers).has_size(1)
	var resumed := EventLog.describe(_engine.submit(HandEffectSamples.discard(A, [hand_ids[1]])))
	assert_array(resumed.slice(0, 3)).contains_exactly(
		["CardDiscardedFromHand:A", "CardDiscarded:A", "StackEntryResolved:A"]
	)
	assert_bool(resumed.has("StackEntryAdded:B")).is_true()
	assert_array(state.waiting_triggers).is_empty()
	assert_array(state.stack).has_size(1)


func test_decision_0057_a_refused_answer_changes_nothing_during_the_resolution() -> void:
	var hand_ids := HandEffectSamples.fill_hand(_builder, A, 3)
	_push_spell(HandEffectSamples.DRAW_ONE)
	_push_spell(HandEffectSamples.DISCARD_ONE)
	DuelChecks.pass_once(_engine, B)
	var not_in_hand: Array[int] = [DuelState.NO_ID]
	var too_many: Array[int] = [hand_ids[0], hand_ids[1]]
	for ids: Array[int] in [not_in_hand, too_many]:
		var intent := HandEffectSamples.discard(A, ids)
		assert_int(_engine.validate(intent)).is_not_equal(REASON.NONE)
		(
			assert_array(DuelChecks.rejection_defects(_engine, intent, _engine.validate(intent)))
			. is_empty()
		)
	var state := _engine.get_state()
	assert_object(state.resolving_entry).is_not_null()
	assert_int(state.resolving_effect_index).is_equal(1)


func test_decision_0057_a_clone_taken_during_the_wait_resumes_identically() -> void:
	var hand_ids := HandEffectSamples.fill_hand(_builder, A, 3)
	_builder.add_to_deck(A, TriggerSamples.SOLDIER)
	_push_spell(HandEffectSamples.DRAW_ONE)
	_push_spell(HandEffectSamples.DISCARD_ONE)
	DuelChecks.pass_once(_engine, B)
	var twin := DuelEngine.new(_catalog)
	twin.start_from_state(_engine.get_state().clone())
	var answer := HandEffectSamples.discard(A, [hand_ids[2]])
	var first := EventLog.describe(_engine.submit(answer))
	var second := EventLog.describe(twin.submit(answer))
	assert_array(first).is_equal(second)
	var defects := DeepCompare.find_clone_defects(_engine.get_state(), twin.get_state())
	assert_array(Array(defects)).is_empty()


func test_decision_0057_the_wait_is_not_a_priority_and_awaits_only_the_owner() -> void:
	HandEffectSamples.fill_hand(_builder, A, 3)
	_push_spell(HandEffectSamples.DISCARD_ONE)
	DuelChecks.pass_once(_engine, B)
	assert_array(_engine.awaited_players()).contains_exactly([A])
	for intent: DuelIntent in [PassPriority.new(A), PassPriority.new(B), EndTurn.new(A)]:
		assert_int(_engine.validate(intent)).is_equal(REASON.DECISION_PENDING)


func test_decision_0057_the_agent_answers_a_discard_wait_with_bounded_legal_choices() -> void:
	HandEffectSamples.fill_hand(_builder, A, HAND_LIMIT)
	_push_spell(HandEffectSamples.STUDY)
	_engine.get_state().stack[0].card.definition_id = HandEffectSamples.DISCARD_TWO
	var required := 3
	DuelChecks.pass_once(_engine, B)
	_engine.get_state().pending_decision.required_count = required
	var candidates := RandomLegalAgent.candidates(_engine.get_state(), A)
	assert_int(candidates.size()).is_equal(MAX_DISCARD_CANDIDATES)
	for candidate: DuelIntent in candidates:
		assert_bool(candidate is ChooseDiscard).is_true()
		assert_int((candidate as ChooseDiscard).card_ids.size()).is_equal(required)


func test_decision_0057_the_agent_samples_discard_choices_with_its_own_seed() -> void:
	HandEffectSamples.fill_hand(_builder, A, HAND_LIMIT)
	_push_spell(HandEffectSamples.DISCARD_TWO)
	DuelChecks.pass_once(_engine, B)
	_engine.get_state().pending_decision.required_count = 3
	var state := _engine.get_state()
	var truncated := RandomLegalAgent.candidates(state, A)
	var sampler := RandomNumberGenerator.new()
	sampler.seed = 5
	var sampled := RandomLegalAgent.candidates(state, A, sampler)
	assert_int(sampled.size()).is_equal(MAX_DISCARD_CANDIDATES)
	assert_array(EventLog.describe_intents(sampled)).is_not_equal(
		EventLog.describe_intents(truncated)
	)
	for candidate: DuelIntent in sampled:
		assert_int(_engine.validate(candidate)).is_equal(REASON.NONE)


func test_decision_0057_the_agent_answers_a_top_card_wait_with_both_places() -> void:
	_builder.add_to_deck(A, TriggerSamples.SOLDIER)
	_push_spell(HandEffectSamples.LOOK)
	DuelChecks.pass_once(_engine, B)
	var candidates := RandomLegalAgent.candidates(_engine.get_state(), A)
	assert_int(candidates.size()).is_equal(ChooseTopCardPlace.TopCardPlace.size())
	for candidate: DuelIntent in candidates:
		assert_int(_engine.validate(candidate)).is_equal(REASON.NONE)


func test_decision_0057_random_agents_play_the_hand_effect_cards_without_defects() -> void:
	var asked := 0
	for rng_seed: int in AGENT_SEEDS:
		var report := _play_agents(rng_seed)
		var message := "graine %d : %s" % [rng_seed, "\n".join(report.defects)]
		assert_array(Array(report.defects)).override_failure_message(message).is_empty()
		asked += report.hand_choices
	assert_int(asked).is_greater(0)


func test_decision_0057_a_host_journal_with_hand_choices_replays_to_the_same_duel() -> void:
	var setup := _hand_effect_setup(HOST_SEED)
	var host_engine := DuelEngine.new(_catalog, _config)
	var clock := ManualClock.new()
	var host := DuelHost.new(host_engine, clock)
	host.set_agent(A, RandomLegalAgent.new(HOST_SEED))
	host.set_agent(B, RandomLegalAgent.new(HOST_SEED + 1))
	var host_events := host.start(setup)
	host_events.append_array(HostDriver.run(host, clock, HOST_TICK_MSEC, HOST_TICKS))
	var replay_engine := DuelEngine.new(_catalog, _config)
	var replay_events := host.get_journal().replay_into(replay_engine)
	assert_array(EventLog.describe(replay_events)).is_equal(EventLog.describe(host_events))
	var defects := DeepCompare.find_clone_defects(
		host_engine.get_state(), replay_engine.get_state()
	)
	assert_array(Array(defects)).is_empty()
	assert_bool(_has_hand_choice(host_events)).is_true()


# Empile un Spell de A et l'état de départ ; la priorité revient à B, qui passe. Renvoie l'entrée.
func _push_spell(spell_id: StringName, piece_ids: Array[int] = []) -> int:
	var card := _builder.make_card_instance(A, spell_id)
	var entry_id := _builder.push_spell(card, piece_ids)
	_builder.with_priority_player(B)
	_engine.start_from_state(_builder.build())
	return entry_id


func _has_hand_choice(events: Array[DuelEvent]) -> bool:
	return events.any(
		func(event: DuelEvent) -> bool:
			return event is CardDiscardedFromHand or event is TopCardPlaceChosen
	)


func _hand_effect_setup(rng_seed: int) -> DuelSetup:
	_catalog.add_hero(HeroDefinition.from_dict(CatalogSamples.hero()))
	var kinds: Array[StringName] = [
		HandEffectSamples.STUDY,
		HandEffectSamples.DISCARD_TWO,
		HandEffectSamples.DISCARD_ONE,
		HandEffectSamples.INSPIRATION,
		HandEffectSamples.DRAW_ONE,
		HandEffectSamples.LOOK,
		HandEffectSamples.CHARGE,
		HandEffectSamples.SCOUT,
		HandEffectSamples.LOOKOUT,
		TriggerSamples.SOLDIER,
	]
	var deck: Array[StringName] = []
	for kind: StringName in kinds:
		for copy: int in SetupSamples.COPIES_PER_CARD:
			deck.append(kind)
	return SetupSamples.mirror_setup(deck, SetupSamples.HERO_ID, rng_seed)


func _play_agents(rng_seed: int) -> AgentReport:
	var report := AgentReport.new()
	var engine := DuelEngine.new(_catalog)
	var events := engine.start_new_duel(_hand_effect_setup(rng_seed))
	var agent := RandomLegalAgent.new(rng_seed)
	for step: int in AGENT_STEPS:
		if engine.get_state().is_ended():
			break
		var intent := agent.choose_intent(engine)
		if intent == null:
			report.defects.append("pas %d : aucune intention légale" % step)
			break
		events = engine.submit(intent)
		events.append_array(engine.advance_clock(HOST_TICK_MSEC))
		if EventLog.rejection_reason(events) != EventLog.NOT_A_SINGLE_REJECTION:
			report.defects.append("pas %d : intention refusée" % step)
		for violation: String in DuelOracle.find_violations(engine.get_state()):
			report.defects.append("pas %d : %s" % [step, violation])
		if _has_hand_choice(events):
			report.hand_choices += 1
		if not report.defects.is_empty():
			break
	return report


class AgentReport:
	extends RefCounted
	var defects: PackedStringArray = PackedStringArray()
	var hand_choices: int = 0
