class_name EffectLostAllTargets
extends PlayerEvent
## 207.5.5 : l'effet d'une entrée du joueur a perdu toutes ses cibles et n'a pas lieu.

var stack_entry_id: int = DuelState.NO_ID


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A, entry_id: int = DuelState.NO_ID
) -> void:
	super(concerned_player)
	stack_entry_id = entry_id
