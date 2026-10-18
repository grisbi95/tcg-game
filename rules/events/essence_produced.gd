class_name EssenceProduced
extends PlayerEvent
## 203.6.3, 203.6.4 : de l'Essence s'ajoute à la réserve d'Essence du joueur.

var amount: int = 0


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A, essence_amount: int = 0
) -> void:
	super(concerned_player)
	amount = essence_amount
