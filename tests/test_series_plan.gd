extends GdUnitTestSuite
## Plan de série en données (ruleset 0.56 ; décision 0069) : fichier de `data/series/` lu par
## `GameLibrary`, contrôles du chargement, contraintes des décisions de design 0229, 0230 et 0231
## du ruleset, parties du plan et partie libre de `DuelSeries`, en-tête de la fiche de relevé.

const PROTOCOL_PATH: String = "res://docs/ruleset/70-playtest/protocole.md"
const PLAN_SECTION: String = "## Plan de série"
const TABLE_ROW_PREFIX: String = "| "
const TABLE_SEPARATOR: String = "|"
const PROTOCOL_CELL_COUNT: int = 5  # Partie, Affrontement, Joueur A, Joueur B, Premier joueur
const GAME_COUNT: int = 24  # décision de design 0229
const PLAYTEST_DECK_COUNT: int = 4  # décision de design 0224
const GAMES_PER_MATCHUP: int = 4  # décision de design 0229
const MATCHUP_COUNT: int = 6  # décision de design 0229
const GAMES_PER_PLAYER_AND_DECK: int = 6  # décision de design 0230
const STARTS_PER_DECK_AND_MATCHUP: int = 2  # décision de design 0231
const SEED: int = 4242
const DATE_TEXT: String = "2026-10-28"
const PLAN_GAME_NUMBER: int = 7
const UNKNOWN_GAME_NUMBER: int = 25
const KNOWN_DECK_IDS: Array[StringName] = [&"percee", &"phalange"]

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B

var _catalog: Catalog
var _decks: Array[DeckList] = []
var _plan: SeriesPlan


func before() -> void:
	_catalog = GameLibrary.load_catalog()
	_decks = GameLibrary.load_decks(_catalog)
	_plan = GameLibrary.load_series_plan(_catalog, _decks)


func test_decision_0069_plan_has_24_games_numbered_in_order() -> void:
	assert_object(_plan).is_not_null()
	assert_str(_plan.edition).is_equal(_catalog.edition)
	assert_int(_plan.game_count()).is_equal(GAME_COUNT)
	for index: int in _plan.game_count():
		assert_int(_plan.games[index].game_number).is_equal(SeriesPlan.FIRST_GAME_NUMBER + index)


func test_decision_0069_plan_is_the_table_of_the_protocol() -> void:
	var protocol_games := _protocol_games()
	assert_int(protocol_games.size()).is_equal(GAME_COUNT)
	for expected: SeriesPlanGame in protocol_games:
		var game := _plan.find_game(expected.game_number)
		assert_object(game).is_not_null()
		assert_str(String(game.deck_id_a)).is_equal(String(expected.deck_id_a))
		assert_str(String(game.deck_id_b)).is_equal(String(expected.deck_id_b))
		assert_int(game.first_player).is_equal(expected.first_player)


func test_decision_0229_six_distinct_matchups_of_four_games_without_mirror() -> void:
	var games_by_matchup := _games_by_matchup()
	assert_int(games_by_matchup.size()).is_equal(MATCHUP_COUNT)
	for matchup: String in games_by_matchup:
		assert_int(games_by_matchup[matchup].size()).is_equal(GAMES_PER_MATCHUP)
	for game: SeriesPlanGame in _plan.games:
		assert_str(String(game.deck_id_a)).is_not_equal(String(game.deck_id_b))
	var deck_ids: Dictionary[StringName, bool] = {}
	for game: SeriesPlanGame in _plan.games:
		deck_ids[game.deck_id_a] = true
		deck_ids[game.deck_id_b] = true
	assert_int(deck_ids.size()).is_equal(PLAYTEST_DECK_COUNT)


func test_decision_0230_each_player_holds_each_deck_six_times() -> void:
	var counts: Dictionary[String, int] = {}
	for game: SeriesPlanGame in _plan.games:
		for side: DuelState.PlayerSide in DuelState.SIDES:
			var key := "%s:%s" % [PlaytestSheet.letter(side), game.deck_id(side)]
			counts[key] = counts.get(key, 0) + 1
	assert_int(counts.size()).is_equal(PLAYTEST_DECK_COUNT * DuelState.SIDES.size())
	for key: String in counts:
		assert_int(counts[key]).override_failure_message(key).is_equal(GAMES_PER_PLAYER_AND_DECK)


func test_decision_0231_each_deck_starts_two_games_of_four_in_each_matchup() -> void:
	var games_by_matchup := _games_by_matchup()
	for matchup: String in games_by_matchup:
		var starts: Dictionary[StringName, int] = {}
		for game: SeriesPlanGame in games_by_matchup[matchup]:
			var starting_deck := game.deck_id(game.first_player)
			starts[starting_deck] = starts.get(starting_deck, 0) + 1
		for deck_id: StringName in starts:
			assert_int(starts[deck_id]).is_equal(STARTS_PER_DECK_AND_MATCHUP)


func test_decision_0229_library_expects_six_matchups_of_four_games() -> void:
	assert_int(GameLibrary.SERIES_GAME_COUNT).is_equal(MATCHUP_COUNT * GAMES_PER_MATCHUP)
	assert_int(GameLibrary.SERIES_GAME_COUNT).is_equal(GAME_COUNT)


func test_decision_0229_plan_of_another_game_count_is_an_error() -> void:
	var games: Array[String] = [
		_game_text(1, "percee", "phalange", "A"), _game_text(2, "phalange", "percee", "B")
	]
	var loader := SeriesPlanLoader.new(_catalog.edition, KNOWN_DECK_IDS, GAME_COUNT)
	loader.load_text(_plan_text(games), "essai")
	assert_array(Array(loader.find_errors())).contains(
		["essai : 2 parties, attendues %d" % GAME_COUNT]
	)


func test_decision_0069_unknown_deck_is_an_error() -> void:
	var errors := _load_errors(_plan_text([_game_text(1, "percee", "inconnu", "A")]))
	assert_array(Array(errors)).contains(
		["essai : partie 1 : « deck_b » : deck « inconnu » inconnu"]
	)


func test_decision_0069_missing_game_number_is_an_error() -> void:
	var games: Array[String] = [
		_game_text(1, "percee", "phalange", "A"), _game_text(3, "phalange", "percee", "B")
	]
	assert_array(Array(_load_errors(_plan_text(games)))).contains(["essai : partie 2 manquante"])


func test_decision_0069_duplicate_game_number_is_an_error() -> void:
	var games: Array[String] = [
		_game_text(1, "percee", "phalange", "A"), _game_text(1, "phalange", "percee", "B")
	]
	assert_array(Array(_load_errors(_plan_text(games)))).contains(["essai : partie 1 en double"])


func test_decision_0069_first_player_is_a_or_b() -> void:
	var errors := _load_errors(_plan_text([_game_text(1, "percee", "phalange", "C")]))
	assert_array(Array(errors)).contains(
		["essai : partie 1 : « first_player » : « C » inconnu (valeurs : A, B)"]
	)


func test_decision_0069_valid_plan_text_loads_without_error() -> void:
	var games: Array[String] = [
		_game_text(2, "phalange", "percee", "B"), _game_text(1, "percee", "phalange", "A")
	]
	var loader := SeriesPlanLoader.new(_catalog.edition, KNOWN_DECK_IDS)
	loader.load_text(_plan_text(games), "essai")
	assert_array(Array(loader.find_errors())).is_empty()
	var plan := loader.get_plan()
	assert_int(plan.games[0].game_number).is_equal(1)
	assert_int(plan.games[1].first_player).is_equal(B)


func test_decision_0069_every_plan_game_sets_up_its_decks_and_imposed_first_player() -> void:
	var series := _plan_series()
	for game: SeriesPlanGame in series.get_plan_games():
		series.choose_plan_game(game.game_number)
		assert_int(series.get_game_number()).is_equal(game.game_number)
		var duel_setup := series.make_setup(SEED)
		assert_array(Array(duel_setup.find_errors(_catalog, DuelConfig.new()))).is_empty()
		var deck_a := series.get_deck(A)
		var deck_b := series.get_deck(B)
		assert_str(String(deck_a.deck_id)).is_equal(String(game.deck_id_a))
		assert_str(String(deck_b.deck_id)).is_equal(String(game.deck_id_b))
		assert_array(duel_setup.deck_a).is_equal(deck_a.card_ids())
		assert_array(duel_setup.deck_b).is_equal(deck_b.card_ids())
		assert_str(String(duel_setup.hero_a)).is_equal(String(deck_a.hero_id))
		assert_str(String(duel_setup.hero_b)).is_equal(String(deck_b.hero_id))
		assert_bool(duel_setup.is_first_player_imposed).is_true()
		assert_int(duel_setup.imposed_first_player).is_equal(game.first_player)


func test_decision_0069_plan_game_ignores_the_free_game_choices() -> void:
	var series := _plan_series()
	series.set_first_player_choice(DuelSeries.FirstPlayerChoice.DRAWN)
	series.choose_plan_game(PLAN_GAME_NUMBER)
	var game := _plan.find_game(PLAN_GAME_NUMBER)
	var duel_setup := series.make_setup(SEED)
	assert_bool(series.is_free_game()).is_false()
	assert_int(series.get_game_number()).is_equal(PLAN_GAME_NUMBER)
	assert_object(series.get_chosen_game()).is_same(game)
	assert_int(duel_setup.imposed_first_player).is_equal(game.first_player)
	var engine := DuelEngine.new(_catalog)
	engine.start_new_duel(duel_setup)
	assert_int(engine.get_state().first_player).is_equal(game.first_player)


func test_decision_0069_unknown_plan_game_is_reported_and_changes_nothing() -> void:
	var series := _plan_series()
	series.choose_plan_game(PLAN_GAME_NUMBER)
	var choose_unknown := func() -> void: series.choose_plan_game(UNKNOWN_GAME_NUMBER)
	await assert_error(choose_unknown).is_push_error(
		DuelSeries.UNKNOWN_GAME_FORMAT % UNKNOWN_GAME_NUMBER
	)
	assert_int(series.get_game_number()).is_equal(PLAN_GAME_NUMBER)


func test_decision_0069_free_game_keeps_the_choices_of_decision_0066() -> void:
	var series := _plan_series()
	series.choose_plan_game(PLAN_GAME_NUMBER)
	series.set_first_player_choice(DuelSeries.FirstPlayerChoice.DRAWN)
	series.choose_free_game()
	var duel_setup := series.make_setup(SEED)
	assert_int(series.get_game_number()).is_equal(DuelSeries.NO_PLAN_GAME)
	assert_str(String(series.get_deck(A).deck_id)).is_equal(String(GameLibrary.TEST_DECK_ID))
	assert_array(duel_setup.deck_a).is_equal(series.get_deck(A).card_ids())
	assert_bool(duel_setup.is_first_player_imposed).is_false()


func test_decision_0069_sheet_carries_the_plan_game_number_and_deck_names() -> void:
	var series := _plan_series()
	series.choose_plan_game(PLAN_GAME_NUMBER)
	var sheet := _sheet_of(series)
	var header := sheet.to_csv().split("\n\n")[0]
	var game := _plan.find_game(PLAN_GAME_NUMBER)
	var expected_lines: Array[String] = [
		"Partie n°,%d" % PLAN_GAME_NUMBER,
		"Deck de A,%s" % _deck_named(game.deck_id_a).deck_name,
		"Deck de B,%s" % _deck_named(game.deck_id_b).deck_name,
	]
	for line: String in expected_lines:
		assert_array(Array(header.split("\n"))).contains([line])
	var file_prefix := "fiche-partie-%d-%s-graine-" % [PLAN_GAME_NUMBER, DATE_TEXT]
	assert_str(sheet.file_name()).starts_with(file_prefix)


func test_decision_0069_free_game_sheet_is_marked_off_plan() -> void:
	var sheet := _sheet_of(_plan_series())
	var header_lines := Array(sheet.to_csv().split("\n\n")[0].split("\n"))
	assert_array(header_lines).contains(["Partie n°,hors plan", "Deck de A,Deck de test"])
	var file_prefix := "fiche-partie-hors-plan-%s-graine-" % DATE_TEXT
	assert_str(sheet.file_name()).starts_with(file_prefix)


func _plan_series() -> DuelSeries:
	var test_deck := _deck_named(GameLibrary.TEST_DECK_ID)
	var series := DuelSeries.new(test_deck, test_deck)
	series.set_plan(_plan, _decks)
	return series


func _deck_named(deck_id: StringName) -> DeckList:
	for deck: DeckList in _decks:
		if deck.deck_id == deck_id:
			return deck
	return null


# Fiche du journal de la partie choisie, sans entrée : seul son en-tête compte ici.
func _sheet_of(series: DuelSeries) -> PlaytestSheet:
	var journal := DuelJournal.new()
	journal.setup = series.make_setup(SEED)
	var recorder := PlaytestRecorder.new(_catalog)
	return recorder.record(journal, series.get_game_number(), DATE_TEXT, series.get_deck_names())


# Clé d'un affrontement : les deux decks dans l'ordre alphabétique.
func _games_by_matchup() -> Dictionary[String, Array]:
	var games_by_matchup: Dictionary[String, Array] = {}
	for game: SeriesPlanGame in _plan.games:
		var pair: Array[String] = [String(game.deck_id_a), String(game.deck_id_b)]
		pair.sort()
		var key := "-".join(pair)
		if not games_by_matchup.has(key):
			games_by_matchup[key] = []
		games_by_matchup[key].append(game)
	return games_by_matchup


# Lignes du tableau « Plan de série » du protocole, decks traduits par leur nom affiché.
func _protocol_games() -> Array[SeriesPlanGame]:
	var text := FileAccess.get_file_as_string(PROTOCOL_PATH)
	var section := text.substr(text.find(PLAN_SECTION))
	var games: Array[SeriesPlanGame] = []
	for line: String in section.split("\n"):
		var cells := _cells(line)
		if cells.size() != PROTOCOL_CELL_COUNT or not cells[0].is_valid_int():
			continue
		var game := SeriesPlanGame.new()
		game.game_number = cells[0].to_int()
		game.deck_id_a = _deck_id_of_name(cells[2])
		game.deck_id_b = _deck_id_of_name(cells[3])
		game.first_player = A if cells[4].begins_with("A") else B
		games.append(game)
		if games.size() == GAME_COUNT:
			break
	return games


func _cells(line: String) -> PackedStringArray:
	var cells := PackedStringArray()
	if not line.begins_with(TABLE_ROW_PREFIX):
		return cells
	for cell: String in line.trim_prefix(TABLE_SEPARATOR).trim_suffix(TABLE_SEPARATOR).split(
		TABLE_SEPARATOR
	):
		cells.append(cell.strip_edges())
	return cells


func _deck_id_of_name(deck_name: String) -> StringName:
	for deck: DeckList in _decks:
		if deck.deck_name == deck_name:
			return deck.deck_id
	return &""


func _load_errors(json_text: String) -> PackedStringArray:
	var loader := SeriesPlanLoader.new(_catalog.edition, KNOWN_DECK_IDS)
	loader.load_text(json_text, "essai")
	return loader.find_errors()


func _plan_text(games: Array[String]) -> String:
	return '{"edition": "%s", "games": [%s]}' % [_catalog.edition, ", ".join(games)]


static func _game_text(game_number: int, deck_a: String, deck_b: String, first: String) -> String:
	return (
		'{"game": %d, "deck_a": "%s", "deck_b": "%s", "first_player": "%s"}'
		% [game_number, deck_a, deck_b, first]
	)
