class_name TurnRules
extends RefCounted
## Préparation, mulligan, début et fin du tour (204 ; décisions 0012, 0013 et 0015).
##
## Le début du tour s'exécute d'un bloc dans `submit()` : aucun joueur ne peut y répondre
## (204.3.9). Les compteurs « par tour » des deux joueurs repartent à zéro au début de chaque
## tour (convention de l'étape 1.3).

const FIRST_TURN: int = 1


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
		_draw_cards(state, side, state.config.opening_hand_size, events)
	if not state.is_ended():
		state.pending_decision = _make_mulligan_decision()


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


## 204.4.7, convention 1.3 : raison du refus de `intent`, ou NONE. L'attente est contrôlée
## par DuelEngine. Pur.
static func validate_end_turn(state: DuelState, intent: EndTurn) -> IntentRejected.RejectReason:
	if state.phase != DuelState.DuelPhase.MAIN:
		return IntentRejected.RejectReason.WRONG_PHASE
	if intent.player != state.active_player:
		return IntentRejected.RejectReason.NOT_YOUR_TURN
	if not state.stack.is_empty():
		return IntentRejected.RejectReason.STACK_NOT_EMPTY
	return IntentRejected.RejectReason.NONE


## 204.4.7, 204.5.3 à 204.5.6 : termine le tour du joueur actif ; les effets déclenchés par la
## fin du tour s'ajoutent à la pile, qui se résout comme toute autre (208.3.1).
static func apply_end_turn(state: DuelState, intent: EndTurn, events: Array[DuelEvent]) -> void:
	state.phase = DuelState.DuelPhase.TURN_END
	events.append(TurnEnded.new(intent.player))
	TriggerRules.trigger_end_of_turn(state, events)
	StackRules.settle_after_triggers(state, events)


## 204.5.7, 204.5.2 : la pile vide, les effets qui durent jusqu'à la fin du tour prennent fin ;
## l'adversaire du joueur actif commence son tour.
static func finish_end_of_turn(state: DuelState, events: Array[DuelEvent]) -> void:
	_end_until_end_of_turn_effects(state, events)
	_start_turn(state, DuelState.opponent_of(state.active_player), events)


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
	_start_turn(state, state.first_player, events)


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


# 204.2.2 : une seule attente pour les deux joueurs (décision 0009).
static func _make_mulligan_decision() -> PendingDecision:
	var decision := PendingDecision.new()
	decision.kind = PendingDecision.DecisionKind.MULLIGAN
	decision.awaited_players.assign(DuelState.SIDES)
	return decision


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
	_draw_cards(state, side, set_aside_ids.size(), events)
	ZoneRules.return_set_aside_to_deck(state, side, events)
	ZoneRules.shuffle_deck(state, side, events)


# 204.1.14, 204.1.16 ; décision 0012 : aucun tirage si le premier joueur est imposé.
static func _designate_first_player(state: DuelState, events: Array[DuelEvent]) -> void:
	if not state.first_player_imposed:
		state.first_player = DuelState.SIDES[state.rng.randi_range(0, DuelState.SIDES.size() - 1)]
	events.append(FirstPlayerChosen.new(state.first_player))


# 204.3.8 puis 204.4.1 ; 208.4.11 : les effets qui attendaient la fin du début du tour
# s'ajoutent à la pile dès le début de la phase principale.
static func _start_turn(
	state: DuelState, side: DuelState.PlayerSide, events: Array[DuelEvent]
) -> void:
	state.phase = DuelState.DuelPhase.TURN_START
	state.turn_number += 1
	state.active_player = side
	state.priority_player = side
	_reset_turn_counters(state)
	events.append(TurnStarted.new(side, state.turn_number))
	_untap_sources(state, side, events)
	_receive_sources(state, side, events)
	_draw_cards(state, side, state.config.cards_drawn_per_turn, events)
	if not state.is_ended():
		state.phase = DuelState.DuelPhase.MAIN
		StackRules.settle_after_triggers(state, events)


# 202.3.14, 203.4.2, 204.4.6 : décomptes « par tour » des deux joueurs, remis à zéro au début
# de chaque tour (convention de l'étape 1.3) ; 207.3.9 : « une fois par tour » aussi.
static func _reset_turn_counters(state: DuelState) -> void:
	state.once_per_turn_card_ids.clear()
	for player: PlayerState in state.players:
		player.sources_recycled_this_turn = 0
		player.hero_power_used_this_turn = false
		player.normal_action_used_this_turn = false


# 204.3.2
static func _untap_sources(
	state: DuelState, side: DuelState.PlayerSide, events: Array[DuelEvent]
) -> void:
	var player := state.get_player(side)
	if player.sources_tilted == 0:
		return
	events.append(SourcesUntapped.new(side, player.sources_tilted))
	player.sources_upright += player.sources_tilted
	player.sources_tilted = 0


# 204.3.1, 204.3.3, 204.3.4, 204.3.5 ; 200.4.1, 200.4.2 : la réserve donne ce qu'elle a.
static func _receive_sources(
	state: DuelState, side: DuelState.PlayerSide, events: Array[DuelEvent]
) -> void:
	var is_first_turn := state.turn_number == FIRST_TURN
	if is_first_turn and not state.config.first_player_receives_source_on_first_turn:
		return
	var player := state.get_player(side)
	var received := mini(state.config.sources_received_per_turn, player.sources_in_reserve)
	for index: int in received:
		player.sources_in_reserve -= 1
		player.sources_upright += 1
		events.append(SourceReceived.new(side))


# 201.3.5, 209.5.2, 209.5.4 : chaque carte se pioche séparément ; 209.2.2 : rien après la fin.
static func _draw_cards(
	state: DuelState, side: DuelState.PlayerSide, count: int, events: Array[DuelEvent]
) -> void:
	for index: int in count:
		if ZoneRules.draw_card(state, side, events) == ZoneRules.DrawOutcome.DECK_EMPTY:
			StateCheckRules.apply_fatigue(state, side, events)
		if state.is_ended():
			return


# 204.5.7
static func _end_until_end_of_turn_effects(state: DuelState, events: Array[DuelEvent]) -> void:
	var remaining: Array[ActiveEffect] = []
	for effect: ActiveEffect in state.active_effects:
		if effect.duration == ActiveEffect.EffectDuration.UNTIL_END_OF_TURN:
			events.append(ActiveEffectEnded.new(effect.effect_id))
		else:
			remaining.append(effect)
	state.active_effects = remaining
