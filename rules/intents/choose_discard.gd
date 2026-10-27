class_name ChooseDiscard
extends DuelIntent
## 212.1.3, 212.2.3, décision 0057 : le joueur à qui appartient l'effet choisit, toutes en même
## temps, les cartes de sa main à défausser. Répond à l'attente CHOOSE_DISCARD.

## Cartes de la main à défausser, désignées par `card_instance_id`.
var card_ids: Array[int] = []


func _init(
	author: DuelState.PlayerSide = DuelState.PlayerSide.A, chosen_card_ids: Array[int] = []
) -> void:
	super(author)
	card_ids = chosen_card_ids
