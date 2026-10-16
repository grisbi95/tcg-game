class_name DuelIntent
extends RefCounted
## Base des intentions soumises à `DuelEngine.submit()` (décisions 0001 et 0007).
##
## Une intention décrit ce qu'un joueur veut faire ; elle ne contient aucune règle et ne
## modifie jamais l'état. Joueurs humains, IA et tests passent par les mêmes intentions.

## Joueur qui soumet l'intention.
var player: DuelState.PlayerSide = DuelState.PlayerSide.A


func _init(author: DuelState.PlayerSide = DuelState.PlayerSide.A) -> void:
	player = author
