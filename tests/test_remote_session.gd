extends GdUnitTestSuite
## Sessions du duel à distance sans réseau (ruleset 0.44 ; décisions 0049 et 0050) : un hôte
## (A, `RemoteHostSession`) et un second écran (B, `RemoteGuestSession`) reliés par
## `LoopbackConnection`, menés comme par leurs écrans de duel.

const DUEL_SEED: int = 5
const EDITION: String = "0.56"
const TICK_MSEC: int = 100
const UNKNOWN_CARD_ID: int = 999_999
const OTHER_EDITION: String = "0.42"
## Assez d'images pour que tout message parte et revienne.
const SETTLE_TICKS: int = 4

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const SESSION := DuelSession.SessionState

var _catalog: Catalog
var _config: DuelConfig = DuelConfig.new()
var _clock: ManualClock
var _host_session: RemoteHostSession
var _guest_session: RemoteGuestSession
var _connections: Array[LoopbackConnection] = []


func before() -> void:
	_catalog = TestCatalog.catalog()


func before_test() -> void:
	_clock = ManualClock.new()
	_connections = LoopbackConnection.pair()
	var setup := TestCatalog.setup(DUEL_SEED)
	setup.impose_first_player(A)
	var host := DuelHost.new(DuelEngine.new(_catalog, _config), _clock)
	_host_session = RemoteHostSession.new(host, setup, _connections[0], EDITION)
	_guest_session = RemoteGuestSession.new(
		DuelEngine.new(_catalog, _config), _connections[1], EDITION
	)


func test_decision_0050_second_screen_starts_once_the_setup_arrives() -> void:
	assert_bool(_guest_session.poll_until_ready()).is_false()
	_host_session.start()
	assert_bool(_guest_session.poll_until_ready()).is_true()
	assert_bool(_guest_session.start().is_empty()).is_false()
	assert_int(_guest_session.get_session_state()).is_equal(SESSION.PLAYING_EVENTS)
	assert_int(_guest_session.get_viewer()).is_equal(B)
	assert_int(_guest_session.get_bottom_side()).is_equal(B)
	assert_int(_host_session.get_bottom_side()).is_equal(A)


func test_decision_0050_mulligans_from_both_screens_reach_the_first_turn() -> void:
	_start_both()
	assert_int(_host_session.get_session_state()).is_equal(SESSION.AWAITING_VIEWER)
	assert_int(_guest_session.get_session_state()).is_equal(SESSION.AWAITING_VIEWER)
	_guest_session.submit(ChooseMulligan.new(B))
	assert_int(_guest_session.get_session_state()).is_equal(SESSION.AWAITING_OTHER)
	_play(_host_session.submit(ChooseMulligan.new(A)), _host_session)
	_settle()
	assert_int(_host_session.get_session_state()).is_equal(SESSION.AWAITING_VIEWER)
	assert_int(_guest_session.get_session_state()).is_equal(SESSION.AWAITING_OTHER)
	var host_state := _host_session.get_engine().get_state()
	assert_int(host_state.turn_number).is_equal(1)
	_assert_same_duel()


func test_decision_0050_second_screen_waits_for_its_intent_to_come_back() -> void:
	_start_both()
	_play(_host_session.submit(ChooseMulligan.new(A)), _host_session)
	_settle()
	assert_int(_guest_session.get_session_state()).is_equal(SESSION.AWAITING_VIEWER)
	_guest_session.submit(ChooseMulligan.new(B))
	assert_int(_guest_session.get_session_state()).is_equal(SESSION.AWAITING_OTHER)
	_settle()
	assert_int(_guest_session.get_session_state()).is_equal(SESSION.AWAITING_OTHER)
	assert_int(_host_session.get_session_state()).is_equal(SESSION.AWAITING_VIEWER)
	_assert_same_duel()


func test_decision_0050_rejected_intent_gives_the_second_screen_back_its_turn() -> void:
	_start_both()
	_play(_host_session.submit(ChooseMulligan.new(A)), _host_session)
	_settle()
	var unknown_card_ids: Array[int] = [UNKNOWN_CARD_ID]
	_guest_session.submit(ChooseMulligan.new(B, unknown_card_ids))
	var guest_events := _settle()
	var expected := IntentRejected.RejectReason.CARD_NOT_IN_HAND
	assert_int(EventLog.rejection_reason(guest_events)).is_equal(expected)
	assert_int(_guest_session.get_session_state()).is_equal(SESSION.AWAITING_VIEWER)


func test_209_2_5_second_screen_concedes() -> void:
	_start_both()
	_guest_session.concede()
	_settle()
	assert_int(_host_session.get_session_state()).is_equal(SESSION.ENDED)
	assert_int(_guest_session.get_session_state()).is_equal(SESSION.ENDED)


func test_decision_0050_departure_of_a_player_disconnects_the_other() -> void:
	_start_both()
	_guest_session.close()
	_tick_host()
	assert_int(_host_session.get_session_state()).is_equal(SESSION.DISCONNECTED)
	assert_str(_host_session.get_disconnection()).is_equal(LoopbackConnection.PEER_LEFT_TEXT)


func test_decision_0049_different_editions_disconnect_without_starting_the_second_screen() -> void:
	var connections := LoopbackConnection.pair()
	var setup := TestCatalog.setup(DUEL_SEED)
	var host := DuelHost.new(DuelEngine.new(_catalog, _config), _clock)
	var host_session := RemoteHostSession.new(host, setup, connections[0], EDITION)
	var guest_session := RemoteGuestSession.new(
		DuelEngine.new(_catalog, _config), connections[1], OTHER_EDITION
	)
	host_session.start()
	assert_bool(guest_session.poll_until_ready()).is_false()
	assert_int(guest_session.get_session_state()).is_equal(SESSION.DISCONNECTED)
	assert_object(guest_session.get_engine().get_state()).is_null()
	host_session.tick()
	assert_int(host_session.get_session_state()).is_equal(SESSION.DISCONNECTED)


func test_decision_0050_host_leaving_after_the_end_keeps_the_end_on_the_second_screen() -> void:
	_start_both()
	_guest_session.concede()
	_tick_host()
	assert_int(_host_session.get_session_state()).is_equal(SESSION.ENDED)
	_host_session.close()
	var events := _guest_session.tick()
	assert_bool(events.is_empty()).is_false()
	assert_int(_guest_session.get_session_state()).is_equal(SESSION.PLAYING_EVENTS)
	_play(events, _guest_session)
	assert_int(_guest_session.get_session_state()).is_equal(SESSION.ENDED)


func test_decision_0050_second_screen_leaving_after_the_end_keeps_the_end_on_the_host() -> void:
	_start_both()
	var events := _host_session.concede()
	_guest_session.close()
	_clock.advance(TICK_MSEC)
	_host_session.tick()
	assert_int(_host_session.get_session_state()).is_equal(SESSION.PLAYING_EVENTS)
	_play(events, _host_session)
	assert_int(_host_session.get_session_state()).is_equal(SESSION.ENDED)


func test_209_2_5_concede_behind_a_waiting_intent_is_not_held_back() -> void:
	_start_both()
	_guest_session.submit(EndTurn.new(B))
	_guest_session.concede()
	_tick_host()
	assert_int(_host_session.get_session_state()).is_equal(SESSION.ENDED)


# 208.6.2, décision 0042 : la réponse commencée chez B attend que la fenêtre de l'hôte s'ouvre.
func test_208_6_2_remote_response_begun_waits_for_the_window_of_the_host() -> void:
	var catalog := ResponseWindowSamples.catalog_with_reaction(ResponseWindowSamples.REACTION_ID)
	var connections := LoopbackConnection.pair()
	var setup := SetupSamples.setup()
	setup.impose_first_player(A)
	var engine := DuelEngine.new(catalog, _config)
	var host := DuelHost.new(engine, _clock)
	var host_session := RemoteHostSession.new(host, setup, connections[0], EDITION)
	var guest_session := RemoteGuestSession.new(
		DuelEngine.new(catalog, _config), connections[1], EDITION
	)
	_play(host_session.start(), host_session)
	ResponseWindowSamples.accept_mulligans(host)
	assert_bool(ResponseWindowSamples.announce_reaction(host, engine)).is_true()
	guest_session.begin_response()
	host_session.tick()
	assert_int(host.get_journal().response_begun_count(B)).is_equal(0)
	host_session.confirm_events_played()
	host_session.tick()
	assert_int(host.get_journal().response_begun_count(B)).is_equal(1)


# Les deux écrans au mulligan, premiers événements affichés.
func _start_both() -> void:
	_play(_host_session.start(), _host_session)
	_guest_session.poll_until_ready()
	_play(_guest_session.start(), _guest_session)


# Comme l'écran : un lot non vide s'affiche, puis se confirme.
func _play(events: Array[DuelEvent], session: DuelSession) -> void:
	if not events.is_empty():
		session.confirm_events_played()


func _tick_host() -> void:
	_clock.advance(TICK_MSEC)
	_play(_host_session.tick(), _host_session)


# Quelques images des deux écrans ; renvoie les événements du second écran.
func _settle() -> Array[DuelEvent]:
	var guest_events: Array[DuelEvent] = []
	for tick: int in SETTLE_TICKS:
		_tick_host()
		var events := _guest_session.tick()
		guest_events.append_array(events)
		_play(events, _guest_session)
	return guest_events


func _assert_same_duel() -> void:
	_clock.advance(RemoteHostLink.TIME_SEND_INTERVAL_MSEC)
	_settle()
	var host_journal := _host_session.get_journal().to_json()
	assert_str(_guest_session.get_journal().to_json()).is_equal(host_journal)
	var defects := DeepCompare.find_clone_defects(
		_host_session.get_engine().get_state(), _guest_session.get_engine().get_state()
	)
	assert_array(Array(defects)).is_empty()
