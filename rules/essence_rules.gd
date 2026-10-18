class_name EssenceRules
extends RefCounted
## Essence et Sources : réserve d'Essence, paiement d'un coût en inclinant et en recyclant (203 ;
## décisions 0003 et 0026).
##
## Pendant son tour, un joueur remplit sa réserve d'Essence (203.6) ; toute Essence produite y
## passe, puis le coût y est pris (203.3.2a). Pendant le tour adverse, la réserve est vide : le
## paiement produit exactement le coût (203.3.2b). Le moment du paiement (203.3.2) relève de
## l'appelant.


## 203.2.1, 203.2.2, 203.2.6, 203.3.1, 203.4.2 : raison du refus de `payment` pour un coût de
## `cost` Essence par `side`, ou NONE si le paiement est possible. Pur.
static func validate_payment(
	state: DuelState, side: DuelState.PlayerSide, payment: EssencePayment, cost: int
) -> IntentRejected.RejectReason:
	var player := state.get_player(side)
	if payment.incline_count < 0 or payment.recycle_count < 0:
		return IntentRejected.RejectReason.NEGATIVE_PAYMENT
	if payment.essence_produced() != essence_still_needed(state, side, cost):
		return IntentRejected.RejectReason.PAYMENT_DOES_NOT_MATCH_COST
	return _validate_sources(state, player, payment)


## 203.6.2, 203.6.3, 203.6.4, 203.6.6 à 203.6.9 : raison du refus de `intent`, ou NONE. Les
## attentes de choix (203.6.9) sont contrôlées par DuelEngine. Pur.
static func validate_production(
	state: DuelState, intent: ProduceEssence
) -> IntentRejected.RejectReason:
	if intent.player != state.active_player:
		return IntentRejected.RejectReason.NOT_YOUR_TURN
	if state.stack.is_empty() and state.phase != DuelState.DuelPhase.MAIN:
		return IntentRejected.RejectReason.WRONG_PHASE
	if not state.stack.is_empty() and intent.player != state.priority_player:
		return IntentRejected.RejectReason.NOT_YOUR_PRIORITY
	var payment := intent.payment
	if payment.incline_count < 0 or payment.recycle_count < 0:
		return IntentRejected.RejectReason.NEGATIVE_PAYMENT
	if payment.essence_produced() == 0:
		return IntentRejected.RejectReason.NO_ESSENCE_PRODUCED
	return _validate_sources(state, state.get_player(intent.player), payment)


## 203.6.3, 203.6.4, 203.6.11 à 203.6.13 : l'Essence produite s'ajoute aussitôt à la réserve
## d'Essence, sans passer par la pile ni changer qui peut agir. Suppose l'intention validée.
static func apply_production(
	state: DuelState, intent: ProduceEssence, events: Array[DuelEvent]
) -> void:
	apply_payment(state, intent.player, intent.payment, events)
	events.append(EssenceProduced.new(intent.player, intent.payment.essence_produced()))


## 203.6.5, 203.3.2a, 203.3.2b : Essence qu'une annonce de coût `cost` doit encore produire, une
## fois prise la réserve d'Essence de `side` (vide pendant le tour adverse, 203.6.2). Pur.
static func essence_still_needed(state: DuelState, side: DuelState.PlayerSide, cost: int) -> int:
	return cost - mini(state.get_player(side).essence_reserve, cost)


## 203.3.2, 203.3.2a, 203.3.2b : paie le coût `cost` d'une annonce ; l'Essence produite par
## `payment` complète la réserve d'Essence, où le coût est pris. Suppose le paiement validé ;
## renvoie les événements des Sources.
static func pay_cost(
	state: DuelState, side: DuelState.PlayerSide, payment: EssencePayment, cost: int
) -> Array[DuelEvent]:
	var events: Array[DuelEvent] = []
	apply_payment(state, side, payment, events)
	state.get_player(side).essence_reserve -= cost
	return events


## 204.5.7a, 203.1.3 : l'Essence que la réserve du joueur actif contient encore est perdue.
static func lose_reserve(state: DuelState, events: Array[DuelEvent]) -> void:
	var player := state.get_player(state.active_player)
	if player.essence_reserve == 0:
		return
	events.append(EssenceLost.new(state.active_player, player.essence_reserve))
	player.essence_reserve = 0


static func _validate_sources(
	state: DuelState, player: PlayerState, payment: EssencePayment
) -> IntentRejected.RejectReason:
	if payment.incline_count > player.sources_upright:
		return IntentRejected.RejectReason.NOT_ENOUGH_UPRIGHT_SOURCES
	# 203.2.6 : les Sources inclinées par ce paiement peuvent y être recyclées.
	if payment.recycle_count > player.sources_tilted + payment.incline_count:
		return IntentRejected.RejectReason.NOT_ENOUGH_TILTED_SOURCES
	if not _recycle_limit_allows(state, player, payment.recycle_count):
		return IntentRejected.RejectReason.RECYCLE_LIMIT_REACHED
	return IntentRejected.RejectReason.NONE


## 203.2.1 à 203.2.3, 203.2.6, 203.5.3 : incline puis recycle les Sources de `payment` ; 203.6.5 :
## l'Essence produite s'ajoute à la réserve d'Essence. Suppose le paiement validé.
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
	player.essence_reserve += payment.essence_produced()


# 203.4.2
static func _recycle_limit_allows(
	state: DuelState, player: PlayerState, recycle_count: int
) -> bool:
	var max_recycles := state.config.max_recycles_per_turn
	if max_recycles == DuelConfig.UNLIMITED_RECYCLES:
		return true
	return player.sources_recycled_this_turn + recycle_count <= max_recycles
