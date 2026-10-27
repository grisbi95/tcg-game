class_name LookRules
extends RefCounted
## Regarder le dessus du deck (217, décision 0057) : l'effet LOOK_AT_TOP_CARD fait regarder au
## joueur à qui appartient l'entrée la carte du dessus de son deck, puis choisir de la laisser ou
## de la mettre sous son deck. Le choix est une attente CHOOSE_TOP_CARD_PLACE posée pendant la
## résolution ; `DuelEngine` reprend ensuite la résolution. Le moteur est omniscient (0043) : la vue
## cache la carte à l'adversaire (201.4.1a, 217.1.5).


## 217.1.1, 217.1.2, 217.1.7 ; 200.4.1 : le joueur de l'entrée regarde la carte du dessus de son
## deck (le dernier élément, 201.3.1) ; deck vide, l'effet n'a pas lieu.
static func resolve(context: EffectContext) -> void:
	var side := context.entry.owner
	var deck := context.state.get_player(side).deck
	if deck.is_empty():
		return
	context.took_place = true
	var top_card: CardInstance = deck.back()
	var top_card_id := top_card.card_instance_id
	context.events.append(TopCardLooked.new(side, top_card_id))
	var decision := PendingDecision.for_resolution(
		PendingDecision.DecisionKind.CHOOSE_TOP_CARD_PLACE, context.entry, [top_card_id]
	)
	StackRules.request_decision(context.state, decision, context.events)


## 217.1.2, 217.1.3, 217.1.6 : raison du refus de `intent`, ou NONE. Le choix n'est pas une cible.
## Pur.
static func validate_choice(
	state: DuelState, intent: ChooseTopCardPlace
) -> IntentRejected.RejectReason:
	var reason := PendingDecision.validate_answer(
		state.pending_decision, PendingDecision.DecisionKind.CHOOSE_TOP_CARD_PLACE, intent.player
	)
	if reason != IntentRejected.RejectReason.NONE:
		return reason
	if not ChooseTopCardPlace.TopCardPlace.values().has(intent.place):
		return IntentRejected.RejectReason.UNKNOWN_CARD_PLACE
	return IntentRejected.RejectReason.NONE


## 217.1.2, 217.1.3, 217.1.4 : la carte reste au dessus ou passe sous le deck (son premier élément).
## La reprise de la résolution suit, par DuelEngine. Suppose l'intention validée.
static func apply_choice(
	state: DuelState, intent: ChooseTopCardPlace, events: Array[DuelEvent]
) -> void:
	state.pending_decision = null
	if intent.place == ChooseTopCardPlace.TopCardPlace.BELOW:
		var deck := state.get_player(intent.player).deck
		deck.push_front(deck.pop_back())
	events.append(TopCardPlaceChosen.new(intent.player, intent.place))


## 209.4.7d, 209.4.14 : le temps de réponse est écoulé, dessus ou dessous est tiré au sort par
## `state.rng`. Suppose l'attente CHOOSE_TOP_CARD_PLACE.
static func place_at_random(state: DuelState, events: Array[DuelEvent]) -> void:
	var side := state.pending_decision.awaited_players[0]
	var places := ChooseTopCardPlace.TopCardPlace.values()
	var place: ChooseTopCardPlace.TopCardPlace = places[state.rng.randi_range(0, places.size() - 1)]
	apply_choice(state, ChooseTopCardPlace.new(side, place), events)
