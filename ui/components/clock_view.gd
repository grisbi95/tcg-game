class_name ClockView
extends PanelContainer
## Pendule d'un joueur (209.4 ; décision 0028) : nom, temps restant et barre du temps restant, aux
## couleurs du joueur ; vive quand elle tourne, estompée sinon. Le temps vient du moteur ; rien
## n'est décompté ici.

const MSEC_PER_SECOND: int = 1000
const SECONDS_PER_MINUTE: int = 60
const BORDER_WIDTH: int = 3
const PADDING: float = 12.0
const BAR_RADIUS: int = 3

var _duration_msec: int = 1

@onready var _name_label: Label = %NameLabel
@onready var _time_label: Label = %TimeLabel
@onready var _time_bar: ProgressBar = %TimeBar


## Pendule de `player_name`, du joueur `owner`, qui part de `duration_msec` (209.4.3).
func setup(owner: DuelState.PlayerSide, player_name: String, duration_msec: int) -> void:
	_duration_msec = maxi(duration_msec, 1)
	_name_label.text = player_name
	_name_label.add_theme_color_override("font_color", DuelPalette.player_ink(owner))
	_time_label.add_theme_color_override("font_color", DuelPalette.INK_COLOR)
	var color := DuelPalette.player_color(owner)
	add_theme_stylebox_override(
		"panel",
		DuelPalette.framed_style(DuelPalette.player_soft(owner), color, BORDER_WIDTH, PADDING)
	)
	_time_bar.add_theme_stylebox_override(
		"background", DuelPalette.fill_style(DuelPalette.BAR_TRACK_COLOR, BAR_RADIUS, 0.0)
	)
	_time_bar.add_theme_stylebox_override("fill", DuelPalette.fill_style(color, BAR_RADIUS, 0.0))


## `remaining_msec` restant ; `is_running` vrai si cette pendule tourne (209.4.4).
func show_clock(remaining_msec: int, is_running: bool) -> void:
	_time_label.text = format_time(remaining_msec)
	_time_bar.value = clampf(float(remaining_msec) / _duration_msec, 0.0, 1.0)
	modulate.a = 1.0 if is_running else DuelPalette.DIMMED_ALPHA


## « 09:05 » ; les secondes entamées comptent pour une seconde pleine.
static func format_time(remaining_msec: int) -> String:
	var seconds := ceili(maxi(remaining_msec, 0) / float(MSEC_PER_SECOND))
	return "%02d:%02d" % [seconds / SECONDS_PER_MINUTE, seconds % SECONDS_PER_MINUTE]
