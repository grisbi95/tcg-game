class_name TimeExpired
extends PlayerEvent
## 209.4.9 à 209.4.14 : le temps de tour ou le temps de réponse du joueur atteint 0 seconde ;
## `consequence` dit ce que l'expiration produit, et ses événements suivent.

## Conséquence d'une expiration.
enum Consequence {
	TURN_ENDED,  # 209.4.9
	PRIORITY_PASSED,  # 209.4.10
	TARGETS_ABANDONED,  # 209.4.11a
	TRIGGERS_ORDERED,  # 209.4.12
	CARDS_DISCARDED_AT_RANDOM,  # 209.4.13 : cartes tirées au sort parmi la main
	TOP_CARD_PLACE_DRAWN_AT_RANDOM,  # 209.4.14 : dessus ou dessous tiré au sort
}

var kind: DuelState.ClockKind = DuelState.ClockKind.TURN
var consequence: Consequence = Consequence.TURN_ENDED


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A,
	clock_kind: DuelState.ClockKind = DuelState.ClockKind.TURN,
	expiry_consequence: Consequence = Consequence.TURN_ENDED
) -> void:
	super(concerned_player)
	kind = clock_kind
	consequence = expiry_consequence
