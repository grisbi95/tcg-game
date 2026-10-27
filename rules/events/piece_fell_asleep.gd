class_name PieceFellAsleep
extends PlayerEvent
## 205.5.7 : un effet endort une Unit ou un Hero éveillé. Un événement par pièce ; n'est pas émis
## quand l'effet n'a pas lieu pour elle (205.5.7a, 205.5.7b). La pièce se réveille au début du tour
## de son joueur (205.5.7c) : PiecesAwakened.

var piece_id: int


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A,
	asleep_piece_id: int = DuelState.NO_ID
) -> void:
	super(concerned_player)
	piece_id = asleep_piece_id
