class_name EssenceLost
extends PlayerEvent
## 204.5.7a : l'Essence que la réserve d'Essence du joueur actif contenait encore est perdue.

var amount: int = 0


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A, essence_amount: int = 0
) -> void:
	super(concerned_player)
	amount = essence_amount
