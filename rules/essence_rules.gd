class_name EssenceRules
extends RefCounted
## Essence et Sources : paiement d'un coût en inclinant et en recyclant (203, décision 0003).
##
## L'Essence n'est jamais stockée : elle est produite au moment de payer (203.1.3, 203.2.4).
## Le moment du paiement (203.3.2) et le tour où il a lieu (203.2.5) relèvent de l'appelant.


## 203.2.1, 203.2.2, 203.2.6, 203.3.1, 203.4.2 : raison du refus de `payment` pour un coût de
## `cost` Essence par `side`, ou NONE si le paiement est possible. Pur.
static func validate_payment(
	state: DuelState, side: DuelState.PlayerSide, payment: EssencePayment, cost: int
) -> IntentRejected.RejectReason:
	var player := state.get_player(side)
	if payment.incline_count < 0 or payment.recycle_count < 0:
		return IntentRejected.RejectReason.NEGATIVE_PAYMENT
	if payment.essence_produced() != cost:
		return IntentRejected.RejectReason.PAYMENT_DOES_NOT_MATCH_COST
	if payment.incline_count > player.sources_upright:
		return IntentRejected.RejectReason.NOT_ENOUGH_UPRIGHT_SOURCES
	# 203.2.6 : les Sources inclinées par ce paiement peuvent y être recyclées.
	if payment.recycle_count > player.sources_tilted + payment.incline_count:
		return IntentRejected.RejectReason.NOT_ENOUGH_TILTED_SOURCES
	if not _recycle_limit_allows(state, player, payment.recycle_count):
		return IntentRejected.RejectReason.RECYCLE_LIMIT_REACHED
	return IntentRejected.RejectReason.NONE


## 203.2.1 à 203.2.3, 203.2.6, 203.5.3 : incline puis recycle les Sources de `payment`.
## Suppose le paiement validé par `validate_payment`.
static func apply_payment(
	state: DuelState, side: DuelState.PlayerSide, payment: EssencePayment, events: Array[DuelEvent]
) -> void:
	var player := state.get_player(side)
	player.sources_upright -= payment.incline_count
	player.sources_tilted += payment.incline_count
	for index: int in payment.incline_count:
		events.append(SourceInclined.new(side))
	player.sources_tilted -= payment.recycle_count
	player.sources_in_fonte += payment.recycle_count
	player.sources_recycled_this_turn += payment.recycle_count
	for index: int in payment.recycle_count:
		events.append(SourceRecycled.new(side))


# 203.4.2
static func _recycle_limit_allows(
	state: DuelState, player: PlayerState, recycle_count: int
) -> bool:
	var max_recycles := state.config.max_recycles_per_turn
	if max_recycles == DuelConfig.UNLIMITED_RECYCLES:
		return true
	return player.sources_recycled_this_turn + recycle_count <= max_recycles
