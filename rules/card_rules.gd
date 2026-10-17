class_name CardRules
extends RefCounted
## Cartes (202) : Gear (annonce, attachement, remplacement) et pouvoir du Hero. Les jetons se
## créent par EffectRules (202.4), les effets statiques se lisent dans ForceRules (207.2).


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
	return EssenceRules.validate_payment(state, intent.player, intent.payment, definition.cost)


## 203.3.2, 201.3.8, 202.2.22, 208.4.1 : paie le coût ; le Gear quitte la main pour la pile
## avec l'Unit choisie. Suppose l'intention validée.
static func announce_gear(state: DuelState, intent: AttachGear, events: Array[DuelEvent]) -> void:
	EssenceRules.apply_payment(state, intent.player, intent.payment, events)
	var player := state.get_player(intent.player)
	var card := player.find_card_in_hand(intent.card_instance_id)
	player.hand.erase(card)
	events.append(GearAnnounced.new(intent.player, card.card_instance_id, intent.unit_piece_id))
	var entry := StackEntry.new()
	entry.kind = StackEntry.StackEntryKind.ATTACH_GEAR
	entry.owner = intent.player
	entry.card = card
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


## 202.3.14 à 202.3.17, 208.1.4, 203.3.2, 207.5.1, 207.5.17 : raison du refus de `intent`, ou
## NONE. L'attente est contrôlée par DuelEngine. Pur.
static func validate_hero_power(
	state: DuelState, intent: UseHeroPower
) -> IntentRejected.RejectReason:
	var reason := StackRules.validate_main_phase_with_empty_stack(state, intent.player)
	if reason != IntentRejected.RejectReason.NONE:
		return reason
	if state.get_player(intent.player).hero_power_used_this_turn:
		return IntentRejected.RejectReason.HERO_POWER_ALREADY_USED
	var hero := _hero_definition(state, intent.player)
	reason = EssenceRules.validate_payment(state, intent.player, intent.payment, hero.power_cost)
	if reason != IntentRejected.RejectReason.NONE:
		return reason
	return _validate_power_targets(state, _make_power_entry(state, intent), hero)


## 202.3.17, 203.3.2, 208.4.1 : l'utilisation compte pour 202.3.14 dès l'annonce ; le coût est
## payé et l'entrée va sur la pile avec ses cibles. Suppose l'intention validée.
static func announce_hero_power(
	state: DuelState, intent: UseHeroPower, events: Array[DuelEvent]
) -> void:
	state.get_player(intent.player).hero_power_used_this_turn = true
	EssenceRules.apply_payment(state, intent.player, intent.payment, events)
	events.append(HeroPowerAnnounced.new(intent.player))
	StackRules.add_to_stack(state, _make_power_entry(state, intent), events)


## 202.3.12, 208.3.2 : applique les effets du pouvoir ; 207.5.17a : sans cible, il n'a pas lieu.
static func resolve_hero_power(
	state: DuelState, entry: StackEntry, events: Array[DuelEvent]
) -> void:
	for effect: EffectDefinition in _hero_definition(state, entry.owner).power:
		if effect.timing == EffectDefinition.EffectTiming.RESOLVE:
			EffectRules.resolve_effect(state, entry, effect, events)
		if state.is_ended():
			return


# 202.2.8, 202.2.9, 202.2.14, 202.4.5a, 202.2.23 : une Unit alliée en jeu, jeton compris.
static func _is_valid_gear_unit(state: DuelState, side: DuelState.PlayerSide, unit_id: int) -> bool:
	var unit := state.find_piece(unit_id)
	return unit != null and EffectRules.is_legal_piece(state, side, _gear_target(), unit)


static func _gear_target() -> TargetSpec:
	var spec := TargetSpec.new()
	spec.what = TargetSpec.TargetWhat.PIECE
	spec.side = TargetSpec.TargetSide.ALLY
	spec.piece_kinds.append(Piece.PieceKind.UNIT)
	return spec


# 207.5.17 : sans aucune cible légale, le pouvoir s'annonce sans cible ; sinon 207.5.1, 207.5.10.
static func _validate_power_targets(
	state: DuelState, entry: StackEntry, hero: HeroDefinition
) -> IntentRejected.RejectReason:
	for effect: EffectDefinition in hero.power:
		if effect.target == null:
			continue
		var none_legal := EffectRules.legal_target_count(state, entry.owner, effect.target) == 0
		if none_legal and EffectRules.chosen_count(entry, effect.target) == 0:
			continue
		var reason := EffectRules.validate_targets(state, entry, effect.target)
		if reason != IntentRejected.RejectReason.NONE:
			return reason
	return EffectRules.validate_no_extra_targets(entry, hero.power)


static func _make_power_entry(state: DuelState, intent: UseHeroPower) -> StackEntry:
	var entry := StackEntry.new()
	entry.kind = StackEntry.StackEntryKind.HERO_POWER
	entry.owner = intent.player
	entry.source_piece_id = state.find_hero(intent.player).piece_id
	entry.target_piece_ids.assign(intent.target_piece_ids)
	entry.target_cells.assign(intent.target_cells)
	entry.target_stack_entry_ids.assign(intent.target_stack_entry_ids)
	return entry


# 202.3.4, 202.3.13 : la carte Hero porte le coût et les effets du pouvoir.
static func _hero_definition(state: DuelState, side: DuelState.PlayerSide) -> HeroDefinition:
	return state.catalog.get_hero(state.find_hero(side).card.definition_id)
