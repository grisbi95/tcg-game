class_name PlayerEvent
extends DuelEvent
## Base des événements qui concernent un seul joueur.

var player: DuelState.PlayerSide = DuelState.PlayerSide.A


func _init(concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A) -> void:
	player = concerned_player
