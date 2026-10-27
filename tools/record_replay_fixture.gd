extends SceneTree
## Régénère le journal et l'empreinte du test de non-régression (décision 0022), quand un
## changement de règle est voulu. Depuis la racine du projet :
## "$GODOT_BIN" --headless --path . -s tools/record_replay_fixture.gd
##
## Avec l'argument `--fingerprint-only`, le journal enregistré reste en place et seule l'empreinte
## est recalculée par son rejeu :
## "$GODOT_BIN" --headless --path . -s tools/record_replay_fixture.gd -- --fingerprint-only
## À employer quand le comportement est inchangé mais que l'état a changé de forme (champ ajouté) :
## `events_sha256` et `event_count` doivent rester identiques, seul `final_state_sha256` bouge.

const EXIT_FAILURE: int = 1
const FINGERPRINT_ONLY_ARGUMENT: String = "--fingerprint-only"


func _init() -> void:
	if OS.get_cmdline_user_args().has(FINGERPRINT_ONLY_ARGUMENT):
		_record_fingerprint_only()
		return
	var journal := ReplayFixture.play()
	var fingerprint := ReplayFixture.fingerprint_of(journal)
	if not ReplayFixture.write(journal, fingerprint):
		quit(EXIT_FAILURE)
		return
	var summary := [
		journal.entries.size(), fingerprint.event_count, fingerprint.turn_number, fingerprint.result
	]
	print("Journal enregistré : %d entrées, %d événements, tour %d, résultat %d" % summary)
	quit()


func _record_fingerprint_only() -> void:
	var journal := DuelJournal.from_json(ReplayFixture.read_journal_text())
	var fingerprint := ReplayFixture.fingerprint_of(journal)
	if not ReplayFixture.write_fingerprint(fingerprint):
		quit(EXIT_FAILURE)
		return
	print("Empreinte recalculée : %d événements" % fingerprint.event_count)
	quit()
