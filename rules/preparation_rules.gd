class_name PreparationRules
extends RefCounted
## Préparation et mulligan (204.1, 204.2 ; décisions 0012, 0013 et 0015). Appelle TurnRules pour
## commencer le premier tour et piocher ; TurnRules n'appelle jamais ce module.


## 204.1.9, 204.1.16 : préparation jusqu'à l'attente des mulligans. Suppose `setup` valide
## (`DuelSetup.find_errors()` vide) pour le catalogue de `state`.
static func start_preparation(state: DuelState, setup: DuelSetup, events: Array[DuelEvent]) -> void:
	state.phase = DuelState.DuelPhase.PREPARATION
	state.first_player_imposed = setup.is_first_player_imposed
	state.first_player = setup.imposed_first_player
	for side: DuelState.PlayerSide in DuelState.SIDES:
		_set_starting_values(state, side)
		ZoneRules.create_deck(state, side, setup.deck_of(side))
	for side: DuelState.PlayerSide in DuelState.SIDES:
		_place_hero(state, side, state.catalog.get_hero(setup.hero_of(side)), events)
	for side: DuelState.PlayerSide in DuelState.SIDES:
		_put_setup_sources_into_play(state, side, events)
	for side: DuelState.PlayerSide in DuelState.SIDES:
		ZoneRules.shuffle_deck(state, side, events)
	for side: DuelState.PlayerSide in DuelState.SIDES:
		TurnRules.draw_cards(state, side, state.config.opening_hand_size, events)
	if not state.is_ended():
		_request_mulligans(state, events)


## 204.2.1, 204.2.4, décisions 0009 et 0013 : raison du refus de `intent`, ou NONE. Pur.
static func validate_mulligan(
	state: DuelState, intent: ChooseMulligan
) -> IntentRejected.RejectReason:
	var reason := PendingDecision.validate_answer(
		state.pending_decision, PendingDecision.DecisionKind.MULLIGAN, intent.player
	)
	if reason != IntentRejected.RejectReason.NONE:
		return reason
	var player := state.get_player(intent.player)
	var seen_ids: Array[int] = []
	for card_id: int in intent.set_aside_card_ids:
		if seen_ids.has(card_id):
			return IntentRejected.RejectReason.DUPLICATE_CARD
		if player.find_card_in_hand(card_id) == null:
			return IntentRejected.RejectReason.CARD_NOT_IN_HAND
		seen_ids.append(card_id)
	return IntentRejected.RejectReason.NONE


## 204.2.2, 204.2.3, décision 0013 : garde le choix caché ; à la dernière réponse, exécute les
## mulligans, désigne le premier joueur et commence le premier tour (204.1.11).
static func apply_mulligan(
	state: DuelState, intent: ChooseMulligan, events: Array[DuelEvent]
) -> void:
	var decision := state.pending_decision
	decision.set_aside_card_ids.append_array(intent.set_aside_card_ids)
	decision.awaited_players.erase(intent.player)
	events.append(MulliganDecided.new(intent.player))
	if decision.awaited_players.is_empty():
		_finish_preparation(state, decision.set_aside_card_ids, events)


# 204.1.16, décision 0015 : mulligans joueur A puis B, tirage du premier joueur, premier tour.
static func _finish_preparation(
	state: DuelState, set_aside_card_ids: Array[int], events: Array[DuelEvent]
) -> void:
	state.pending_decision = null
	for side: DuelState.PlayerSide in DuelState.SIDES:
		_execute_mulligan(state, side, _ids_in_hand(state, side, set_aside_card_ids), events)
		if state.is_ended():
			return
	_designate_first_player(state, events)
	TurnRules.start_turn(state, state.first_player, events)


# 209.4.3, 209.5.1
static func _set_starting_values(state: DuelState, side: DuelState.PlayerSide) -> void:
	var player := state.get_player(side)
	player.clock_remaining_msec = state.config.clock_duration_msec
	player.fatigue_counter = state.config.starting_fatigue


# 204.1.1, 204.1.8 ; 201.5.1 : la carte Hero appartient à son joueur.
static func _place_hero(
	state: DuelState, side: DuelState.PlayerSide, hero: HeroDefinition, events: Array[DuelEvent]
) -> void:
	var card := CardInstance.new()
	card.card_instance_id = state.allocate_card_instance_id()
	card.definition_id = hero.id
	card.owner = side
	var piece := Piece.new()
	piece.piece_id = state.allocate_piece_id()
	piece.kind = Piece.PieceKind.HERO
	piece.owner = side
	piece.cell = BoardGeometry.hero_start_cell(side)
	piece.card = card
	piece.health = hero.health
	state.pieces.append(piece)
	events.append(HeroPlaced.new(side, piece.piece_id, piece.cell))


# 204.1.12, 204.1.13, 204.1.17
static func _put_setup_sources_into_play(
	state: DuelState, side: DuelState.PlayerSide, events: Array[DuelEvent]
) -> void:
	var player := state.get_player(side)
	player.sources_upright = state.config.setup_sources_in_play
	player.sources_in_reserve = state.config.setup_sources_in_reserve
	events.append(SourcesPutIntoPlay.new(side, player.sources_upright))


# 204.2.2 : une seule attente pour les deux joueurs (décision 0009), annoncée à chacun.
static func _request_mulligans(state: DuelState, events: Array[DuelEvent]) -> void:
	var decision := PendingDecision.new()
	decision.kind = PendingDecision.DecisionKind.MULLIGAN
	decision.awaited_players.assign(DuelState.SIDES)
	state.pending_decision = decision
	for side: DuelState.PlayerSide in DuelState.SIDES:
		events.append(DecisionRequested.new(side, decision.kind))


# 204.2.9 : seules des cartes de la main s'écartent.
static func _ids_in_hand(
	state: DuelState, side: DuelState.PlayerSide, card_ids: Array[int]
) -> Array[int]:
	var player := state.get_player(side)
	var ids_in_hand: Array[int] = []
	for card_id: int in card_ids:
		if player.find_card_in_hand(card_id) != null:
			ids_in_hand.append(card_id)
	return ids_in_hand


# 204.2.9 ; 204.2.12 à 204.2.14 : sans carte écartée, le joueur garde sa main et ne mélange pas.
static func _execute_mulligan(
	state: DuelState,
	side: DuelState.PlayerSide,
	set_aside_ids: Array[int],
	events: Array[DuelEvent]
) -> void:
	if set_aside_ids.is_empty():
		return
	ZoneRules.set_aside_cards(state, side, set_aside_ids, events)
	TurnRules.draw_cards(state, side, set_aside_ids.size(), events)
	ZoneRules.return_set_aside_to_deck(state, side, events)
	ZoneRules.shuffle_deck(state, side, events)


# 204.1.14, 204.1.16 ; décision 0012 : aucun tirage si le premier joueur est imposé.
static func _designate_first_player(state: DuelState, events: Array[DuelEvent]) -> void:
	if not state.first_player_imposed:
		state.first_player = DuelState.SIDES[state.rng.randi_range(0, DuelState.SIDES.size() - 1)]
	events.append(FirstPlayerChosen.new(state.first_player))
