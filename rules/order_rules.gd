class_name OrderRules
extends RefCounted
## Ordre du Hero (211, décision 0055) : annonce et résolution. Le paiement passe par EssenceRules,
## la vitesse par StackRules, les cibles et les effets par EffectRules ; ce module n'est appelé
## que par DuelEngine.


## 208.1.12, 204.4.8, 211.2.1, 211.2.4 à 211.2.7, 211.3.1, 211.4.1, 211.4.2, 202.3.19, 202.3.21 :
## raison du refus de `intent`, ou NONE. L'attente est contrôlée par DuelEngine. Pur.
static func validate_announce(
	state: DuelState, intent: AnnounceOrder
) -> IntentRejected.RejectReason:
	var order := find_order(state, intent.player, intent.order_index)
	if order == null:
		return IntentRejected.RejectReason.ORDER_NOT_FOUND
	var reason := StackRules.validate_speed(state, intent.player, order.speed)
	if reason != IntentRejected.RejectReason.NONE:
		return reason
	if state.find_hero(intent.player).is_asleep():
		return IntentRejected.RejectReason.PIECE_ASLEEP
	reason = EssenceRules.validate_payment(state, intent.player, intent.payment, order.cost)
	if reason != IntentRejected.RejectReason.NONE:
		return reason
	return EffectRules.validate_announced_targets(state, _make_entry(state, intent), order.effects)


## 211.2.2, 211.2.3, 211.3.1, 211.4.1, 208.1.12, 208.7.17 : le Hero s'endort dès l'annonce, sans
## que ce soit un coût ; le coût se paie, puis l'Ordre va sur la pile avec ses cibles, et chacun
## peut y répondre. Suppose l'intention validée.
static func apply_announce(
	state: DuelState, intent: AnnounceOrder, events: Array[DuelEvent]
) -> void:
	var hero := state.find_hero(intent.player)
	var order := find_order(state, intent.player, intent.order_index)
	hero.is_awake = false
	events.append_array(EssenceRules.pay_cost(state, intent.player, intent.payment, order.cost))
	events.append(OrderAnnounced.new(intent.player, hero.piece_id, intent.order_index))
	StackRules.add_to_stack(state, _make_entry(state, intent), events)


## 211.2.8, 211.3.2, 208.3.2 : l'Ordre se résout comme un Spell, par ses effets ; l'Essence payée
## reste dépensée, même si l'Ordre n'a pas lieu. Aucune carte ne va en défausse (211.1.4).
static func resolve_order(state: DuelState, entry: StackEntry, events: Array[DuelEvent]) -> void:
	var hero := state.catalog.get_hero(entry.source_definition_id)
	EffectRules.resolve_all(state, entry, hero.orders[entry.effect_index].effects, events)


## 202.3.21 : nombre d'Ordres du Hero de `side`, 0 si le Hero n'existe pas. Pur.
static func order_count(state: DuelState, side: DuelState.PlayerSide) -> int:
	var definition := _hero_definition(state, side)
	return 0 if definition == null else definition.orders.size()


## 202.3.19, 202.3.21 : l'Ordre de rang `order_index` du Hero de `side`, ou null si le Hero ou cet
## Ordre n'existe pas. Pur.
static func find_order(state: DuelState, side: DuelState.PlayerSide, order_index: int) -> HeroOrder:
	if order_index < 0 or order_index >= order_count(state, side):
		return null
	return _hero_definition(state, side).orders[order_index]


static func _hero_definition(state: DuelState, side: DuelState.PlayerSide) -> HeroDefinition:
	var hero := state.find_hero(side)
	return null if hero == null else state.catalog.get_hero(hero.card.definition_id)


# 211.2.8, 208.7.17 : l'entrée appartient au joueur dont le Hero porte l'Ordre, avec ses cibles
# choisies à l'annonce (211.4.1) ; elle reçoit des réponses.
static func _make_entry(state: DuelState, intent: AnnounceOrder) -> StackEntry:
	var hero := state.find_hero(intent.player)
	var entry := StackEntry.new()
	entry.kind = StackEntry.StackEntryKind.ORDER
	entry.owner = intent.player
	entry.source_piece_id = hero.piece_id
	entry.source_card_instance_id = hero.card.card_instance_id
	entry.source_definition_id = hero.card.definition_id
	entry.effect_index = intent.order_index
	return entry.with_targets(
		intent.target_piece_ids, intent.target_cells, intent.target_stack_entry_ids
	)
