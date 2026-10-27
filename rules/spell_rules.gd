class_name SpellRules
extends RefCounted
## Spells (207.1) : vitesses, annonce, résolution. L'application des effets et la suite d'effets du
## texte sont dans EffectRules (207.4, 207.7), les cibles de l'annonce dans TriggerTargets
## (207.5.1a) ; ni l'un ni l'autre n'appelle ce module. Contrecarrer (207.6) reste avec l'effet
## COUNTER dans EffectRules.


## 207.1.3 à 207.1.6, 208.1.3, 208.2.3, 203.3.2, 207.5.1a, 207.5.8, 213.1.3 à 213.1.5, 213.1.9 :
## raison du refus de `intent`, ou NONE. L'attente est contrôlée par DuelEngine. Pur.
static func validate_cast(state: DuelState, intent: CastSpell) -> IntentRejected.RejectReason:
	var card := state.get_player(intent.player).find_card_in_hand(intent.card_instance_id)
	if card == null:
		return IntentRejected.RejectReason.CARD_NOT_IN_HAND
	var definition := state.catalog.get_card(card.definition_id)
	if definition.card_type != CardDefinition.CardType.SPELL:
		return IntentRejected.RejectReason.NOT_A_SPELL
	var reason := StackRules.validate_speed(state, intent.player, definition.speed)
	if reason != IntentRejected.RejectReason.NONE:
		return reason
	reason = ValueRules.validate_x_value(definition, intent.x_value)
	if reason != IntentRejected.RejectReason.NONE:
		return reason
	var entry := _make_spell_entry(intent, card)
	var cost := ValueRules.current_cost(definition, entry)
	reason = EssenceRules.validate_payment(state, intent.player, intent.payment, cost)
	if reason != IntentRejected.RejectReason.NONE:
		return reason
	return TriggerTargets.validate_announced_targets(
		state, entry, EffectText.effects_of(EffectText.resolution_of(definition.texts))
	)


## 203.3.2, 203.3.2a, 201.3.8, 207.5.1a, 208.4.1, 208.7.1, 213.1.5 : paie le coût (X Essence pour un
## coût X) ; la carte quitte la main pour la pile avec ses cibles et la valeur de X. 208.4.4,
## 208.7.10 : les effets que déclenche l'annonce attendent leur ajout juste après et peuvent
## recevoir une réponse. Suppose l'intention validée.
static func announce_spell(state: DuelState, intent: CastSpell, events: Array[DuelEvent]) -> void:
	var player := state.get_player(intent.player)
	var card := player.find_card_in_hand(intent.card_instance_id)
	var entry := _make_spell_entry(intent, card)
	var cost := ValueRules.current_cost(state.catalog.get_card(card.definition_id), entry)
	events.append_array(EssenceRules.pay_cost(state, intent.player, intent.payment, cost))
	player.hand.erase(card)
	events.append(SpellAnnounced.new(intent.player, card.card_instance_id))
	StackRules.add_to_stack(state, entry, events)
	TriggerRules.trigger_spell_announced(state, entry, events)  # 208.4.4


## 202.2.20, 208.3.2 : le Spell se résout une fois ; 207.1.7, 207.1.7a, 207.7.8 : sa carte va
## ensuite dans la défausse de son joueur, que son effet ait eu lieu ou non, une condition « si »
## fausse comprise. Si la partie s'arrête pendant ses effets (209.2.2), la carte ne bouge plus.
## Décision 0057 : un effet qui attend un choix suspend la résolution, la carte reste sur l'entrée ;
## la reprise rappelle cette fonction.
static func resolve_spell(state: DuelState, entry: StackEntry, events: Array[DuelEvent]) -> void:
	var definition := state.catalog.get_card(entry.card.definition_id)
	EffectRules.resolve_text(state, entry, EffectText.resolution_of(definition.texts), events)
	if state.is_ended() or state.pending_decision != null:
		return
	state.get_player(entry.card.owner).discard.append(entry.card)
	events.append(CardDiscarded.new(entry.card.owner, entry.card.card_instance_id))


# 207.5.1a, 213.1.8 : l'entrée porte les cibles et la valeur de X choisies à l'annonce.
static func _make_spell_entry(intent: CastSpell, card: CardInstance) -> StackEntry:
	var entry := StackEntry.new()
	entry.kind = StackEntry.StackEntryKind.SPELL
	entry.owner = intent.player
	entry.card = card
	entry.x_value = intent.x_value
	return entry.with_targets(
		intent.target_piece_ids, intent.target_cells, intent.target_stack_entry_ids
	)
