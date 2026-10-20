extends GdUnitTestSuite
## Textes du panneau de fin sans scène : `EndSummary` (décision 0036, point 4 ; ruleset 0.36,
## raisons de fin 209.2.x, 209.3.1, 209.4.5). Le moteur a déjà tranché : on contrôle seulement la
## phrase déduite des événements du dernier lot et de l'état.

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const FALLEN_HEALTH: int = 0
const ALIVE_HEALTH: int = 3
const MSEC_PER_SECOND: int = 1000
const MSEC_PER_MINUTE: int = 60000


func _no_events() -> Array[DuelEvent]:
	return []


func _events(list: Array[DuelEvent]) -> Array[DuelEvent]:
	return list


func test_decision_0036_conceded_player_a_is_named() -> void:
	var state := DuelStateBuilder.new().build()
	var events := _events([PlayerConceded.new(A)])
	assert_str(EndSummary.reason_text(events, state)).is_equal("Le joueur A abandonne")


func test_decision_0036_conceded_player_b_is_named() -> void:
	var state := DuelStateBuilder.new().build()
	var events := _events([PlayerConceded.new(B)])
	assert_str(EndSummary.reason_text(events, state)).is_equal("Le joueur B abandonne")


func test_decision_0036_concession_wins_over_clock_and_hero() -> void:
	var state := DuelStateBuilder.new().with_hero_health(A, FALLEN_HEALTH).build()
	var events := _events([TimeExpired.new(A), PlayerConceded.new(B)])
	assert_str(EndSummary.reason_text(events, state)).is_equal("Le joueur B abandonne")


func test_decision_0036_expired_clock_of_player_a_is_named() -> void:
	var state := DuelStateBuilder.new().build()
	var events := _events([TimeExpired.new(A)])
	assert_str(EndSummary.reason_text(events, state)).is_equal("Pendule du joueur A à 0")


func test_decision_0036_expired_clock_of_player_b_is_named() -> void:
	var state := DuelStateBuilder.new().build()
	var events := _events([TimeExpired.new(B)])
	assert_str(EndSummary.reason_text(events, state)).is_equal("Pendule du joueur B à 0")


func test_decision_0036_both_clocks_expired() -> void:
	var state := DuelStateBuilder.new().build()
	var events := _events([TimeExpired.new(A), TimeExpired.new(B)])
	assert_str(EndSummary.reason_text(events, state)).is_equal("Pendules des deux joueurs à 0")


func test_decision_0036_clock_wins_over_fallen_hero() -> void:
	var state := DuelStateBuilder.new().with_hero_health(B, FALLEN_HEALTH).build()
	var events := _events([TimeExpired.new(A)])
	assert_str(EndSummary.reason_text(events, state)).is_equal("Pendule du joueur A à 0")


func test_decision_0036_hero_a_at_zero_health() -> void:
	var state := (
		DuelStateBuilder
		. new()
		. with_hero_health(A, FALLEN_HEALTH)
		. with_hero_health(B, ALIVE_HEALTH)
		. build()
	)
	assert_str(EndSummary.reason_text(_no_events(), state)).is_equal("PV du Hero A à 0")


func test_decision_0036_hero_b_at_zero_health() -> void:
	var state := (
		DuelStateBuilder
		. new()
		. with_hero_health(A, ALIVE_HEALTH)
		. with_hero_health(B, FALLEN_HEALTH)
		. build()
	)
	assert_str(EndSummary.reason_text(_no_events(), state)).is_equal("PV du Hero B à 0")


func test_decision_0036_both_heroes_at_zero_health_is_a_tie() -> void:
	var state := (
		DuelStateBuilder
		. new()
		. with_hero_health(A, FALLEN_HEALTH)
		. with_hero_health(B, FALLEN_HEALTH)
		. build()
	)
	assert_str(EndSummary.reason_text(_no_events(), state)).is_equal("PV des deux Heroes à 0")


func test_decision_0036_unrelated_events_do_not_change_the_hero_reason() -> void:
	var state := DuelStateBuilder.new().with_hero_health(A, FALLEN_HEALTH).build()
	var events := _events([TurnEnded.new(A), DuelEnded.new()])
	assert_str(EndSummary.reason_text(events, state)).is_equal("PV du Hero A à 0")


func test_decision_0036_unknown_reason_falls_back() -> void:
	var state := DuelStateBuilder.new().build()
	assert_str(EndSummary.reason_text(_no_events(), state)).is_equal("Partie terminée")


func test_decision_0036_reason_leaves_the_state_untouched() -> void:
	var state := DuelStateBuilder.new().with_hero_health(A, FALLEN_HEALTH).build()
	var snapshot := state.clone()
	EndSummary.reason_text(_events([TimeExpired.new(B)]), state)
	assert_array(DeepCompare.find_clone_defects(snapshot, state)).is_empty()


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
