class_name TurnRules
extends RefCounted
## Début et fin du tour (204.3 à 204.5). La préparation et le mulligan (204.1, 204.2) sont dans
## PreparationRules, qui appelle ce module ; celui-ci n'appelle jamais PreparationRules.
##
## Le début du tour s'exécute d'un bloc dans `submit()` : aucun joueur ne peut y répondre
## (204.3.9). Les compteurs « par tour » des deux joueurs repartent à zéro au début de chaque
## tour (convention de l'étape 1.3).

const FIRST_TURN: int = 1


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


## 204.5.6, 204.5.7 : la fin du tour se poursuit quand sa pile est vide et qu'aucun choix
## n'est attendu. Pur.
static func is_end_of_turn_ready(state: DuelState) -> bool:
	return (
		state.phase == DuelState.DuelPhase.TURN_END
		and state.pending_decision == null
		and state.stack.is_empty()
	)


## 204.5.7, 204.5.7a, 204.5.2 : la pile vide, les effets qui durent jusqu'à la fin du tour
## prennent fin et l'Essence non dépensée est perdue ; l'adversaire du joueur actif commence son
## tour.
static func finish_end_of_turn(state: DuelState, events: Array[DuelEvent]) -> void:
	_end_until_end_of_turn_effects(state, events)
	EssenceRules.lose_reserve(state, events)
	start_turn(state, DuelState.opponent_of(state.active_player), events)


## 204.3.8 puis 204.4.1 ; 208.4.11 : commence le tour de `side`. Les effets qui attendaient la
## fin du début du tour s'ajoutent à la pile dès le début de la phase principale, par DuelEngine.
static func start_turn(
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
	draw_cards(state, side, state.config.cards_drawn_per_turn, events)
	if not state.is_ended():
		state.phase = DuelState.DuelPhase.MAIN


## 201.3.5, 209.5.2, 209.5.4 : `side` pioche `count` cartes, chacune séparément ; 209.2.2 : rien
## après la fin de la partie.
static func draw_cards(
	state: DuelState, side: DuelState.PlayerSide, count: int, events: Array[DuelEvent]
) -> void:
	for index: int in count:
		if ZoneRules.draw_card(state, side, events) == ZoneRules.DrawOutcome.DECK_EMPTY:
			StateCheckRules.apply_fatigue(state, side, events)
		if state.is_ended():
			return


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


# 204.5.7
static func _end_until_end_of_turn_effects(state: DuelState, events: Array[DuelEvent]) -> void:
	var remaining: Array[ActiveEffect] = []
	for effect: ActiveEffect in state.active_effects:
		if effect.duration == ActiveEffect.EffectDuration.UNTIL_END_OF_TURN:
			events.append(ActiveEffectEnded.new(effect.effect_id))
		else:
			remaining.append(effect)
	state.active_effects = remaining
