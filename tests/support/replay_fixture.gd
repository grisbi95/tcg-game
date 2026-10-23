class_name ReplayFixture
extends RefCounted
## Duel de non-régression (décision 0022) : deux RandomLegalAgent à graine fixe jouent les decks
## de test par DuelHost, avec une horloge manuelle. Son journal et son empreinte attendue vivent
## dans tests/fixtures/ ; `tools/record_replay_fixture.gd` les régénère quand un changement de
## règle est voulu.

const JOURNAL_PATH: String = "res://tests/fixtures/replay_random_duel.journal.json"
const FINGERPRINT_PATH: String = "res://tests/fixtures/replay_random_duel.fingerprint.json"
const DUEL_SEED: int = 11
## Graines choisies le 23 octobre 2026 (ruleset 0.42, décision de design 0208) : le duel finit par
## la perte de PV du Hero de A, gagné par B. Les graines 47 et 48 donnaient la victoire de A une
## fois le pouvoir du Hero retiré.
const AGENT_SEED_A: int = 55
const AGENT_SEED_B: int = 56
const TICK_MSEC: int = 1_500
## Borne de pas : le duel des graines ci-dessus finit bien avant.
const MAX_TICKS: int = 20_000


## Joue le duel par l'hôte jusqu'à sa fin et renvoie son journal.
static func play() -> DuelJournal:
	var clock := ManualClock.new()
	var host := DuelHost.new(DuelEngine.new(TestCatalog.catalog()), clock)
	host.set_agent(DuelState.PlayerSide.A, RandomLegalAgent.new(AGENT_SEED_A))
	host.set_agent(DuelState.PlayerSide.B, RandomLegalAgent.new(AGENT_SEED_B))
	host.start(TestCatalog.setup(DUEL_SEED))
	HostDriver.run(host, clock, TICK_MSEC, MAX_TICKS)
	return host.get_journal()


## Rejoue `journal` dans un moteur neuf et renvoie l'empreinte du duel.
static func fingerprint_of(journal: DuelJournal) -> ReplayFingerprint:
	var engine := DuelEngine.new(TestCatalog.catalog())
	var events := journal.replay_into(engine)
	return ReplayFingerprint.of(events, engine.get_state())


## Vrai si les deux fichiers sont écrits.
static func write(journal: DuelJournal, fingerprint: ReplayFingerprint) -> bool:
	var fingerprint_text := JSON.stringify(fingerprint.to_dict(), "\t")
	return (
		_write_text(JOURNAL_PATH, journal.to_json())
		and _write_text(FINGERPRINT_PATH, fingerprint_text)
	)


static func read_journal_text() -> String:
	return FileAccess.get_file_as_string(JOURNAL_PATH)


static func read_fingerprint() -> ReplayFingerprint:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FINGERPRINT_PATH))
	var data: Dictionary = parsed if parsed is Dictionary else {}
	return ReplayFingerprint.from_dict(data)


static func _write_text(path: String, text: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("ReplayFixture : écriture impossible de %s" % path)
		return false
	return file.store_string(text + "\n")
