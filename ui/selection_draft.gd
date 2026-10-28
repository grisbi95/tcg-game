class_name SelectionDraft
extends RefCounted
## Paiement préparé pendant le tour adverse (décision 0023) : les Sources pressées s'ajoutent au
## paiement de la réponse, dans la limite de ce que le moteur dit encore disponible. Aucune règle
## ici : les Sources montrées viennent des requêtes de `DuelEngine`.

var _engine: DuelEngine
var _side: DuelState.PlayerSide = DuelState.PlayerSide.A
var _payment: EssencePayment = EssencePayment.new()


func setup(engine: DuelEngine, side: DuelState.PlayerSide) -> void:
	_engine = engine
	_side = side
	clear()


func clear() -> void:
	_payment = EssencePayment.new()


## Le paiement préparé, copié : un paiement ne sert qu'une fois.
func payment() -> EssencePayment:
	return EssencePayment.new(_payment.incline_count, _payment.recycle_count)


## 203.2.1, 203.2.2 : Sources redressées, une fois le paiement préparé déduit.
func shown_upright_sources() -> int:
	return _engine.upright_sources_after_payment(_side, _payment)


func shown_tilted_sources() -> int:
	return _engine.tilted_sources_after_payment(_side, _payment)


func shown_fonte_sources() -> int:
	return _engine.fonte_after_payment(_side, _payment)


## Ajoute une Source au paiement si elle est encore disponible : inclinée si `is_tilted` (elle se
## recycle), sinon redressée (elle s'incline). Rend vrai si le paiement a changé.
func add_source(is_tilted: bool) -> bool:
	var available := shown_tilted_sources() if is_tilted else shown_upright_sources()
	if available <= 0:
		return false
	if is_tilted:
		_payment.recycle_count += 1
	else:
		_payment.incline_count += 1
	return true
