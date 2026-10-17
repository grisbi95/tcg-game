class_name DuelHost
extends RefCounted
## Hôte du duel (décisions 0020 et 0021) : machine à états qui fait jouer humains et agents,
## attend l'affichage des événements et le relais entre deux joueurs humains, et avance la
## pendule du temps réel écoulé ; tient le journal du duel (décision 0022).
##
## Aucune règle ici : chaque intention passe par `DuelEngine.submit()`. La scène qui l'anime
## appelle `tick()` à chaque image et lui transmet les gestes ; les événements renvoyés sont les
## seuls faits de jeu (décision 0006). 209.4.4f : la pendule tourne aussi pendant le relais et
## l'affichage des événements.

signal host_state_changed(host_state: HostState)

## Enum journalisable : ajouter à la fin, sans réordonner.
enum HostState {
	AWAITING_HUMAN,
	PLAYING_EVENTS,
	AWAITING_AI,
	RELAY,
	ENDED,
	NOT_STARTED,
}

var _engine: DuelEngine
var _clock: MonotonicClock
var _journal: DuelJournal = DuelJournal.new()
## Joueurs confiés à un agent ; les autres sont humains.
var _agents: Dictionary[DuelState.PlayerSide, DuelAgent] = {}
var _host_state: HostState = HostState.NOT_STARTED
var _last_clock_msec: int = 0
## Lots d'événements renvoyés dont la scène n'a pas encore confirmé l'affichage.
var _unplayed_batch_count: int = 0
var _awaited_player: DuelState.PlayerSide = DuelState.PlayerSide.A
## Joueur humain devant l'écran ; sans objet tant que `_is_screen_assigned` est faux.
var _screen_player: DuelState.PlayerSide = DuelState.PlayerSide.A
var _is_screen_assigned: bool = false


## `engine` n'a pas encore démarré de duel ; `clock` est remplacée par une horloge manuelle dans
## les tests (décision 0021).
func _init(engine: DuelEngine, clock: MonotonicClock = MonotonicClock.new()) -> void:
	_engine = engine
	_clock = clock


## Confie le joueur `side` à `agent`, avant `start()` ; sans agent, le joueur est humain.
func set_agent(side: DuelState.PlayerSide, agent: DuelAgent) -> void:
	_agents[side] = agent


## Décision 0012 : démarre le duel et renvoie ses premiers événements, à afficher. Un setup
## refusé laisse l'hôte en NOT_STARTED.
func start(setup: DuelSetup) -> Array[DuelEvent]:
	var events := _engine.start_new_duel(setup)
	if events.any(func(event: DuelEvent) -> bool: return event is DuelSetupRejected):
		return events
	_journal = DuelJournal.new(setup, _engine.get_state().catalog.edition)
	_last_clock_msec = _clock.now_msec()
	_assign_screen_to_single_human()
	_await_display()
	return events


## À chaque image : décompte le temps réel écoulé, puis fait jouer l'agent attendu. Renvoie les
## événements produits, à afficher.
func tick() -> Array[DuelEvent]:
	var events := _advance_clock()
	if _host_state == HostState.AWAITING_AI:
		events.append_array(_play_agent())
	return events


## Intention de l'humain devant l'écran, après décompte du temps écoulé jusque-là. Ignorée, sans
## aucun événement, hors AWAITING_HUMAN ou si elle vient d'un autre joueur.
func submit_human(intent: DuelIntent) -> Array[DuelEvent]:
	var events: Array[DuelEvent] = []
	if _host_state != HostState.AWAITING_HUMAN or intent.player != _screen_player:
		return events
	events = _advance_clock()
	if _host_state == HostState.AWAITING_HUMAN:
		events.append_array(_submit(intent))
	return events


## 209.2.5 : un joueur humain abandonne, à tout moment du duel en cours, même hors de son
## tour ; le temps écoulé jusque-là est d'abord décompté. Ignoré pour un joueur confié à un agent.
func concede(side: DuelState.PlayerSide) -> Array[DuelEvent]:
	var events: Array[DuelEvent] = []
	if _agents.has(side) or not _is_duel_running():
		return events
	events = _advance_clock()
	if not _engine.get_state().is_ended():
		events.append_array(_submit(Concede.new(side)))
	return events


## La scène a fini d'afficher le plus ancien lot d'événements qu'elle n'avait pas confirmé.
func confirm_events_played() -> void:
	if _host_state != HostState.PLAYING_EVENTS:
		return
	_unplayed_batch_count -= 1
	if _unplayed_batch_count == 0:
		_choose_next_state()


## Le joueur attendu a pris l'appareil.
func confirm_relay() -> void:
	if _host_state != HostState.RELAY:
		return
	_assign_screen(_awaited_player)
	_change_state(HostState.AWAITING_HUMAN)


func get_host_state() -> HostState:
	return _host_state


## Décision 0022 : préparation, intentions acceptées et temps écoulé depuis `start()`.
func get_journal() -> DuelJournal:
	return _journal


## Joueur dont on attend une intention, hors NOT_STARTED, PLAYING_EVENTS et ENDED.
func get_awaited_player() -> DuelState.PlayerSide:
	return _awaited_player


## Joueur humain devant l'écran, dont la vue montre ce qu'il peut voir (201.4).
func get_screen_player() -> DuelState.PlayerSide:
	return _screen_player


# 209.4.4f, décision 0021 : la pendule tourne dans tout état du duel en cours.
func _advance_clock() -> Array[DuelEvent]:
	var events: Array[DuelEvent] = []
	if not _is_duel_running() or _engine.get_state().is_ended():
		return events
	var now_msec := _clock.now_msec()
	var elapsed_msec := now_msec - _last_clock_msec
	_last_clock_msec = now_msec
	_journal.record_elapsed(elapsed_msec)
	events = _engine.advance_clock(elapsed_msec)
	if not events.is_empty():
		_await_display()
	return events


func _play_agent() -> Array[DuelEvent]:
	var intent := _agents[_awaited_player].choose_intent(_engine)
	if intent == null:
		push_error("DuelHost : l'agent du joueur attendu ne propose aucune intention")
		return []
	var events := _submit(intent)
	if _host_state == HostState.AWAITING_AI:
		push_error("DuelHost : intention de l'agent refusée par le moteur")
	return events


# Une intention refusée ne change rien : l'hôte reste dans son état, et le journal ne la garde pas.
func _submit(intent: DuelIntent) -> Array[DuelEvent]:
	var events := _engine.submit(intent)
	if not (events.size() == 1 and events[0] is IntentRejected):
		_journal.record_intent(intent)
		_await_display()
	return events


func _await_display() -> void:
	_unplayed_batch_count += 1
	_change_state(HostState.PLAYING_EVENTS)


func _choose_next_state() -> void:
	if _engine.get_state().is_ended():
		_change_state(HostState.ENDED)
		return
	var owners := _engine.awaited_players()
	if owners.is_empty():
		push_error("DuelHost : duel en cours sans joueur attendu")
		return
	_awaited_player = owners[0]
	if _agents.has(_awaited_player):
		_change_state(HostState.AWAITING_AI)
	elif _needs_relay():
		_change_state(HostState.RELAY)
	else:
		_assign_screen(_awaited_player)
		_change_state(HostState.AWAITING_HUMAN)


# Le relais ne sert qu'entre deux humains, y compris pour appeler le premier à l'écran.
func _needs_relay() -> bool:
	if not _agents.is_empty():
		return false
	return not _is_screen_assigned or _screen_player != _awaited_player


func _assign_screen_to_single_human() -> void:
	if _agents.size() != DuelState.PLAYER_COUNT - 1:
		return
	for side: DuelState.PlayerSide in DuelState.SIDES:
		if not _agents.has(side):
			_assign_screen(side)


func _assign_screen(side: DuelState.PlayerSide) -> void:
	_screen_player = side
	_is_screen_assigned = true


func _is_duel_running() -> bool:
	return _host_state != HostState.NOT_STARTED and _host_state != HostState.ENDED


# Un second lot d'événements pendant PLAYING_EVENTS ne change pas l'état : aucun signal.
func _change_state(host_state: HostState) -> void:
	if host_state == _host_state:
		return
	_host_state = host_state
	host_state_changed.emit(host_state)
