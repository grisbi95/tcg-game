class_name SourcesUntapped
extends PlayerEvent
## 204.3.2 : le joueur redresse ses Sources inclinées.

var count: int = 0


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A, sources_count: int = 0
) -> void:
	super(concerned_player)
	count = sources_count
