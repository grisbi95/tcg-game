class_name StackRules
extends RefCounted
## Pile et priorité (208).
##
## Une annonce s'ajoute par `add_to_stack`, appelée par le module de son chapitre ; un effet
## déclenché, par TriggerRules (décision 0017). La boucle de résolution vit dans DuelEngine, qui
## aiguille chaque entrée vers le module de son genre et la reprend après un choix (décision 0057) :
## StackRules n'appelle aucun autre module.


## 208.4.1, 208.2.4, 208.7.12 : ajoute `entry` au sommet de la pile ; l'adversaire du joueur à
## qui elle appartient peut le premier répondre ou passer, sauf si elle est sans réponse, qui ne
## donne la main à personne. 208.7.8 : les effets déclenchés qui surviennent ensuite reçoivent son
## étiquette. Renvoie l'identifiant de l'entrée, attribué ici sauf pour un effet déclenché, qui a
## le sien depuis son attente (décision 0017).
static func add_to_stack(state: DuelState, entry: StackEntry, events: Array[DuelEvent]) -> int:
	if entry.stack_entry_id == DuelState.NO_ID:
		entry.stack_entry_id = state.allocate_stack_entry_id()
	state.stack.append(entry)
	state.triggers_allow_response = entry.allows_response
	if entry.allows_response:
		state.priority_player = DuelState.opponent_of(entry.owner)
		state.get_player(state.priority_player).response_time_remaining_msec = (
			state.config.response_time_msec
		)
	_record_announcement(state, entry)
	events.append(StackEntryAdded.new(entry.owner, entry.stack_entry_id))
	return entry.stack_entry_id


## 208.7.13 : vrai si la pile contient une entrée sans réponse, qui se résout aussitôt avec le
## reste de la pile. Pur.
static func resolves_at_once(state: DuelState) -> bool:
	return state.stack.any(func(entry: StackEntry) -> bool: return not entry.allows_response)


## 208.1.6 à 208.1.11 : annonce du joueur actif, phase principale, pile vide.
static func validate_main_phase_with_empty_stack(
	state: DuelState, side: DuelState.PlayerSide
) -> IntentRejected.RejectReason:
	if state.phase != DuelState.DuelPhase.MAIN:
		return IntentRejected.RejectReason.WRONG_PHASE
	if side != state.active_player:
		return IntentRejected.RejectReason.NOT_YOUR_TURN
	if not state.stack.is_empty():
		return IntentRejected.RejectReason.STACK_NOT_EMPTY
	return IntentRejected.RejectReason.NONE


## 207.1.3 à 207.1.6, 208.2.3, 211.2.4 à 211.2.7 : raison du refus d'une annonce de vitesse
## `speed` par `side` (Spell ou Ordre), ou NONE. Action : phase principale du joueur actif, pile
## vide. Réaction : de même, ou chaque fois que `side` peut répondre. Pur.
static func validate_speed(
	state: DuelState, side: DuelState.PlayerSide, speed: CardDefinition.SpellSpeed
) -> IntentRejected.RejectReason:
	var responding := not state.stack.is_empty()
	if responding and speed == CardDefinition.SpellSpeed.REACTION:
		if side != state.priority_player:
			return IntentRejected.RejectReason.NOT_YOUR_PRIORITY
		return IntentRejected.RejectReason.NONE
	if state.phase != DuelState.DuelPhase.MAIN:
		return IntentRejected.RejectReason.WRONG_PHASE
	if side != state.active_player:
		return IntentRejected.RejectReason.NOT_YOUR_TURN
	if responding:
		return IntentRejected.RejectReason.STACK_NOT_EMPTY
	return IntentRejected.RejectReason.NONE


## 208.2.4, 208.3.1 : raison du refus de `intent`, ou NONE. L'attente est contrôlée
## par DuelEngine. Pur.
static func validate_pass(state: DuelState, intent: PassPriority) -> IntentRejected.RejectReason:
	if state.stack.is_empty():
		return IntentRejected.RejectReason.STACK_EMPTY
	if intent.player != state.priority_player:
		return IntentRejected.RejectReason.NOT_YOUR_PRIORITY
	return IntentRejected.RejectReason.NONE


## 208.3.1, 208.3.1a : la passe du joueur qui peut répondre résout toute la pile d'un bloc ; le
## propriétaire du sommet est considéré comme ayant passé. La résolution suit, par DuelEngine.
static func apply_pass(_state: DuelState, intent: PassPriority, events: Array[DuelEvent]) -> void:
	events.append(PriorityPassed.new(intent.player))


## 208.3.2, décision 0057 : retire de la pile l'entrée du sommet, la dernière ajoutée, la renvoie
## et la tient pour en cours de résolution, au premier de ses effets. Suppose la pile non vide.
static func take_top_entry(state: DuelState) -> StackEntry:
	var entry: StackEntry = state.stack.pop_back()
	state.resolving_entry = entry
	state.resolving_effect_index = 0
	state.previous_effect_took_place = false
	return entry


## Décision 0057 : l'entrée en cours de résolution a appliqué tous ses effets. Suppose la partie
## en cours : une partie arrêtée garde l'entrée en l'état (209.2.2).
static func end_resolution(state: DuelState) -> void:
	state.resolving_entry = null
	state.resolving_effect_index = 0
	state.previous_effect_took_place = false


## 207.5.2, 208.4.6, 209.4.6, 209.4.7c, 209.4.7d : le moteur attend le choix de `decision` ; chaque
## joueur attendu reçoit un temps de réponse complet (décisions 0009 et 0017).
static func request_decision(
	state: DuelState, decision: PendingDecision, events: Array[DuelEvent]
) -> void:
	state.pending_decision = decision
	for side: DuelState.PlayerSide in decision.awaited_players:
		state.get_player(side).response_time_remaining_msec = state.config.response_time_msec
	events.append(DecisionRequested.new(decision.awaited_players[0], decision.kind))


## 208.3.2, 209.2.2 : annonce que l'entrée est résolue, sauf si la partie s'est arrêtée pendant
## sa résolution ; la partie s'arrête alors aussitôt, sans événement de résolution.
static func announce_entry_resolved(
	state: DuelState, entry: StackEntry, events: Array[DuelEvent]
) -> void:
	if not state.is_ended():
		events.append(StackEntryResolved.new(entry.owner, entry.stack_entry_id))


## 208.5.1, 208.5.1a : pile vide et aucun choix attendu, c'est de nouveau au joueur actif d'agir.
static func return_priority_to_active_player(state: DuelState) -> void:
	if state.pending_decision != null or not state.stack.is_empty():
		return
	state.priority_player = state.active_player


# 208.1.1 à 208.1.5, 208.1.12, 209.2.10, Q-109 : une annonce faite pendant son propre tour
# interrompt l'inactivité, décidée à la fin du tour. Un effet déclenché n'est pas une annonce
# (207.3.2).
static func _record_announcement(state: DuelState, entry: StackEntry) -> void:
	if entry.kind == StackEntry.StackEntryKind.TRIGGERED_EFFECT:
		return
	if entry.owner != state.active_player:
		return
	state.get_player(entry.owner).announced_this_turn = true
