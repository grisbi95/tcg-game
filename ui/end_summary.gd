class_name EndSummary
extends RefCounted
## Textes du panneau de fin de partie (décision 0036, point 4) : traduction du résultat et de la
## raison que porte `DuelEnded` (décision 0040), rien d'autre. Fonctions pures, testables sans
## scène.

const MSEC_PER_SECOND: int = 1000
const SECONDS_PER_MINUTE: int = 60
const CONCEDED_FORMAT: String = "Le joueur %s abandonne"
const CLOCK_FORMAT: String = "Pendule du joueur %s à 0"
const BOTH_CLOCKS_TEXT: String = "Pendules des deux joueurs à 0"
const HERO_FORMAT: String = "PV du Hero %s à 0"
const BOTH_HEROES_TEXT: String = "PV des deux Heroes à 0"
const FATIGUE_FORMAT: String = "PV du Hero %s à 0 par la fatigue"
const BOTH_HEROES_FATIGUE_TEXT: String = "PV des deux Heroes à 0 par la fatigue"
const UNKNOWN_REASON_TEXT: String = "Partie terminée"
const DETAILS_FORMAT: String = "Tour %d · %d min %d s"


## Une ligne d'après le `DuelEnded` du dernier lot ; « Partie terminée » s'il manque.
static func reason_text(events: Array[DuelEvent]) -> String:
	for event: DuelEvent in events:
		if event is DuelEnded:
			return _reason_text_of(event as DuelEnded)
	return UNKNOWN_REASON_TEXT


## « Tour 7 · 12 min 4 s » : tour en cours à la fin et durée du duel.
static func details_text(turn_number: int, total_elapsed_msec: int) -> String:
	var seconds := floori(total_elapsed_msec / float(MSEC_PER_SECOND))
	return (
		DETAILS_FORMAT
		% [turn_number, floori(seconds / float(SECONDS_PER_MINUTE)), seconds % SECONDS_PER_MINUTE]
	)


static func _reason_text_of(ended: DuelEnded) -> String:
	var is_draw := ended.result == DuelState.DuelResult.DRAW
	var loser_letter := "" if is_draw else PlayerNames.letter(_loser_of(ended.result))
	match ended.reason:
		DuelState.EndReason.CONCEDED:
			return CONCEDED_FORMAT % loser_letter
		DuelState.EndReason.TIME_EXPIRED:
			return BOTH_CLOCKS_TEXT if is_draw else CLOCK_FORMAT % loser_letter
		DuelState.EndReason.HERO_HEALTH_ZERO:
			return BOTH_HEROES_TEXT if is_draw else HERO_FORMAT % loser_letter
		DuelState.EndReason.HERO_HEALTH_ZERO_BY_FATIGUE:
			return BOTH_HEROES_FATIGUE_TEXT if is_draw else FATIGUE_FORMAT % loser_letter
	return UNKNOWN_REASON_TEXT


static func _loser_of(result: DuelState.DuelResult) -> DuelState.PlayerSide:
	if result == DuelState.DuelResult.PLAYER_A_WINS:
		return DuelState.PlayerSide.B
	return DuelState.PlayerSide.A
