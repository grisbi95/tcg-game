class_name UseHeroPower
extends DuelIntent
## 208.1.4, 202.3.12, 202.3.13, 207.5.1 : le joueur actif annonce le pouvoir de son Hero,
## choisit ses cibles et paie son coût (décision 0003). Les cibles se renseignent après la
## construction.

var payment: EssencePayment = EssencePayment.new()
var target_piece_ids: Array[int] = []
var target_cells: Array[Vector2i] = []
var target_stack_entry_ids: Array[int] = []


func _init(
	author: DuelState.PlayerSide = DuelState.PlayerSide.A,
	essence_payment: EssencePayment = EssencePayment.new()
) -> void:
	super(author)
	payment = essence_payment
