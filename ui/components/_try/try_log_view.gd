extends Control
## Essai de LogView : le journal d'un début de duel, en phrases.

const LOG_SCENE: PackedScene = preload("res://ui/components/log_view.tscn")


func _ready() -> void:
	var row := HBoxContainer.new()
	TrySamples.frame(self, row)
	var log_view: LogView = LOG_SCENE.instantiate()
	row.add_child(log_view)
	var events: Array[DuelEvent] = [
		FirstPlayerChosen.new(DuelState.PlayerSide.A),
		TurnStarted.new(DuelState.PlayerSide.A, 1),
		CardDrawn.new(DuelState.PlayerSide.A),
		EssenceProduced.new(DuelState.PlayerSide.A, 1),
		DeployAnnounced.new(DuelState.PlayerSide.A),
		PriorityPassed.new(DuelState.PlayerSide.B),
		TurnEnded.new(DuelState.PlayerSide.A),
		EssenceLost.new(DuelState.PlayerSide.A, 1),
		DuelEnded.new(),
	]
	log_view.append_events(events)
