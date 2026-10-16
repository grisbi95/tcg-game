class_name NormalActionFailed
extends PlayerEvent
## 205.4.3 à 205.4.6, 200.4.1 : l'action normale échoue à sa résolution et n'a pas lieu.

var piece_id: int = DuelState.NO_ID


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A,
	acting_piece_id: int = DuelState.NO_ID
) -> void:
	super(concerned_player)
	piece_id = acting_piece_id
