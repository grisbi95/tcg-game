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


static func card_ids(cards: Array[CardInstance]) -> Array[int]:
	var identifiers: Array[int] = []
	for card: CardInstance in cards:
		identifiers.append(card.card_instance_id)
	return identifiers
