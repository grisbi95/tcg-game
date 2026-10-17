class_name DuelAgent
extends RefCounted
## Base des agents d'IA (décisions 0019 et 0020) : l'hôte du duel demande à l'agent du joueur
## attendu l'intention qu'il joue. Aucune règle ici ; le moteur seul juge.


## Intention du joueur que le moteur attend ; null si l'agent n'en propose aucune.
func choose_intent(_engine: DuelEngine) -> DuelIntent:
	return null
