class_name EffectTriggered
extends PlayerEvent
## 207.3.1, 208.4.2 : un effet déclenché survient et attend son ajout à la pile (décision 0017) ;
## le joueur est celui à qui il appartient (207.3.4).

## Identifiant que l'effet gardera sur la pile.
var stack_entry_id: int = DuelState.NO_ID
## Pièce qui porte l'effet, peut-être déjà partie du plateau (207.3.3).
var source_piece_id: int = DuelState.NO_ID


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A,
	triggered_entry_id: int = DuelState.NO_ID,
	bearer_piece_id: int = DuelState.NO_ID
) -> void:
	super(concerned_player)
	stack_entry_id = triggered_entry_id
	source_piece_id = bearer_piece_id
