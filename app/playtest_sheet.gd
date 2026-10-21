class_name PlaytestSheet
extends RefCounted
## Fiche de relevé d'une partie, aux champs du protocole de playtest (section « Fiche de relevé »
## de `docs/ruleset/70-playtest/protocole.md`, décision 0042) : relevé par tour, notes sur
## Dernier souffle, relevé de fin de partie ; puis son écriture en CSV (UTF-8, virgule, point
## décimal, guillemets doublés). Les cellules que le protocole laisse au joueur restent vides.

## Oui ou non d'une cellule, ou cellule vide.
enum Mark {
	NONE,
	NO,
	YES,
}

## Cellule sans valeur : le protocole la laisse vide.
const NO_VALUE: int = -1

const MIME_TYPE: String = "text/csv"
const FILE_NAME_FORMAT: String = "fiche-partie-%d-%s-graine-%d.csv"
const SEPARATOR: String = ","
const LINE_BREAK: String = "\n"
const QUOTE: String = '"'
const YES_TEXT: String = "oui"
const NO_TEXT: String = "non"
const NO_WINNER_TEXT: String = "aucun"
const NO_FATIGUE_TEXT: String = "aucun"
const MSEC_PER_MINUTE: float = 60_000.0
const MSEC_PER_SECOND: float = 1_000.0

## « Graine » s'ajoute à l'en-tête du modèle du protocole : elle permet de rejouer la partie.
const HEADER_LABELS: Array[String] = ["Partie n°", "Date", "Joueur A", "Joueur B", "Graine"]
const TURN_COLUMNS: Array[String] = ["Rang du tour", "Joueur actif"]
const PLAYER_COLUMN_FORMATS: Array[String] = [
	"%s : Essence inutilisée",
	"%s : Essence perdue",
	"%s : Cartes en main",
	"%s : Sources en jeu",
	"%s : Sources recyclées",
	"%s : Combat",
	"%s : Carte jouée",
]
const LAST_BREATH_COLUMNS: Array[String] = [
	"Rang du tour",
	"Joueur actif",
	"Issue d'un combat changée (oui ou non)",
	"Issue de la partie changée (oui ou non)",
]
const END_COLUMNS: Array[String] = ["Champ de fin de partie", "Valeur"]
const WINNER_LABEL: String = "Vainqueur"
const FIRST_PLAYER_LABEL: String = "Premier joueur"
const END_CAUSE_LABEL: String = (
	"Cause de fin (0 PV par la fatigue, 0 PV par une autre cause, temps écoulé, abandon ou"
	+ " partie nulle)"
)
const DURATION_LABEL: String = "Durée (min)"
const TIME_LEFT_FORMAT: String = "Temps restant, pendule de %s (min)"
const MULLIGAN_LABEL: String = "Nombre de mulligans"
const FATIGUE_LABEL: String = "Tour de la première augmentation d'un compteur de fatigue"
const SCREEN_SUFFIX: String = " (version sur écran)"
const WINDOW_TIME_FORMAT: String = (
	"Temps de pendule consommé par les fenêtres de réponse, %s (s)" + SCREEN_SUFFIX
)
const RESPONSES_FORMAT: String = "Réponses commencées, %s" + SCREEN_SUFFIX
const FREE_LABELS: Array[String] = [
	"Ressenti du rythme" + SCREEN_SUFFIX,
	"Lisibilité du texte des cartes de main (version sur écran, affichage en 1280×720)",
	"Champ libre",
]
const END_CAUSE_TEXTS: Dictionary[DuelState.EndReason, String] = {
	DuelState.EndReason.HERO_HEALTH_ZERO_BY_FATIGUE: "0 PV par la fatigue",
	DuelState.EndReason.HERO_HEALTH_ZERO: "0 PV par une autre cause",
	DuelState.EndReason.TIME_EXPIRED: "temps écoulé",
	DuelState.EndReason.CONCEDED: "abandon",
}
const DRAW_CAUSE_TEXT: String = "partie nulle"


## Cellules d'un joueur sur la ligne d'un tour ; les cellules réservées au joueur actif restent
## vides pour l'autre (décisions 0160, 0173 et 0195 du ruleset).
class PlayerCells:
	extends RefCounted
	var essence_unused: int = NO_VALUE
	var essence_lost: int = NO_VALUE
	var hand_count: int = 0
	var sources_in_play: int = 0
	var sources_recycled: int = 0
	var fought: Mark = Mark.NO
	var card_played: Mark = Mark.NONE


## Une ligne du relevé : le tour d'un joueur (décision 0159 du ruleset).
class TurnRow:
	extends RefCounted
	var turn_rank: int = 0
	var active_player: DuelState.PlayerSide = DuelState.PlayerSide.A
	## Indexées par `DuelState.PlayerSide`.
	var cells: Array[PlayerCells] = [PlayerCells.new(), PlayerCells.new()]


## Un déclenchement de Dernier souffle (210.3.2, décision 0175 du ruleset) ; les deux jugements
## restent au joueur.
class LastBreathNote:
	extends RefCounted
	var turn_rank: int = 0
	var active_player: DuelState.PlayerSide = DuelState.PlayerSide.A


## Relevé de fin de partie ; les temps en millisecondes, indexés par `DuelState.PlayerSide`.
class EndFields:
	extends RefCounted
	var result: DuelState.DuelResult = DuelState.DuelResult.NONE
	var reason: DuelState.EndReason = DuelState.EndReason.NONE
	var first_player: DuelState.PlayerSide = DuelState.PlayerSide.A
	var duration_msec: int = 0
	var time_left_msec: Array[int] = [0, 0]
	var mulligan_count: int = 0
	var first_fatigue_turn_rank: int = NO_VALUE
	var response_window_msec: Array[int] = [0, 0]
	var response_begun_count: Array[int] = [0, 0]


var game_number: int = 0
var date_text: String = ""
var rng_seed: int = 0
var turn_rows: Array[TurnRow] = []
var last_breath_notes: Array[LastBreathNote] = []
var end_fields: EndFields = EndFields.new()


## « fiche-partie-3-2026-10-21-graine-42.csv » : la graine permet de rejouer la partie.
func file_name() -> String:
	return FILE_NAME_FORMAT % [game_number, date_text, rng_seed]


## Trois tableaux séparés par une ligne vide, précédés de l'en-tête de la fiche.
func to_csv() -> String:
	var tables: Array[String] = [_header_table(), _turn_table(), _last_breath_table(), _end_table()]
	return LINE_BREAK.join(tables) + LINE_BREAK


## « A » ou « B », comme sur la fiche du protocole.
static func letter(side: DuelState.PlayerSide) -> String:
	return DuelState.PlayerSide.keys()[side]


func _header_table() -> String:
	var values: Array[String] = [str(game_number), date_text, "", "", str(rng_seed)]
	var lines: Array[String] = []
	for index: int in HEADER_LABELS.size():
		lines.append(_line([HEADER_LABELS[index], values[index]]))
	return LINE_BREAK.join(lines) + LINE_BREAK


func _turn_table() -> String:
	var columns: Array[String] = TURN_COLUMNS.duplicate()
	for side: DuelState.PlayerSide in DuelState.SIDES:
		for format: String in PLAYER_COLUMN_FORMATS:
			columns.append(format % letter(side))
	var lines: Array[String] = [_line(columns)]
	for row: TurnRow in turn_rows:
		lines.append(_line(_turn_cells(row)))
	return LINE_BREAK.join(lines) + LINE_BREAK


func _turn_cells(row: TurnRow) -> Array[String]:
	var cells: Array[String] = [str(row.turn_rank), letter(row.active_player)]
	for side: DuelState.PlayerSide in DuelState.SIDES:
		var player_cells := row.cells[side]
		cells.append(_count_text(player_cells.essence_unused))
		cells.append(_count_text(player_cells.essence_lost))
		cells.append(str(player_cells.hand_count))
		cells.append(str(player_cells.sources_in_play))
		cells.append(str(player_cells.sources_recycled))
		cells.append(_mark_text(player_cells.fought))
		cells.append(_mark_text(player_cells.card_played))
	return cells


func _last_breath_table() -> String:
	var lines: Array[String] = [_line(LAST_BREATH_COLUMNS)]
	for note: LastBreathNote in last_breath_notes:
		lines.append(_line([str(note.turn_rank), letter(note.active_player), "", ""]))
	return LINE_BREAK.join(lines) + LINE_BREAK


func _end_table() -> String:
	var lines: Array[String] = [_line(END_COLUMNS)]
	lines.append(_line([WINNER_LABEL, _winner_text()]))
	lines.append(_line([FIRST_PLAYER_LABEL, letter(end_fields.first_player)]))
	lines.append(_line([END_CAUSE_LABEL, _end_cause_text()]))
	lines.append(_line([DURATION_LABEL, _minutes_text(end_fields.duration_msec)]))
	for side: DuelState.PlayerSide in DuelState.SIDES:
		var label := TIME_LEFT_FORMAT % letter(side)
		lines.append(_line([label, _minutes_text(end_fields.time_left_msec[side])]))
	lines.append(_line([MULLIGAN_LABEL, str(end_fields.mulligan_count)]))
	lines.append(_line([FATIGUE_LABEL, _fatigue_text()]))
	for side: DuelState.PlayerSide in DuelState.SIDES:
		var label := WINDOW_TIME_FORMAT % letter(side)
		lines.append(_line([label, _seconds_text(end_fields.response_window_msec[side])]))
	for side: DuelState.PlayerSide in DuelState.SIDES:
		var label := RESPONSES_FORMAT % letter(side)
		lines.append(_line([label, str(end_fields.response_begun_count[side])]))
	for label: String in FREE_LABELS:
		lines.append(_line([label, ""]))
	return LINE_BREAK.join(lines) + LINE_BREAK


func _winner_text() -> String:
	match end_fields.result:
		DuelState.DuelResult.PLAYER_A_WINS:
			return letter(DuelState.PlayerSide.A)
		DuelState.DuelResult.PLAYER_B_WINS:
			return letter(DuelState.PlayerSide.B)
	return NO_WINNER_TEXT


# Décision 0161 du ruleset : « 0 PV par la fatigue » est distinct des autres chutes à 0 PV.
func _end_cause_text() -> String:
	if end_fields.result == DuelState.DuelResult.DRAW:
		return DRAW_CAUSE_TEXT
	return END_CAUSE_TEXTS.get(end_fields.reason, "")


func _fatigue_text() -> String:
	if end_fields.first_fatigue_turn_rank == NO_VALUE:
		return NO_FATIGUE_TEXT
	return str(end_fields.first_fatigue_turn_rank)


static func _count_text(value: int) -> String:
	return "" if value == NO_VALUE else str(value)


static func _mark_text(mark: Mark) -> String:
	match mark:
		Mark.YES:
			return YES_TEXT
		Mark.NO:
			return NO_TEXT
	return ""


static func _minutes_text(msec: int) -> String:
	return "%.1f" % (msec / MSEC_PER_MINUTE)


static func _seconds_text(msec: int) -> String:
	return "%.1f" % (msec / MSEC_PER_SECOND)


static func _line(cells: Array[String]) -> String:
	var escaped: Array[String] = []
	for cell: String in cells:
		escaped.append(_escape(cell))
	return SEPARATOR.join(escaped)


# RFC 4180 : une cellule qui contient le séparateur, un guillemet ou un saut de ligne se met
# entre guillemets, les siens doublés.
static func _escape(cell: String) -> String:
	var needs_quotes := (
		cell.contains(SEPARATOR) or cell.contains(QUOTE) or cell.contains(LINE_BREAK)
	)
	if not needs_quotes:
		return cell
	return QUOTE + cell.replace(QUOTE, QUOTE + QUOTE) + QUOTE
