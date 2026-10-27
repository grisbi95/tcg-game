class_name ActionRules
extends RefCounted
## Actions (205) : déploiement, action normale d'une Unit, déplacement du Hero, échecs.


## 208.1.1, 208.1.8, 208.1.9, 205.1.2 à 205.1.4, 205.1.11, 203.3.2 : raison du refus de `intent`, ou
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
	if _is_enemy_hero_cell(state, definition, intent.player, intent.cell):
		return IntentRejected.RejectReason.CELL_OCCUPIED_BY_ENEMY_HERO
	if state.piece_at(intent.cell) != null:
		return IntentRejected.RejectReason.CELL_NOT_FREE
	return EssenceRules.validate_payment(state, intent.player, intent.payment, definition.cost)


## 203.3.2, 203.3.2a, 201.3.8, 205.1.5, 208.4.1, 208.7.3 : paie le coût, puis la carte quitte la
## main pour la pile avec sa case. Suppose l'intention validée.
static func announce_deploy(state: DuelState, intent: DeployCard, events: Array[DuelEvent]) -> void:
	var player := state.get_player(intent.player)
	var card := player.find_card_in_hand(intent.card_instance_id)
	var cost := state.catalog.get_card(card.definition_id).cost
	events.append_array(EssenceRules.pay_cost(state, intent.player, intent.payment, cost))
	player.hand.erase(card)
	events.append(DeployAnnounced.new(intent.player, card.card_instance_id, intent.cell))
	var entry := StackEntry.new()
	entry.kind = StackEntry.StackEntryKind.DEPLOY
	entry.owner = intent.player
	entry.card = card
	entry.allows_response = false  # 208.7.3
	entry.target_cells.append(intent.cell)
	StackRules.add_to_stack(state, entry, events)


## 205.1.2 à 205.1.10, 205.6.1 : résout le déploiement `entry` selon le plateau du moment ;
## 205.1.2b : la case n'est pas recontrôlée, même si le Building qui permettait Avant-poste est
## parti. Une Unit dont la case est occupée par une pièce ennemie ne se déploie pas encore : son
## combat attend la fin de la résolution (205.1.6, 205.6.2, 205.6.3).
static func resolve_deploy(state: DuelState, entry: StackEntry, events: Array[DuelEvent]) -> void:
	var occupant := state.piece_at(entry.target_cells[0])
	var definition := state.catalog.get_card(entry.card.definition_id)
	if (
		occupant != null
		and definition.card_type == CardDefinition.CardType.UNIT
		and occupant.owner != entry.owner
	):
		_put_deploy_combat_on_hold(state, entry, events)
	else:
		_finish_deploy(state, entry, events)


## 204.4.5, 205.5.3, 208.1.2, 208.1.10, 208.1.11, 205.2.5, 205.2.6, 205.3.1 à 205.3.3,
## 202.2.17 : raison du refus de `intent`, ou NONE. L'attente est contrôlée par DuelEngine. Pur.
static func validate_normal_action(
	state: DuelState, intent: TakeNormalAction
) -> IntentRejected.RejectReason:
	var reason := StackRules.validate_main_phase_with_empty_stack(state, intent.player)
	if reason != IntentRejected.RejectReason.NONE:
		return reason
	var piece := state.find_piece(intent.piece_id)
	if piece == null or piece.owner != intent.player:
		return IntentRejected.RejectReason.PIECE_NOT_YOURS
	if piece.kind == Piece.PieceKind.BUILDING:
		return IntentRejected.RejectReason.NO_NORMAL_ACTION
	if not piece.is_awake:
		return IntentRejected.RejectReason.PIECE_ASLEEP
	if not BoardGeometry.are_adjacent(piece.cell, intent.cell):
		return IntentRejected.RejectReason.CELL_NOT_ADJACENT
	if piece.kind == Piece.PieceKind.HERO:
		return _validate_hero_target(state, intent.cell)
	return _validate_unit_target(state, piece, intent.cell)


## 205.4.7, 208.4.1, 208.7.2, 208.7.4, 208.7.5 : la pièce s'endort dès l'annonce, même si l'action
## échoue ensuite ; l'action va sur la pile avec sa case, sans réponse sauf si c'est une attaque.
## Suppose l'intention validée.
static func announce_normal_action(
	state: DuelState, intent: TakeNormalAction, events: Array[DuelEvent]
) -> void:
	state.find_piece(intent.piece_id).is_awake = false
	events.append(NormalActionAnnounced.new(intent.player, intent.piece_id, intent.cell))
	var entry := StackEntry.new()
	entry.kind = StackEntry.StackEntryKind.NORMAL_ACTION
	entry.owner = intent.player
	entry.source_piece_id = intent.piece_id
	entry.allows_response = _is_attack(state, state.find_piece(intent.piece_id), intent.cell)
	entry.target_cells.append(intent.cell)
	StackRules.add_to_stack(state, entry, events)


## 205.4.1 : l'action se résout selon le plateau du moment ; 205.4.3, 205.4.4 : elle échoue si
## sa pièce a quitté le plateau ou n'est plus adjacente à la case visée. Le Hero ne se déplace
## que vers une case encore libre (205.3.1, 200.4.1). 205.2.3, 205.2.3a : une attaque annoncée a
## lieu aussitôt ; annoncée vers une case libre, elle attend la fin de la résolution.
static func resolve_normal_action(
	state: DuelState, entry: StackEntry, events: Array[DuelEvent]
) -> void:
	var piece := state.find_piece(entry.source_piece_id)
	if piece == null:
		events.append(NormalActionFailed.new(entry.owner, entry.source_piece_id))
		return
	_act_on_target_cell(state, entry, piece, events)


## 205.6.9 : le combat en attente se résout selon le plateau du moment, comme 205.4.1 ; 205.6.10 :
## l'Unit d'une action normale a quitté le plateau, 205.6.16 : la carte d'un déploiement a quitté
## la pile, le combat n'a pas lieu.
static func resolve_pending_combat(
	state: DuelState, entry: StackEntry, events: Array[DuelEvent]
) -> void:
	if _is_deploy_combat(entry):
		if entry.card != null:  # 205.6.16
			_resolve_deploy_combat(state, entry, events)
		return
	var piece := state.find_piece(entry.source_piece_id)
	if piece != null:  # 205.6.10
		_act_on_target_cell(state, entry, piece, events)


# 205.3.1, 205.3.3 ; 202.3.10 : le Hero n'attaque jamais, sa case visée est libre.
static func _validate_hero_target(state: DuelState, cell: Vector2i) -> IntentRejected.RejectReason:
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


# 205.1.11 : une Unit ne s'annonce pas sur la case du Hero ennemi ; un Building n'est pas concerné.
static func _is_enemy_hero_cell(
	state: DuelState, definition: CardDefinition, side: DuelState.PlayerSide, cell: Vector2i
) -> bool:
	var occupant := state.piece_at(cell)
	return (
		definition.card_type == CardDefinition.CardType.UNIT
		and occupant != null
		and occupant.kind == Piece.PieceKind.HERO
		and occupant.owner != side
	)


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
	state: DuelState, card: CardInstance, cell: Vector2i, events: Array[DuelEvent]
) -> void:
	var piece := _make_piece(state, card)
	piece.cell = cell
	state.pieces.append(piece)
	events.append(PieceDeployed.new(piece.owner, piece.piece_id, cell))
	TriggerRules.trigger(state, piece, EffectDefinition.TriggerEvent.ARRIVAL, events)


# 205.1.6, 206.1.1 : l'Unit entre en jeu sans case et attaque ; si elle gagne, elle prend la
# case (206.3.3). Libre de Hero ennemi à l'annonce (205.1.11), la case le reste jusqu'ici : le Hero
# ne se déplace que par sa propre action normale, pile vide (205.3.1, 208.1.10, 208.1.11).
# 210.3.1a : entrer en jeu, c'est arriver sur le plateau (glossaire, En jeu).
static func _enter_attacking(
	state: DuelState, card: CardInstance, defender: Piece, events: Array[DuelEvent]
) -> void:
	var piece := _make_piece(state, card)
	state.pieces.append(piece)
	events.append(PieceEnteredAttacking.new(piece.owner, piece.piece_id, defender.cell))
	TriggerRules.trigger(state, piece, EffectDefinition.TriggerEvent.ARRIVAL, events)
	CombatRules.resolve_attack(state, piece, defender, events)


# 205.6.2, 205.6.3 : un combat en attente de déploiement n'a pas de pièce source.
static func _is_deploy_combat(combat: StackEntry) -> bool:
	return combat.source_piece_id == DuelState.NO_ID


# 208.7.2, 208.7.4 : l'étiquette « avec réponse » d'une action normale dit qu'elle a été annoncée
# comme attaque (205.2.3), sinon vers une case libre (205.2.3a).
static func _was_announced_as_attack(action: StackEntry) -> bool:
	return action.allows_response


# 205.2.3, 205.2.3a, 205.6.9 : une attaque annoncée a lieu aussitôt, un combat en attente à sa
# résolution ; une action annoncée vers une case libre met son combat en attente.
static func _attacks_now(entry: StackEntry) -> bool:
	return entry.kind == StackEntry.StackEntryKind.PENDING_COMBAT or _was_announced_as_attack(entry)


# 205.4.1, 205.4.4, 205.4.5, 205.6.11, 205.6.13, 205.6.15, 205.6.17 : suite commune de l'action
# normale et de son combat en attente, selon le plateau du moment.
static func _act_on_target_cell(
	state: DuelState, entry: StackEntry, piece: Piece, events: Array[DuelEvent]
) -> void:
	var cell := entry.target_cells[0]
	if not BoardGeometry.are_adjacent(piece.cell, cell):
		events.append(NormalActionFailed.new(entry.owner, entry.source_piece_id))
		return
	var occupant := state.piece_at(cell)
	if occupant == null:
		ZoneRules.move_piece(piece, cell, events)
	elif piece.kind == Piece.PieceKind.UNIT and occupant.owner != piece.owner:
		if _attacks_now(entry):
			CombatRules.resolve_attack(state, piece, occupant, events)
		else:
			_put_action_combat_on_hold(state, piece, cell, events)
	else:
		events.append(NormalActionFailed.new(entry.owner, entry.source_piece_id))


# 205.1.2, 205.1.7, 205.1.9, 205.1.10, 205.6.12, 205.6.14 : case libre, la pièce entre en jeu ;
# sinon la carte revient dans la main.
static func _finish_deploy(state: DuelState, entry: StackEntry, events: Array[DuelEvent]) -> void:
	var cell := entry.target_cells[0]
	if state.piece_at(cell) == null:
		_deploy_on_free_cell(state, entry.card, cell, events)
	else:
		ZoneRules.return_card_to_hand(state, entry.card, events)


# 205.2.6, 208.7.2 : une Unit qui vise une case occupée par une pièce ennemie attaque.
static func _is_attack(state: DuelState, piece: Piece, cell: Vector2i) -> bool:
	var occupant := state.piece_at(cell)
	return piece.kind == Piece.PieceKind.UNIT and occupant != null and occupant.owner != piece.owner


# 205.1.6, 205.6.1, 205.6.8 : la carte reste sur la pile avec le combat, qui appartient au joueur
# de l'attaquant (205.6.5).
static func _put_deploy_combat_on_hold(
	state: DuelState, deploy: StackEntry, events: Array[DuelEvent]
) -> void:
	var combat := StackEntry.new()
	combat.owner = deploy.owner
	combat.card = deploy.card
	combat.target_cells.assign(deploy.target_cells)
	TriggerRules.wait_pending_combat(state, combat, events)


# 205.2.3a, 205.6.1, 205.6.7 : l'Unit reste sur sa case de départ pendant l'attente.
static func _put_action_combat_on_hold(
	state: DuelState, unit: Piece, cell: Vector2i, events: Array[DuelEvent]
) -> void:
	var combat := StackEntry.new()
	combat.owner = unit.owner
	combat.source_piece_id = unit.piece_id
	combat.target_cells.append(cell)
	TriggerRules.wait_pending_combat(state, combat, events)


# 205.6.12, 205.6.14, 205.6.15
static func _resolve_deploy_combat(
	state: DuelState, combat: StackEntry, events: Array[DuelEvent]
) -> void:
	var occupant := state.piece_at(combat.target_cells[0])
	if occupant != null and occupant.owner != combat.owner:
		_enter_attacking(state, combat.card, occupant, events)
	else:
		_finish_deploy(state, combat, events)


# 202.2.2, 202.2.3, 201.5.2 : une Unit ou un Building, contrôlé par le joueur de sa carte ;
# 205.5.4 : une Unit naît endormie (`is_awake` reste faux) ; sans objet pour un Building (205.5.6).
static func _make_piece(state: DuelState, card: CardInstance) -> Piece:
	var definition := state.catalog.get_card(card.definition_id)
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


## 205.5.1, 205.5.2, 205.5.5, 205.5.6, 200.4.1 : les pièces endormies de `pieces`, toutes au même
## joueur, s'éveillent et un seul PiecesAwakened les liste. Une pièce déjà éveillée le reste sans
## être rapportée, un Building n'a aucun état de sommeil ; aucun événement si rien ne dormait.
## Sert au réveil du début du tour (204.3.10, 204.3.11) et à l'effet WAKE (décision 0057).
static func wake_pieces(pieces: Array[Piece], events: Array[DuelEvent]) -> void:
	var awakened_ids: Array[int] = []
	var awakened_owner := DuelState.PlayerSide.A
	for piece: Piece in pieces:
		if piece.is_asleep():
			piece.is_awake = true
			awakened_ids.append(piece.piece_id)
			awakened_owner = piece.owner
	if not awakened_ids.is_empty():
		events.append(PiecesAwakened.new(awakened_owner, awakened_ids))


## 205.5.1, 207.3.3 : « réveillez cette Unit » ; l'effet a lieu même si la pièce `piece_id` a quitté
## le plateau, alors sans rien réveiller.
static func wake_source_piece(state: DuelState, piece_id: int, events: Array[DuelEvent]) -> void:
	var source := state.find_piece(piece_id)
	if source != null:
		wake_pieces([source], events)
