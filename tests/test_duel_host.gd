# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## DuelHost : machine à états, relais, agents et temps réel (ruleset 0.40, 209.4.4f, 209.4.9,
## 209.4.10 ; décisions 0020, 0021 et 0045).
##
## Sans scène : `ManualClock` tient lieu de temps réel, et chaque lot d'événements est confirmé
## comme affiché par l'appel que ferait la scène.

const CLOCK_MSEC: int = 90_000  # 209.4.3 : temps de tour de 90 secondes
const AGENT_SEED: int = 3
const AGENT_STEP_MSEC: int = 1_000
## Un duel d'agents finit bien avant : l'hôte qui avance sans bloquer atteint ENDED.
const MAX_HOST_STEPS: int = 5_000
const UNKNOWN_HERO: StringName = &"unknown_hero"
const SHORT_RESPONSE_MSEC: int = 3_000  # 209.4.6 réduit
const OVERRUN_MSEC: int = 5_000  # temps écoulé fenêtre ouverte, plus que le temps de réponse de B
const UNIT_COST: int = 2  # CatalogSamples.unit()

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


func test_decision_0020_start_plays_the_first_events() -> void:
	assert_int(_host.get_host_state()).is_equal(HOST.NOT_STARTED)
	var events := _host.start(SetupSamples.setup())
	assert_array(events).is_not_empty()
	assert_int(_host.get_host_state()).is_equal(HOST.PLAYING_EVENTS)


func test_decision_0020_rejected_setup_leaves_the_host_not_started() -> void:
	var setup := SetupSamples.setup()
	setup.hero_a = UNKNOWN_HERO
	var events := _host.start(setup)
	assert_array(EventLog.describe(events)).contains_exactly(["DuelSetupRejected"])
	assert_int(_host.get_host_state()).is_equal(HOST.NOT_STARTED)


func test_decision_0020_two_humans_relay_to_the_first_awaited_player() -> void:
	_host.start(SetupSamples.setup())
	_host.confirm_events_played()
	assert_int(_host.get_host_state()).is_equal(HOST.RELAY)
	assert_int(_host.get_awaited_player()).is_equal(A)
	_host.confirm_relay()
	assert_int(_host.get_host_state()).is_equal(HOST.AWAITING_HUMAN)
	assert_int(_host.get_screen_player()).is_equal(A)


func test_decision_0020_relay_between_humans_for_the_mulligan() -> void:
	_reach_human_a()
	var events := _host.submit_human(ChooseMulligan.new(A))
	assert_array(EventLog.describe(events)).contains_exactly(["MulliganDecided:A"])
	_host.confirm_events_played()
	assert_int(_host.get_host_state()).is_equal(HOST.RELAY)
	assert_int(_host.get_awaited_player()).is_equal(B)
	_host.confirm_relay()
	assert_int(_host.get_screen_player()).is_equal(B)


func test_decision_0020_human_intent_ignored_outside_awaiting_human() -> void:
	_host.start(SetupSamples.setup())
	_host.confirm_events_played()
	var snapshot := _engine.get_state().clone()
	assert_array(_host.submit_human(ChooseMulligan.new(A))).is_empty()
	assert_int(_host.get_host_state()).is_equal(HOST.RELAY)
	assert_array(DeepCompare.find_clone_defects(snapshot, _engine.get_state())).is_empty()


func test_decision_0020_human_intent_ignored_from_the_other_player() -> void:
	_reach_human_a()
	var snapshot := _engine.get_state().clone()
	assert_array(_host.submit_human(ChooseMulligan.new(B))).is_empty()
	assert_int(_host.get_host_state()).is_equal(HOST.AWAITING_HUMAN)
	assert_array(DeepCompare.find_clone_defects(snapshot, _engine.get_state())).is_empty()


func test_decision_0020_rejected_intent_keeps_the_human_awaited() -> void:
	_reach_human_a()
	var events := _host.submit_human(EndTurn.new(A))
	assert_int(EventLog.rejection_reason(events)).is_equal(
		IntentRejected.RejectReason.DECISION_PENDING
	)
	assert_int(_host.get_host_state()).is_equal(HOST.AWAITING_HUMAN)


func test_decision_0020_single_human_holds_the_screen_without_relay() -> void:
	_host.set_agent(A, RandomLegalAgent.new(AGENT_SEED))
	_host.start(SetupSamples.setup())
	assert_int(_host.get_screen_player()).is_equal(B)
	_host.confirm_events_played()
	assert_int(_host.get_host_state()).is_equal(HOST.AWAITING_AI)


func test_decision_0020_agent_plays_on_the_next_tick() -> void:
	_host.set_agent(B, RandomLegalAgent.new(AGENT_SEED))
	_host.start(SetupSamples.setup())
	_host.confirm_events_played()
	assert_int(_host.get_host_state()).is_equal(HOST.AWAITING_HUMAN)
	_host.submit_human(ChooseMulligan.new(A))
	_host.confirm_events_played()
	assert_int(_host.get_host_state()).is_equal(HOST.AWAITING_AI)
	assert_int(_host.get_awaited_player()).is_equal(B)
	var events := _host.tick()
	assert_str(EventLog.describe(events)[0]).is_equal("MulliganDecided:B")
	assert_int(_host.get_host_state()).is_equal(HOST.PLAYING_EVENTS)


func test_decision_0020_two_agents_play_until_the_end() -> void:
	_host.set_agent(A, RandomLegalAgent.new(AGENT_SEED))
	_host.set_agent(B, RandomLegalAgent.new(AGENT_SEED + 1))
	_host.start(SetupSamples.setup())
	HostDriver.run(_host, _clock, AGENT_STEP_MSEC, MAX_HOST_STEPS)
	assert_int(_host.get_host_state()).is_equal(HOST.ENDED)
	assert_bool(_engine.get_state().is_ended()).is_true()


func test_decision_0020_each_event_batch_needs_its_confirmation() -> void:
	_reach_b_mulligan()
	_host.submit_human(ChooseMulligan.new(B))
	_clock.advance(CLOCK_MSEC)
	assert_array(_host.tick()).is_not_empty()
	_host.confirm_events_played()
	assert_int(_host.get_host_state()).is_equal(HOST.PLAYING_EVENTS)
	_host.confirm_events_played()
	assert_int(_host.get_host_state()).is_not_equal(HOST.PLAYING_EVENTS)


func test_decision_0020_one_confirmation_per_call_after_response_expiry_during_the_window() -> void:
	_reach_window_of_b_with_short_response_time()
	_clock.advance(OVERRUN_MSEC)
	var labels := EventLog.describe(_host.tick())  # 209.4.4g puis 209.4.10 : B passe
	assert_array(labels.slice(0, 2)).contains_exactly(["TimeExpired:B", "PriorityPassed:B"])
	assert_int(_host.get_host_state()).is_equal(HOST.PLAYING_EVENTS)
	_host.confirm_events_played()
	assert_int(_host.get_host_state()).is_not_equal(HOST.PLAYING_EVENTS)


func test_decision_0020_state_changes_are_signaled() -> void:
	var states: Array[DuelHost.HostState] = []
	_host.host_state_changed.connect(
		func(host_state: DuelHost.HostState) -> void: states.append(host_state)
	)
	_reach_human_a()
	assert_array(states).contains_exactly([HOST.PLAYING_EVENTS, HOST.RELAY, HOST.AWAITING_HUMAN])


func test_209_2_5_human_concedes_at_any_time_through_the_host() -> void:
	_reach_b_mulligan()
	_host.submit_human(ChooseMulligan.new(B))
	assert_int(_host.get_host_state()).is_equal(HOST.PLAYING_EVENTS)
	var labels := EventLog.describe(_host.concede(B))
	assert_array(labels).contains(["PlayerConceded:B", "DuelEnded"])
	assert_int(_engine.get_state().result).is_equal(DuelState.DuelResult.PLAYER_A_WINS)


func test_decision_0020_agent_player_cannot_concede_through_the_host() -> void:
	_host.set_agent(A, RandomLegalAgent.new(AGENT_SEED))
	_host.start(_setup())
	assert_array(_host.concede(A)).is_empty()
	assert_bool(_engine.get_state().is_ended()).is_false()


func test_209_4_4f_clock_runs_during_relay_and_animations() -> void:
	_reach_b_mulligan()
	_host.submit_human(ChooseMulligan.new(B))
	_clock.advance(1_000)
	_host.tick()
	_assert_clocks(CLOCK_MSEC - 1_000, CLOCK_MSEC)
	_host.confirm_events_played()
	assert_int(_host.get_host_state()).is_equal(HOST.RELAY)
	_clock.advance(500)
	_host.tick()
	_assert_clocks(CLOCK_MSEC - 1_500, CLOCK_MSEC)


func test_209_4_2d_host_counts_no_time_during_the_mulligan() -> void:
	_host.start(_setup())
	_clock.advance(1_000)
	_host.tick()
	_host.confirm_events_played()
	_host.confirm_relay()
	_clock.advance(1_000)
	_host.submit_human(ChooseMulligan.new(A))
	_assert_clocks(CLOCK_MSEC, CLOCK_MSEC)


func test_209_4_9_turn_time_expiry_ends_the_turn_through_the_host() -> void:
	_reach_first_turn_of_a()
	_clock.advance(CLOCK_MSEC)
	var labels := EventLog.describe(_host.tick())
	assert_array(labels.slice(0, 3)).contains_exactly(
		["TimeExpired:A", "TurnEnded:A", "TurnStarted:B"]
	)
	assert_int(_engine.get_state().active_player).is_equal(B)
	assert_bool(_engine.get_state().is_ended()).is_false()


func test_decision_0021_clock_counts_only_real_elapsed_time() -> void:
	_reach_first_turn_of_a()
	_host.tick()
	_assert_clocks(CLOCK_MSEC, CLOCK_MSEC)
	_clock.advance(250)
	_host.tick()
	_assert_clocks(CLOCK_MSEC - 250, CLOCK_MSEC)


func test_decision_0021_time_before_an_intent_counts_first() -> void:
	_reach_first_turn_of_a()
	_clock.advance(300)
	_host.submit_human(EndTurn.new(A))
	_assert_clocks(CLOCK_MSEC - 300, CLOCK_MSEC)


func test_decision_0021_no_time_counted_before_start_nor_after_end() -> void:
	_clock.advance(1_000)
	assert_array(_host.tick()).is_empty()
	_reach_first_turn_of_a()
	_assert_clocks(CLOCK_MSEC, CLOCK_MSEC)
	_host.submit_human(Concede.new(A))
	_host.confirm_events_played()
	assert_int(_host.get_host_state()).is_equal(HOST.ENDED)
	_clock.advance(1_000)
	assert_array(_host.tick()).is_empty()
	_assert_clocks(CLOCK_MSEC, CLOCK_MSEC)


func test_decision_0021_monotonic_clock_never_goes_back() -> void:
	var clock := MonotonicClock.new()
	var first_msec := clock.now_msec()
	assert_int(clock.now_msec()).is_greater_equal(first_msec)


# Deux humains, joueur A devant l'écran pour son mulligan, sans temps écoulé.
func _reach_human_a() -> void:
	_host.start(_setup())
	_host.confirm_events_played()
	_host.confirm_relay()


# A a gardé sa main ; B est devant l'écran pour son mulligan.
func _reach_b_mulligan() -> void:
	_reach_human_a()
	_host.submit_human(ChooseMulligan.new(A))
	_host.confirm_events_played()
	_host.confirm_relay()


# Mulligans faits, joueur A devant l'écran pour son premier tour, sans temps écoulé.
func _reach_first_turn_of_a() -> void:
	_reach_b_mulligan()
	_host.submit_human(ChooseMulligan.new(B))
	_host.confirm_events_played()
	_host.confirm_relay()


# 209.4.6 : temps de réponse réduit, qui tombe pendant la fenêtre de réponse de B (209.4.4g). A a
# déployé une Unit, B a pris l'appareil et reçoit sa fenêtre de réponse.
func _reach_window_of_b_with_short_response_time() -> void:
	var config := DuelConfig.new()
	config.response_time_msec = SHORT_RESPONSE_MSEC
	_engine = DuelEngine.new(SetupSamples.catalog(), config)
	_host = DuelHost.new(_engine, _clock)
	_reach_human_a()
	ResponseWindowSamples.accept_mulligans(_host)
	var is_deployed := false
	for card: CardInstance in _engine.get_state().get_player(A).hand:
		is_deployed = (
			is_deployed or ResponseWindowSamples.try_deploy(_host, _engine, card, UNIT_COST)
		)
		if is_deployed:
			break
	assert_bool(is_deployed).is_true()
	_host.confirm_events_played()
	_host.confirm_relay()
	assert_bool(_host.is_response_window_open()).is_true()
	assert_int(_host.get_awaited_player()).is_equal(B)


# Décision 0012 : A commence, pour des tests qui ne dépendent pas du tirage.
func _setup() -> DuelSetup:
	var setup := SetupSamples.setup()
	setup.impose_first_player(A)
	return setup


func _assert_clocks(expected_a_msec: int, expected_b_msec: int) -> void:
	var state := _engine.get_state()
	assert_int(state.get_player(A).turn_time_remaining_msec).is_equal(expected_a_msec)
	assert_int(state.get_player(B).turn_time_remaining_msec).is_equal(expected_b_msec)
