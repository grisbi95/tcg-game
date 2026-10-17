class_name RandomLegalAgent
extends RefCounted
## Agent qui joue une intention légale au hasard (décision 0019) : il fabrique des intentions
## candidates à partir de l'état, ne garde que celles que `DuelEngine.validate()` accepte, et en
## tire une par sa propre graine.
##
## Aucune règle ici : le moteur seul juge. L'agent ne prétend pas énumérer tous les coups
## légaux ; il ne propose ni l'abandon ni les paiements inhabituels.


## Cibles d'une candidate : aucune, une pièce, une case ou une entrée de la pile.
class TargetVariant:
	extends RefCounted
	var piece_ids: Array[int] = []
	var cells: Array[Vector2i] = []
	var stack_entry_ids: Array[int] = []


var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init(rng_seed: int) -> void:
	_rng.seed = rng_seed


## Une intention légale du joueur que le moteur attend (le premier dont la pendule tourne, 209.4.4),
## tirée au hasard ; null si le duel ne demande rien ou si aucune candidate n'est légale.
func choose_intent(engine: DuelEngine) -> DuelIntent:
	var owners := engine.clock_owners()
	if owners.is_empty():
		return null
	var legal: Array[DuelIntent] = []
	for intent: DuelIntent in candidates(engine.get_state(), owners[0]):
		if engine.validate(intent) == IntentRejected.RejectReason.NONE:
			legal.append(intent)
	if legal.is_empty():
		return null
	return legal[_rng.randi_range(0, legal.size() - 1)]


## Intentions candidates de `side`, légales ou non.
static func candidates(state: DuelState, side: DuelState.PlayerSide) -> Array[DuelIntent]:
	if state.pending_decision != null:
		return _decision_candidates(state, side)
	var intents: Array[DuelIntent] = [PassPriority.new(side), EndTurn.new(side)]
	intents.append_array(_hand_candidates(state, side))
	intents.append_array(_normal_action_candidates(state, side))
	intents.append_array(_hero_power_candidates(state, side))
	return intents


static func _decision_candidates(state: DuelState, side: DuelState.PlayerSide) -> Array[DuelIntent]:
	var decision := state.pending_decision
	match decision.kind:
		PendingDecision.DecisionKind.MULLIGAN:
			return _mulligan_candidates(state, side)
		PendingDecision.DecisionKind.ORDER_TRIGGERS:
			var reversed := decision.candidate_ids.duplicate()
			reversed.reverse()
			return [
				OrderTriggers.new(side, decision.candidate_ids), OrderTriggers.new(side, reversed)
			]
		PendingDecision.DecisionKind.CHOOSE_TARGETS:
			return _choose_targets_candidates(decision, side)
	return []


static func _mulligan_candidates(state: DuelState, side: DuelState.PlayerSide) -> Array[DuelIntent]:
	var intents: Array[DuelIntent] = [ChooseMulligan.new(side)]
	for card: CardInstance in state.get_player(side).hand:
		var set_aside: Array[int] = [card.card_instance_id]
		intents.append(ChooseMulligan.new(side, set_aside))
	return intents


static func _choose_targets_candidates(
	decision: PendingDecision, side: DuelState.PlayerSide
) -> Array[DuelIntent]:
	var intents: Array[DuelIntent] = []
	for target_id: int in decision.candidate_ids:
		var by_piece := ChooseTargets.new(side)
		by_piece.target_piece_ids.append(target_id)
		var by_entry := ChooseTargets.new(side)
		by_entry.target_stack_entry_ids.append(target_id)
		intents.append_array([by_piece, by_entry])
	for cell: Vector2i in decision.candidate_cells:
		var by_cell := ChooseTargets.new(side)
		by_cell.target_cells.append(cell)
		intents.append(by_cell)
	return intents


static func _hand_candidates(state: DuelState, side: DuelState.PlayerSide) -> Array[DuelIntent]:
	var intents: Array[DuelIntent] = []
	for card: CardInstance in state.get_player(side).hand:
		var definition := state.catalog.get_card(card.definition_id)
		var payment := simple_payment(state, side, definition.cost)
		match definition.card_type:
			CardDefinition.CardType.SPELL:
				intents.append_array(_spell_candidates(state, side, card, payment))
			CardDefinition.CardType.GEAR:
				intents.append_array(_gear_candidates(state, side, card, payment))
			_:
				for cell: Vector2i in BoardGeometry.all_cells():
					intents.append(DeployCard.new(side, card.card_instance_id, cell, payment))
	return intents


static func _spell_candidates(
	state: DuelState, side: DuelState.PlayerSide, card: CardInstance, payment: EssencePayment
) -> Array[DuelIntent]:
	var intents: Array[DuelIntent] = []
	for variant: TargetVariant in _target_variants(state):
		var cast := CastSpell.new(side, card.card_instance_id, payment)
		cast.target_piece_ids.assign(variant.piece_ids)
		cast.target_cells.assign(variant.cells)
		cast.target_stack_entry_ids.assign(variant.stack_entry_ids)
		intents.append(cast)
	return intents


static func _gear_candidates(
	state: DuelState, side: DuelState.PlayerSide, card: CardInstance, payment: EssencePayment
) -> Array[DuelIntent]:
	var intents: Array[DuelIntent] = []
	for piece: Piece in state.pieces:
		intents.append(AttachGear.new(side, card.card_instance_id, piece.piece_id, payment))
	return intents


static func _normal_action_candidates(
	state: DuelState, side: DuelState.PlayerSide
) -> Array[DuelIntent]:
	var intents: Array[DuelIntent] = []
	for piece: Piece in state.pieces:
		if piece.owner != side or not BoardGeometry.is_on_board(piece.cell):
			continue
		for cell: Vector2i in BoardGeometry.adjacent_cells(piece.cell):
			intents.append(TakeNormalAction.new(side, piece.piece_id, cell))
	return intents


static func _hero_power_candidates(
	state: DuelState, side: DuelState.PlayerSide
) -> Array[DuelIntent]:
	var hero := state.find_hero(side)
	var cost := state.catalog.get_hero(hero.card.definition_id).power_cost
	var payment := simple_payment(state, side, cost)
	var intents: Array[DuelIntent] = []
	for variant: TargetVariant in _target_variants(state):
		var power := UseHeroPower.new(side, payment)
		power.target_piece_ids.assign(variant.piece_ids)
		power.target_cells.assign(variant.cells)
		power.target_stack_entry_ids.assign(variant.stack_entry_ids)
		intents.append(power)
	return intents


## Décision 0003 : paiement de `cost` qui incline d'abord, puis recycle le reste.
static func simple_payment(
	state: DuelState, side: DuelState.PlayerSide, cost: int
) -> EssencePayment:
	var inclined := mini(cost, state.get_player(side).sources_upright)
	return EssencePayment.new(inclined, cost - inclined)


static func _target_variants(state: DuelState) -> Array[TargetVariant]:
	var variants: Array[TargetVariant] = [TargetVariant.new()]
	for piece: Piece in state.pieces:
		var by_piece := TargetVariant.new()
		by_piece.piece_ids.append(piece.piece_id)
		variants.append(by_piece)
	for cell: Vector2i in BoardGeometry.all_cells():
		var by_cell := TargetVariant.new()
		by_cell.cells.append(cell)
		variants.append(by_cell)
	for entry: StackEntry in state.stack:
		var by_entry := TargetVariant.new()
		by_entry.stack_entry_ids.append(entry.stack_entry_id)
		variants.append(by_entry)
	return variants
