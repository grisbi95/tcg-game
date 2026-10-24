class_name TurnTimerBar
extends HBoxContainer
## Barre de temps d'un camp (209.4 ; décisions 0045 et 0053, fiche E17) : se vide à la couleur du
## camp tant que ce camp doit agir, passe à l'orange sous `ALERT_SECONDS` secondes, avec les
## secondes en gras. Deux états seulement : actif (opaque) et inactif (piste vide estompée, sans
## secondes). Le reste d'un tour en pause (209.4.8a) s'écrit au bout, en petit. Le temps vient du
## moteur ; rien n'est décompté ici. Le tracé de la barre vient des variations du thème
## (`TimerBarA`, `TimerBarB`, `TimerBarAlert`) : un `TextureProgressBar` peut remplacer
## `ProgressBar` en ne changeant que `_apply_bar_look`.

const ALERT_SECONDS: int = 10
const INACTIVE_ALPHA: float = 0.25
const SECONDS_FORMAT: String = "%d s"
const PAUSED_FORMAT: String = "· tour %d s"
const MIN_DURATION_MSEC: int = 1  # évite une division par zéro dans la barre
const FULL_RATIO: float = 1.0
const EMPTY_RATIO: float = 0.0
const SECONDS_LOOK: StringName = &"TimerSecondsLabel"
const SECONDS_ALERT_LOOK: StringName = &"TimerSecondsAlertLabel"
const ALERT_BAR_LOOK: StringName = &"TimerBarAlert"
const SIDE_BAR_LOOKS: Dictionary[DuelState.PlayerSide, StringName] = {
	DuelState.PlayerSide.A: &"TimerBarA",
	DuelState.PlayerSide.B: &"TimerBarB",
}

var _side: DuelState.PlayerSide = DuelState.PlayerSide.A
var _durations_msec: Dictionary[DuelState.ClockKind, int] = {}
var _displayed_key: String = ""

@onready var _bar: Range = %Bar
@onready var _seconds_label: Label = %SecondsLabel
@onready var _paused_label: Label = %PausedLabel


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
		_show_inactive()
	_paused_label.visible = reading.has_paused_turn()
	if reading.has_paused_turn():
		_paused_label.text = PAUSED_FORMAT % ClockReading.started_seconds(reading.paused_turn_msec)
		_paused_label.modulate.a = DuelPalette.DIMMED_ALPHA


## « 18 s » ; les secondes entamées comptent pour une seconde pleine.
static func seconds_text(remaining_msec: int) -> String:
	return SECONDS_FORMAT % ClockReading.started_seconds(remaining_msec)


## Vrai sous ALERT_SECONDS secondes entamées.
static func is_alert(remaining_msec: int) -> bool:
	return ClockReading.started_seconds(remaining_msec) < ALERT_SECONDS


func _show_active(reading: ClockReading) -> void:
	var duration_msec: int = _durations_msec.get(reading.kind, MIN_DURATION_MSEC)
	var is_alert_shown := is_alert(reading.remaining_msec)
	_apply_bar_look(ALERT_BAR_LOOK if is_alert_shown else SIDE_BAR_LOOKS[_side])
	_bar.value = clampf(float(reading.remaining_msec) / duration_msec, EMPTY_RATIO, FULL_RATIO)
	_bar.modulate.a = 1.0
	_seconds_label.theme_type_variation = SECONDS_ALERT_LOOK if is_alert_shown else SECONDS_LOOK
	_seconds_label.text = seconds_text(reading.remaining_msec)
	_seconds_label.visible = true


func _show_inactive() -> void:
	_apply_bar_look(SIDE_BAR_LOOKS[_side])
	_bar.value = EMPTY_RATIO
	_bar.modulate.a = INACTIVE_ALPHA
	_seconds_label.visible = false


func _apply_bar_look(look: StringName) -> void:
	_bar.theme_type_variation = look
