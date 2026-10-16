class_name SourcesPutIntoPlay
extends PlayerEvent
## 204.1.12, 204.1.17 : le joueur met des Sources de sa réserve en jeu, redressées.

var count: int = 0


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A, sources_count: int = 0
) -> void:
	super(concerned_player)
	count = sources_count
