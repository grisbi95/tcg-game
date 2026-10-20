class_name ResponseWindowProbe
extends RefCounted
## Ce que l'hôte laisse voir d'une fenêtre de réponse menée jusqu'à son échéance (208.6).

var playable_reaction_count: int = 0
var was_running_at_opening: bool = false
var time_left_at_opening_msec: int = 0
var time_left_before_deadline_msec: int = 0
var labels_before_deadline: Array[String] = []
var labels_at_deadline: Array[String] = []


## La fenêtre est déjà ouverte ; la pendule avance jusqu'à l'échéance, en deux temps.
static func run_to_deadline(
	host: DuelHost, clock: ManualClock, window_msec: int
) -> ResponseWindowProbe:
	var probe := ResponseWindowProbe.new()
	probe.was_running_at_opening = host.is_response_window_running()
	probe.time_left_at_opening_msec = host.get_response_time_left_msec()
	clock.advance(window_msec - 1)
	probe.labels_before_deadline = EventLog.describe(host.tick())
	probe.time_left_before_deadline_msec = host.get_response_time_left_msec()
	clock.advance(1)
	probe.labels_at_deadline = EventLog.describe(host.tick())
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
