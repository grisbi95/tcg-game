# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## Écriture CSV de la fiche de relevé, `PlaytestSheet` (ruleset 0.37 ; décision 0042).
##
## Suit les décisions de design du ruleset 0155 (fiche de relevé), 0159 (compte des tours), 0161
## (compléments de la fiche : fatigue distincte des autres chutes à 0 PV), 0173 (cellules
## réservées au joueur actif), 0175 (Dernier souffle observé) et 0198 (fenêtre de réponse à
## l'écran). Le relevé qui remplit la fiche se teste dans `test_playtest_recorder.gd`.

const GAME_NUMBER: int = 3
const DATE_TEXT: String = "2026-10-21"
const RNG_SEED: int = 42
const FILE_NAME: String = "fiche-partie-3-2026-10-21-graine-42.csv"
const TURN_TABLE_COLUMNS: String = (
	"Rang du tour,Joueur actif,"
	+ "A : Essence inutilisée,A : Essence perdue,A : Cartes en main,A : Sources en jeu,"
	+ "A : Sources recyclées,A : Combat,A : Carte jouée,"
	+ "B : Essence inutilisée,B : Essence perdue,B : Cartes en main,B : Sources en jeu,"
	+ "B : Sources recyclées,B : Combat,B : Carte jouée"
)
const LAST_BREATH_COLUMNS: String = (
	"Rang du tour,Joueur actif,Issue d'un combat changée (oui ou non),"
	+ "Issue de la partie changée (oui ou non)"
)
const END_COLUMNS: String = "Champ de fin de partie,Valeur"
const TABLE_SEPARATOR: String = "\n\n"
const HEADER_AND_THREE_TABLES: int = 4
const SIXTEEN_CELLS_OF_THE_FIRST_ROW: String = "1,A,2,1,5,1,1,non,oui,,,4,2,0,non,"
const COLUMN_COUNT: int = 16
const SMALL_DECK_SIZE: int = 7  # 201.6.1 réduite : la fatigue arrive au deuxième tour de A
const FIRST_FATIGUE_RANK: int = 2
const LAST_BREATH_LINE: String = "5,A,,"
const WAIT_MSEC: int = 75_000  # 1,25 min
const SECOND_WAIT_MSEC: int = 3_000

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B

var _fixture_sheet: PlaytestSheet


func before() -> void:
	var journal := DuelJournal.from_json(ReplayFixture.read_journal_text())
	var recorder := PlaytestRecorder.new(TestCatalog.catalog())
	_fixture_sheet = recorder.record(journal, GAME_NUMBER, DATE_TEXT)


func test_decision_0042_file_name_carries_game_date_and_seed() -> void:
	var sheet := PlaytestSheet.new()
	sheet.game_number = GAME_NUMBER
	sheet.date_text = DATE_TEXT
	sheet.rng_seed = RNG_SEED
	assert_str(sheet.file_name()).is_equal(FILE_NAME)


func test_decision_0042_turn_table_starts_with_the_sixteen_columns_of_the_model() -> void:
	var table := _tables(_economy_sheet().to_csv())[1]
	assert_str(table.split("\n")[0]).is_equal(TURN_TABLE_COLUMNS)
	assert_int(TURN_TABLE_COLUMNS.split(",").size()).is_equal(COLUMN_COUNT)


func test_decision_0042_three_tables_are_separated_by_a_blank_line() -> void:
	var tables := _tables(_economy_sheet().to_csv())
	assert_int(tables.size()).is_equal(HEADER_AND_THREE_TABLES)
	assert_str(tables[0]).starts_with("Partie n°,3\nDate,2026-10-21\n")
	assert_str(tables[0]).ends_with("Graine,%d" % SetupSamples.DEFAULT_SEED)
	assert_str(tables[1]).starts_with(TURN_TABLE_COLUMNS)
	assert_str(tables[2].split("\n")[0]).is_equal(LAST_BREATH_COLUMNS)
	assert_str(tables[3].split("\n")[0]).is_equal(END_COLUMNS)


func test_decision_0159_row_line_holds_one_cell_per_column() -> void:
	var sheet := _economy_sheet()
	var lines := _tables(sheet.to_csv())[1].split("\n")
	assert_int(lines.size()).is_equal(sheet.turn_rows.size() + 1)
	# A déploie, recycle une Source et termine ; les cellules de B réservées à son tour sont vides.
	assert_str(lines[1]).is_equal(SIXTEEN_CELLS_OF_THE_FIRST_ROW)
	for line: String in lines:
		assert_int(line.split(",").size()).is_equal(COLUMN_COUNT)


func test_decision_0173_cells_reserved_to_the_active_player_are_empty_for_the_other() -> void:
	var first_row := _tables(_economy_sheet().to_csv())[1].split("\n")[1]
	var cells := first_row.split(",")
	# Essence inutilisée, Essence perdue et Carte jouée de B, joueur non actif de la première ligne.
	for index: int in [9, 10, 15]:
		assert_str(cells[index]).is_empty()
	for index: int in [2, 3, 8]:
		assert_str(cells[index]).is_not_empty()


func test_decision_0042_cell_with_a_comma_is_quoted_and_its_quotes_doubled() -> void:
	var sheet := PlaytestSheet.new()
	sheet.date_text = 'le "21", octobre'
	sheet.end_fields.reason = DuelState.EndReason.CONCEDED
	sheet.end_fields.result = DuelState.DuelResult.PLAYER_A_WINS
	var csv := sheet.to_csv()
	assert_str(_line_containing(csv, "Date,")).is_equal('Date,"le ""21"", octobre"')
	var cause_line := _line_containing(csv, "Cause de fin")
	assert_str(cause_line).starts_with('"Cause de fin (0 PV par la fatigue, 0 PV')
	assert_str(cause_line).ends_with('nulle)",abandon')


func test_209_2_6_end_cause_is_conceded_in_the_csv() -> void:
	var driver := PlaytestScenarios.fresh()
	driver.end_turn(A)
	driver.host.concede(B)
	var csv := driver.record_sheet(GAME_NUMBER, DATE_TEXT).to_csv()
	assert_str(_line_containing(csv, "Vainqueur")).is_equal("Vainqueur,A")
	assert_str(_line_containing(csv, "Premier joueur")).is_equal("Premier joueur,A")
	assert_str(_line_containing(csv, "Cause de fin")).ends_with(",abandon")


func test_209_2_2_end_cause_is_hero_health_zero_in_the_csv() -> void:
	var csv := _fixture_sheet.to_csv()
	assert_str(_line_containing(csv, "Vainqueur")).is_equal("Vainqueur,B")
	assert_str(_line_containing(csv, "Premier joueur")).is_equal("Premier joueur,A")
	assert_str(_line_containing(csv, "Cause de fin")).ends_with(",0 PV par une autre cause")


func test_209_5_3_end_cause_fatigue_text() -> void:
	var sheet := _ended_sheet(
		DuelState.DuelResult.PLAYER_B_WINS, DuelState.EndReason.HERO_HEALTH_ZERO_BY_FATIGUE
	)
	var csv := sheet.to_csv()
	assert_str(_line_containing(csv, "Cause de fin")).ends_with(",0 PV par la fatigue")
	assert_str(_line_containing(csv, "Vainqueur")).is_equal("Vainqueur,B")


func test_209_2_2_end_cause_other_text() -> void:
	var sheet := _ended_sheet(
		DuelState.DuelResult.PLAYER_A_WINS, DuelState.EndReason.HERO_HEALTH_ZERO
	)
	var cause_line := _line_containing(sheet.to_csv(), "Cause de fin")
	assert_str(cause_line).ends_with(",0 PV par une autre cause")
	assert_str(cause_line).not_contains(",0 PV par la fatigue")


func test_209_3_1_draw_text() -> void:
	# Deux Heroes à 0 PV en même temps : la raison reste une chute à 0 PV, la fiche dit nulle.
	var sheet := _ended_sheet(DuelState.DuelResult.DRAW, DuelState.EndReason.HERO_HEALTH_ZERO)
	var csv := sheet.to_csv()
	assert_str(_line_containing(csv, "Cause de fin")).ends_with(",partie nulle")
	assert_str(_line_containing(csv, "Vainqueur")).is_equal("Vainqueur,aucun")


func test_204_1_9_duration_is_written_in_minutes_with_a_decimal_point() -> void:
	var driver := PlaytestScenarios.fresh()
	driver.wait(WAIT_MSEC)
	driver.wait(SECOND_WAIT_MSEC)
	var csv := driver.record_sheet(GAME_NUMBER, DATE_TEXT).to_csv()
	assert_str(_line_containing(csv, "Durée")).is_equal("Durée (min),1.3")


func test_209_4_9_turn_expiries_are_written_per_player() -> void:
	var csv := PlaytestScenarios.expiring().record_sheet(GAME_NUMBER, DATE_TEXT).to_csv()
	assert_str(_line_containing(csv, "temps de tour, A")).is_equal(
		'"Tours terminés par l\'expiration du temps de tour, A",1'
	)
	assert_str(_line_containing(csv, "temps de tour, B")).ends_with(",0")


func test_209_4_10_response_expiries_are_written_per_player() -> void:
	var csv := PlaytestScenarios.expiring().record_sheet(GAME_NUMBER, DATE_TEXT).to_csv()
	assert_str(_line_containing(csv, "temps de réponse, A")).is_equal(
		'"Réponses passées par l\'expiration du temps de réponse, A",1'
	)
	assert_str(_line_containing(csv, "temps de réponse, B")).ends_with(",0")


func test_204_2_1_mulligan_count_is_written() -> void:
	var driver := HumanDuelDriver.new(SetupSamples.catalog())
	driver.start(SetupSamples.setup(), [A, B])
	var csv := driver.record_sheet(GAME_NUMBER, DATE_TEXT).to_csv()
	assert_str(_line_containing(csv, "Nombre de mulligans")).is_equal("Nombre de mulligans,2")


func test_209_5_2_first_fatigue_turn_is_written_or_none() -> void:
	var none := _line_containing(_economy_sheet().to_csv(), "compteur de fatigue")
	assert_str(none).ends_with(",aucun")
	var driver := PlaytestScenarios.small_deck_duel(SMALL_DECK_SIZE)
	for round_index: int in FIRST_FATIGUE_RANK + 1:
		driver.end_turn(A)
		driver.end_turn(B)
	var csv := driver.record_sheet(GAME_NUMBER, DATE_TEXT).to_csv()
	assert_str(_line_containing(csv, "compteur de fatigue")).ends_with(",%d" % FIRST_FATIGUE_RANK)


func test_decision_0198_free_notes_are_left_empty() -> void:
	var csv := _economy_sheet().to_csv()
	assert_str(_line_containing(csv, "Ressenti du rythme")).ends_with(",")
	assert_str(_line_containing(csv, "Lisibilité du texte")).ends_with(",")
	assert_str(_line_containing(csv, "Champ libre")).is_equal("Champ libre,")


func test_210_3_2_last_breath_table_has_one_line_per_trigger() -> void:
	var driver := PlaytestScenarios.walk_to_attack(PlaytestScenarios.martyr_duel())
	driver.end_turn(A)
	var table := _tables(driver.record_sheet(GAME_NUMBER, DATE_TEXT).to_csv())[2]
	var lines := table.split("\n")
	assert_int(lines.size()).is_equal(3)
	# Rang 5 de A ; les deux jugements restent au joueur (décision 0175 du ruleset).
	assert_str(lines[1]).is_equal(LAST_BREATH_LINE)
	assert_str(lines[2]).is_equal(LAST_BREATH_LINE)
	var empty := _tables(_economy_sheet().to_csv())[2]
	assert_int(empty.split("\n").size()).is_equal(1)


func _record(journal: DuelJournal) -> PlaytestSheet:
	var recorder := PlaytestRecorder.new(SetupSamples.catalog())
	return recorder.record(journal, GAME_NUMBER, DATE_TEXT)


func _economy_sheet() -> PlaytestSheet:
	return PlaytestScenarios.economy().record_sheet(GAME_NUMBER, DATE_TEXT)


func _ended_sheet(result: DuelState.DuelResult, reason: DuelState.EndReason) -> PlaytestSheet:
	var sheet := PlaytestSheet.new()
	sheet.end_fields.result = result
	sheet.end_fields.reason = reason
	return sheet


# Les tableaux d'un CSV : l'en-tête de la fiche, puis le relevé par tour, les notes sur Dernier
# souffle et la fin de partie.
func _tables(csv: String) -> PackedStringArray:
	return csv.strip_edges().split(TABLE_SEPARATOR)


func _line_containing(csv: String, fragment: String) -> String:
	for line: String in csv.split("\n"):
		if line.contains(fragment):
			return line
	fail("aucune ligne ne contient « %s »" % fragment)
	return ""
