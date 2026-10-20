extends GdUnitTestSuite
## Journal, codec des intentions et replay (ruleset 0.34 ; décisions 0001, 0020 et 0022).
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
		var name: StringName = global_class["class"]
		(
			assert_bool(IntentCodec.INTENT_SCRIPTS.has(name))
			. override_failure_message("%s absente d'IntentCodec.INTENT_SCRIPTS" % name)
			. is_true()
		)
		var script: GDScript = IntentCodec.INTENT_SCRIPTS.get(name)
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
