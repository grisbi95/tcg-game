extends GdUnitTestSuite
## Fenêtre de réponse à l'écran, décomptée par DuelHost (ruleset 0.36, 208.6 et 209.4.4g ;
## décision 0029).
##
## Sans scène : `ManualClock` tient lieu de temps réel. A déploie une Unit à son premier tour ;
## B, qui peut alors répondre ou passer, n'a aucune Réaction dans le deck d'essai (208.6.6).

const CLOCK_MSEC: int = 600_000  # 209.4.3 : 10 minutes
const RESPONSE_WINDOW_MSEC: int = 2_000  # 208.6.2
const UNIT_COST: int = 2  # CatalogSamples.unit()
const AGENT_SEED: int = 3

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
	_clock.advance(500)
	assert_int(_host.get_response_time_left_msec()).is_equal(RESPONSE_WINDOW_MSEC - 500)


func test_208_6_1_window_opens_once_the_device_is_handed_over() -> void:
	_reach_first_turn_of_a()
	_deploy_from_a()
	_host.confirm_events_played()
	assert_int(_host.get_host_state()).is_equal(HOST.RELAY)
	assert_bool(_host.is_response_window_running()).is_false()
	_clock.advance(5_000)
	_host.tick()
	_host.confirm_relay()
	assert_int(_host.get_response_time_left_msec()).is_equal(RESPONSE_WINDOW_MSEC)


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
	_clock.advance(RESPONSE_WINDOW_MSEC + 300)
	var labels := EventLog.describe(_host.submit_human(PassPriority.new(B)))
	assert_str(labels[0]).is_equal("PriorityPassed:B")
	assert_int(labels.count("PriorityPassed:B")).is_equal(1)


func test_208_6_4_player_passes_before_the_end_of_the_window() -> void:
	_reach_answer_of_b()
	_clock.advance(500)
	var labels := EventLog.describe(_host.submit_human(PassPriority.new(B)))
	assert_str(labels[0]).is_equal("PriorityPassed:B")
	assert_bool(_host.is_response_window_running()).is_false()
	assert_int(_host.get_response_time_left_msec()).is_equal(0)


func test_208_6_5_started_response_stops_the_countdown() -> void:
	_reach_answer_of_b()
	_clock.advance(500)
	_host.begin_response()
	assert_bool(_host.is_response_window_running()).is_false()
	assert_int(_host.get_response_time_left_msec()).is_equal(0)
	_clock.advance(RESPONSE_WINDOW_MSEC * 10)
	assert_array(_host.tick()).is_empty()
	assert_int(_host.get_host_state()).is_equal(HOST.AWAITING_HUMAN)


func test_208_6_5a_stopped_player_answers_or_passes_himself() -> void:
	_reach_answer_of_b()
	_host.begin_response()
	_clock.advance(RESPONSE_WINDOW_MSEC * 10)
	_host.tick()
	assert_array(_engine.get_state().stack).is_not_empty()
	var labels := EventLog.describe(_host.submit_human(PassPriority.new(B)))
	assert_str(labels[0]).is_equal("PriorityPassed:B")


func test_208_6_6_same_window_without_any_playable_reaction() -> void:
	_reach_answer_of_b()
	var reactions := _engine.get_state().get_player(B).hand.filter(
		func(card: CardInstance) -> bool: return _is_reaction(card)
	)
	assert_array(reactions).is_empty()
	assert_int(_host.get_response_time_left_msec()).is_equal(RESPONSE_WINDOW_MSEC)


func test_208_6_7_no_window_outside_an_answer() -> void:
	_reach_human_a()
	assert_bool(_host.is_response_window_running()).is_false()
	_reach_mulligans_then_first_turn_of_a()
	assert_bool(_host.is_response_window_running()).is_false()
	_clock.advance(RESPONSE_WINDOW_MSEC * 10)
	assert_array(_host.tick()).is_empty()
	assert_int(_host.get_host_state()).is_equal(HOST.AWAITING_HUMAN)


func test_209_4_4g_clock_runs_during_the_window() -> void:
	_reach_answer_of_b()
	_clock.advance(RESPONSE_WINDOW_MSEC + 700)
	_host.tick()
	# La pendule de B s'arrête à l'échéance ; le reste compte après la passe automatique.
	assert_int(_engine.get_state().get_player(B).clock_remaining_msec).is_equal(
		CLOCK_MSEC - RESPONSE_WINDOW_MSEC
	)


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


# Deux humains, joueur A devant l'écran pour son mulligan, sans temps écoulé.
func _reach_human_a() -> void:
	_host.start(_setup())
	_host.confirm_events_played()
	_host.confirm_relay()


func _reach_mulligans_then_first_turn_of_a() -> void:
	_host.submit_human(ChooseMulligan.new(A))
	_host.confirm_events_played()
	_host.confirm_relay()
	_host.submit_human(ChooseMulligan.new(B))
	_host.confirm_events_played()
	_host.confirm_relay()


func _reach_first_turn_of_a() -> void:
	_reach_human_a()
	_reach_mulligans_then_first_turn_of_a()


# 208.2.4 : A a annoncé un déploiement ; B a pris l'appareil et peut répondre ou passer.
func _reach_answer_of_b() -> void:
	_reach_first_turn_of_a()
	_deploy_from_a()
	_host.confirm_events_played()
	_host.confirm_relay()


func _deploy_from_a() -> void:
	var payment := EssencePayment.new(UNIT_COST, 0)
	for card: CardInstance in _engine.get_state().get_player(A).hand:
		for cell: Vector2i in BoardGeometry.all_cells():
			var intent := DeployCard.new(A, card.card_instance_id, cell, payment)
			if _engine.validate(intent) == IntentRejected.RejectReason.NONE:
				_host.submit_human(intent)
				return
	fail("aucun déploiement légal pour A")


func _is_reaction(card: CardInstance) -> bool:
	var definition := _engine.get_state().catalog.get_card(card.definition_id)
	return definition.speed == CardDefinition.SpellSpeed.REACTION


# Décision 0012 : A commence, pour des tests qui ne dépendent pas du tirage.
func _setup() -> DuelSetup:
	var setup := SetupSamples.setup()
	setup.impose_first_player(A)
	return setup
