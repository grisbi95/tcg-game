class_name ChooseMulligan
extends DuelIntent
## 204.2.4, 204.2.12 : réponse d'un joueur à l'attente du mulligan (décisions 0009 et 0013).
##
## Une liste vide garde la main (204.2.12) ; sinon les cartes listées sont écartées.

## Cartes de la main à écarter, désignées par `card_instance_id`.
var set_aside_card_ids: Array[int] = []


func _init(
	author: DuelState.PlayerSide = DuelState.PlayerSide.A, card_ids: Array[int] = []
) -> void:
	super(author)
	set_aside_card_ids = card_ids
