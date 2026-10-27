class_name ChooseTopCardPlace
extends DuelIntent
## 217.1.2, 217.1.3, décision 0057 : le joueur qui regarde la carte du dessus de son deck la laisse
## au dessus ou la met sous son deck. Répond à l'attente CHOOSE_TOP_CARD_PLACE.

## Où va la carte regardée. Enum journalisable : ajouter à la fin, sans réordonner.
enum TopCardPlace {
	ON_TOP,  # 217.1.2
	BELOW,  # 217.1.3
}

var place: TopCardPlace = TopCardPlace.ON_TOP


func _init(
	author: DuelState.PlayerSide = DuelState.PlayerSide.A,
	chosen_place: TopCardPlace = TopCardPlace.ON_TOP
) -> void:
	super(author)
	place = chosen_place
