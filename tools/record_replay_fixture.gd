extends SceneTree
## Régénère le journal et l'empreinte du test de non-régression (décision 0022), quand un
## changement de règle est voulu. Depuis la racine du projet :
## "$GODOT_BIN" --headless --path . -s tools/record_replay_fixture.gd

const EXIT_FAILURE: int = 1


func _init() -> void:
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
