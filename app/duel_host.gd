class_name DuelHost
extends RefCounted
## Hôte du duel (décisions 0020 et 0021) : machine à états qui fait jouer humains et agents,
## attend l'affichage des événements et le relais entre deux joueurs humains, et avance la
## pendule du temps réel écoulé ; tient le journal du duel (décision 0022).
##
## Aucune règle ici : chaque intention passe par `DuelEngine.submit()`. La scène qui l'anime
## appelle `tick()` à chaque image et lui transmet les gestes ; les événements renvoyés sont les
## seuls faits de jeu (décision 0006). 209.4.4f : la pendule tourne aussi pendant le relais et
## l'affichage des événements. Décision 0029 : l'hôte décompte la fenêtre de réponse (208.6).

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
## Lots d'événements renvoyés dont la scène n'a pas encore confirmé l'affichage. Un lot est ce
## que renvoie un appel public (`start`, `tick`, `submit_human`, `concede`), même s'il réunit
## plusieurs étapes (passe automatique puis fin de la pendule, par exemple) ; il est compté à un
## seul endroit, `_close_batch()`, par lequel sort chacun de ces appels.
var _unplayed_batch_count: int = 0
## Vrai quand l'appel public en cours a des événements à afficher, pas encore comptés.
var _is_display_pending: bool = false
var _awaited_player: DuelState.PlayerSide = DuelState.PlayerSide.A
## Joueur humain devant l'écran ; sans objet tant que `_is_screen_assigned` est faux.
var _screen_player: DuelState.PlayerSide = DuelState.PlayerSide.A
var _is_screen_assigned: bool = false
## Décision 0029 : décompte de la fenêtre de réponse du joueur attendu (208.6.1).
var _is_response_window_running: bool = false
var _response_deadline_msec: int = 0
## Entrée au sommet de la pile à l'ouverture de la dernière fenêtre : retrouver la même occasion
## de répondre, après un coup qui ne la change pas (Essence produite), n'en rouvre pas (208.6.5a).
var _response_stack_entry_id: int = DuelState.NO_ID


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
	return _close_batch(_start_steps(setup))


## À chaque image : décompte le temps réel écoulé, puis fait jouer l'agent attendu. Renvoie les
## événements produits, à afficher.
func tick() -> Array[DuelEvent]:
	return _close_batch(_tick_steps())


## Intention de l'humain devant l'écran, après décompte du temps écoulé jusque-là. Ignorée, sans
## aucun événement, hors AWAITING_HUMAN ou si elle vient d'un autre joueur.
func submit_human(intent: DuelIntent) -> Array[DuelEvent]:
	return _close_batch(_submit_human_steps(intent))


## 209.2.5 : un joueur humain abandonne, à tout moment du duel en cours, même hors de son
## tour ; le temps écoulé jusque-là est d'abord décompté. Ignoré pour un joueur confié à un agent.
func concede(side: DuelState.PlayerSide) -> Array[DuelEvent]:
	return _close_batch(_concede_steps(side))


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
	_await_human()


## 208.6.5 : le joueur devant l'écran commence une réponse ; le décompte de sa fenêtre s'arrête
## et ne reprend pas (208.6.5a). Sans effet hors d'une fenêtre de réponse, ou après son échéance :
## la passe automatique du prochain `tick()` l'emporte (208.6.3).
func begin_response() -> void:
	if _host_state != HostState.AWAITING_HUMAN or _clock.now_msec() >= _response_deadline_msec:
		return
	_is_response_window_running = false


## Décision 0029 : vrai tant que court le décompte de la fenêtre de réponse (208.6.1, 208.6.5).
func is_response_window_running() -> bool:
	return _is_response_window_running


## Temps restant de la fenêtre de réponse, à afficher ; 0 hors décompte.
func get_response_time_left_msec() -> int:
	if not _is_response_window_running:
		return 0
	return maxi(_response_deadline_msec - _clock.now_msec(), 0)


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


func _start_steps(setup: DuelSetup) -> Array[DuelEvent]:
	var events := _engine.start_new_duel(setup)
	if events.any(func(event: DuelEvent) -> bool: return event is DuelSetupRejected):
		return events
	_journal = DuelJournal.new(setup, _engine.get_state().catalog.edition)
	_last_clock_msec = _clock.now_msec()
	_assign_screen_to_single_human()
	_await_display()
	return events


func _tick_steps() -> Array[DuelEvent]:
	var events := _count_elapsed_time()
	if _host_state == HostState.AWAITING_AI:
		events.append_array(_play_agent())
	return events


func _submit_human_steps(intent: DuelIntent) -> Array[DuelEvent]:
	var events: Array[DuelEvent] = []
	if _host_state != HostState.AWAITING_HUMAN or intent.player != _screen_player:
		return events
	events = _count_elapsed_time()
	if _host_state == HostState.AWAITING_HUMAN:
		events.append_array(_submit(intent))
	return events


func _concede_steps(side: DuelState.PlayerSide) -> Array[DuelEvent]:
	var events: Array[DuelEvent] = []
	if _agents.has(side) or not _is_duel_running():
		return events
	events = _count_elapsed_time()
	if not _engine.get_state().is_ended():
		events.append_array(_submit(Concede.new(side)))
	return events


# Décision 0021 : le temps réel écoulé compte avant tout geste ; 208.6.3 : une fenêtre de réponse
# échue fait d'abord passer son joueur.
func _count_elapsed_time() -> Array[DuelEvent]:
	var events := _expire_response_window()
	events.append_array(_advance_clock_until(_clock.now_msec()))
	return events


# 208.6.3, 209.4.4g : la pendule compte jusqu'à l'échéance, puis le joueur silencieux passe.
func _expire_response_window() -> Array[DuelEvent]:
	var events: Array[DuelEvent] = []
	if not _is_response_window_running or _host_state != HostState.AWAITING_HUMAN:
		return events
	if _clock.now_msec() < _response_deadline_msec:
		return events
	_is_response_window_running = false
	events = _advance_clock_until(maxi(_response_deadline_msec, _last_clock_msec))
	if _host_state == HostState.AWAITING_HUMAN:
		events.append_array(_submit(PassPriority.new(_awaited_player)))
	return events


# 209.4.4f, décision 0021 : la pendule tourne dans tout état du duel en cours.
func _advance_clock_until(until_msec: int) -> Array[DuelEvent]:
	var events: Array[DuelEvent] = []
	if not _is_duel_running() or _engine.get_state().is_ended():
		return events
	var elapsed_msec := until_msec - _last_clock_msec
	_last_clock_msec = until_msec
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


# Des événements à afficher closent la fenêtre de réponse : passe (208.6.4), réponse (208.6.5) ou
# fin du duel par la pendule (209.4.5).
func _await_display() -> void:
	_is_response_window_running = false
	_is_display_pending = true
	_change_state(HostState.PLAYING_EVENTS)


# Un appel public qui a des événements à afficher compte un seul lot, quelles que soient ses étapes.
func _close_batch(events: Array[DuelEvent]) -> Array[DuelEvent]:
	if _is_display_pending:
		_unplayed_batch_count += 1
		_is_display_pending = false
	return events


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
		_await_human()


# 208.6.1 : entre deux humains, la fenêtre ne s'ouvre qu'une fois l'appareil passé.
func _await_human() -> void:
	_assign_screen(_awaited_player)
	_open_response_window()
	_change_state(HostState.AWAITING_HUMAN)


# 208.6.1, 208.6.6, 208.6.7 : une fenêtre, la même pour tous, s'ouvre à chaque nouvelle occasion
# de répondre ou passer, et seulement alors ; le moteur seul dit si le joueur peut passer. Celle
# d'avant s'est fermée à l'affichage des événements ; la même occasion ne la rouvre pas (208.6.5a).
func _open_response_window() -> void:
	if _engine.validate(PassPriority.new(_awaited_player)) != IntentRejected.RejectReason.NONE:
		_response_stack_entry_id = DuelState.NO_ID
		return
	var top_entry: StackEntry = _engine.get_state().stack.back()
	if top_entry.stack_entry_id == _response_stack_entry_id:
		return
	_response_stack_entry_id = top_entry.stack_entry_id
	_response_deadline_msec = _clock.now_msec() + _engine.get_state().config.response_window_msec
	_is_response_window_running = true


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
