extends GdUnitTestSuite
## Duels aléatoires avec oracle et déterminisme (ruleset 0.36 ; décisions 0001, 0018 et 0019 ;
## tests/CLAUDE.md, « Duels aléatoires »).
##
## Deux decks de test, RandomLegalAgent pour les deux joueurs, la pendule avancée d'un pas après
## chaque intention. Un écart se rapporte avec la graine, le pas et l'intention. L'agent recycle
## ses Sources dès que l'inclinaison ne suffit pas : passé quelques centaines de pas, il n'a plus
## d'Essence ; d'où beaucoup de duels courts, et quelques longs pour aller jusqu'à la victoire.
## Un duel au hasard peut aussi ne jamais finir (mains pleines, deck jamais vide, aucune fatigue).

const SHORT_SEEDS: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
const SHORT_STEPS: int = 300
## Graines dont le duel finit avant LONG_STEPS (relevé du 18 octobre 2026, ruleset 0.36 ;
## revérifié le 22 octobre 2026 au ruleset 0.39, mêmes graines).
const LONG_SEEDS: Array[int] = [4, 6]
const LONG_STEPS: int = 2_000
const CLOCK_STEP_MSEC: int = 50

var _catalog: Catalog
## Partagée par tous les duels : la configuration est en lecture seule (DeepCompare).
var _config: DuelConfig = DuelConfig.new()
## Un duel joué par graine, une fois pour toute la suite.
var _short_reports: Array[DuelReport] = []
var _long_reports: Array[DuelReport] = []


func before() -> void:
	_catalog = TestCatalog.catalog()
	for rng_seed: int in SHORT_SEEDS:
		_short_reports.append(_play(rng_seed, SHORT_STEPS))
	for rng_seed: int in LONG_SEEDS:
		_long_reports.append(_play(rng_seed, LONG_STEPS))


func test_decision_0019_random_duels_keep_every_checked_condition() -> void:
	var reports := _short_reports + _long_reports
	for report: DuelReport in reports:
		var message := "graine %d : %s" % [report.rng_seed, "\n".join(report.defects)]
		assert_array(Array(report.defects)).override_failure_message(message).is_empty()


func test_decision_0019_long_random_duels_reach_victory() -> void:
	for report: DuelReport in _long_reports:
		var message := "graine %d : pas de fin en %d pas" % [report.rng_seed, LONG_STEPS]
		var state := report.engine.get_state()
		assert_bool(state.is_ended()).override_failure_message(message).is_true()


func test_decision_0001_same_seeds_same_duel() -> void:
	var first := _short_reports[0]
	var second := _play(first.rng_seed, SHORT_STEPS)
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


func test_decision_0001_clone_mid_duel_is_identical() -> void:
	var state := _short_reports[1].engine.get_state()
	assert_array(Array(DeepCompare.find_clone_defects(state, state.clone()))).is_empty()


# Joue au plus `steps` intentions ; relève chaque refus, absence d'intention et écart d'oracle.
func _play(rng_seed: int, steps: int) -> DuelReport:
	var report := DuelReport.new()
	report.rng_seed = rng_seed
	report.engine = DuelEngine.new(_catalog, _config)
	report.events.append_array(report.engine.start_new_duel(TestCatalog.setup(rng_seed)))
	var agent := RandomLegalAgent.new(rng_seed)
	for step: int in steps:
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


func _record_defects(report: DuelReport, where: String, events: Array[DuelEvent]) -> void:
	if EventLog.rejection_reason(events) != EventLog.NOT_A_SINGLE_REJECTION:
		report.defects.append("%s : intention refusée" % where)
	for violation: String in DuelOracle.find_violations(report.engine.get_state()):
		report.defects.append("%s : %s" % [where, violation])


class DuelReport:
	extends RefCounted
	var rng_seed: int = 0
	var engine: DuelEngine
	var events: Array[DuelEvent] = []
	var defects: PackedStringArray = PackedStringArray()
