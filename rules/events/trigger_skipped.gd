class_name TriggerSkipped
extends PlayerEvent
## 207.5.9, 207.5.10, 207.3.5a : un effet déclenché en attente ne s'ajoute pas à la pile, faute
## de cibles légales ou parce que sa mention « une fois par tour » a déjà servi ce tour.

var stack_entry_id: int = DuelState.NO_ID


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A,
	skipped_entry_id: int = DuelState.NO_ID
) -> void:
	super(concerned_player)
	stack_entry_id = skipped_entry_id
