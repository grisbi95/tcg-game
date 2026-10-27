class_name TopCardPlaceChosen
extends PlayerEvent
## 217.1.2, 217.1.3, 217.1.4 : le joueur a laissé la carte regardée au dessus de son deck ou l'a
## mise dessous ; l'adversaire voit ce choix, pas la carte (217.1.5).

var place: ChooseTopCardPlace.TopCardPlace = ChooseTopCardPlace.TopCardPlace.ON_TOP


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A,
	chosen_place: ChooseTopCardPlace.TopCardPlace = ChooseTopCardPlace.TopCardPlace.ON_TOP
) -> void:
	super(concerned_player)
	place = chosen_place
