class_name StackEntryAdded
extends PlayerEvent
## 208.4.1 : une entrée s'ajoute au sommet de la pile ; le joueur est celui à qui elle appartient.

## Entrée ajoutée, lisible sur la pile par `DuelState.find_stack_entry()`.
var stack_entry_id: int = DuelState.NO_ID


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A,
	added_entry_id: int = DuelState.NO_ID
) -> void:
	super(concerned_player)
	stack_entry_id = added_entry_id
