extends GdUnitTestSuite
## Duel à distance sans réseau (ruleset 0.44 ; décisions 0001, 0022, 0043 et 0049) : messages
## écrits puis relus en JSON comme par le relais, journal de l'hôte rejoué par le second écran,
## intentions du joueur distant soumises par l'hôte.

const DUEL_SEED: int = 5
const AGENT_SEED_A: int = 31
const AGENT_SEED_B: int = 32
const HOST_TICKS: int = 400
const TICK_MSEC: int = 700
const SHORT_WAIT_MSEC: int = 40
const EDITION: String = "0.53"
const UNKNOWN_CARD_ID: int = 999_999

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B

var _catalog: Catalog
## Partagée par les moteurs comparés : la configuration est en lecture seule (DeepCompare).
var _config: DuelConfig = DuelConfig.new()
var _clock: ManualClock
var _host_engine: DuelEngine
var _host: DuelHost
var _host_link: RemoteHostLink
var _guest: RemoteGuestLink


func before() -> void:
	_catalog = TestCatalog.catalog()


func test_decision_0049_messages_survive_the_json_round_trip() -> void:
	var setup := TestCatalog.setup(DUEL_SEED)
	setup.impose_first_player(B)
	var window_time := DuelJournal.Entry.new()
	window_time.kind = DuelJournal.EntryKind.RESPONSE_WINDOW_TIME
	window_time.player = B
	window_time.elapsed_msec = TICK_MSEC
	var messages: Array[RemoteMessage] = [
		RemoteMessage.hello(EDITION),
		RemoteMessage.of_setup(setup),
		RemoteMessage.of_entry(window_time),
		RemoteMessage.of_intent(PassPriority.new(B)),
		RemoteMessage.response_begun(),
		RemoteMessage.rejected(IntentRejected.RejectReason.NOT_YOUR_PRIORITY),
	]
	for message: RemoteMessage in messages:
		var read := RemoteMessage.from_json(message.to_json())
		assert_object(read).is_not_null()
		assert_str(read.to_json()).is_equal(message.to_json())
		assert_array(Array(DeepCompare.find_clone_defects(message, read))).is_empty()


func test_decision_0049_malformed_messages_are_refused() -> void:
	var texts: Array[String] = [
		"pas du JSON",
		"[]",
		'{"kind": "UNKNOWN"}',
		'{"kind": "SETUP"}',
		'{"kind": "JOURNAL_ENTRY", "entry": {"elapsed_msec": -1}}',
		'{"kind": "INTENT", "intent": {"type": "Inconnue"}}',
		'{"kind": "INTENT_REJECTED", "reject_reason": "INCONNUE"}',
		'{"kind": "HELLO", "protocol_version": 1}',
	]
	for text: String in texts:
		assert_object(RemoteMessage.from_json(text)).override_failure_message(text).is_null()


func test_decision_0049_hello_reports_a_different_edition_or_protocol() -> void:
	assert_str(RemoteMessage.hello(EDITION).find_incompatibility(EDITION)).is_empty()
	assert_str(RemoteMessage.hello("0.42").find_incompatibility(EDITION)).is_not_empty()
	var old_protocol := RemoteMessage.hello(EDITION)
	old_protocol.protocol_version = RemoteMessage.PROTOCOL_VERSION + 1
	assert_str(old_protocol.find_incompatibility(EDITION)).is_not_empty()
	var host_link := RemoteHostLink.new(DuelHost.new(_new_engine()), B, EDITION)
	host_link.receive(RemoteMessage.hello("0.42"))
	assert_str(host_link.get_incompatibility()).is_not_empty()


func test_decision_0049_streamed_journal_rebuilds_the_host_duel() -> void:
	_build(true)
	var host_events := _host.start(TestCatalog.setup(DUEL_SEED))
	var guest_events := _exchange()
	for tick: int in HOST_TICKS:
		if _host.get_host_state() == DuelHost.HostState.ENDED:
			break
		_host.confirm_events_played()
		_clock.advance(TICK_MSEC)
		host_events.append_array(_host.tick())
		guest_events.append_array(_exchange())
	_clock.advance(RemoteHostLink.TIME_SEND_INTERVAL_MSEC)
	guest_events.append_array(_exchange())
	assert_str(_guest.get_journal().to_json()).is_equal(_host.get_journal().to_json())
	assert_array(EventLog.describe(guest_events)).is_equal(EventLog.describe(host_events))
	var host_state := _host_engine.get_state()
	var defects := DeepCompare.find_clone_defects(host_state, _guest.get_engine().get_state())
	assert_array(Array(defects)).is_empty()


func test_decision_0049_time_alone_waits_for_the_send_interval() -> void:
	_start_human_duel()
	_clock.advance(SHORT_WAIT_MSEC)
	_host.tick()
	assert_array(_host_link.take_outgoing(_clock.now_msec())).is_empty()
	_clock.advance(RemoteHostLink.TIME_SEND_INTERVAL_MSEC)
	_host.tick()
	_exchange()
	assert_str(_guest.get_journal().to_json()).is_equal(_host.get_journal().to_json())


func test_decision_0049_remote_intent_waits_until_the_host_awaits_its_player() -> void:
	_start_human_duel()
	_guest.send_intent(ChooseMulligan.new(B))
	_exchange()
	assert_array(_host_link.submit_received()).is_empty()
	_play_local(ChooseMulligan.new(A))
	var events := _host_link.submit_received()
	assert_int(EventLog.rejection_reason(events)).is_equal(EventLog.NOT_A_SINGLE_REJECTION)
	assert_bool(events.is_empty()).is_false()
	_settle()
	_exchange()
	assert_str(_guest.get_journal().to_json()).is_equal(_host.get_journal().to_json())


func test_decision_0049_rejected_remote_intent_goes_back_to_the_second_screen_only() -> void:
	_start_human_duel()
	_play_local(ChooseMulligan.new(A))
	var unknown_card_ids: Array[int] = [UNKNOWN_CARD_ID]
	_guest.send_intent(ChooseMulligan.new(B, unknown_card_ids))
	_exchange()
	assert_array(_host_link.submit_received()).is_empty()
	var guest_events := _exchange()
	var expected := IntentRejected.RejectReason.CARD_NOT_IN_HAND
	assert_int(EventLog.rejection_reason(guest_events)).is_equal(expected)


func test_decision_0049_remote_intent_of_the_other_player_is_ignored() -> void:
	_start_human_duel()
	_guest.send_intent(ChooseMulligan.new(A))
	_exchange()
	assert_array(_host_link.submit_received()).is_empty()
	assert_int(_host.get_journal().entries.size()).is_equal(0)


func test_209_2_5_remote_player_concedes_at_any_time() -> void:
	_start_human_duel()
	_guest.send_intent(Concede.new(B))
	_exchange()
	_host_link.submit_received()
	_settle()
	_exchange()
	assert_bool(_host_engine.get_state().is_ended()).is_true()
	assert_bool(_guest.get_engine().get_state().is_ended()).is_true()


func _new_engine() -> DuelEngine:
	return DuelEngine.new(_catalog, _config)


# Hôte et second écran reliés sans réseau ; B joue sur le second écran.
func _build(with_agents: bool) -> void:
	_clock = ManualClock.new()
	_host_engine = _new_engine()
	_host = DuelHost.new(_host_engine, _clock)
	if with_agents:
		_host.set_agent(A, RandomLegalAgent.new(AGENT_SEED_A))
		_host.set_agent(B, RandomLegalAgent.new(AGENT_SEED_B))
	_host_link = RemoteHostLink.new(_host, B, EDITION)
	_guest = RemoteGuestLink.new(_new_engine(), B, EDITION)


# Deux humains, A devant l'hôte et premier joueur ; l'hôte attend le mulligan de A.
func _start_human_duel() -> void:
	_build(false)
	var setup := TestCatalog.setup(DUEL_SEED)
	setup.impose_first_player(A)
	_host.start(setup)
	_settle()
	_exchange()


func _play_local(intent: DuelIntent) -> void:
	_host.submit_human(intent)
	_settle()


# Comme la scène de l'hôte : affichage confirmé, relais confirmé aussitôt (décision 0048).
func _settle() -> void:
	_host.confirm_events_played()
	_host.confirm_relay()


# Porte les messages dans les deux sens, écrits puis relus en JSON comme par le relais ; renvoie
# les événements du second écran.
func _exchange() -> Array[DuelEvent]:
	var guest_events: Array[DuelEvent] = []
	for message: RemoteMessage in _host_link.take_outgoing(_clock.now_msec()):
		guest_events.append_array(_guest.receive(RemoteMessage.from_json(message.to_json())))
	for message: RemoteMessage in _guest.take_outgoing():
		_host_link.receive(RemoteMessage.from_json(message.to_json()))
	return guest_events
