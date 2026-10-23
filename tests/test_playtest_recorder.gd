# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## Relevé de playtest d'un journal, `PlaytestRecorder` (ruleset 0.41 ; décision 0042).
##
## Suit les décisions de design du ruleset 0155 (fiche de relevé), 0159 (compte des tours), 0160
## (moment de l'Essence inutilisée), 0161 (compléments de la fiche), 0168 (précisions du
## protocole), 0173 (Carte jouée sur le tour du joueur), 0175 (Dernier souffle observé), 0195
## (Essence perdue) et 0198 (fenêtre de réponse à l'écran). Les mesures de fin de partie sont
## relevées ici ; leur écriture en CSV se teste dans `test_playtest_sheet.gd`.
##
## Deux sources de journaux : celui de `tests/fixtures/` (deux agents, duel long, sans fenêtre de
## réponse) pour les mesures globales, et un duel de deux humains sur `HumanDuelDriver` pour les
## mesures précises, dont les valeurs sortent des règles et non du relevé.

const GAME_NUMBER: int = 3
const DATE_TEXT: String = "2026-10-21"
const OPENING_HAND_SIZE: int = 4  # 204.1.15
const CARDS_DRAWN_PER_TURN: int = 1  # 204.3.6
const STARTING_SOURCES: int = 2  # 204.1.2
const SOURCES_RECEIVED_PER_TURN: int = 1  # 204.3.1
const IDLE_ROUNDS: int = 3
const WAIT_MSEC: int = 75_000
const SECOND_WAIT_MSEC: int = 3_000
const SMALL_DECK_SIZE: int = 5  # 201.6.1 réduite : la fatigue arrive au deuxième tour de A
const MARTYR_COUNT_AT_TIE: int = 2  # les deux Units de la rencontre portent Dernier souffle
const ATTACK_TURN_RANK: int = 5  # PlaytestScenarios.walk_to_attack : l'Unit de A attaque au tour 5
const OWN_END_ROW: int = 2  # tour 2 de A, dans PlaytestScenarios.answering_in_own_turn
const END_OF_TURN_ROW_COUNT: int = 6  # tours 1 à 3 de A et de B, le dernier ouvert

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B

var _fixture_catalog: Catalog
var _fixture_journal: DuelJournal
var _fixture_sheet: PlaytestSheet


func before() -> void:
	_fixture_catalog = TestCatalog.catalog()
	_fixture_journal = DuelJournal.from_json(ReplayFixture.read_journal_text())
	_fixture_sheet = _record_fixture()


func test_decision_0042_two_records_of_the_same_journal_give_the_same_csv() -> void:
	var again := _record_fixture()
	assert_str(again.to_csv()).is_equal(_fixture_sheet.to_csv())
	assert_str(again.file_name()).is_equal(_fixture_sheet.file_name())


func test_decision_0042_sheet_takes_its_identity_from_the_caller_and_the_journal() -> void:
	assert_int(_fixture_sheet.game_number).is_equal(GAME_NUMBER)
	assert_str(_fixture_sheet.date_text).is_equal(DATE_TEXT)
	assert_int(_fixture_sheet.rng_seed).is_equal(ReplayFixture.DUEL_SEED)


func test_decision_0159_one_row_per_turn_started_with_the_rank_of_each_player() -> void:
	var events := _fixture_journal.replay_into(DuelEngine.new(_fixture_catalog))
	var started: Array[TurnStarted] = []
	for event: DuelEvent in events:
		if event is TurnStarted:
			started.append(event as TurnStarted)
	assert_int(started.size()).is_greater(2)
	assert_int(_fixture_sheet.turn_rows.size()).is_equal(started.size())
	var ranks: Array[int] = [0, 0]
	for index: int in started.size():
		var side := started[index].player
		ranks[side] += 1
		var row: PlaytestSheet.TurnRow = _fixture_sheet.turn_rows[index]
		assert_int(row.active_player).is_equal(side)
		assert_int(row.turn_rank).is_equal(ranks[side])


func test_decision_0159_ranks_run_1_1_2_2_in_a_game_of_alternating_turns() -> void:
	var sheet := _sheet_of(PlaytestScenarios.idle_rounds(IDLE_ROUNDS))
	var ranks: Array[int] = []
	var players: Array[int] = []
	for row: PlaytestSheet.TurnRow in sheet.turn_rows:
		ranks.append(row.turn_rank)
		players.append(row.active_player)
	assert_array(ranks).is_equal([1, 1, 2, 2, 3, 3, 4])
	assert_array(players).is_equal([A, B, A, B, A, B, A])


func test_204_3_2_essence_unused_is_the_upright_sources_before_untap() -> void:
	var sheet := _sheet_of(PlaytestScenarios.idle_rounds(IDLE_ROUNDS))
	# A ne reçoit pas de Source à son premier tour (204.3.4) ; B en reçoit une à chaque tour.
	var expected_a: Array[int] = [STARTING_SOURCES, STARTING_SOURCES, STARTING_SOURCES + 1]
	var expected_b: Array[int] = [STARTING_SOURCES, STARTING_SOURCES + 1, STARTING_SOURCES + 2]
	for rank: int in IDLE_ROUNDS:
		assert_int(_cells(sheet, 2 * rank, A).essence_unused).is_equal(expected_a[rank])
		assert_int(_cells(sheet, 2 * rank, B).essence_unused).is_equal(PlaytestSheet.NO_VALUE)
		assert_int(_cells(sheet, 2 * rank + 1, B).essence_unused).is_equal(expected_b[rank])
		assert_int(_cells(sheet, 2 * rank + 1, A).essence_unused).is_equal(PlaytestSheet.NO_VALUE)


func test_204_3_2_essence_spent_during_the_turn_is_not_unused() -> void:
	var sheet := _sheet_of(PlaytestScenarios.economy())
	# A a incliné ses deux Sources pour déployer, puis en a recyclé une : l'autre reste inclinée.
	assert_int(_cells(sheet, 2, A).essence_unused).is_equal(0)


func test_204_5_7a_essence_lost_is_the_reserve_at_end_of_turn() -> void:
	var driver := PlaytestScenarios.fresh()
	driver.play(ProduceEssence.new(A, EssencePayment.new(STARTING_SOURCES)))
	driver.end_turn(A)
	driver.end_turn(B)
	driver.end_turn(A)
	var sheet := _sheet_of(driver)
	assert_int(_cells(sheet, 0, A).essence_lost).is_equal(STARTING_SOURCES)
	assert_int(_cells(sheet, 0, B).essence_lost).is_equal(PlaytestSheet.NO_VALUE)
	assert_int(_cells(sheet, 1, B).essence_lost).is_equal(0)
	assert_int(_cells(sheet, 1, A).essence_lost).is_equal(PlaytestSheet.NO_VALUE)
	assert_int(_cells(sheet, 2, A).essence_lost).is_equal(0)


func test_204_5_7a_essence_spent_on_a_deploy_is_not_lost() -> void:
	# Les Sources inclinées pour le déploiement ne laissent que l'Essence du recyclage.
	assert_int(_cells(_sheet_of(PlaytestScenarios.economy()), 0, A).essence_lost).is_equal(1)
	var spent := _sheet_of(PlaytestScenarios.deploying())
	assert_int(_cells(spent, 0, A).essence_lost).is_equal(0)


func test_201_3_2_hand_counts_at_end_of_turn() -> void:
	var sheet := _sheet_of(PlaytestScenarios.economy())
	var a_after_deploy := OPENING_HAND_SIZE + CARDS_DRAWN_PER_TURN - 1
	assert_int(_cells(sheet, 0, A).hand_count).is_equal(a_after_deploy)
	assert_int(_cells(sheet, 0, B).hand_count).is_equal(OPENING_HAND_SIZE)
	assert_int(_cells(sheet, 1, A).hand_count).is_equal(a_after_deploy)
	assert_int(_cells(sheet, 1, B).hand_count).is_equal(OPENING_HAND_SIZE + CARDS_DRAWN_PER_TURN)


func test_203_5_4_sources_in_play_at_end_of_turn() -> void:
	var sheet := _sheet_of(PlaytestScenarios.economy())
	# A a recyclé une Source, qui sort du jeu pour toujours ; B reçoit une Source à son tour.
	assert_int(_cells(sheet, 0, A).sources_in_play).is_equal(STARTING_SOURCES - 1)
	assert_int(_cells(sheet, 0, B).sources_in_play).is_equal(STARTING_SOURCES)
	assert_int(_cells(sheet, 1, A).sources_in_play).is_equal(STARTING_SOURCES - 1)
	var b_after_reception := STARTING_SOURCES + SOURCES_RECEIVED_PER_TURN
	assert_int(_cells(sheet, 1, B).sources_in_play).is_equal(b_after_reception)


func test_203_2_2_sources_recycled_during_the_turn() -> void:
	var sheet := _sheet_of(PlaytestScenarios.economy())
	assert_int(_cells(sheet, 0, A).sources_recycled).is_equal(1)
	assert_int(_cells(sheet, 0, B).sources_recycled).is_equal(0)
	assert_int(_cells(sheet, 1, A).sources_recycled).is_equal(0)
	assert_int(_cells(sheet, 1, B).sources_recycled).is_equal(0)


func test_206_1_1_fought_is_yes_when_the_player_attacked() -> void:
	var driver := PlaytestScenarios.walk_to_attack(PlaytestScenarios.fresh())
	driver.end_turn(A)
	var sheet := _sheet_of(driver)
	var attack_index := sheet.turn_rows.size() - 2
	assert_int(_cells(sheet, attack_index, A).fought).is_equal(PlaytestSheet.Mark.YES)
	assert_int(_cells(sheet, attack_index, B).fought).is_equal(PlaytestSheet.Mark.NO)
	for index: int in attack_index:
		for side: DuelState.PlayerSide in DuelState.SIDES:
			assert_int(_cells(sheet, index, side).fought).is_equal(PlaytestSheet.Mark.NO)


func test_decision_0168_card_played_covers_the_turn_and_the_responses_before_it() -> void:
	var sheet := _sheet_of(PlaytestScenarios.deploying())
	assert_int(_cells(sheet, 0, A).card_played).is_equal(PlaytestSheet.Mark.YES)
	assert_int(_cells(sheet, 0, B).card_played).is_equal(PlaytestSheet.Mark.NONE)
	assert_int(_cells(sheet, 1, B).card_played).is_equal(PlaytestSheet.Mark.NO)
	assert_int(_cells(sheet, 1, A).card_played).is_equal(PlaytestSheet.Mark.NONE)
	assert_int(_cells(sheet, 2, A).card_played).is_equal(PlaytestSheet.Mark.NO)
	var answering := _sheet_of(PlaytestScenarios.answering())
	assert_int(_cells(answering, 0, A).card_played).is_equal(PlaytestSheet.Mark.YES)
	assert_int(_cells(answering, 0, B).card_played).is_equal(PlaytestSheet.Mark.NONE)
	assert_int(_cells(answering, 1, B).card_played).is_equal(PlaytestSheet.Mark.YES)
	assert_int(_cells(answering, 2, A).card_played).is_equal(PlaytestSheet.Mark.NO)
	assert_int(_cells(answering, 3, B).card_played).is_equal(PlaytestSheet.Mark.NO)


func test_209_2_6_end_cause_is_conceded() -> void:
	var driver := PlaytestScenarios.fresh()
	driver.end_turn(A)
	driver.host.concede(B)
	var fields := _sheet_of(driver).end_fields
	assert_int(fields.reason).is_equal(DuelState.EndReason.CONCEDED)
	assert_int(fields.result).is_equal(DuelState.DuelResult.PLAYER_A_WINS)
	assert_int(fields.first_player).is_equal(A)


func test_209_2_2_end_cause_is_hero_health_zero() -> void:
	var fields := _fixture_sheet.end_fields
	assert_int(fields.reason).is_equal(DuelState.EndReason.HERO_HEALTH_ZERO)
	assert_int(fields.result).is_equal(DuelState.DuelResult.PLAYER_B_WINS)
	assert_int(fields.first_player).is_equal(A)


func test_204_1_9_duration_is_the_journal_total() -> void:
	var driver := PlaytestScenarios.fresh()
	driver.wait(WAIT_MSEC)
	driver.wait(SECOND_WAIT_MSEC)
	var sheet := _sheet_of(driver)
	assert_int(sheet.end_fields.duration_msec).is_equal(WAIT_MSEC + SECOND_WAIT_MSEC)
	var fixture_total_msec := _fixture_journal.total_elapsed_msec()
	assert_int(_fixture_sheet.end_fields.duration_msec).is_equal(fixture_total_msec)


func test_209_4_9_turn_expiries_per_player() -> void:
	var sheet := _sheet_of(PlaytestScenarios.expiring())
	assert_int(sheet.end_fields.turn_expiry_count[A]).is_equal(1)
	assert_int(sheet.end_fields.turn_expiry_count[B]).is_equal(0)
	var without := _sheet_of(PlaytestScenarios.idle_rounds(IDLE_ROUNDS)).end_fields
	assert_int(without.turn_expiry_count[A] + without.turn_expiry_count[B]).is_equal(0)


func test_209_4_10_response_expiries_per_player() -> void:
	var fields := _sheet_of(PlaytestScenarios.expiring()).end_fields
	assert_int(fields.response_expiry_count[A]).is_equal(1)
	assert_int(fields.response_expiry_count[B]).is_equal(0)
	var without := _sheet_of(PlaytestScenarios.deploying()).end_fields
	assert_int(without.response_expiry_count[A] + without.response_expiry_count[B]).is_equal(0)


func test_204_2_1_mulligan_count_counts_players_who_set_cards_aside() -> void:
	var redrawing_sides: Array[Array] = [[], [A], [B], [A, B]]
	var expected_counts: Array[int] = [0, 1, 1, 2]
	for index: int in redrawing_sides.size():
		var driver := HumanDuelDriver.new(SetupSamples.catalog())
		var sides: Array[DuelState.PlayerSide] = []
		sides.assign(redrawing_sides[index])
		driver.start(SetupSamples.setup(), sides)
		assert_int(_sheet_of(driver).end_fields.mulligan_count).is_equal(expected_counts[index])


func test_209_5_2_first_fatigue_turn_is_none_without_fatigue() -> void:
	var sheet := _sheet_of(PlaytestScenarios.idle_rounds(IDLE_ROUNDS))
	assert_int(sheet.end_fields.first_fatigue_turn_rank).is_equal(PlaytestSheet.NO_VALUE)


func test_209_5_2_first_fatigue_turn_is_the_rank_of_the_turn_it_appears() -> void:
	var driver := PlaytestScenarios.small_deck_duel(SMALL_DECK_SIZE)
	for round_index: int in IDLE_ROUNDS:
		driver.end_turn(A)
		driver.end_turn(B)
	# 4 en main, 1 au deck : A pioche 1 à son tour 1, la pioche de son tour 2 manque.
	assert_int(_sheet_of(driver).end_fields.first_fatigue_turn_rank).is_equal(2)


func test_210_3_2_last_breath_note_per_trigger() -> void:
	var driver := PlaytestScenarios.walk_to_attack(PlaytestScenarios.martyr_duel())
	driver.end_turn(A)
	var sheet := _sheet_of(driver)
	assert_int(sheet.last_breath_notes.size()).is_equal(MARTYR_COUNT_AT_TIE)
	for note: PlaytestSheet.LastBreathNote in sheet.last_breath_notes:
		assert_int(note.turn_rank).is_equal(ATTACK_TURN_RANK)
		assert_int(note.active_player).is_equal(A)
	var without := _sheet_of(PlaytestScenarios.walk_to_attack(PlaytestScenarios.fresh()))
	assert_array(without.last_breath_notes).is_empty()


func test_decision_0160_last_row_of_a_game_ended_during_a_turn_comes_from_the_final_state() -> void:
	var engine := DuelEngine.new(_fixture_catalog)
	_fixture_journal.replay_into(engine)
	var state := engine.get_state()
	var last_row: PlaytestSheet.TurnRow = _fixture_sheet.turn_rows.back()
	assert_int(last_row.active_player).is_equal(state.active_player)
	for side: DuelState.PlayerSide in DuelState.SIDES:
		var player := state.get_player(side)
		var cells := last_row.cells[side]
		assert_int(cells.hand_count).is_equal(player.hand.size())
		assert_int(cells.sources_in_play).is_equal(player.sources_upright + player.sources_tilted)
		assert_int(cells.sources_recycled).is_equal(player.sources_recycled_this_turn)
		assert_int(cells.fought).is_not_equal(PlaytestSheet.Mark.NONE)
	var played := last_row.cells[last_row.active_player].card_played
	assert_int(played).is_not_equal(PlaytestSheet.Mark.NONE)


func _record_fixture() -> PlaytestSheet:
	var recorder := PlaytestRecorder.new(_fixture_catalog)
	return recorder.record(_fixture_journal, GAME_NUMBER, DATE_TEXT)


# Journal construit à la main, rejoué sur le catalogue d'essai.
func _record(journal: DuelJournal) -> PlaytestSheet:
	var recorder := PlaytestRecorder.new(SetupSamples.catalog())
	return recorder.record(journal, GAME_NUMBER, DATE_TEXT)


# Un scénario correct ne fait refuser aucune intention.
func _sheet_of(driver: HumanDuelDriver) -> PlaytestSheet:
	assert_int(driver.rejected_intent_count).is_equal(0)
	return driver.record_sheet(GAME_NUMBER, DATE_TEXT)


func _cells(
	sheet: PlaytestSheet, row_index: int, side: DuelState.PlayerSide
) -> PlaytestSheet.PlayerCells:
	var row: PlaytestSheet.TurnRow = sheet.turn_rows[row_index]
	return row.cells[side]


func test_204_5_7a_turn_cells_cover_the_responses_of_the_turn() -> void:
	var driver := PlaytestScenarios.before_own_end_of_turn()
	var hands_before := _hand_counts(driver)
	PlaytestScenarios.answer_then_end_own_turn(driver)
	var sheet := _sheet_of(driver)
	assert_int(sheet.turn_rows.size()).is_equal(END_OF_TURN_ROW_COUNT)
	var row_cells := _cells(sheet, OWN_END_ROW, A)
	assert_int(row_cells.card_played).is_equal(PlaytestSheet.Mark.YES)
	assert_int(row_cells.hand_count).is_equal(hands_before[A] - 1)
	assert_int(_cells(sheet, OWN_END_ROW, B).hand_count).is_equal(hands_before[B] - 1)
	var next_row := _cells(sheet, OWN_END_ROW + 2, A)
	assert_int(next_row.card_played).is_equal(PlaytestSheet.Mark.NO)


func test_decision_0168_response_in_the_opponents_turn_counts_on_next_own_row() -> void:
	var sheet := _sheet_of(PlaytestScenarios.answering_in_own_turn())
	assert_int(_cells(sheet, OWN_END_ROW - 1, B).card_played).is_equal(PlaytestSheet.Mark.NO)
	assert_int(_cells(sheet, OWN_END_ROW + 1, B).card_played).is_equal(PlaytestSheet.Mark.YES)


func test_203_2_2_sources_of_the_payments_are_on_the_row_of_the_turn() -> void:
	var driver := PlaytestScenarios.before_own_end_of_turn()
	var sources_before := _sources_in_play(driver)
	PlaytestScenarios.answer_then_end_own_turn(driver)
	var sheet := _sheet_of(driver)
	var row_cells := _cells(sheet, OWN_END_ROW, A)
	# A a recyclé une Source pour produire l'Essence de sa Réaction ; la réserve garde l'autre.
	assert_int(row_cells.sources_recycled).is_equal(1)
	assert_int(row_cells.sources_in_play).is_equal(sources_before[A] - 1)
	assert_int(row_cells.essence_lost).is_equal(1)
	assert_int(_cells(sheet, OWN_END_ROW, B).sources_recycled).is_equal(0)
	assert_int(_cells(sheet, OWN_END_ROW, B).sources_in_play).is_equal(sources_before[B])
	assert_int(_cells(sheet, OWN_END_ROW + 2, A).sources_recycled).is_equal(0)


func _hand_counts(driver: HumanDuelDriver) -> Array[int]:
	var counts: Array[int] = []
	for side: DuelState.PlayerSide in DuelState.SIDES:
		counts.append(driver.engine.get_state().get_player(side).hand.size())
	return counts


func _sources_in_play(driver: HumanDuelDriver) -> Array[int]:
	var counts: Array[int] = []
	for side: DuelState.PlayerSide in DuelState.SIDES:
		var player := driver.engine.get_state().get_player(side)
		counts.append(player.sources_upright + player.sources_tilted)
	return counts
