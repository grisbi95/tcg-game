# gdlint: disable=max-public-methods,max-file-lines

extends GdUnitTestSuite
## Fenêtre de réponse à l'écran, décomptée par DuelHost (ruleset 0.37, 208.6 et 209.4.4g ;
## décisions 0029 et 0042).
##
## Sans scène : `ManualClock` tient lieu de temps réel. A déploie une Unit à son premier tour ;
## B, qui peut alors répondre ou passer, n'a aucune Réaction dans le deck d'essai (208.6.6).

const CLOCK_MSEC: int = 600_000  # 209.4.3 : 10 minutes
const RESPONSE_WINDOW_MSEC: int = 2_000  # 208.6.2
const UNIT_COST: int = 2  # CatalogSamples.unit()
const AGENT_SEED: int = 3
const SHORT_CLOCK_MSEC: int = 1_500  # inférieure à la fenêtre, pour la faire tomber dedans
const HANDOVER_MSEC: int = 5_000  # temps passé à se passer l'appareil
const PARTIAL_COUNTDOWN_MSEC: int = 500  # fraction de la fenêtre écoulée avant un geste
const LATE_GESTURE_MSEC: int = 300  # retard d'un geste après l'échéance
const CLOCK_LAG_MSEC: int = 700  # temps écoulé au-delà de l'échéance avant le tick
const LONG_WAIT_FACTOR: int = 10  # multiple de la fenêtre : « bien plus » long que 2 s
const REACTION_ID: StringName = &"window_reaction"
const REACTION_COST: int = 1  # CatalogSamples.spell()
const HERALD_COST: int = 2  # CatalogSamples.unit()
const SOURCE_TO_RECYCLE: int = 1  # Source inclinée par le déploiement de A, recyclée (203.6.4)

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const HOST := DuelHost.HostState

var _engine: DuelEngine
var _clock: ManualClock
var _host: DuelHost


func before_test() -> void:
	_engine = DuelEngine.new(SetupSamples.catalog())
	_clock = ManualClock.new()
	_host = DuelHost.new(_engine, _clock)


func test_208_6_1_window_opens_when_the_human_can_answer() -> void:
	_reach_answer_of_b()
	assert_int(_host.get_awaited_player()).is_equal(B)
	assert_bool(_host.is_response_window_running()).is_true()
	assert_int(_host.get_response_time_left_msec()).is_equal(RESPONSE_WINDOW_MSEC)
	_clock.advance(PARTIAL_COUNTDOWN_MSEC)
	assert_int(_host.get_response_time_left_msec()).is_equal(
		RESPONSE_WINDOW_MSEC - PARTIAL_COUNTDOWN_MSEC
	)


func test_208_6_1_window_opens_once_the_device_is_handed_over() -> void:
	_reach_first_turn_of_a()
	_deploy_from_a()
	_host.confirm_events_played()
	assert_int(_host.get_host_state()).is_equal(HOST.RELAY)
	assert_bool(_host.is_response_window_running()).is_false()
	_clock.advance(HANDOVER_MSEC)
	_host.tick()
	_host.confirm_relay()
	assert_int(_host.get_response_time_left_msec()).is_equal(RESPONSE_WINDOW_MSEC)


func test_208_6_1_answer_opens_a_window_for_the_other_player() -> void:
	_reach_window_of_a_on_reaction_of_b()
	assert_bool(_host.is_response_window_running()).is_true()
	assert_int(_host.get_response_time_left_msec()).is_equal(RESPONSE_WINDOW_MSEC)
	assert_int(_engine.get_state().stack.size()).is_equal(2)
	_clock.advance(RESPONSE_WINDOW_MSEC)
	var labels := EventLog.describe(_host.tick())
	assert_str(labels[0]).is_equal("PriorityPassed:A")
	assert_bool(_host.is_response_window_running()).is_false()
	assert_array(_engine.get_state().stack).is_empty()  # 208.3.1a : toute la pile se résout


func test_208_6_2_window_lasts_two_seconds() -> void:
	assert_int(DuelConfig.new().response_window_msec).is_equal(RESPONSE_WINDOW_MSEC)


func test_208_6_3_silent_player_passes_automatically() -> void:
	_reach_answer_of_b()
	_clock.advance(RESPONSE_WINDOW_MSEC - 1)
	assert_array(_host.tick()).is_empty()
	_clock.advance(1)
	var labels := EventLog.describe(_host.tick())
	assert_str(labels[0]).is_equal("PriorityPassed:B")
	assert_bool(_host.is_response_window_running()).is_false()
	assert_int(_host.get_host_state()).is_equal(HOST.PLAYING_EVENTS)
	assert_array(_engine.get_state().stack).is_empty()


func test_208_6_3_automatic_pass_is_journaled_like_any_intent() -> void:
	_reach_answer_of_b()
	_clock.advance(RESPONSE_WINDOW_MSEC)
	_host.tick()
	var last_entry: DuelJournal.Entry = _host.get_journal().entries.back()
	assert_object(last_entry.intent).is_instanceof(PassPriority)
	assert_int(last_entry.intent.player).is_equal(B)
	var replayed := DuelEngine.new(SetupSamples.catalog())
	_host.get_journal().replay_into(replayed)
	var no_events: Array[DuelEvent] = []
	var expected := ReplayFingerprint.of(no_events, _engine.get_state())
	var actual := ReplayFingerprint.of(no_events, replayed.get_state())
	assert_array(actual.find_differences(expected)).is_empty()


func test_208_6_3_late_gesture_comes_after_the_automatic_pass() -> void:
	_reach_answer_of_b()
	_clock.advance(RESPONSE_WINDOW_MSEC + LATE_GESTURE_MSEC)
	var labels := EventLog.describe(_host.submit_human(PassPriority.new(B)))
	assert_str(labels[0]).is_equal("PriorityPassed:B")
	assert_int(labels.count("PriorityPassed:B")).is_equal(1)


func test_208_6_3_late_response_start_does_not_cancel_the_pass() -> void:
	_reach_answer_of_b()
	_clock.advance(RESPONSE_WINDOW_MSEC)
	_host.begin_response()
	var labels := EventLog.describe(_host.tick())
	assert_str(labels[0]).is_equal("PriorityPassed:B")
	assert_array(_engine.get_state().stack).is_empty()


func test_208_6_4_player_passes_before_the_end_of_the_window() -> void:
	_reach_answer_of_b()
	_clock.advance(PARTIAL_COUNTDOWN_MSEC)
	var labels := EventLog.describe(_host.submit_human(PassPriority.new(B)))
	assert_str(labels[0]).is_equal("PriorityPassed:B")
	assert_bool(_host.is_response_window_running()).is_false()
	assert_int(_host.get_response_time_left_msec()).is_equal(0)


func test_208_6_5_started_response_stops_the_countdown() -> void:
	_reach_answer_of_b()
	_clock.advance(PARTIAL_COUNTDOWN_MSEC)
	_host.begin_response()
	assert_bool(_host.is_response_window_running()).is_false()
	assert_int(_host.get_response_time_left_msec()).is_equal(0)
	_clock.advance(RESPONSE_WINDOW_MSEC * LONG_WAIT_FACTOR)
	assert_array(_host.tick()).is_empty()
	assert_int(_host.get_host_state()).is_equal(HOST.AWAITING_HUMAN)


func test_208_6_5_response_start_ignored_outside_a_window() -> void:
	_reach_first_turn_of_a()
	_host.begin_response()  # tour de A, pile vide : aucune fenêtre
	assert_int(_host.get_host_state()).is_equal(HOST.AWAITING_HUMAN)
	assert_bool(_host.is_response_window_running()).is_false()
	_deploy_from_a()
	_host.begin_response()  # PLAYING_EVENTS
	_host.confirm_events_played()
	_host.begin_response()  # RELAY
	assert_int(_host.get_host_state()).is_equal(HOST.RELAY)
	_clock.advance(HANDOVER_MSEC)
	_host.tick()
	_host.confirm_relay()
	assert_bool(_host.is_response_window_running()).is_true()
	assert_int(_host.get_response_time_left_msec()).is_equal(RESPONSE_WINDOW_MSEC)


func test_208_6_2_window_time_is_journaled_for_the_awaited_player() -> void:
	_reach_answer_of_b()
	_clock.advance(PARTIAL_COUNTDOWN_MSEC)
	_host.tick()
	var last_entry := _last_journal_entry()
	assert_int(last_entry.kind).is_equal(DuelJournal.EntryKind.RESPONSE_WINDOW_TIME)
	assert_int(last_entry.player).is_equal(B)
	assert_int(last_entry.elapsed_msec).is_equal(PARTIAL_COUNTDOWN_MSEC)
	assert_int(_host.get_journal().response_window_elapsed_msec(B)).is_equal(PARTIAL_COUNTDOWN_MSEC)
	assert_int(_host.get_journal().response_window_elapsed_msec(A)).is_equal(0)


func test_208_6_3_automatic_pass_counts_the_window_until_its_deadline() -> void:
	_reach_answer_of_b()
	_clock.advance(RESPONSE_WINDOW_MSEC + LATE_GESTURE_MSEC)
	_host.tick()
	var journal := _host.get_journal()
	assert_int(journal.response_window_elapsed_msec(B)).is_equal(RESPONSE_WINDOW_MSEC)
	var entries := journal.entries
	var window_entry := entries[entries.size() - 3]
	var pass_entry := entries[entries.size() - 2]
	var ordinary_entry := entries[entries.size() - 1]
	assert_int(window_entry.kind).is_equal(DuelJournal.EntryKind.RESPONSE_WINDOW_TIME)
	assert_int(window_entry.elapsed_msec).is_equal(RESPONSE_WINDOW_MSEC)
	assert_object(pass_entry.intent).is_instanceof(PassPriority)
	assert_int(ordinary_entry.kind).is_equal(DuelJournal.EntryKind.ELAPSED_TIME)
	assert_int(ordinary_entry.elapsed_msec).is_equal(LATE_GESTURE_MSEC)


func test_209_4_4g_time_before_the_window_opened_is_ordinary_time() -> void:
	_reach_first_turn_of_a()
	_deploy_from_a()
	_host.confirm_events_played()
	_clock.advance(HANDOVER_MSEC)
	_host.confirm_relay()
	_clock.advance(PARTIAL_COUNTDOWN_MSEC)
	_host.tick()
	var entries := _host.get_journal().entries
	var ordinary_entry := entries[entries.size() - 2]
	assert_int(ordinary_entry.kind).is_equal(DuelJournal.EntryKind.ELAPSED_TIME)
	assert_int(ordinary_entry.elapsed_msec).is_equal(HANDOVER_MSEC)
	var window_entry := entries[entries.size() - 1]
	assert_int(window_entry.kind).is_equal(DuelJournal.EntryKind.RESPONSE_WINDOW_TIME)
	assert_int(window_entry.player).is_equal(B)
	assert_int(window_entry.elapsed_msec).is_equal(PARTIAL_COUNTDOWN_MSEC)
	assert_int(_host.get_journal().response_window_elapsed_msec(B)).is_equal(PARTIAL_COUNTDOWN_MSEC)


func test_208_6_5_started_response_is_journaled_once() -> void:
	_reach_answer_of_b()
	var entry_count := _host.get_journal().entries.size()
	_host.begin_response()
	var last_entry := _last_journal_entry()
	assert_int(last_entry.kind).is_equal(DuelJournal.EntryKind.RESPONSE_BEGUN)
	assert_int(last_entry.player).is_equal(B)
	assert_int(_host.get_journal().entries.size()).is_equal(entry_count + 1)
	_host.begin_response()
	assert_int(_host.get_journal().entries.size()).is_equal(entry_count + 1)
	assert_int(_host.get_journal().response_begun_count(B)).is_equal(1)
	assert_int(_host.get_journal().response_begun_count(A)).is_equal(0)


func test_208_6_5_response_start_outside_a_window_is_not_journaled() -> void:
	_reach_first_turn_of_a()
	var entry_count := _host.get_journal().entries.size()
	_host.begin_response()  # tour de A, pile vide : aucune fenêtre
	_deploy_from_a()
	entry_count += 1  # le déploiement lui-même
	_host.begin_response()  # PLAYING_EVENTS
	_host.confirm_events_played()
	_host.begin_response()  # RELAY
	assert_int(_host.get_host_state()).is_equal(HOST.RELAY)
	assert_int(_host.get_journal().entries.size()).is_equal(entry_count)
	for side: DuelState.PlayerSide in DuelState.SIDES:
		assert_int(_host.get_journal().response_begun_count(side)).is_equal(0)


func test_208_6_5_response_start_after_the_deadline_is_not_journaled() -> void:
	_reach_answer_of_b()
	_clock.advance(RESPONSE_WINDOW_MSEC)
	_host.begin_response()
	assert_int(_host.get_journal().response_begun_count(B)).is_equal(0)
	_host.tick()
	assert_int(_host.get_journal().response_begun_count(B)).is_equal(0)


func test_208_6_5_time_after_a_started_response_is_ordinary_time() -> void:
	_reach_answer_of_b()
	_clock.advance(PARTIAL_COUNTDOWN_MSEC)
	_host.tick()
	_host.begin_response()
	_clock.advance(CLOCK_LAG_MSEC)
	_host.tick()
	var entries := _host.get_journal().entries
	assert_int(entries[entries.size() - 3].kind).is_equal(
		DuelJournal.EntryKind.RESPONSE_WINDOW_TIME
	)
	assert_int(entries[entries.size() - 2].kind).is_equal(DuelJournal.EntryKind.RESPONSE_BEGUN)
	var ordinary_entry := entries[entries.size() - 1]
	assert_int(ordinary_entry.kind).is_equal(DuelJournal.EntryKind.ELAPSED_TIME)
	assert_int(ordinary_entry.elapsed_msec).is_equal(CLOCK_LAG_MSEC)
	assert_int(_host.get_journal().response_window_elapsed_msec(B)).is_equal(PARTIAL_COUNTDOWN_MSEC)


func test_208_6_5a_stopped_player_answers_or_passes_himself() -> void:
	_reach_answer_of_b()
	_host.begin_response()
	_clock.advance(RESPONSE_WINDOW_MSEC * LONG_WAIT_FACTOR)
	_host.tick()
	assert_array(_engine.get_state().stack).is_not_empty()
	var labels := EventLog.describe(_host.submit_human(PassPriority.new(B)))
	assert_str(labels[0]).is_equal("PriorityPassed:B")


func test_208_6_5a_essence_produced_does_not_reopen_the_window() -> void:
	_reach_window_of_a_on_reaction_of_b()
	var produce := ProduceEssence.new(A, EssencePayment.new(0, SOURCE_TO_RECYCLE))  # décision 0026
	assert_int(_engine.validate(produce)).is_equal(IntentRejected.RejectReason.NONE)
	_host.begin_response()
	var labels := EventLog.describe(_host.submit_human(produce))
	assert_str(labels[0]).is_not_equal("IntentRejected")
	_host.confirm_events_played()
	assert_int(_host.get_host_state()).is_equal(HOST.AWAITING_HUMAN)
	assert_int(_host.get_awaited_player()).is_equal(A)
	assert_bool(_host.is_response_window_running()).is_false()
	assert_int(_host.get_response_time_left_msec()).is_equal(0)
	_clock.advance(RESPONSE_WINDOW_MSEC * LONG_WAIT_FACTOR)
	assert_array(_host.tick()).is_empty()  # aucun PriorityPassed:A
	assert_int(_host.get_host_state()).is_equal(HOST.AWAITING_HUMAN)
	assert_int(_engine.get_state().stack.size()).is_equal(2)
	var pass_labels := EventLog.describe(_host.submit_human(PassPriority.new(A)))
	assert_str(pass_labels[0]).is_equal("PriorityPassed:A")
	assert_array(_engine.get_state().stack).is_empty()


func test_208_6_6_same_window_with_or_without_a_playable_reaction() -> void:
	var playable := _observe_window(true)
	var empty := _observe_window(false)
	assert_int(playable.playable_reaction_count).is_equal(1)
	assert_int(empty.playable_reaction_count).is_equal(0)
	for probe: ResponseWindowProbe in [playable, empty]:
		assert_bool(probe.was_running_at_opening).is_true()
		assert_int(probe.time_left_at_opening_msec).is_equal(RESPONSE_WINDOW_MSEC)
		assert_array(probe.labels_before_deadline).is_empty()
		assert_str(probe.labels_at_deadline[0]).is_equal("PriorityPassed:B")
	assert_int(playable.time_left_at_opening_msec).is_equal(empty.time_left_at_opening_msec)
	assert_int(playable.time_left_before_deadline_msec).is_equal(
		empty.time_left_before_deadline_msec
	)
	assert_array(playable.labels_at_deadline).is_equal(empty.labels_at_deadline)


func test_208_6_7_no_window_outside_an_answer() -> void:
	_reach_human_a()
	assert_bool(_host.is_response_window_running()).is_false()
	ResponseWindowSamples.accept_mulligans(_host)
	assert_bool(_host.is_response_window_running()).is_false()
	_clock.advance(RESPONSE_WINDOW_MSEC * LONG_WAIT_FACTOR)
	assert_array(_host.tick()).is_empty()
	assert_int(_host.get_host_state()).is_equal(HOST.AWAITING_HUMAN)


func test_208_6_7_no_window_while_a_decision_is_pending() -> void:
	_restart_duel(ResponseWindowSamples.catalog_with_herald())
	_reach_first_turn_of_a()
	var state := _engine.get_state()
	DuelStateBuilder.place_unit_in(state, B, SetupSamples.deck()[0], "B4")
	DuelStateBuilder.place_unit_in(state, B, SetupSamples.deck()[0], "D4")
	var herald := ResponseWindowSamples.add_to_hand(_engine.get_state(), A, TriggerSamples.HERALD)
	assert_bool(ResponseWindowSamples.try_deploy(_host, _engine, herald, HERALD_COST)).is_true()
	_host.confirm_events_played()
	_host.confirm_relay()
	assert_bool(_host.is_response_window_running()).is_true()
	_host.submit_human(PassPriority.new(B))
	assert_object(state.pending_decision).is_not_null()
	assert_int(state.pending_decision.kind).is_equal(PendingDecision.DecisionKind.CHOOSE_TARGETS)
	_host.confirm_events_played()
	_host.confirm_relay()
	assert_int(_host.get_awaited_player()).is_equal(A)
	assert_int(_host.get_host_state()).is_equal(HOST.AWAITING_HUMAN)
	assert_bool(_host.is_response_window_running()).is_false()
	assert_int(_host.get_response_time_left_msec()).is_equal(0)
	var intent_count := ResponseWindowSamples.journaled_intent_count(_host)
	_clock.advance(RESPONSE_WINDOW_MSEC * LONG_WAIT_FACTOR)
	assert_array(_host.tick()).is_empty()
	assert_int(ResponseWindowSamples.journaled_intent_count(_host)).is_equal(intent_count)
	assert_int(_host.get_host_state()).is_equal(HOST.AWAITING_HUMAN)
	assert_object(state.pending_decision).is_not_null()


func test_209_2_5_concede_during_the_window() -> void:
	_reach_answer_of_b()
	_clock.advance(PARTIAL_COUNTDOWN_MSEC)
	assert_bool(_host.is_response_window_running()).is_true()
	var labels := EventLog.describe(_host.concede(B))
	assert_array(labels).contains_exactly(["PlayerConceded:B", "DuelEnded"])
	assert_bool(_host.is_response_window_running()).is_false()
	assert_int(_host.get_response_time_left_msec()).is_equal(0)
	assert_int(_engine.get_state().result).is_equal(DuelState.DuelResult.PLAYER_A_WINS)
	var intent_count := ResponseWindowSamples.journaled_intent_count(_host)
	_clock.advance(RESPONSE_WINDOW_MSEC * LONG_WAIT_FACTOR)
	assert_array(_host.tick()).is_empty()
	_host.confirm_events_played()
	assert_int(_host.get_host_state()).is_equal(HOST.ENDED)
	assert_int(ResponseWindowSamples.journaled_intent_count(_host)).is_equal(intent_count)
	var last_entry: DuelJournal.Entry = _host.get_journal().entries.back()
	assert_object(last_entry.intent).is_instanceof(Concede)


func test_209_4_4g_clock_runs_during_the_window() -> void:
	_reach_answer_of_b()
	_clock.advance(RESPONSE_WINDOW_MSEC + CLOCK_LAG_MSEC)
	_host.tick()
	# La pendule de B s'arrête à l'échéance ; le reste compte après la passe automatique.
	assert_int(_engine.get_state().get_player(B).clock_remaining_msec).is_equal(
		CLOCK_MSEC - RESPONSE_WINDOW_MSEC
	)


func test_209_4_5_clock_end_during_the_window_closes_it() -> void:
	_use_short_clock(SHORT_CLOCK_MSEC)
	_reach_answer_of_b()
	assert_bool(_host.is_response_window_running()).is_true()
	_clock.advance(SHORT_CLOCK_MSEC)
	var labels := EventLog.describe(_host.tick())
	assert_array(labels).contains_exactly(["TimeExpired:B", "DuelEnded"])
	assert_array(labels).not_contains("PriorityPassed:B")
	assert_bool(_host.is_response_window_running()).is_false()
	assert_int(_host.get_response_time_left_msec()).is_equal(0)
	_host.confirm_events_played()
	assert_int(_host.get_host_state()).is_equal(HOST.ENDED)
	assert_bool(_host.is_response_window_running()).is_false()
	assert_int(_engine.get_state().result).is_equal(DuelState.DuelResult.PLAYER_A_WINS)


func test_209_4_5_clock_end_at_the_deadline_sends_no_pass() -> void:
	_use_short_clock(RESPONSE_WINDOW_MSEC)
	_reach_answer_of_b()
	var entry_count: int = _host.get_journal().entries.size()
	_clock.advance(RESPONSE_WINDOW_MSEC)
	var labels := EventLog.describe(_host.tick())
	assert_array(labels).contains_exactly(["TimeExpired:B", "DuelEnded"])
	assert_bool(_host.is_response_window_running()).is_false()
	assert_int(_host.get_response_time_left_msec()).is_equal(0)
	var last_entry: DuelJournal.Entry = _host.get_journal().entries.back()
	assert_bool(last_entry.intent is PassPriority).is_false()
	assert_int(_host.get_journal().entries.size()).is_equal(entry_count + 1)
	assert_int(_host.get_host_state()).is_equal(HOST.PLAYING_EVENTS)


func test_decision_0029_no_window_for_an_agent() -> void:
	_host.set_agent(B, RandomLegalAgent.new(AGENT_SEED))
	_host.start(_setup())
	_host.confirm_events_played()
	_host.submit_human(ChooseMulligan.new(A))
	_host.confirm_events_played()
	_host.tick()
	_host.confirm_events_played()
	_deploy_from_a()
	_host.confirm_events_played()
	assert_int(_host.get_host_state()).is_equal(HOST.AWAITING_AI)
	assert_bool(_host.is_response_window_running()).is_false()


func _last_journal_entry() -> DuelJournal.Entry:
	return _host.get_journal().entries.back()


# 209.4.3 : pendule de départ réduite, la pendule de B ne tournant que lorsqu'il est attendu.
func _use_short_clock(clock_duration_msec: int) -> void:
	var config := DuelConfig.new()
	config.clock_duration_msec = clock_duration_msec
	_engine = DuelEngine.new(SetupSamples.catalog(), config)
	_host = DuelHost.new(_engine, _clock)


# Nouveau duel complet (moteur, pendule, hôte), aussi pour comparer deux parties dans un test.
func _restart_duel(catalog: Catalog) -> void:
	_engine = DuelEngine.new(catalog)
	_clock = ManualClock.new()
	_host = DuelHost.new(_engine, _clock)


# 208.6.6 : mène A à son déploiement puis laisse la fenêtre de B aller à son échéance.
func _observe_window(give_reaction_to_b: bool) -> ResponseWindowProbe:
	_restart_duel(ResponseWindowSamples.catalog_with_reaction(REACTION_ID))
	_reach_answer_of_b()
	if give_reaction_to_b:
		ResponseWindowSamples.add_to_hand(_engine.get_state(), B, REACTION_ID)
	var reaction_count := ResponseWindowProbe.count_castable(_engine, B, REACTION_COST)
	var probe := ResponseWindowProbe.run_to_deadline(_host, _clock, RESPONSE_WINDOW_MSEC)
	probe.playable_reaction_count = reaction_count
	return probe


# 208.2.4 : A déploie, B répond par une Réaction ; A, au tour duquel on joue, reçoit sa fenêtre.
func _reach_window_of_a_on_reaction_of_b() -> void:
	_restart_duel(ResponseWindowSamples.catalog_with_reaction(REACTION_ID))
	_reach_answer_of_b()
	var reaction := ResponseWindowSamples.add_to_hand(_engine.get_state(), B, REACTION_ID)
	var cast := CastSpell.new(B, reaction.card_instance_id, EssencePayment.new(REACTION_COST))
	var cast_labels := EventLog.describe(_host.submit_human(cast))
	assert_str(cast_labels[0]).is_not_equal("IntentRejected")
	_host.confirm_events_played()
	assert_int(_host.get_host_state()).is_equal(HOST.RELAY)
	assert_int(_host.get_awaited_player()).is_equal(A)
	_clock.advance(HANDOVER_MSEC)
	_host.tick()
	_host.confirm_relay()


# Deux humains, joueur A devant l'écran pour son mulligan, sans temps écoulé.
func _reach_human_a() -> void:
	_host.start(_setup())
	_host.confirm_events_played()
	_host.confirm_relay()


func _reach_first_turn_of_a() -> void:
	_reach_human_a()
	ResponseWindowSamples.accept_mulligans(_host)


# 208.2.4 : A a annoncé un déploiement ; B a pris l'appareil et peut répondre ou passer.
func _reach_answer_of_b() -> void:
	_reach_first_turn_of_a()
	_deploy_from_a()
	_host.confirm_events_played()
	_host.confirm_relay()


func _deploy_from_a() -> void:
	for card: CardInstance in _engine.get_state().get_player(A).hand:
		if ResponseWindowSamples.try_deploy(_host, _engine, card, UNIT_COST):
			return
	fail("aucun déploiement légal pour A")


# Décision 0012 : A commence, pour des tests qui ne dépendent pas du tirage.
func _setup() -> DuelSetup:
	var setup := SetupSamples.setup()
	setup.impose_first_player(A)
	return setup
