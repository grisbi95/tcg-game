class_name ProduceEssence
extends DuelIntent
## 203.6.3, 203.6.4, décision 0026 : pendant son tour, quand il peut agir, le joueur incline ou
## recycle des Sources pour remplir sa réserve d'Essence, sans passer par la pile (203.6.11 à
## 203.6.13).

var payment: EssencePayment = EssencePayment.new()


func _init(
	author: DuelState.PlayerSide = DuelState.PlayerSide.A,
	essence_payment: EssencePayment = EssencePayment.new()
) -> void:
	super(author)
	payment = essence_payment
