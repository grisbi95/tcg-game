class_name ClockView
extends PanelContainer
## Temps d'un joueur (209.4 ; décision 0028) : nom, libellé « Tour » ou « Réponse », temps restant
## et barre, aux couleurs du joueur ; vif quand il s'écoule, estompé sinon. Le temps de tour en
## pause (209.4.8a) reste lisible sous la barre. Le temps vient du moteur ; rien n'est décompté ici.

const MSEC_PER_SECOND: int = 1000
const SECONDS_PER_MINUTE: int = 60
const ALERT_SECONDS: int = 10
const BORDER_WIDTH: int = 3
const PADDING: float = 12.0
const BAR_RADIUS: int = 3
const KIND_LABELS: Dictionary[DuelState.ClockKind, String] = {
	DuelState.ClockKind.TURN: "Tour",
	DuelState.ClockKind.RESPONSE: "Réponse",
}

var _side: DuelState.PlayerSide = DuelState.PlayerSide.A
var _player_name: String = ""
var _durations_msec: Dictionary[DuelState.ClockKind, int] = {}

@onready var _name_label: Label = %NameLabel
@onready var _time_label: Label = %TimeLabel
@onready var _time_bar: ProgressBar = %TimeBar
@onready var _paused_label: Label = %PausedLabel


## Temps de `player_name`, du joueur `side` ; un temps de tour part de `turn_duration_msec`, un
## temps de réponse de `response_duration_msec` (209.4.3).
func setup(
	side: DuelState.PlayerSide,
	player_name: String,
	turn_duration_msec: int,
	response_duration_msec: int
) -> void:
	_side = side
	_player_name = player_name
	_durations_msec[DuelState.ClockKind.TURN] = maxi(turn_duration_msec, 1)
	_durations_msec[DuelState.ClockKind.RESPONSE] = maxi(response_duration_msec, 1)
	_name_label.add_theme_color_override("font_color", DuelPalette.player_ink(side))
	var color := DuelPalette.player_color(side)
	add_theme_stylebox_override(
		"panel",
		DuelPalette.framed_style(DuelPalette.player_soft(side), color, BORDER_WIDTH, PADDING)
	)
	_time_bar.add_theme_stylebox_override(
		"background", DuelPalette.fill_style(DuelPalette.BAR_TRACK_COLOR, BAR_RADIUS, 0.0)
	)
	_paused_label.add_theme_color_override("font_color", DuelPalette.MUTED_COLOR)
	_show_alert(false)


## Montre le temps de `reading` (209.4.4, 209.4.8a).
func show_clock(reading: ClockReading) -> void:
	var duration_msec: int = _durations_msec.get(reading.kind, 1)
	_name_label.text = "%s · %s" % [_player_name, KIND_LABELS[reading.kind]]
	_time_label.text = format_time(reading.remaining_msec)
	_time_bar.value = clampf(float(reading.remaining_msec) / duration_msec, 0.0, 1.0)
	_show_alert(reading.is_running and is_alert(reading.remaining_msec))
	_paused_label.visible = reading.has_paused_turn()
	if reading.has_paused_turn():
		_paused_label.text = "Tour %s · en pause" % format_time(reading.paused_turn_msec)
	modulate.a = 1.0 if reading.is_running else DuelPalette.DIMMED_ALPHA


## « 09:05 » ; les secondes entamées comptent pour une seconde pleine.
static func format_time(remaining_msec: int) -> String:
	var seconds := ceili(maxi(remaining_msec, 0) / float(MSEC_PER_SECOND))
	var minutes := floori(seconds / float(SECONDS_PER_MINUTE))
	return "%02d:%02d" % [minutes, seconds % SECONDS_PER_MINUTE]


## Vrai sous ALERT_SECONDS secondes entamées.
static func is_alert(remaining_msec: int) -> bool:
	return ceili(maxi(remaining_msec, 0) / float(MSEC_PER_SECOND)) < ALERT_SECONDS


func _show_alert(is_alert_shown: bool) -> void:
	var ink := DuelPalette.HIGHLIGHT_COLOR if is_alert_shown else DuelPalette.INK_COLOR
	var fill := DuelPalette.HIGHLIGHT_COLOR if is_alert_shown else DuelPalette.player_color(_side)
	_time_label.add_theme_color_override("font_color", ink)
	_time_bar.add_theme_stylebox_override("fill", DuelPalette.fill_style(fill, BAR_RADIUS, 0.0))
