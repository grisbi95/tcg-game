class_name CombatPutOnHold
extends PlayerEvent
## 205.6.1 à 205.6.4 : un combat naît à la résolution d'un déploiement ou d'une action normale ;
## il attend la fin de cette résolution avant de s'ajouter à la pile (décision 0046). Le joueur
## est celui à qui appartient l'attaquant (205.6.5).

## Identifiant que le combat gardera sur la pile.
var stack_entry_id: int = DuelState.NO_ID
## Unit qui fait son action normale et reste sur sa case (205.6.7) ; NO_ID pour un déploiement.
var piece_id: int = DuelState.NO_ID
## Carte de l'Unit qui se déploie, qui reste sur la pile avec le combat (205.6.8) ; NO_ID pour une
## action normale.
var card_instance_id: int = DuelState.NO_ID
## Case de la pièce attaquée.
var cell: Vector2i = BoardGeometry.NO_CELL


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A,
	held_entry_id: int = DuelState.NO_ID,
	attacking_piece_id: int = DuelState.NO_ID,
	attacked_cell: Vector2i = BoardGeometry.NO_CELL
) -> void:
	super(concerned_player)
	stack_entry_id = held_entry_id
	piece_id = attacking_piece_id
	cell = attacked_cell
