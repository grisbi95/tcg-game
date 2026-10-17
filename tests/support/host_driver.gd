class_name HostDriver
extends RefCounted
## Fait jouer un DuelHost sans scène (décision 0020) : à chaque image, confirme l'affichage en
## attente, avance l'horloge manuelle d'un pas, puis appelle `tick()`.


## S'arrête à ENDED ou après `max_ticks` images ; renvoie les événements des images jouées.
static func run(
	host: DuelHost, clock: ManualClock, tick_msec: int, max_ticks: int
) -> Array[DuelEvent]:
	var events: Array[DuelEvent] = []
	for tick: int in max_ticks:
		if host.get_host_state() == DuelHost.HostState.ENDED:
			break
		if host.get_host_state() == DuelHost.HostState.PLAYING_EVENTS:
			host.confirm_events_played()
		clock.advance(tick_msec)
		events.append_array(host.tick())
	return events
