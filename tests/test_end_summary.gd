extends GdUnitTestSuite
## Textes du panneau de fin sans scène : `EndSummary` (décisions 0036, point 4, et 0040 ; ruleset
## 0.37, raisons de fin 209.2.x, 209.3.1, 209.5.3). Le moteur a déjà tranché : on contrôle
## seulement la phrase traduite du `DuelEnded` du dernier lot.

const A_WINS: DuelState.DuelResult = DuelState.DuelResult.PLAYER_A_WINS
const B_WINS: DuelState.DuelResult = DuelState.DuelResult.PLAYER_B_WINS
const DRAW: DuelState.DuelResult = DuelState.DuelResult.DRAW
const REASON := DuelState.EndReason
const MSEC_PER_SECOND: int = 1000
const MSEC_PER_MINUTE: int = 60000


func _ended(result: DuelState.DuelResult, reason: DuelState.EndReason) -> Array[DuelEvent]:
	return [DuelEnded.new(result, reason)]


func test_decision_0040_conceded_player_a_is_named() -> void:
	assert_str(EndSummary.reason_text(_ended(B_WINS, REASON.CONCEDED))).is_equal(
		"Le joueur A abandonne"
	)


func test_decision_0040_conceded_player_b_is_named() -> void:
	assert_str(EndSummary.reason_text(_ended(A_WINS, REASON.CONCEDED))).is_equal(
		"Le joueur B abandonne"
	)


func test_decision_0040_expired_clock_of_player_a_is_named() -> void:
	assert_str(EndSummary.reason_text(_ended(B_WINS, REASON.TIME_EXPIRED))).is_equal(
		"Pendule du joueur A à 0"
	)


func test_decision_0040_expired_clock_of_player_b_is_named() -> void:
	assert_str(EndSummary.reason_text(_ended(A_WINS, REASON.TIME_EXPIRED))).is_equal(
		"Pendule du joueur B à 0"
	)


func test_decision_0040_both_clocks_expired() -> void:
	assert_str(EndSummary.reason_text(_ended(DRAW, REASON.TIME_EXPIRED))).is_equal(
		"Pendules des deux joueurs à 0"
	)


func test_decision_0040_hero_a_at_zero_health() -> void:
	assert_str(EndSummary.reason_text(_ended(B_WINS, REASON.HERO_HEALTH_ZERO))).is_equal(
		"PV du Hero A à 0"
	)


func test_decision_0040_hero_b_at_zero_health() -> void:
	assert_str(EndSummary.reason_text(_ended(A_WINS, REASON.HERO_HEALTH_ZERO))).is_equal(
		"PV du Hero B à 0"
	)


func test_decision_0040_both_heroes_at_zero_health_is_a_tie() -> void:
	assert_str(EndSummary.reason_text(_ended(DRAW, REASON.HERO_HEALTH_ZERO))).is_equal(
		"PV des deux Heroes à 0"
	)


func test_decision_0040_hero_b_at_zero_health_by_fatigue() -> void:
	var events := _ended(A_WINS, REASON.HERO_HEALTH_ZERO_BY_FATIGUE)
	assert_str(EndSummary.reason_text(events)).is_equal("PV du Hero B à 0 par la fatigue")


func test_decision_0040_both_heroes_at_zero_health_by_fatigue() -> void:
	var events := _ended(DRAW, REASON.HERO_HEALTH_ZERO_BY_FATIGUE)
	assert_str(EndSummary.reason_text(events)).is_equal("PV des deux Heroes à 0 par la fatigue")


func test_decision_0040_duel_ended_is_found_among_other_events() -> void:
	var events: Array[DuelEvent] = [TurnEnded.new(DuelState.PlayerSide.A)]
	events.append_array(_ended(B_WINS, REASON.CONCEDED))
	assert_str(EndSummary.reason_text(events)).is_equal("Le joueur A abandonne")


func test_decision_0040_missing_duel_ended_falls_back() -> void:
	var events: Array[DuelEvent] = [TurnEnded.new(DuelState.PlayerSide.A)]
	assert_str(EndSummary.reason_text(events)).is_equal("Partie terminée")


func test_decision_0040_unknown_reason_falls_back() -> void:
	assert_str(EndSummary.reason_text(_ended(A_WINS, REASON.NONE))).is_equal("Partie terminée")


func test_decision_0036_details_at_zero_seconds() -> void:
	assert_str(EndSummary.details_text(1, 0)).is_equal("Tour 1 · 0 min 0 s")


func test_decision_0036_details_truncate_milliseconds() -> void:
	assert_str(EndSummary.details_text(1, MSEC_PER_SECOND - 1)).is_equal("Tour 1 · 0 min 0 s")


func test_decision_0036_details_at_59_seconds() -> void:
	var elapsed_msec := 59 * MSEC_PER_SECOND
	assert_str(EndSummary.details_text(4, elapsed_msec)).is_equal("Tour 4 · 0 min 59 s")


func test_decision_0036_details_just_before_one_minute() -> void:
	assert_str(EndSummary.details_text(4, MSEC_PER_MINUTE - 1)).is_equal("Tour 4 · 0 min 59 s")


func test_decision_0036_details_at_one_minute() -> void:
	assert_str(EndSummary.details_text(4, MSEC_PER_MINUTE)).is_equal("Tour 4 · 1 min 0 s")


func test_decision_0036_details_with_minutes_and_seconds() -> void:
	var elapsed_msec := 12 * MSEC_PER_MINUTE + 4 * MSEC_PER_SECOND + 500
	assert_str(EndSummary.details_text(7, elapsed_msec)).is_equal("Tour 7 · 12 min 4 s")
