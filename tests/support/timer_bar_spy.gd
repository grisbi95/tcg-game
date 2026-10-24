class_name TimerBarSpy
extends TurnTimerBar
## Barre de temps d'essai : enregistre les temps qu'on lui montre, sans scène ni arbre (le script
## n'est jamais prêt, ses `@onready` restent vides). Sert aux suites de `DuelCenterPresenter`.

var readings: Array[ClockReading] = []


func show_reading(reading: ClockReading) -> void:
	readings.append(reading)


## Dernier temps montré.
func last_reading() -> ClockReading:
	return readings[-1]
