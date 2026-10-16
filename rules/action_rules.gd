class_name ActionRules
extends RefCounted
## Actions (205) : déploiement à l'étape 1.5, bloc 2 ; action normale et Hero au bloc 3.


## 208.1.1, 208.1.8, 208.1.9, 205.1.2 à 205.1.4, 203.3.2 : raison du refus de `intent`, ou
## NONE. L'attente est contrôlée par DuelEngine. Pur.
static func validate_deploy(state: DuelState, intent: DeployCard) -> IntentRejected.RejectReason:
	var reason := _validate_main_phase_with_empty_stack(state, intent.player)
	if reason != IntentRejected.RejectReason.NONE:
		return reason
	var card := state.get_player(intent.player).find_card_in_hand(intent.card_instance_id)
	if card == null:
		return IntentRejected.RejectReason.CARD_NOT_IN_HAND
	var definition := state.catalog.get_card(card.definition_id)
	if not _is_deployable(definition):
		return IntentRejected.RejectReason.NOT_DEPLOYABLE
	if not _is_in_deploy_zone(definition, intent.player, intent.cell):
		return IntentRejected.RejectReason.CELL_NOT_IN_DEPLOY_ZONE
	if state.piece_at(intent.cell) != null:
		return IntentRejected.RejectReason.CELL_NOT_FREE
	return EssenceRules.validate_payment(state, intent.player, intent.payment, definition.cost)


## 203.3.2, 201.3.8, 205.1.5, 208.4.1 : paie le coût, puis la carte quitte la main pour la
## pile avec sa case. Suppose l'intention validée.
static func announce_deploy(state: DuelState, intent: DeployCard, events: Array[DuelEvent]) -> void:
	EssenceRules.apply_payment(state, intent.player, intent.payment, events)
	var player := state.get_player(intent.player)
	var card := player.find_card_in_hand(intent.card_instance_id)
	player.hand.erase(card)
	events.append(DeployAnnounced.new(intent.player, card.card_instance_id, intent.cell))
	var entry := StackEntry.new()
	entry.kind = StackEntry.StackEntryKind.DEPLOY
	entry.owner = intent.player
	entry.card = card
	entry.target_cells.append(intent.cell)
	StackRules.add_to_stack(state, entry, events)


## 205.1.2 à 205.1.10, 205.4.1 : résout le déploiement `entry` selon le plateau du moment.
static func resolve_deploy(state: DuelState, entry: StackEntry, events: Array[DuelEvent]) -> void:
	var cell := entry.target_cells[0]
	var occupant := state.piece_at(cell)
	var definition := state.catalog.get_card(entry.card.definition_id)
	if occupant == null:
		_deploy_on_free_cell(state, entry.card, definition, cell, events)
	elif definition.card_type == CardDefinition.CardType.UNIT and occupant.owner != entry.owner:
		_enter_attacking(state, entry.card, occupant, events)
	else:
		_return_to_hand(state, entry.card, events)


# 208.1.8, 208.1.9, 208.1.10, 208.1.11 : annonce du joueur actif, phase principale, pile vide.
static func _validate_main_phase_with_empty_stack(
	state: DuelState, side: DuelState.PlayerSide
) -> IntentRejected.RejectReason:
	if state.phase != DuelState.DuelPhase.MAIN:
		return IntentRejected.RejectReason.WRONG_PHASE
	if side != state.active_player:
		return IntentRejected.RejectReason.NOT_YOUR_TURN
	if not state.stack.is_empty():
		return IntentRejected.RejectReason.STACK_NOT_EMPTY
	return IntentRejected.RejectReason.NONE


# 202.2.2, 202.2.3, 202.2.5, 202.2.7 : seules les Units et les Buildings deviennent des pièces.
static func _is_deployable(definition: CardDefinition) -> bool:
	return definition.card_type in [CardDefinition.CardType.UNIT, CardDefinition.CardType.BUILDING]


# 205.1.2, 205.1.3, 205.1.4 ; Avant-poste (205.1.2a) vient à l'étape 1.7.
static func _is_in_deploy_zone(
	definition: CardDefinition, side: DuelState.PlayerSide, cell: Vector2i
) -> bool:
	if BoardGeometry.is_in_central_row(cell):
		return false
	if definition.card_type == CardDefinition.CardType.UNIT:
		return BoardGeometry.is_in_first_row(side, cell)
	return BoardGeometry.is_in_near_rows(side, cell)


# 205.1.2, 205.1.3 ; 201.5.2 : la pièce est contrôlée par le joueur à qui la carte appartient.
static func _deploy_on_free_cell(
	state: DuelState,
	card: CardInstance,
	definition: CardDefinition,
	cell: Vector2i,
	events: Array[DuelEvent]
) -> void:
	var piece := _make_piece(state, card, definition)
	piece.cell = cell
	state.pieces.append(piece)
	events.append(PieceDeployed.new(piece.owner, piece.piece_id, cell))


# 205.1.6, 206.1.1 : l'Unit entre en jeu sans case et attaque ; si elle gagne, elle prend la
# case (206.3.3). Un Hero ennemi n'est jamais sur une case de déploiement d'Unit (205.3.2).
static func _enter_attacking(
	state: DuelState, card: CardInstance, defender: Piece, events: Array[DuelEvent]
) -> void:
	var piece := _make_piece(state, card, state.catalog.get_card(card.definition_id))
	state.pieces.append(piece)
	events.append(PieceEnteredAttacking.new(piece.owner, piece.piece_id, defender.cell))
	CombatRules.resolve_attack(state, piece, defender, events)


# 205.1.7, 205.1.8, 205.1.9, 205.1.10, 201.3.6a : l'Essence payée reste dépensée.
static func _return_to_hand(state: DuelState, card: CardInstance, events: Array[DuelEvent]) -> void:
	var owner := state.get_player(card.owner)
	if ZoneRules.has_room_in_hand(state, card.owner):
		owner.hand.append(card)
		events.append(CardReturnedToHand.new(card.owner, card.card_instance_id))
	else:
		owner.discard.append(card)
		events.append(CardDiscarded.new(card.owner, card.card_instance_id))


static func _make_piece(state: DuelState, card: CardInstance, definition: CardDefinition) -> Piece:
	var piece := Piece.new()
	piece.piece_id = state.allocate_piece_id()
	piece.kind = (
		Piece.PieceKind.UNIT
		if definition.card_type == CardDefinition.CardType.UNIT
		else Piece.PieceKind.BUILDING
	)
	piece.owner = card.owner
	piece.card = card
	return piece
