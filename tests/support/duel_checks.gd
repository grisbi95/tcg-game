class_name DuelChecks
extends RefCounted
## Contrôles partagés par les suites qui passent par DuelEngine.

## Nombre de passes au plus pour vider une pile : une entrée, son combat en attente, et la marge.
const MAX_PASSES: int = 4


## Écarts d'une soumission refusée : raison différente de `expected`, ou état modifié. Vide si
## `intent` est refusée pour `expected` sans rien changer (décision 0001).
static func rejection_defects(
	engine: DuelEngine, intent: DuelIntent, expected: IntentRejected.RejectReason
) -> PackedStringArray:
	var snapshot := engine.get_state().clone()
	var defects := PackedStringArray()
	var reason := EventLog.rejection_reason(engine.submit(intent))
	if reason != expected:
		defects.append("raison %d au lieu de %d" % [reason, expected])
	defects.append_array(DeepCompare.find_clone_defects(snapshot, engine.get_state()))
	return defects


## `player` passe la priorité : la pile entière se résout d'un bloc (208.3.1, 208.3.1a). Renvoie
## les événements de la soumission ; refusée si `player` n'a pas la priorité (208.2.4).
static func pass_once(engine: DuelEngine, player: DuelState.PlayerSide) -> Array[DuelEvent]:
	return engine.submit(PassPriority.new(player))


## Le joueur qui a la priorité passe tant que la pile n'est pas vide : une entrée posée à la main
## se résout, puis chaque combat en attente qu'elle fait naître (205.6.4, 208.7.14). Renvoie les
## événements de toutes les passes.
static func pass_until_stack_empty(engine: DuelEngine) -> Array[DuelEvent]:
	var events: Array[DuelEvent] = []
	var state := engine.get_state()
	for pass_index: int in MAX_PASSES:
		if state.stack.is_empty():
			break
		events.append_array(pass_once(engine, state.priority_player))
	return events


## Vrai si l'étiquette décrit un événement `HeroPlaced`.
static func is_hero_placed(label: String) -> bool:
	return label.begins_with("HeroPlaced")


static func card_ids(cards: Array[CardInstance]) -> Array[int]:
	var identifiers: Array[int] = []
	for card: CardInstance in cards:
		identifiers.append(card.card_instance_id)
	return identifiers
