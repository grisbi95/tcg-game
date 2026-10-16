class_name StackRules
extends RefCounted
## Pile et priorité (208), sans effet déclenché : ceux-ci viennent à l'étape 1.7.
##
## Une annonce s'ajoute par `add_to_stack`, appelée par le module de son chapitre. Ce qu'une
## entrée fait en se résolvant appartient au module de son genre.


## 208.4.1, 208.2.4 : ajoute `entry` au sommet de la pile ; l'adversaire du joueur à qui elle
## appartient peut le premier répondre ou passer. Renvoie l'identifiant attribué.
static func add_to_stack(state: DuelState, entry: StackEntry, events: Array[DuelEvent]) -> int:
	entry.stack_entry_id = state.allocate_stack_entry_id()
	state.stack.append(entry)
	state.consecutive_passes = 0
	state.priority_player = DuelState.opponent_of(entry.owner)
	events.append(StackEntryAdded.new(entry.owner, entry.stack_entry_id))
	return entry.stack_entry_id


## 208.2.2, 208.2.4, 208.3.1 : raison du refus de `intent`, ou NONE. L'attente est contrôlée
## par DuelEngine. Pur.
static func validate_pass(state: DuelState, intent: PassPriority) -> IntentRejected.RejectReason:
	if state.stack.is_empty():
		return IntentRejected.RejectReason.STACK_EMPTY
	if intent.player != state.priority_player:
		return IntentRejected.RejectReason.NOT_YOUR_PRIORITY
	return IntentRejected.RejectReason.NONE


## 208.2.2, 208.3.1 : après une passe, l'adversaire peut répondre ou passer ; quand les deux
## joueurs ont passé l'un après l'autre, toute la pile se résout d'un bloc.
static func apply_pass(state: DuelState, intent: PassPriority, events: Array[DuelEvent]) -> void:
	events.append(PriorityPassed.new(intent.player))
	state.consecutive_passes += 1
	if state.consecutive_passes < DuelState.PLAYER_COUNT:
		state.priority_player = DuelState.opponent_of(intent.player)
		return
	_resolve_stack(state, events)


# 208.3.1, 208.3.2, 208.3.3, 208.5.1 ; 209.2.1, 209.2.3 : la victoire se vérifie après chaque
# résolution, et une partie arrêtée laisse le reste de la pile.
static func _resolve_stack(state: DuelState, events: Array[DuelEvent]) -> void:
	state.consecutive_passes = 0
	while not state.stack.is_empty():
		var entry: StackEntry = state.stack.pop_back()
		_resolve_entry(state, entry, events)
		if StateCheckRules.check_victory(state, events):
			return
	state.priority_player = state.active_player


# 208.3.2 : chaque genre se résout par le module de son chapitre ; les genres de l'étape 1.6
# (Spell, pouvoir du Hero, Gear) et 1.7 (effet déclenché) ne font encore rien.
static func _resolve_entry(state: DuelState, entry: StackEntry, events: Array[DuelEvent]) -> void:
	match entry.kind:
		StackEntry.StackEntryKind.DEPLOY:
			ActionRules.resolve_deploy(state, entry, events)
	events.append(StackEntryResolved.new(entry.owner, entry.stack_entry_id))
