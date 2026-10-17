class_name MonotonicClock
extends RefCounted
## Temps réel de l'hôte (décision 0021) : compteur monotone de Godot, qui ne recule jamais et ne
## dépend pas des images rendues. Les tests le remplacent par une horloge manuelle.


## Millisecondes écoulées depuis le lancement du moteur Godot.
func now_msec() -> int:
	return Time.get_ticks_msec()
