class_name CardRules
extends RefCounted
## Cartes (202) : Gear (annonce, attachement, remplacement) et création des jetons (202.4), que
## EffectRules appelle ; les effets statiques se lisent dans ModifierRules (207.2), les coûts
## dans ValueRules.


## 202.2.22, 202.2.23, 207.5.1a, 205.1.5 : un Gear (son Unit) et un Spell s'annoncent avec une
## cible choisie à l'annonce ; une Unit et un Building s'annoncent avec une case. Pur.
static func is_announced_with_target(definition: CardDefinition) -> bool:
	return (
		definition.card_type == CardDefinition.CardType.SPELL
		or definition.card_type == CardDefinition.CardType.GEAR
	)


## 208.1.5 à 208.1.7, 202.2.8, 202.2.9, 202.2.14, 202.2.22, 202.2.23, 203.3.2 : raison du refus
## de `intent`, ou NONE. L'attente est contrôlée par DuelEngine. Pur.
static func validate_attach_gear(
	state: DuelState, intent: AttachGear
) -> IntentRejected.RejectReason:
	var reason := StackRules.validate_main_phase_with_empty_stack(state, intent.player)
	if reason != IntentRejected.RejectReason.NONE:
		return reason
	var card := state.get_player(intent.player).find_card_in_hand(intent.card_instance_id)
	if card == null:
		return IntentRejected.RejectReason.CARD_NOT_IN_HAND
	var definition := state.catalog.get_card(card.definition_id)
	if definition.card_type != CardDefinition.CardType.GEAR:
		return IntentRejected.RejectReason.NOT_A_GEAR
	if not _is_valid_gear_unit(state, intent.player, intent.unit_piece_id):
		return IntentRejected.RejectReason.ILLEGAL_TARGET
	return EssenceRules.validate_payment(
		state, intent.player, intent.payment, ValueRules.current_cost(definition)
	)


## 203.3.2, 203.3.2a, 201.3.8, 202.2.22, 208.4.1, 208.7.6 : paie le coût ; le Gear quitte la main
## pour la pile avec l'Unit choisie. Suppose l'intention validée.
static func announce_gear(state: DuelState, intent: AttachGear, events: Array[DuelEvent]) -> void:
	var player := state.get_player(intent.player)
	var card := player.find_card_in_hand(intent.card_instance_id)
	var cost := ValueRules.current_cost(state.catalog.get_card(card.definition_id))
	events.append_array(EssenceRules.pay_cost(state, intent.player, intent.payment, cost))
	player.hand.erase(card)
	events.append(GearAnnounced.new(intent.player, card.card_instance_id, intent.unit_piece_id))
	var entry := StackEntry.new()
	entry.kind = StackEntry.StackEntryKind.ATTACH_GEAR
	entry.owner = intent.player
	entry.card = card
	entry.allows_response = false  # 208.7.6
	entry.target_piece_ids.append(intent.unit_piece_id)
	StackRules.add_to_stack(state, entry, events)


## 202.2.10 à 202.2.12, 207.2.3a : le Gear s'attache, en remplaçant celui que l'Unit portait ;
## 202.2.24 à 202.2.24c : si l'Unit n'est plus une cible valide, il revient dans la main.
static func resolve_attach_gear(
	state: DuelState, entry: StackEntry, events: Array[DuelEvent]
) -> void:
	var unit_id := entry.target_piece_ids[0]
	if not _is_valid_gear_unit(state, entry.owner, unit_id):
		ZoneRules.return_card_to_hand(state, entry.card, events)
		return
	var unit := state.find_piece(unit_id)
	if unit.attached_gear != null:
		var replaced := unit.attached_gear
		state.get_player(replaced.owner).discard.append(replaced)
		events.append(CardDiscarded.new(replaced.owner, replaced.card_instance_id))
	unit.attached_gear = entry.card
	events.append(GearAttached.new(entry.owner, entry.card.card_instance_id, unit_id))


# 202.2.8, 202.2.9, 202.2.14, 202.4.5a, 202.2.23 : une Unit alliée en jeu, jeton compris.
static func _is_valid_gear_unit(state: DuelState, side: DuelState.PlayerSide, unit_id: int) -> bool:
	var unit := state.find_piece(unit_id)
	return unit != null and EffectRules.is_legal_piece(state, side, _gear_target(), unit)


static func _gear_target() -> TargetSpec:
	var spec := TargetSpec.new()
	spec.what = TargetSpec.TargetWhat.PIECE
	spec.piece_filter.side = PieceFilter.SideFilter.ALLY
	spec.piece_filter.piece_kinds.append(Piece.PieceKind.UNIT)
	return spec


## 202.4.1, 202.4.8, 202.4.9, 202.4.12 ; 201.5.4, 201.5.4a : le jeton appartient au joueur de
## l'entrée qui le crée ; 205.5.4a : il naît endormi (`is_awake` reste faux).
static func create_token(context: EffectContext, cell: Vector2i) -> void:
	var token := Piece.new()
	token.piece_id = context.state.allocate_piece_id()
	token.kind = context.effect.token_piece_kind
	token.owner = context.entry.owner
	token.cell = cell
	token.token_force = context.effect.token_force
	context.state.pieces.append(token)
	context.events.append(TokenCreated.new(token.owner, token.piece_id, cell))
