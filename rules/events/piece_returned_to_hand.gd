class_name PieceReturnedToHand
extends PlayerEvent
## 216.1.1 : une pièce du joueur quitte le plateau, renvoyée dans la main. Sa carte la suit
## (CardReturnedToHand, ou CardDiscarded si la main est pleine, 216.1.2a) ; un jeton n'en a pas
## (216.1.3). Distinct de PieceDestroyed (216.2.1).

var piece_id: int = DuelState.NO_ID


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A,
	returned_piece_id: int = DuelState.NO_ID
) -> void:
	super(concerned_player)
	piece_id = returned_piece_id
