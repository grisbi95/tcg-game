class_name PiecesAwakened
extends PlayerEvent
## 204.3.10, 204.3.11 : au début de son tour, le joueur réveille ses Units et son Hero endormis.
## `piece_ids` liste les seules pièces qui dormaient, dans l'ordre de `DuelState.pieces` ; une
## pièce déjà éveillée (205.5.5) n'y figure pas. Jamais vide : sans pièce endormie, l'événement
## n'est pas émis.

var piece_ids: Array[int] = []


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A,
	awakened_piece_ids: Array[int] = []
) -> void:
	super(concerned_player)
	piece_ids = awakened_piece_ids
