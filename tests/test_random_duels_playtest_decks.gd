extends GdUnitTestSuite
## Duels aléatoires sur les 6 affrontements des 4 decks du catalogue de playtest (étape c.8 ;
## décisions 0001, 0019, 0066 et 0069 ; tests/CLAUDE.md, « Duels aléatoires »).
##
## Vrai catalogue de data/cards/, vrais decks de data/decks/ et plan de série de data/series/,
## chargés par GameLibrary comme l'application ; chaque affrontement est la première partie du plan
## de sa paire de decks, préparée par DuelSeries en partie libre, premier joueur tiré (décision
## 0012). Deux RandomLegalAgent de même graine, la pendule avancée d'un pas après chaque
## intention. Un écart se rapporte avec les decks, la graine, le pas et l'intention.

## Graine retenue par affrontement, dans l'ordre du plan (percee/phalange, percee/echiquier,
## percee/grimoire, phalange/echiquier, phalange/grimoire, echiquier/grimoire) : relevé du
## 28 octobre 2026, édition 0.56, graines 1 à 8, 2 000 pas : tous les duels finissent sauf
## percee/echiquier à la graine 6 ; fins des graines retenues, en pas : 156, 225, 170, 250, 225 et
## 148 pas.
const SEEDS: Array[int] = [2, 1, 6, 8, 7, 3]
const MAX_STEPS: int = 400
const CLOCK_STEP_MSEC: int = 50
## Affrontement rejoué deux fois pour le déterminisme (indice dans `_matchups`).
const REPLAYED_MATCHUP: int = 0

var _catalog: Catalog
var _decks: Array[DeckList] = []
## Première partie du plan de chaque paire de decks, dans l'ordre du plan.
var _matchups: Array[SeriesPlanGame] = []
## Partagée par tous les duels : la configuration est en lecture seule (DeepCompare).
var _config: DuelConfig = DuelConfig.new()
## Un duel joué par affrontement, une fois pour toute la suite.
var _reports: Array[DuelReport] = []


func before() -> void:
	_catalog = GameLibrary.load_catalog()
	_decks = GameLibrary.load_decks(_catalog)
	var plan := GameLibrary.load_series_plan(_catalog, _decks)
	if plan == null:
		return
	_matchups = _distinct_matchups(plan)
	for index: int in mini(_matchups.size(), SEEDS.size()):
		_reports.append(_play(_matchups[index], SEEDS[index]))


func test_decision_0066_playtest_decks_are_all_available() -> void:
	assert_int(_matchups.size()).is_equal(SEEDS.size())
	assert_int(_reports.size()).is_equal(SEEDS.size())


func test_decision_0019_playtest_matchups_keep_every_checked_condition() -> void:
	for report: DuelReport in _reports:
		var message := (
			"%s, graine %d : %s" % [report.label, report.rng_seed, "\n".join(report.defects)]
		)
		assert_array(Array(report.defects)).override_failure_message(message).is_empty()


func test_decision_0019_playtest_matchups_reach_victory() -> void:
	for report: DuelReport in _reports:
		var message := (
			"%s, graine %d : pas de fin en %d pas" % [report.label, report.rng_seed, MAX_STEPS]
		)
		var state := report.engine.get_state()
		assert_bool(state.is_ended()).override_failure_message(message).is_true()


func test_decision_0001_playtest_decks_same_seed_same_duel() -> void:
	var first := _reports[REPLAYED_MATCHUP]
	var second := _play(_matchups[REPLAYED_MATCHUP], SEEDS[REPLAYED_MATCHUP])
	assert_int(second.events.size()).is_equal(first.events.size())
	var event_defects := PackedStringArray()
	for index: int in mini(first.events.size(), second.events.size()):
		event_defects.append_array(
			DeepCompare.find_clone_defects(first.events[index], second.events[index])
		)
	var state_defects := DeepCompare.find_clone_defects(
		first.engine.get_state(), second.engine.get_state()
	)
	assert_array(Array(event_defects)).is_empty()
	assert_array(Array(state_defects)).is_empty()


# Joue au plus MAX_STEPS intentions ; relève chaque refus, absence d'intention et écart d'oracle.
func _play(matchup: SeriesPlanGame, rng_seed: int) -> DuelReport:
	var report := DuelReport.new()
	report.rng_seed = rng_seed
	report.label = "%s contre %s" % [matchup.deck_id_a, matchup.deck_id_b]
	report.engine = DuelEngine.new(_catalog, _config)
	report.events.append_array(report.engine.start_new_duel(_setup(matchup, rng_seed)))
	var agent := RandomLegalAgent.new(rng_seed)
	for step: int in MAX_STEPS:
		if report.engine.get_state().is_ended():
			break
		var intent := agent.choose_intent(report.engine)
		if intent == null:
			report.defects.append("pas %d : aucune intention légale" % step)
			break
		var events := report.engine.submit(intent)
		events.append_array(report.engine.advance_clock(CLOCK_STEP_MSEC))
		report.events.append_array(events)
		_record_defects(report, "pas %d, %s" % [step, EventLog.describe_intent(intent)], events)
		if not report.defects.is_empty():
			break
	return report


# Partie libre aux decks de `matchup`, premier joueur tiré par le moteur (décision 0012).
func _setup(matchup: SeriesPlanGame, rng_seed: int) -> DuelSetup:
	var series := DuelSeries.new(_deck_named(matchup.deck_id_a), _deck_named(matchup.deck_id_b))
	series.set_first_player_choice(DuelSeries.FirstPlayerChoice.DRAWN)
	return series.make_setup(rng_seed)


func _deck_named(deck_id: StringName) -> DeckList:
	for deck: DeckList in _decks:
		if deck.deck_id == deck_id:
			return deck
	return null


# Première partie de chaque paire de decks distincte, dans l'ordre du plan.
static func _distinct_matchups(plan: SeriesPlan) -> Array[SeriesPlanGame]:
	var matchups: Array[SeriesPlanGame] = []
	var seen_pairs: Dictionary[String, bool] = {}
	for game: SeriesPlanGame in plan.games:
		var pair: Array[String] = [String(game.deck_id_a), String(game.deck_id_b)]
		pair.sort()
		var key := "-".join(pair)
		if not seen_pairs.has(key):
			seen_pairs[key] = true
			matchups.append(game)
	return matchups


func _record_defects(report: DuelReport, where: String, events: Array[DuelEvent]) -> void:
	if EventLog.rejection_reason(events) != EventLog.NOT_A_SINGLE_REJECTION:
		report.defects.append("%s : intention refusée" % where)
	for violation: String in DuelOracle.find_violations(report.engine.get_state()):
		report.defects.append("%s : %s" % [where, violation])


class DuelReport:
	extends RefCounted
	var label: String = ""
	var rng_seed: int = 0
	var engine: DuelEngine
	var events: Array[DuelEvent] = []
	var defects: PackedStringArray = PackedStringArray()
