class_name TargetsChosen
extends PlayerEvent
## 207.5.1b, 207.5.2 : le joueur a choisi les cibles de son effet déclenché, qui s'ajoute
## ensuite à la pile.

var stack_entry_id: int = DuelState.NO_ID


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A,
	targeting_entry_id: int = DuelState.NO_ID
) -> void:
	super(concerned_player)
	stack_entry_id = targeting_entry_id
