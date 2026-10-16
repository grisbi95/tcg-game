class_name DeployCard
extends DuelIntent
## 208.1.1, 205.1.5, 203.3.2 : le joueur actif annonce le déploiement d'une Unit ou d'un
## Building de sa main sur une case, et paie son coût (décision 0003).

var card_instance_id: int = DuelState.NO_ID
var cell: Vector2i = BoardGeometry.NO_CELL
var payment: EssencePayment = EssencePayment.new()


func _init(
	author: DuelState.PlayerSide = DuelState.PlayerSide.A,
	card_id: int = DuelState.NO_ID,
	target_cell: Vector2i = BoardGeometry.NO_CELL,
	essence_payment: EssencePayment = EssencePayment.new()
) -> void:
	super(author)
	card_instance_id = card_id
	cell = target_cell
	payment = essence_payment
