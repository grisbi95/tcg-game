class_name StackEntryResolved
extends PlayerEvent
## 208.3.2 : l'entrée du sommet de la pile se résout ; le joueur est celui à qui elle appartient.

## Entrée résolue, déjà retirée de la pile.
var stack_entry_id: int = DuelState.NO_ID


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A,
	resolved_entry_id: int = DuelState.NO_ID
) -> void:
	super(concerned_player)
	stack_entry_id = resolved_entry_id
