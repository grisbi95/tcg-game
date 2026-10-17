class_name DuelChecks
extends RefCounted
## Contrôles partagés par les suites qui passent par DuelEngine.


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


## `first` puis son adversaire passent la priorité l'un après l'autre (208.3.1). Renvoie les
## événements des deux soumissions.
static func pass_twice(engine: DuelEngine, first: DuelState.PlayerSide) -> Array[DuelEvent]:
	var events := engine.submit(PassPriority.new(first))
	events.append_array(engine.submit(PassPriority.new(DuelState.opponent_of(first))))
	return events


## Vrai si l'étiquette décrit un événement `HeroPlaced`.
static func is_hero_placed(label: String) -> bool:
	return label.begins_with("HeroPlaced")


static func card_ids(cards: Array[CardInstance]) -> Array[int]:
	var identifiers: Array[int] = []
	for card: CardInstance in cards:
		identifiers.append(card.card_instance_id)
	return identifiers
