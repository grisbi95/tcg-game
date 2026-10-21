class_name SpellRules
extends RefCounted
## Spells (207.1) : vitesses, annonce, résolution. Les cibles et l'application des effets sont
## dans EffectRules (207.4, 207.5), qui n'appelle jamais ce module ; Contrecarrer (207.6) reste
## avec l'effet COUNTER dans EffectRules.


## 207.1.3 à 207.1.6, 208.1.3, 208.2.3, 203.3.2, 207.5.1a, 207.5.8 : raison du refus de
## `intent`, ou NONE. L'attente est contrôlée par DuelEngine. Pur.
static func validate_cast(state: DuelState, intent: CastSpell) -> IntentRejected.RejectReason:
	var card := state.get_player(intent.player).find_card_in_hand(intent.card_instance_id)
	if card == null:
		return IntentRejected.RejectReason.CARD_NOT_IN_HAND
	var definition := state.catalog.get_card(card.definition_id)
	if definition.card_type != CardDefinition.CardType.SPELL:
		return IntentRejected.RejectReason.NOT_A_SPELL
	var reason := _validate_speed(state, intent.player, definition.speed)
	if reason != IntentRejected.RejectReason.NONE:
		return reason
	reason = EssenceRules.validate_payment(state, intent.player, intent.payment, definition.cost)
	if reason != IntentRejected.RejectReason.NONE:
		return reason
	return _validate_effect_targets(state, _make_spell_entry(intent, card), definition)


## 203.3.2, 203.3.2a, 201.3.8, 207.5.1a, 208.4.1 : paie le coût ; la carte quitte la main pour
## la pile avec ses cibles. Suppose l'intention validée.
static func announce_spell(state: DuelState, intent: CastSpell, events: Array[DuelEvent]) -> void:
	var player := state.get_player(intent.player)
	var card := player.find_card_in_hand(intent.card_instance_id)
	var cost := state.catalog.get_card(card.definition_id).cost
	events.append_array(EssenceRules.pay_cost(state, intent.player, intent.payment, cost))
	player.hand.erase(card)
	events.append(SpellAnnounced.new(intent.player, card.card_instance_id))
	StackRules.add_to_stack(state, _make_spell_entry(intent, card), events)


## 202.2.20, 208.3.2 : le Spell se résout une fois ; 207.1.7, 207.1.7a : sa carte va ensuite
## dans la défausse de son joueur, que son effet ait eu lieu ou non. Si la partie s'arrête
## pendant ses effets (209.2.2), la carte ne bouge plus.
static func resolve_spell(state: DuelState, entry: StackEntry, events: Array[DuelEvent]) -> void:
	var definition := state.catalog.get_card(entry.card.definition_id)
	for effect: EffectDefinition in definition.effects:
		if effect.timing == EffectDefinition.EffectTiming.RESOLVE:
			EffectRules.resolve_effect(state, entry, effect, events)
		if state.is_ended():
			return
	state.get_player(entry.card.owner).discard.append(entry.card)
	events.append(CardDiscarded.new(entry.card.owner, entry.card.card_instance_id))


# 207.1.3, 207.1.4 : Action pendant sa phase principale, pile vide ; 207.1.5, 207.1.6, 208.2.3 :
# Réaction aussi, et chaque fois qu'il peut répondre.
static func _validate_speed(
	state: DuelState, side: DuelState.PlayerSide, speed: CardDefinition.SpellSpeed
) -> IntentRejected.RejectReason:
	var responding := not state.stack.is_empty()
	if responding and speed == CardDefinition.SpellSpeed.REACTION:
		if side != state.priority_player:
			return IntentRejected.RejectReason.NOT_YOUR_PRIORITY
		return IntentRejected.RejectReason.NONE
	if state.phase != DuelState.DuelPhase.MAIN:
		return IntentRejected.RejectReason.WRONG_PHASE
	if side != state.active_player:
		return IntentRejected.RejectReason.NOT_YOUR_TURN
	if responding:
		return IntentRejected.RejectReason.STACK_NOT_EMPTY
	return IntentRejected.RejectReason.NONE


# 207.5.1a : chaque effet qui passe par la pile juge les cibles de son genre.
static func _validate_effect_targets(
	state: DuelState, entry: StackEntry, definition: CardDefinition
) -> IntentRejected.RejectReason:
	for effect: EffectDefinition in definition.effects:
		if effect.target == null:
			continue
		var reason := EffectRules.validate_targets(state, entry, effect.target)
		if reason != IntentRejected.RejectReason.NONE:
			return reason
	return EffectRules.validate_no_extra_targets(entry, definition.effects)


# 207.5.1a : l'entrée porte les cibles choisies à l'annonce.
static func _make_spell_entry(intent: CastSpell, card: CardInstance) -> StackEntry:
	var entry := StackEntry.new()
	entry.kind = StackEntry.StackEntryKind.SPELL
	entry.owner = intent.player
	entry.card = card
	entry.target_piece_ids.assign(intent.target_piece_ids)
	entry.target_cells.assign(intent.target_cells)
	entry.target_stack_entry_ids.assign(intent.target_stack_entry_ids)
	return entry
