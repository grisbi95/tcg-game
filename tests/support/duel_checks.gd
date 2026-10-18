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


## `player` passe la priorité : la pile entière se résout d'un bloc (208.3.1, 208.3.1a). Renvoie
## les événements de la soumission ; refusée si `player` n'a pas la priorité (208.2.4).
static func pass_once(engine: DuelEngine, player: DuelState.PlayerSide) -> Array[DuelEvent]:
	return engine.submit(PassPriority.new(player))


## Vrai si l'étiquette décrit un événement `HeroPlaced`.
static func is_hero_placed(label: String) -> bool:
	return label.begins_with("HeroPlaced")


static func card_ids(cards: Array[CardInstance]) -> Array[int]:
	var identifiers: Array[int] = []
	for card: CardInstance in cards:
		identifiers.append(card.card_instance_id)
	return identifiers
