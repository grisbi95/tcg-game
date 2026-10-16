class_name AttachGear
extends DuelIntent
## 208.1.5, 202.2.22, 203.3.2 : le joueur actif annonce un Gear de sa main, choisit l'Unit
## alliée qui le recevra et paie son coût (décision 0003).

var card_instance_id: int = DuelState.NO_ID
var unit_piece_id: int = DuelState.NO_ID
var payment: EssencePayment = EssencePayment.new()


func _init(
	author: DuelState.PlayerSide = DuelState.PlayerSide.A,
	gear_card_id: int = DuelState.NO_ID,
	target_unit_id: int = DuelState.NO_ID,
	essence_payment: EssencePayment = EssencePayment.new()
) -> void:
	super(author)
	card_instance_id = gear_card_id
	unit_piece_id = target_unit_id
	payment = essence_payment
