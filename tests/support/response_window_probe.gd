class_name ResponseWindowProbe
extends RefCounted
## Ce que l'hôte laisse voir d'une fenêtre de réponse laissée ouverte longtemps (208.6.2).

var playable_reaction_count: int = 0
var was_open_at_opening: bool = false
var labels_after_wait: Array[String] = []
var is_open_after_wait: bool = false


## La fenêtre est déjà ouverte ; la pendule avance de `wait_msec` sans geste du joueur.
static func run_long_wait(
	host: DuelHost, clock: ManualClock, wait_msec: int
) -> ResponseWindowProbe:
	var probe := ResponseWindowProbe.new()
	probe.was_open_at_opening = host.is_response_window_open()
	clock.advance(wait_msec)
	probe.labels_after_wait = EventLog.describe(host.tick())
	probe.is_open_after_wait = host.is_response_window_open()
	return probe


## Cartes de la main que le joueur peut lancer maintenant en payant `essence_cost` d'Essence.
static func count_castable(
	engine: DuelEngine, side: DuelState.PlayerSide, essence_cost: int
) -> int:
	var count := 0
	for card: CardInstance in engine.get_state().get_player(side).hand:
		var cast := CastSpell.new(side, card.card_instance_id, EssencePayment.new(essence_cost))
		if engine.validate(cast) == IntentRejected.RejectReason.NONE:
			count += 1
	return count
