class_name DiscardRules
extends RefCounted
## Défausser (212, décision 0057) : l'effet DISCARD_CARDS fait défausser des cartes de la main du
## joueur à qui appartient l'entrée qui le porte. Le choix des cartes est une attente
## CHOOSE_DISCARD posée pendant la résolution ; `DuelEngine` reprend ensuite la résolution.
##
## Une défausse est l'événement CardDiscardedFromHand (212.2.1, 212.2.4) ; les autres passages à la
## défausse (Spell résolu ou contrecarré, pièce détruite, Gear, carte refusée par la main pleine)
## restent des CardDiscarded (212.2.2 à 212.2.2d), émis par leurs modules.


## 212.1.1 à 212.1.4, 212.1.6, 212.1.7 ; 200.4.1, 200.4.2 : le joueur de l'entrée défausse
## `amount` cartes de sa main, ou toutes si elle en contient moins ; main vide, l'effet n'a pas
## lieu.
## Quand toutes les cartes de la main sont défaussées, le choix est unique et le moteur le prend
## sans demander (décision 0004) ; sinon l'attente est posée.
static func resolve(context: EffectContext) -> void:
	var side := context.entry.owner
	var hand_ids := _card_ids(context.state.get_player(side).hand)
	var count := mini(context.effect.amount, hand_ids.size())
	if count == 0:
		return
	if count == hand_ids.size():
		var kind := PendingDecision.DecisionKind.CHOOSE_DISCARD
		context.events.append(DecisionResolvedAutomatically.new(side, kind))
		_discard(context.state, side, hand_ids, context.events)
		return
	var decision := PendingDecision.for_resolution(
		PendingDecision.DecisionKind.CHOOSE_DISCARD, context.entry, hand_ids
	)
	decision.required_count = count
	StackRules.request_decision(context.state, decision, context.events)


## 212.1.3, 212.2.3, 212.1.7 : raison du refus de `intent`, ou NONE. Les cartes sont toutes
## choisies en même temps, en nombre exact, dans la main, sans doublon. Pur.
static func validate_choice(state: DuelState, intent: ChooseDiscard) -> IntentRejected.RejectReason:
	var reason := PendingDecision.validate_answer(
		state.pending_decision, PendingDecision.DecisionKind.CHOOSE_DISCARD, intent.player
	)
	if reason != IntentRejected.RejectReason.NONE:
		return reason
	if intent.card_ids.size() != state.pending_decision.required_count:
		return IntentRejected.RejectReason.WRONG_DISCARD_COUNT
	var player := state.get_player(intent.player)
	for card_id: int in intent.card_ids:
		if player.find_card_in_hand(card_id) == null:
			return IntentRejected.RejectReason.CARD_NOT_IN_HAND
		if intent.card_ids.count(card_id) > 1:
			return IntentRejected.RejectReason.DUPLICATE_CARD
	return IntentRejected.RejectReason.NONE


## 212.1.3, 212.2.3, 212.2.4 : les cartes choisies passent de la main à la défausse. La reprise de
## la résolution suit, par DuelEngine. Suppose l'intention validée.
static func apply_choice(state: DuelState, intent: ChooseDiscard, events: Array[DuelEvent]) -> void:
	state.pending_decision = null
	_discard(state, intent.player, intent.card_ids, events)


## 209.4.7c, 209.4.13 : le temps de réponse est écoulé, les cartes sont tirées au sort parmi la main
## par `state.rng` (mélange partiel de Fisher-Yates). Suppose l'attente CHOOSE_DISCARD.
static func discard_at_random(state: DuelState, events: Array[DuelEvent]) -> void:
	var decision := state.pending_decision
	var side := decision.awaited_players[0]
	var pool := _card_ids(state.get_player(side).hand)
	var chosen: Array[int] = []
	for rank: int in decision.required_count:
		var picked := state.rng.randi_range(rank, pool.size() - 1)
		var card_id := pool[picked]
		pool[picked] = pool[rank]
		pool[rank] = card_id
		chosen.append(card_id)
	apply_choice(state, ChooseDiscard.new(side, chosen), events)


# 212.1.1, 212.2.1, 212.2.4 : un événement par carte, dans l'ordre du choix, chacun déclenchant les
# effets « quand vous défaussez une carte » ; 212.2.5 : « une fois par tour » ne les ajoute qu'une
# fois à la pile (TriggerRules).
static func _discard(
	state: DuelState, side: DuelState.PlayerSide, card_ids: Array[int], events: Array[DuelEvent]
) -> void:
	var player := state.get_player(side)
	for card_id: int in card_ids:
		var card := player.find_card_in_hand(card_id)
		player.hand.erase(card)
		player.discard.append(card)
		events.append(CardDiscardedFromHand.new(side, card_id))
		var trigger_event := EffectDefinition.TriggerEvent.OWN_CARD_DISCARDED
		TriggerRules.trigger_for_player(state, side, trigger_event, events)


static func _card_ids(cards: Array[CardInstance]) -> Array[int]:
	var identifiers: Array[int] = []
	for card: CardInstance in cards:
		identifiers.append(card.card_instance_id)
	return identifiers
