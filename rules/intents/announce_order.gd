class_name AnnounceOrder
extends DuelIntent
## 208.1.12, 211.2, 211.3.1, 211.4.1 : le joueur annonce un Ordre de son Hero, choisit ses cibles et
## paie son coût (décisions 0003 et 0055). Les cibles se renseignent après la construction.

## 202.3.21 : rang de l'Ordre dans le texte du Hero, à partir de 0.
var order_index: int = 0
var payment: EssencePayment = EssencePayment.new()
## 207.5.11 : pièces ciblées.
var target_piece_ids: Array[int] = []
## 202.4.12 : cases ciblées.
var target_cells: Array[Vector2i] = []
## 207.5.14 : Spells de la pile ciblés ; jamais un Ordre (211.1.4).
var target_stack_entry_ids: Array[int] = []


func _init(
	author: DuelState.PlayerSide = DuelState.PlayerSide.A,
	rank: int = 0,
	essence_payment: EssencePayment = EssencePayment.new()
) -> void:
	super(author)
	order_index = rank
	payment = essence_payment
