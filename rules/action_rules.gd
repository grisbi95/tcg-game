class_name ActionRules
extends RefCounted
## Actions (205) : déploiement, action normale d'une Unit, déplacement du Hero, échecs.


## 208.1.1, 208.1.8, 208.1.9, 205.1.2 à 205.1.4, 203.3.2 : raison du refus de `intent`, ou
## NONE. L'attente est contrôlée par DuelEngine. Pur.
static func validate_deploy(state: DuelState, intent: DeployCard) -> IntentRejected.RejectReason:
	var reason := StackRules.validate_main_phase_with_empty_stack(state, intent.player)
	if reason != IntentRejected.RejectReason.NONE:
		return reason
	var card := state.get_player(intent.player).find_card_in_hand(intent.card_instance_id)
	if card == null:
		return IntentRejected.RejectReason.CARD_NOT_IN_HAND
	var definition := state.catalog.get_card(card.definition_id)
	if not _is_deployable(definition):
		return IntentRejected.RejectReason.NOT_DEPLOYABLE
	if not _is_in_deploy_zone(state, definition, intent.player, intent.cell):
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


## 205.1.2 à 205.1.10 : résout le déploiement `entry` selon le plateau du moment ; 205.1.2b :
## la case n'est pas recontrôlée, même si le Building qui permettait Avant-poste est parti.
static func resolve_deploy(state: DuelState, entry: StackEntry, events: Array[DuelEvent]) -> void:
	var cell := entry.target_cells[0]
	var occupant := state.piece_at(cell)
	var definition := state.catalog.get_card(entry.card.definition_id)
	if occupant == null:
		_deploy_on_free_cell(state, entry.card, definition, cell, events)
	elif definition.card_type == CardDefinition.CardType.UNIT and occupant.owner != entry.owner:
		_enter_attacking(state, entry.card, occupant, events)
	else:
		ZoneRules.return_card_to_hand(state, entry.card, events)


## 204.4.5, 204.4.6, 208.1.2, 208.1.10, 208.1.11, 205.2.5, 205.2.6, 205.3.1 à 205.3.3,
## 202.2.17 : raison du refus de `intent`, ou NONE. L'attente est contrôlée par DuelEngine. Pur.
static func validate_normal_action(
	state: DuelState, intent: TakeNormalAction
) -> IntentRejected.RejectReason:
	var reason := StackRules.validate_main_phase_with_empty_stack(state, intent.player)
	if reason != IntentRejected.RejectReason.NONE:
		return reason
	if state.get_player(intent.player).normal_action_used_this_turn:
		return IntentRejected.RejectReason.NORMAL_ACTION_ALREADY_USED
	var piece := state.find_piece(intent.piece_id)
	if piece == null or piece.owner != intent.player:
		return IntentRejected.RejectReason.PIECE_NOT_YOURS
	if piece.kind == Piece.PieceKind.BUILDING:
		return IntentRejected.RejectReason.NO_NORMAL_ACTION
	if not BoardGeometry.are_adjacent(piece.cell, intent.cell):
		return IntentRejected.RejectReason.CELL_NOT_ADJACENT
	if piece.kind == Piece.PieceKind.HERO:
		return _validate_hero_target(state, piece, intent.cell)
	return _validate_unit_target(state, piece, intent.cell)


## 205.4.7, 208.4.1 : l'action compte pour 204.4.6 dès l'annonce ; elle va sur la pile avec sa
## case. Suppose l'intention validée.
static func announce_normal_action(
	state: DuelState, intent: TakeNormalAction, events: Array[DuelEvent]
) -> void:
	state.get_player(intent.player).normal_action_used_this_turn = true
	events.append(NormalActionAnnounced.new(intent.player, intent.piece_id, intent.cell))
	var entry := StackEntry.new()
	entry.kind = StackEntry.StackEntryKind.NORMAL_ACTION
	entry.owner = intent.player
	entry.source_piece_id = intent.piece_id
	entry.target_cells.append(intent.cell)
	StackRules.add_to_stack(state, entry, events)


## 205.4.1 : l'action se résout selon le plateau du moment ; 205.4.3, 205.4.4 : elle échoue si
## sa pièce a quitté le plateau ou n'est plus adjacente à la case visée. Le Hero ne se déplace
## que vers une case encore libre (205.3.1, 200.4.1).
static func resolve_normal_action(
	state: DuelState, entry: StackEntry, events: Array[DuelEvent]
) -> void:
	var piece := state.find_piece(entry.source_piece_id)
	var cell := entry.target_cells[0]
	if piece == null or not BoardGeometry.are_adjacent(piece.cell, cell):
		events.append(NormalActionFailed.new(entry.owner, entry.source_piece_id))
		return
	var occupant := state.piece_at(cell)
	if occupant == null:
		move_piece(piece, cell, events)
	elif piece.kind == Piece.PieceKind.UNIT and occupant.owner != piece.owner:
		CombatRules.resolve_attack(state, piece, occupant, events)
	else:
		events.append(NormalActionFailed.new(entry.owner, entry.source_piece_id))


## 205.2.2, 205.3.1, 206.3.3 : `piece` passe sur `to_cell`.
static func move_piece(piece: Piece, to_cell: Vector2i, events: Array[DuelEvent]) -> void:
	events.append(PieceMoved.new(piece.owner, piece.piece_id, piece.cell, to_cell))
	piece.cell = to_cell


# 205.3.2, 205.3.3 ; 202.3.10 : le Hero n'attaque jamais, sa case visée est libre.
static func _validate_hero_target(
	state: DuelState, hero: Piece, cell: Vector2i
) -> IntentRejected.RejectReason:
	if not BoardGeometry.is_in_near_rows(hero.owner, cell):
		return IntentRejected.RejectReason.CELL_OUTSIDE_HERO_ROWS
	if state.piece_at(cell) != null:
		return IntentRejected.RejectReason.CELL_NOT_FREE
	return IntentRejected.RejectReason.NONE


# 205.2.6 : la case visée est libre ou occupée par une pièce ennemie.
static func _validate_unit_target(
	state: DuelState, unit: Piece, cell: Vector2i
) -> IntentRejected.RejectReason:
	var occupant := state.piece_at(cell)
	if occupant != null and occupant.owner == unit.owner:
		return IntentRejected.RejectReason.CELL_OCCUPIED_BY_ALLY
	return IntentRejected.RejectReason.NONE


# 202.2.2, 202.2.3, 202.2.5, 202.2.7 : seules les Units et les Buildings deviennent des pièces.
static func _is_deployable(definition: CardDefinition) -> bool:
	return definition.card_type in [CardDefinition.CardType.UNIT, CardDefinition.CardType.BUILDING]


# 205.1.2, 205.1.2a, 205.1.3, 205.1.4
static func _is_in_deploy_zone(
	state: DuelState, definition: CardDefinition, side: DuelState.PlayerSide, cell: Vector2i
) -> bool:
	if BoardGeometry.is_in_central_row(cell):
		return false
	if definition.card_type == CardDefinition.CardType.UNIT:
		return (
			BoardGeometry.is_in_first_row(side, cell)
			or KeywordRules.is_outpost_cell(state, side, cell)
		)
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
	TriggerRules.trigger(state, piece, EffectDefinition.TriggerEvent.ARRIVAL, events)


# 205.1.6, 206.1.1 : l'Unit entre en jeu sans case et attaque ; si elle gagne, elle prend la
# case (206.3.3). Un Hero ennemi n'est jamais sur une case de déploiement d'Unit (205.3.2).
# 210.3.1a : entrer en jeu, c'est arriver sur le plateau (glossaire, En jeu).
static func _enter_attacking(
	state: DuelState, card: CardInstance, defender: Piece, events: Array[DuelEvent]
) -> void:
	var piece := _make_piece(state, card, state.catalog.get_card(card.definition_id))
	state.pieces.append(piece)
	events.append(PieceEnteredAttacking.new(piece.owner, piece.piece_id, defender.cell))
	TriggerRules.trigger(state, piece, EffectDefinition.TriggerEvent.ARRIVAL, events)
	CombatRules.resolve_attack(state, piece, defender, events)


# 202.2.2, 202.2.3, 201.5.2 : une Unit ou un Building, contrôlé par le joueur de sa carte.
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
