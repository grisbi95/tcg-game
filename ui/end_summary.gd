class_name EndSummary
extends RefCounted
## Textes du panneau de fin de partie (décision 0036, point 4), déduits pour l'affichage seulement
## des événements du dernier lot et de l'état : aucune règle ici, le moteur a déjà tranché.
## Fonctions pures, testables sans scène.

const MSEC_PER_SECOND: int = 1000
const SECONDS_PER_MINUTE: int = 60
const CONCEDED_FORMAT: String = "Le joueur %s abandonne"
const CLOCK_FORMAT: String = "Pendule du joueur %s à 0"
const BOTH_CLOCKS_TEXT: String = "Pendules des deux joueurs à 0"
const HERO_FORMAT: String = "PV du Hero %s à 0"
const BOTH_HEROES_TEXT: String = "PV des deux Heroes à 0"
const UNKNOWN_REASON_TEXT: String = "Partie terminée"
const DETAILS_FORMAT: String = "Tour %d · %d min %d s"


## Une ligne : abandon, pendule, puis PV du Hero à 0, dans cet ordre de priorité.
static func reason_text(events: Array[DuelEvent], state: DuelState) -> String:
	for event: DuelEvent in events:
		if event is PlayerConceded:
			var conceded := event as PlayerConceded
			return CONCEDED_FORMAT % PlayerNames.letter(conceded.player)
	var expired := _expired_players(events)
	if expired.size() == DuelState.PLAYER_COUNT:
		return BOTH_CLOCKS_TEXT
	if expired.size() == 1:
		return CLOCK_FORMAT % PlayerNames.letter(expired[0])
	return _hero_reason_text(state)


## « Tour 7 · 12 min 4 s » : tour en cours à la fin et durée du duel.
static func details_text(turn_number: int, total_elapsed_msec: int) -> String:
	var seconds := total_elapsed_msec / MSEC_PER_SECOND
	return (
		DETAILS_FORMAT % [turn_number, seconds / SECONDS_PER_MINUTE, seconds % SECONDS_PER_MINUTE]
	)


static func _expired_players(events: Array[DuelEvent]) -> Array[DuelState.PlayerSide]:
	var expired: Array[DuelState.PlayerSide] = []
	for event: DuelEvent in events:
		if event is TimeExpired:
			var time_expired := event as TimeExpired
			expired.append(time_expired.player)
	return expired


static func _hero_reason_text(state: DuelState) -> String:
	var fallen: Array[DuelState.PlayerSide] = []
	for side: DuelState.PlayerSide in DuelState.SIDES:
		var hero := state.find_hero(side)
		if hero != null and hero.health == 0:
			fallen.append(side)
	if fallen.size() == DuelState.PLAYER_COUNT:
		return BOTH_HEROES_TEXT
	if fallen.size() == 1:
		return HERO_FORMAT % PlayerNames.letter(fallen[0])
	return UNKNOWN_REASON_TEXT
