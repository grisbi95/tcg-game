# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## Journal, codec des intentions et replay (ruleset 0.37 ; décisions 0001, 0020, 0022 et 0042).
##
## Non-régression : le journal de tests/fixtures/ est rejoué et son empreinte comparée à celle
## enregistrée ; un écart signale un changement de comportement du moteur. S'il est voulu,
## régénérer depuis la racine : "$GODOT_BIN" --headless --path . -s tools/record_replay_fixture.gd

const DUEL_SEED: int = 5
const AGENT_SEED_A: int = 31
const AGENT_SEED_B: int = 32
const HOST_TICKS: int = 400
const TICK_MSEC: int = 700
## Au-delà de 2^53, un nombre JSON perd sa précision : la graine s'écrit en texte.
const LARGE_SEED: int = 4_611_686_018_427_387_903
const FILLER_INT: int = 1
const FILLER_CELL := Vector2i(2, 3)
const WINDOW_MSEC_FIRST: int = 1_500
const WINDOW_MSEC_SECOND: int = 800

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B

var _catalog: Catalog
## Partagée par les moteurs comparés : la configuration est en lecture seule (DeepCompare).
var _config: DuelConfig = DuelConfig.new()


func before() -> void:
	_catalog = TestCatalog.catalog()


func test_decision_0022_replay_matches_the_recorded_fingerprint() -> void:
	var journal_text := ReplayFixture.read_journal_text()
	assert_array(Array(DuelJournal.find_errors(journal_text))).is_empty()
	var actual := ReplayFixture.fingerprint_of(DuelJournal.from_json(journal_text))
	var differences := actual.find_differences(ReplayFixture.read_fingerprint())
	var message := "Le replay diverge :\n" + "\n".join(differences)
	assert_array(Array(differences)).override_failure_message(message).is_empty()


func test_decision_0022_host_journal_replays_to_the_same_duel() -> void:
	var host_engine := DuelEngine.new(_catalog, _config)
	var host_events: Array[DuelEvent] = []
	var journal := _play_agents(host_engine, host_events)
	var replay_engine := DuelEngine.new(_catalog, _config)
	var replay_events := journal.replay_into(replay_engine)
	assert_array(EventLog.describe(replay_events)).is_equal(EventLog.describe(host_events))
	var host_state := host_engine.get_state()
	var defects := DeepCompare.find_clone_defects(host_state, replay_engine.get_state())
	assert_array(Array(defects)).is_empty()


func test_decision_0022_json_round_trip_keeps_the_journal() -> void:
	var events: Array[DuelEvent] = []
	var text := _play_agents(DuelEngine.new(_catalog), events).to_json()
	assert_str(DuelJournal.from_json(text).to_json()).is_equal(text)


func test_decision_0022_setup_round_trip_keeps_seed_and_first_player() -> void:
	var setup := TestCatalog.setup(DUEL_SEED)
	setup.rng_seed = LARGE_SEED
	setup.impose_first_player(B)
	var read_setup := DuelJournal.from_json(DuelJournal.new(setup).to_json()).setup
	assert_array(Array(DeepCompare.find_clone_defects(setup, read_setup))).is_empty()


func test_decision_0022_consecutive_elapsed_times_are_merged() -> void:
	var journal := DuelJournal.new()
	journal.record_elapsed(100)
	journal.record_elapsed(200)
	journal.record_intent(PassPriority.new(A))
	journal.record_elapsed(0)
	journal.record_elapsed(50)
	assert_int(journal.entries.size()).is_equal(3)
	assert_int(journal.entries[0].elapsed_msec).is_equal(300)
	assert_int(journal.entries[2].elapsed_msec).is_equal(50)


func test_decision_0036_total_elapsed_msec_sums_the_elapsed_times() -> void:
	var journal := DuelJournal.new()
	assert_int(journal.total_elapsed_msec()).is_equal(0)
	journal.record_elapsed(100)
	journal.record_elapsed(200)
	journal.record_intent(PassPriority.new(A))
	assert_int(journal.total_elapsed_msec()).is_equal(300)
	journal.record_elapsed(50)
	assert_int(journal.total_elapsed_msec()).is_equal(350)


func test_decision_0042_consecutive_window_times_of_a_player_are_merged() -> void:
	var journal := DuelJournal.new()
	journal.record_response_window_elapsed(B, WINDOW_MSEC_FIRST)
	journal.record_response_window_elapsed(B, WINDOW_MSEC_SECOND)
	journal.record_response_window_elapsed(B, 0)
	assert_int(journal.entries.size()).is_equal(1)
	assert_int(journal.entries[0].elapsed_msec).is_equal(WINDOW_MSEC_FIRST + WINDOW_MSEC_SECOND)
	journal.record_response_window_elapsed(A, 100)
	assert_int(journal.entries.size()).is_equal(2)
	journal.record_elapsed(50)
	assert_int(journal.entries.size()).is_equal(3)
	journal.record_response_window_elapsed(A, 70)
	assert_int(journal.entries.size()).is_equal(4)
	var kinds: Array[DuelJournal.EntryKind] = []
	for entry: DuelJournal.Entry in journal.entries:
		kinds.append(entry.kind)
	(
		assert_array(kinds)
		. contains_exactly(
			[
				DuelJournal.EntryKind.RESPONSE_WINDOW_TIME,
				DuelJournal.EntryKind.RESPONSE_WINDOW_TIME,
				DuelJournal.EntryKind.ELAPSED_TIME,
				DuelJournal.EntryKind.RESPONSE_WINDOW_TIME,
			]
		)
	)


func test_decision_0042_total_elapsed_adds_ordinary_and_window_times_not_responses() -> void:
	var journal := DuelJournal.new()
	journal.record_elapsed(100)
	journal.record_response_window_elapsed(A, 200)
	journal.record_response_begun(A)
	journal.record_response_window_elapsed(B, 400)
	journal.record_response_begun(B)
	journal.record_intent(PassPriority.new(B))
	assert_int(journal.total_elapsed_msec()).is_equal(700)


func test_decision_0042_json_round_trip_keeps_window_times_and_responses() -> void:
	var journal := _journal_with_window_entries()
	var text := journal.to_json()
	var read := DuelJournal.from_json(text)
	assert_object(read).is_not_null()
	assert_str(read.to_json()).is_equal(text)
	assert_int(read.entries.size()).is_equal(journal.entries.size())
	assert_int(read.response_window_elapsed_msec(B)).is_equal(WINDOW_MSEC_FIRST)
	assert_int(read.response_begun_count(B)).is_equal(1)
	assert_int(read.response_begun_count(A)).is_equal(0)


func test_decision_0042_window_entry_encoding_names_the_player() -> void:
	var journal := DuelJournal.new()
	journal.record_response_window_elapsed(B, WINDOW_MSEC_FIRST)
	journal.record_response_begun(A)
	var encoded: Array = _journal_entries_of(journal)
	var window_entry: Dictionary = encoded[0]
	var begun_entry: Dictionary = encoded[1]
	assert_int(JsonValues.to_int(window_entry["response_window_elapsed_msec"])).is_equal(
		WINDOW_MSEC_FIRST
	)
	assert_int(JsonValues.to_int(window_entry["player"])).is_equal(B)
	assert_bool(begun_entry["response_begun"]).is_true()
	assert_int(JsonValues.to_int(begun_entry["player"])).is_equal(A)


func test_decision_0042_malformed_window_entries_are_refused() -> void:
	var malformed_entries: Array[Dictionary] = [
		{"response_begun": true},
		{"response_begun": true, "player": 7},
		{"response_begun": true, "player": "B"},
		{"response_window_elapsed_msec": WINDOW_MSEC_FIRST},
		{"response_window_elapsed_msec": 0, "player": A},
		{"response_window_elapsed_msec": -WINDOW_MSEC_FIRST, "player": A},
		{"response_window_elapsed_msec": WINDOW_MSEC_FIRST, "player": 2},
	]
	for entry: Dictionary in malformed_entries:
		var data := _journal_data()
		data["entries"] = [entry]
		var errors := DuelJournal.find_errors(JSON.stringify(data))
		assert_array(Array(errors)).override_failure_message(str(entry)).contains(
			["entrée 0 mal formée"]
		)
		assert_object(DuelJournal.from_json(JSON.stringify(data))).is_null()


func test_decision_0042_replay_ignores_responses_and_runs_both_kinds_of_time() -> void:
	var ordinary_engine := DuelEngine.new(_catalog, _config)
	_journal_with_time(false).replay_into(ordinary_engine)
	var window_engine := DuelEngine.new(_catalog, _config)
	_journal_with_time(true).replay_into(window_engine)
	var defects := DeepCompare.find_clone_defects(
		ordinary_engine.get_state(), window_engine.get_state()
	)
	assert_array(Array(defects)).is_empty()
	var clock_msec := window_engine.get_state().get_player(A).clock_remaining_msec
	assert_int(clock_msec).is_equal(
		_config.clock_duration_msec - WINDOW_MSEC_FIRST - WINDOW_MSEC_SECOND
	)


func test_decision_0042_counts_are_per_player() -> void:
	var journal := _journal_with_window_entries()
	assert_int(journal.response_window_elapsed_msec(A)).is_equal(WINDOW_MSEC_SECOND)
	assert_int(journal.response_window_elapsed_msec(B)).is_equal(WINDOW_MSEC_FIRST)
	assert_int(journal.response_begun_count(A)).is_equal(0)
	assert_int(journal.response_begun_count(B)).is_equal(1)
	journal.record_response_begun(A)
	journal.record_response_begun(A)
	assert_int(journal.response_begun_count(A)).is_equal(2)
	assert_int(DuelJournal.new().response_window_elapsed_msec(A)).is_equal(0)


func test_decision_0022_rejected_intents_are_not_recorded() -> void:
	var host := DuelHost.new(DuelEngine.new(SetupSamples.catalog()), ManualClock.new())
	host.start(SetupSamples.setup())
	host.confirm_events_played()
	host.confirm_relay()
	host.submit_human(EndTurn.new(A))
	assert_array(host.get_journal().entries).is_empty()
	host.submit_human(ChooseMulligan.new(A))
	assert_int(host.get_journal().entries.size()).is_equal(1)


func test_decision_0022_journal_keeps_copies_of_what_it_records() -> void:
	var setup := TestCatalog.setup(DUEL_SEED)
	var journal := DuelJournal.new(setup)
	var intent := ChooseMulligan.new(A, [1])
	journal.record_intent(intent)
	setup.rng_seed += 1
	intent.set_aside_card_ids.append(2)
	assert_int(journal.setup.rng_seed).is_equal(DUEL_SEED)
	var recorded := journal.entries[0].intent as ChooseMulligan
	assert_array(recorded.set_aside_card_ids).contains_exactly([1])


func test_decision_0022_no_time_recorded_after_the_end() -> void:
	var clock := ManualClock.new()
	var host := DuelHost.new(DuelEngine.new(SetupSamples.catalog()), clock)
	host.start(SetupSamples.setup())
	host.confirm_events_played()
	host.concede(A)
	var entry_count := host.get_journal().entries.size()
	clock.advance(TICK_MSEC)
	host.tick()
	assert_int(host.get_journal().entries.size()).is_equal(entry_count)


func test_decision_0022_other_format_version_is_refused() -> void:
	var data := _journal_data()
	data["format_version"] = DuelJournal.FORMAT_VERSION + 1
	var errors := DuelJournal.find_errors(JSON.stringify(data))
	assert_str(errors[0]).starts_with("version du format")
	assert_object(DuelJournal.from_json(JSON.stringify(data))).is_null()


func test_decision_0042_format_1_journal_is_refused() -> void:
	var data := _journal_data()
	data["format_version"] = 1
	var errors := DuelJournal.find_errors(JSON.stringify(data))
	assert_str(errors[0]).starts_with("version du format 1")
	assert_object(DuelJournal.from_json(JSON.stringify(data))).is_null()


func test_decision_0022_malformed_journals_are_refused() -> void:
	var data := _journal_data()
	data["entries"] = [{"intent": {"type": "Unknown"}}]
	assert_array(Array(DuelJournal.find_errors(JSON.stringify(data)))).contains(
		["entrée 0 mal formée"]
	)
	data = _journal_data()
	data["setup"] = {"deck_a": [1]}
	assert_array(Array(DuelJournal.find_errors(JSON.stringify(data)))).is_not_empty()
	assert_array(Array(DuelJournal.find_errors("pas du JSON"))).is_not_empty()


func test_decision_0022_codec_knows_every_intent_class() -> void:
	for global_class: Dictionary in ProjectSettings.get_global_class_list():
		if global_class["base"] != &"DuelIntent":
			continue
		var intent_class: StringName = global_class["class"]
		(
			assert_bool(IntentCodec.INTENT_SCRIPTS.has(intent_class))
			. override_failure_message("%s absente d'IntentCodec.INTENT_SCRIPTS" % intent_class)
			. is_true()
		)
		var script: GDScript = IntentCodec.INTENT_SCRIPTS.get(intent_class)
		assert_str(script.resource_path if script != null else "").is_equal(global_class["path"])


func test_decision_0022_codec_round_trip_for_each_intent_class() -> void:
	for script: GDScript in IntentCodec.INTENT_SCRIPTS.values():
		var intent: DuelIntent = script.new()
		_fill_fields(intent)
		var decoded := IntentCodec.decode(IntentCodec.encode(intent))
		assert_object(decoded).is_not_null()
		var defects := DeepCompare.find_clone_defects(intent, decoded)
		var message := "%s : %s" % [script.get_global_name(), "\n".join(defects)]
		assert_array(Array(defects)).override_failure_message(message).is_empty()


# Deux agents jouent au plus HOST_TICKS images par l'hôte ; `events` reçoit leurs événements.
func _play_agents(engine: DuelEngine, events: Array[DuelEvent]) -> DuelJournal:
	var clock := ManualClock.new()
	var host := DuelHost.new(engine, clock)
	host.set_agent(A, RandomLegalAgent.new(AGENT_SEED_A))
	host.set_agent(B, RandomLegalAgent.new(AGENT_SEED_B))
	events.append_array(host.start(TestCatalog.setup(DUEL_SEED)))
	events.append_array(HostDriver.run(host, clock, TICK_MSEC, HOST_TICKS))
	return host.get_journal()


# A commence : mulligans, du temps (ordinaire, ou de fenêtre de A avec une réponse commencée,
# pendant que sa pendule tourne), puis la fin de son tour.
func _journal_with_time(is_window_time: bool) -> DuelJournal:
	var setup := TestCatalog.setup(DUEL_SEED)
	setup.impose_first_player(A)
	var journal := DuelJournal.new(setup)
	journal.record_intent(ChooseMulligan.new(A))
	journal.record_intent(ChooseMulligan.new(B))
	if is_window_time:
		journal.record_response_window_elapsed(A, WINDOW_MSEC_FIRST)
		journal.record_response_begun(A)
		journal.record_response_window_elapsed(A, WINDOW_MSEC_SECOND)
	else:
		journal.record_elapsed(WINDOW_MSEC_FIRST + WINDOW_MSEC_SECOND)
	journal.record_intent(EndTurn.new(A))
	return journal


# Une fenêtre de B puis une réponse commencée de B, une fenêtre de A, du temps ordinaire.
func _journal_with_window_entries() -> DuelJournal:
	var journal := DuelJournal.new(TestCatalog.setup(DUEL_SEED))
	journal.record_intent(ChooseMulligan.new(A))
	journal.record_response_window_elapsed(B, WINDOW_MSEC_FIRST)
	journal.record_response_begun(B)
	journal.record_response_window_elapsed(A, WINDOW_MSEC_SECOND)
	journal.record_elapsed(WINDOW_MSEC_FIRST)
	return journal


func _journal_entries_of(journal: DuelJournal) -> Array:
	var parsed: Variant = JSON.parse_string(journal.to_json())
	var data: Dictionary = parsed
	var encoded: Array = data["entries"]
	return encoded


func _journal_data() -> Dictionary:
	var parsed: Variant = JSON.parse_string(DuelJournal.new(TestCatalog.setup(DUEL_SEED)).to_json())
	return parsed


# Donne à chaque champ de script une valeur autre que celle par défaut.
func _fill_fields(object: Object) -> void:
	for field: String in ScriptFields.of(object):
		var current: Variant = object.get(field)
		if current is int:
			object.set(field, FILLER_INT)
		elif current is Vector2i:
			object.set(field, FILLER_CELL)
		elif current is Array:
			var items: Array = current
			items.assign(
				[FILLER_CELL] if items.get_typed_builtin() == TYPE_VECTOR2I else [FILLER_INT]
			)
		elif current is Object:
			var nested: Object = current
			_fill_fields(nested)
