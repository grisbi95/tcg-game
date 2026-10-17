class_name SpellAnnounced
extends PlayerEvent
## 208.1.3, 201.4.8 : le joueur annonce un Spell, révélé aux deux joueurs.

var card_instance_id: int = DuelState.NO_ID


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A,
	spell_card_id: int = DuelState.NO_ID
) -> void:
	super(concerned_player)
	card_instance_id = spell_card_id
