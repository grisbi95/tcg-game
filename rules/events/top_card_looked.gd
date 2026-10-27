class_name TopCardLooked
extends PlayerEvent
## 217.1.1 : le joueur regarde la carte du dessus de son deck. Le moteur est omniscient :
## l'identifiant de la carte est porté ici, la vue ne le montre qu'à ce joueur (201.4.1a, 217.1.5).

var card_instance_id: int = DuelState.NO_ID


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A,
	looked_card_id: int = DuelState.NO_ID
) -> void:
	super(concerned_player)
	card_instance_id = looked_card_id
