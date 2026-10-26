class_name TurnTimerBar
extends HBoxContainer
## Barre de temps d'un camp (209.4 ; décisions 0045 et 0053, fiche E17), sur toute la largeur de
## la grille et sans texte : se vide à la couleur du camp tant que ce camp doit agir, passe à
## l'orange sous `ALERT_SECONDS` secondes. Inactive, la piste est estompée ; un tour en pause
## (209.4.8a) y reste dessiné, estompé lui aussi. Le temps vient du moteur ; rien n'est décompté
## ici. Le tracé de la barre vient des variations du thème (`TimerBarA`, `TimerBarB`,
## `TimerBarAlert`) : un `TextureProgressBar` peut remplacer `ProgressBar` en ne changeant que
## `_apply_bar_look`.

const ALERT_SECONDS: int = 10
const INACTIVE_ALPHA: float = 0.25
const MIN_DURATION_MSEC: int = 1  # évite une division par zéro dans la barre
const FULL_RATIO: float = 1.0
const EMPTY_RATIO: float = 0.0
const ALERT_BAR_LOOK: StringName = &"TimerBarAlert"
const SIDE_BAR_LOOKS: Dictionary[DuelState.PlayerSide, StringName] = {
	DuelState.PlayerSide.A: &"TimerBarA",
	DuelState.PlayerSide.B: &"TimerBarB",
}

var _side: DuelState.PlayerSide = DuelState.PlayerSide.A
var _durations_msec: Dictionary[DuelState.ClockKind, int] = {}
var _displayed_key: String = ""

@onready var _bar: Range = %Bar


## Barre du camp `side` ; un temps de tour part de `turn_duration_msec`, un temps de réponse de
## `response_duration_msec` (209.4.3). Vide jusqu'au premier `show_reading`.
func setup(
	side: DuelState.PlayerSide, turn_duration_msec: int, response_duration_msec: int
) -> void:
	_side = side
	_durations_msec[DuelState.ClockKind.TURN] = maxi(turn_duration_msec, MIN_DURATION_MSEC)
	_durations_msec[DuelState.ClockKind.RESPONSE] = maxi(response_duration_msec, MIN_DURATION_MSEC)
	_displayed_key = ""
	show_reading(ClockReading.new())


## Montre le temps de `reading` (209.4.4, 209.4.8a). Peut être appelée à chaque image : la barre
## ne se redessine que si son affichage change.
func show_reading(reading: ClockReading) -> void:
	var key := reading.display_key()
	if key == _displayed_key:
		return
	_displayed_key = key
	if reading.is_running:
		_show_active(reading)
	else:
		_show_inactive(reading)


## Vrai sous ALERT_SECONDS secondes entamées.
static func is_alert(remaining_msec: int) -> bool:
	return ClockReading.started_seconds(remaining_msec) < ALERT_SECONDS


func _show_active(reading: ClockReading) -> void:
	_apply_bar_look(ALERT_BAR_LOOK if is_alert(reading.remaining_msec) else SIDE_BAR_LOOKS[_side])
	_bar.value = _ratio(reading.remaining_msec, reading.kind)
	_bar.modulate.a = 1.0


func _show_inactive(reading: ClockReading) -> void:
	_apply_bar_look(SIDE_BAR_LOOKS[_side])
	_bar.value = EMPTY_RATIO
	if reading.has_paused_turn():
		_bar.value = _ratio(reading.paused_turn_msec, DuelState.ClockKind.TURN)
	_bar.modulate.a = INACTIVE_ALPHA


func _ratio(time_msec: int, kind: DuelState.ClockKind) -> float:
	var duration_msec: int = _durations_msec.get(kind, MIN_DURATION_MSEC)
	return clampf(float(time_msec) / duration_msec, EMPTY_RATIO, FULL_RATIO)


func _apply_bar_look(look: StringName) -> void:
	_bar.theme_type_variation = look
