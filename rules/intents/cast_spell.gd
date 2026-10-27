class_name CastSpell
extends DuelIntent
## 208.1.3, 207.5.1a, 203.3.2, 213.1.3 : le joueur annonce un Spell de sa main, choisit ses cibles
## et paie son coût (décision 0003). Les cibles se renseignent après la construction.

var card_instance_id: int = DuelState.NO_ID
var payment: EssencePayment = EssencePayment.new()
## 207.5.11 : pièces ciblées.
var target_piece_ids: Array[int] = []
## 202.4.12 : cases ciblées.
var target_cells: Array[Vector2i] = []
## 207.5.14 : Spells de la pile ciblés.
var target_stack_entry_ids: Array[int] = []
## 213.1.3, 213.1.4 : valeur choisie pour X, au moins 1 pour un Spell à coût X ; 0 sinon. Choisie
## avec l'intention, avant les cibles (213.1.9).
var x_value: int = 0


func _init(
	author: DuelState.PlayerSide = DuelState.PlayerSide.A,
	card_id: int = DuelState.NO_ID,
	essence_payment: EssencePayment = EssencePayment.new()
) -> void:
	super(author)
	card_instance_id = card_id
	payment = essence_payment
