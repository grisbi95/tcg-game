class_name ClockView
extends PanelContainer
## Pendule d'un joueur (209.4) : temps restant en minutes et secondes, cadre marqué quand elle
## tourne. Le temps vient du moteur ; rien n'est décompté ici.

const MSEC_PER_SECOND: int = 1000
const SECONDS_PER_MINUTE: int = 60

var _owner_color: Color = DuelPalette.NEUTRAL_COLOR

@onready var _time_label: Label = %TimeLabel


func setup(owner: DuelState.PlayerSide) -> void:
	_owner_color = DuelPalette.player_color(owner)


## `remaining_msec` restant ; `is_running` vrai si cette pendule tourne (209.4.4).
func show_clock(remaining_msec: int, is_running: bool) -> void:
	_time_label.text = format_time(remaining_msec)
	var border := DuelPalette.RUNNING_COLOR if is_running else _owner_color
	add_theme_stylebox_override("panel", DuelPalette.panel_style(border, is_running))


## « 09:05 » ; les secondes entamées comptent pour une seconde pleine.
static func format_time(remaining_msec: int) -> String:
	var seconds := ceili(maxi(remaining_msec, 0) / float(MSEC_PER_SECOND))
	return "%02d:%02d" % [seconds / SECONDS_PER_MINUTE, seconds % SECONDS_PER_MINUTE]
