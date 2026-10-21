class_name PlayerNames
extends RefCounted
## Nom affiché d'un joueur, partagé par les vues : « A », « Joueur A ».


static func letter(side: DuelState.PlayerSide) -> String:
	return DuelState.PlayerSide.keys()[side]


static func display_name(side: DuelState.PlayerSide) -> String:
	return "Joueur %s" % letter(side)
