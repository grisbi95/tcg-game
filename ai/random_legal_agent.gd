class_name RandomLegalAgent
extends DuelAgent
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

	## Copie ces cibles dans les tableaux de l'intention.
	func copy_into(
		target_piece_ids: Array[int],
		target_cells: Array[Vector2i],
		target_stack_entry_ids: Array[int]
	) -> void:
		target_piece_ids.assign(piece_ids)
		target_cells.assign(cells)
		target_stack_entry_ids.assign(stack_entry_ids)


var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init(rng_seed: int) -> void:
	_rng.seed = rng_seed


## Une intention légale du joueur que le moteur attend (le premier des joueurs attendus, 209.4.4),
## tirée au hasard ; null si le duel ne demande rien ou si aucune candidate n'est légale.
func choose_intent(engine: DuelEngine) -> DuelIntent:
	var owners := engine.awaited_players()
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
	intents.append_array(_order_candidates(state, side))
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
			return _choose_targets_candidates(state, decision, side)
	return []


static func _mulligan_candidates(state: DuelState, side: DuelState.PlayerSide) -> Array[DuelIntent]:
	var intents: Array[DuelIntent] = [ChooseMulligan.new(side)]
	for card: CardInstance in state.get_player(side).hand:
		var set_aside: Array[int] = [card.card_instance_id]
		intents.append(ChooseMulligan.new(side, set_aside))
	return intents


static func _choose_targets_candidates(
	state: DuelState, decision: PendingDecision, side: DuelState.PlayerSide
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
	intents.append_array(_two_target_choices(state, decision, side))
	return intents


# Décision 0056 : un effet à deux cibles (échange, ou pièce et case de destination) se répond en
# une seule intention ; sans un tel effet en attente, ces choix ne valent rien et ne se fabriquent
# pas. Le moteur juge les paires et les cases qui ne conviennent pas.
static func _two_target_choices(
	state: DuelState, decision: PendingDecision, side: DuelState.PlayerSide
) -> Array[DuelIntent]:
	var intents: Array[DuelIntent] = []
	var effect := _awaited_effect(state, decision)
	if effect == null:
		return intents
	for first_index: int in decision.candidate_ids.size():
		if effect.target.count_max > 1:
			for second_id: int in decision.candidate_ids.slice(first_index + 1):
				var pair := ChooseTargets.new(side)
				pair.target_piece_ids.assign([decision.candidate_ids[first_index], second_id])
				intents.append(pair)
		if effect.destination != null:
			for cell: Vector2i in decision.candidate_cells:
				var moved := ChooseTargets.new(side)
				moved.target_piece_ids.append(decision.candidate_ids[first_index])
				moved.target_cells.append(cell)
				intents.append(moved)
	return intents


static func _awaited_effect(state: DuelState, decision: PendingDecision) -> EffectDefinition:
	for entry: StackEntry in state.triggers_to_add:
		if entry.stack_entry_id == decision.subject_stack_entry_id:
			return TriggerRules.effect_of(state, entry)
	return null


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
	var definition := state.catalog.get_card(card.definition_id)
	for variant: TargetVariant in _target_variants(state, definition.effects):
		var cast := CastSpell.new(side, card.card_instance_id, payment)
		variant.copy_into(cast.target_piece_ids, cast.target_cells, cast.target_stack_entry_ids)
		intents.append(cast)
	return intents


static func _order_candidates(state: DuelState, side: DuelState.PlayerSide) -> Array[DuelIntent]:
	var intents: Array[DuelIntent] = []
	for index: int in OrderRules.order_count(state, side):
		var hero_order := OrderRules.find_order(state, side, index)
		var payment := simple_payment(state, side, hero_order.cost)
		for variant: TargetVariant in _target_variants(state, hero_order.effects):
			var order := AnnounceOrder.new(side, index, payment)
			variant.copy_into(
				order.target_piece_ids, order.target_cells, order.target_stack_entry_ids
			)
			intents.append(order)
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


## Décisions 0003 et 0026 : paiement de `cost` qui prend d'abord la réserve d'Essence (203.3.2a),
## puis incline, puis recycle le reste.
static func simple_payment(
	state: DuelState, side: DuelState.PlayerSide, cost: int
) -> EssencePayment:
	var to_produce := EssenceRules.essence_still_needed(state, side, cost)
	var inclined := mini(to_produce, state.get_player(side).sources_upright)
	return EssencePayment.new(inclined, to_produce - inclined)


static func _target_variants(
	state: DuelState, effects: Array[EffectDefinition]
) -> Array[TargetVariant]:
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
	variants.append_array(_two_target_variants(state, effects))
	return variants


# Décision 0056 : une paire de pièces pour un effet à deux cibles, une pièce et une case libre pour
# un effet à destination ; sans eux, ces variantes ne valent rien et ne se fabriquent pas.
static func _two_target_variants(
	state: DuelState, effects: Array[EffectDefinition]
) -> Array[TargetVariant]:
	var variants: Array[TargetVariant] = []
	for effect: EffectDefinition in effects:
		if effect.destination != null:
			variants.append_array(_piece_and_cell_variants(state))
		elif effect.target != null and effect.target.count_max > 1:
			variants.append_array(_piece_pair_variants(state))
	return variants


static func _piece_and_cell_variants(state: DuelState) -> Array[TargetVariant]:
	var variants: Array[TargetVariant] = []
	for piece: Piece in state.pieces:
		for cell: Vector2i in BoardGeometry.all_cells():
			if state.piece_at(cell) == null:
				var moved := TargetVariant.new()
				moved.piece_ids.append(piece.piece_id)
				moved.cells.append(cell)
				variants.append(moved)
	return variants


static func _piece_pair_variants(state: DuelState) -> Array[TargetVariant]:
	var variants: Array[TargetVariant] = []
	for first_index: int in state.pieces.size():
		for second: Piece in state.pieces.slice(first_index + 1):
			var pair := TargetVariant.new()
			pair.piece_ids.assign([state.pieces[first_index].piece_id, second.piece_id])
			variants.append(pair)
	return variants
