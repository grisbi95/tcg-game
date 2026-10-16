class_name CardDiscarded
extends PlayerEvent
## Une carte va dans la défausse du joueur sans passer par une pièce détruite : carte qui ne
## revient pas dans une main pleine (205.1.10, 201.3.6a), Gear d'une Unit détruite (202.2.13),
## Spell résolu (207.1.7, 207.1.7a).

var card_instance_id: int = DuelState.NO_ID


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A,
	discarded_card_id: int = DuelState.NO_ID
) -> void:
	super(concerned_player)
	card_instance_id = discarded_card_id
