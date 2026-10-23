class_name DuelHost
extends RefCounted
## Hôte du duel (décisions 0020 et 0021) : machine à états qui fait jouer humains et agents,
## attend l'affichage des événements et le relais entre deux joueurs humains, et avance le
## temps de tour et de réponse du temps réel écoulé ; tient le journal du duel (décision 0022).
##
## Aucune règle ici : chaque intention passe par `DuelEngine.submit()`. La scène qui l'anime
## appelle `tick()` à chaque image et lui transmet les gestes ; les événements renvoyés sont les
## seuls faits de jeu (décision 0006). 209.4.4f : le temps tourne aussi pendant le relais et
## l'affichage des événements. Décision 0029 : l'hôte ouvre et ferme la fenêtre de réponse
## (208.6), que l'expiration du temps de réponse ferme aussi (209.4.10, décision 0045) ;
## décision 0042 : il en journalise le temps et les réponses commencées, pour le relevé.

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
## plusieurs étapes (coup d'un agent puis expiration d'un temps, par exemple) ; il est compté à un
## seul endroit, `_close_batch()`, par lequel sort chacun de ces appels.
var _unplayed_batch_count: int = 0
## Vrai quand l'appel public en cours a des événements à afficher, pas encore comptés.
var _is_display_pending: bool = false
var _awaited_player: DuelState.PlayerSide = DuelState.PlayerSide.A
## Joueur humain devant l'écran ; sans objet tant que `_is_screen_assigned` est faux.
var _screen_player: DuelState.PlayerSide = DuelState.PlayerSide.A
var _is_screen_assigned: bool = false
## Décision 0029 : fenêtre de réponse ouverte au joueur attendu (208.6.1), jusqu'à son geste.
var _is_response_window_open: bool = false
## Décision 0042 : le temps compté depuis cet instant, fenêtre ouverte, s'inscrit au journal
## comme temps de fenêtre de réponse (208.6.2).
var _response_opened_msec: int = 0
## Entrée au sommet de la pile à l'ouverture de la fenêtre : la même occasion de répondre,
## retrouvée après un coup qui ne la change pas (Essence produite), ne compte qu'une réponse
## commencée (décision 0042).
var _response_stack_entry_id: int = DuelState.NO_ID
var _has_response_begun: bool = false


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


## Décision 0042 : le joueur devant l'écran commence une réponse pendant sa fenêtre ; le journal
## le note pour le relevé (208.6.2), une fois par occasion de répondre (entrée au sommet de la
## pile), même si la fenêtre se rouvre après une production d'Essence. La fenêtre reste ouverte.
## Sans effet hors d'une fenêtre de réponse.
func begin_response() -> void:
	if not _is_response_window_open or _has_response_begun:
		return
	_has_response_begun = true
	_journal.record_response_begun(_awaited_player)


## Décision 0029 : vrai tant que la fenêtre de réponse est montrée au joueur attendu (208.6.1),
## de son ouverture à l'affichage des événements de son geste (208.6.2).
func is_response_window_open() -> bool:
	return _is_response_window_open


## Moteur mené par l'hôte, pour les vues et la session (décision 0050).
func get_engine() -> DuelEngine:
	return _engine


## Horloge du temps réel de l'hôte (décision 0021), que suit aussi l'envoi du journal à distance.
func get_clock() -> MonotonicClock:
	return _clock


func get_host_state() -> HostState:
	return _host_state


## Décisions 0022 et 0042 : préparation, puis intentions acceptées, temps écoulé, temps des
## fenêtres de réponse et réponses commencées depuis `start()`.
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


# Décision 0021 : le temps réel écoulé compte avant tout geste ; décision 0045 : le moteur
# applique lui-même l'expiration (209.4.9, 209.4.10) et l'hôte en affiche les événements.
func _tick_steps() -> Array[DuelEvent]:
	var events := _advance_clock_until(_clock.now_msec())
	if _host_state == HostState.AWAITING_AI:
		events.append_array(_play_agent())
	return events


func _submit_human_steps(intent: DuelIntent) -> Array[DuelEvent]:
	var events: Array[DuelEvent] = []
	if _host_state != HostState.AWAITING_HUMAN or intent.player != _screen_player:
		return events
	events = _advance_clock_until(_clock.now_msec())
	if _host_state == HostState.AWAITING_HUMAN:
		events.append_array(_submit(intent))
	return events


func _concede_steps(side: DuelState.PlayerSide) -> Array[DuelEvent]:
	var events: Array[DuelEvent] = []
	if _agents.has(side) or not _is_duel_running():
		return events
	events = _advance_clock_until(_clock.now_msec())
	if not _engine.get_state().is_ended():
		events.append_array(_submit(Concede.new(side)))
	return events


# 209.4.4f, décision 0021 : le temps tourne dans tout état du duel en cours.
func _advance_clock_until(until_msec: int) -> Array[DuelEvent]:
	var events: Array[DuelEvent] = []
	if not _is_duel_running() or _engine.get_state().is_ended():
		return events
	var from_msec := _last_clock_msec
	_last_clock_msec = until_msec
	_journal_elapsed(from_msec, until_msec)
	events = _engine.advance_clock(until_msec - from_msec)
	if not events.is_empty():
		_await_display()
	return events


# Décision 0042 : la part écoulée fenêtre ouverte s'inscrit comme temps de fenêtre de réponse du
# joueur attendu (208.6.2, 209.4.4g), le reste comme temps ordinaire.
func _journal_elapsed(from_msec: int, until_msec: int) -> void:
	if not _is_response_window_open:
		_journal.record_elapsed(until_msec - from_msec)
		return
	var window_from_msec := clampi(_response_opened_msec, from_msec, until_msec)
	_journal.record_elapsed(window_from_msec - from_msec)
	_journal.record_response_window_elapsed(_awaited_player, until_msec - window_from_msec)


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


# Des événements à afficher closent la fenêtre de réponse : passe (208.6.4), réponse (208.6.2) ou
# expiration du temps de réponse (209.4.10).
func _await_display() -> void:
	_is_response_window_open = false
	_is_display_pending = true
	_change_state(HostState.PLAYING_EVENTS)


# Un appel public qui a des événements à afficher compte un seul lot, quelles que soient ses étapes.
func _close_batch(events: Array[DuelEvent]) -> Array[DuelEvent]:
	if _is_display_pending:
		_unplayed_batch_count += 1
		_is_display_pending = false
	return events


# Décision 0020 : une fois tous les lots affichés, l'hôte attend le joueur que désigne le moteur.
func _choose_next_state() -> void:
	if _engine.get_state().is_ended():
		_change_state(HostState.ENDED)
		return
	var owners := _engine.awaited_players()
	if owners.is_empty():
		push_error("DuelHost : duel en cours sans joueur attendu")
		return
	_awaited_player = owners[0]
	var next_state := _state_for_awaited_player()
	match next_state:
		HostState.AWAITING_HUMAN:
			_await_human()
		HostState.AWAITING_AI, HostState.RELAY:
			_change_state(next_state)


func _state_for_awaited_player() -> HostState:
	if _agents.has(_awaited_player):
		return HostState.AWAITING_AI
	if _needs_relay():
		return HostState.RELAY
	return HostState.AWAITING_HUMAN


# 208.6.1 : entre deux humains, la fenêtre ne s'ouvre qu'une fois l'appareil passé.
func _await_human() -> void:
	_assign_screen(_awaited_player)
	_open_response_window()
	_change_state(HostState.AWAITING_HUMAN)


# 208.6.1, 208.6.6, 208.6.7 : une fenêtre, la même pour tous, s'ouvre chaque fois que le joueur
# peut répondre ou passer, et seulement alors ; le moteur seul dit s'il peut passer. Celle d'avant
# s'est fermée à l'affichage des événements ; la même occasion, retrouvée, rouvre la fenêtre sans
# compter une seconde réponse commencée (décision 0042).
func _open_response_window() -> void:
	if _engine.validate(PassPriority.new(_awaited_player)) != IntentRejected.RejectReason.NONE:
		_response_stack_entry_id = DuelState.NO_ID
		return
	var top_entry: StackEntry = _engine.get_state().stack.back()
	if top_entry.stack_entry_id != _response_stack_entry_id:
		_response_stack_entry_id = top_entry.stack_entry_id
		_has_response_begun = false
	_response_opened_msec = _clock.now_msec()
	_is_response_window_open = true


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
