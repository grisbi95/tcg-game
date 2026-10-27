class_name CardDiscardedFromHand
extends PlayerEvent
## 212.2.1, 212.2.4 : une carte passe de la main à la défausse par un effet qui dit Défausser ;
## un événement par carte. Distinct de CardDiscarded, passage générique à la défausse (212.2.2).

var card_instance_id: int = DuelState.NO_ID


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A,
	discarded_card_id: int = DuelState.NO_ID
) -> void:
	super(concerned_player)
	card_instance_id = discarded_card_id
