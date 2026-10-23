class_name RemoteGuestSession
extends DuelSession
## Second écran d'un duel à distance (décisions 0043, 0049 et 0050) : le joueur qui rejoint joue B ;
## le duel se rejoue ici, dans une copie du moteur, depuis le journal reçu de l'hôte
## (`RemoteGuestLink`). Ses intentions partent à l'hôte, seul à les soumettre : l'écran attend leurs
## événements, ou leur refus, avant d'accepter un autre geste. Aucune règle ici.

const VIEWER: DuelState.PlayerSide = DuelState.PlayerSide.B

var _link: RemoteGuestLink
var _connection: RelayConnection
var _session_state: SessionState = SessionState.NOT_STARTED
## Événements reçus avant `start()`, préparation comprise.
var _early_events: Array[DuelEvent] = []
var _is_opened: bool = false
## Lots renvoyés dont l'écran n'a pas encore confirmé l'affichage.
var _unplayed_batch_count: int = 0
## Vrai de l'envoi d'une intention à son retour dans le journal de l'hôte, ou à son refus.
var _is_intent_pending: bool = false
var _disconnection: String = ""


## `engine`, pas encore démarré, porte le catalogue et la configuration de l'hôte ; `connection`
## est appariée à l'hôte ; `edition` est celle du catalogue d'ici.
func _init(engine: DuelEngine, connection: RelayConnection, edition: String) -> void:
	_link = RemoteGuestLink.new(engine, VIEWER, edition)
	_connection = connection
	_send_outgoing()


## Avant `start()`, à chaque image : reçoit les messages de l'hôte, gardés pour le démarrage.
## Vrai une fois la préparation reçue : l'écran de duel peut alors démarrer.
func poll_until_ready() -> bool:
	_early_events.append_array(_receive())
	return _link.is_started()


func start() -> Array[DuelEvent]:
	_is_opened = true
	var events := _early_events
	_early_events = []
	_begin_batch(events)
	return events


func tick() -> Array[DuelEvent]:
	if _session_state == SessionState.DISCONNECTED or not _is_opened:
		return []
	var events := _receive()
	_begin_batch(events)
	return events


func submit(intent: DuelIntent) -> Array[DuelEvent]:
	_link.send_intent(intent)
	_send_outgoing()
	_is_intent_pending = true
	_set_session_state(SessionState.AWAITING_OTHER)
	return []


func concede() -> Array[DuelEvent]:
	_link.send_intent(Concede.new(VIEWER))
	_send_outgoing()
	return []


func begin_response() -> void:
	_link.begin_response()
	_send_outgoing()


func confirm_events_played() -> void:
	if _session_state != SessionState.PLAYING_EVENTS:
		return
	_unplayed_batch_count -= 1
	if _unplayed_batch_count == 0:
		_set_session_state(_next_state())


func get_session_state() -> SessionState:
	return _session_state


func get_viewer() -> DuelState.PlayerSide:
	return VIEWER


## Décision 0050 : le joueur qui rejoint voit son camp en bas.
func get_bottom_side() -> DuelState.PlayerSide:
	return VIEWER


## 208.6.1 : comme l'hôte, la fenêtre est ouverte quand le joueur attendu peut passer.
func is_response_window_open() -> bool:
	if _session_state != SessionState.AWAITING_VIEWER:
		return false
	var engine := _link.get_engine()
	return engine.validate(PassPriority.new(VIEWER)) == IntentRejected.RejectReason.NONE


func get_engine() -> DuelEngine:
	return _link.get_engine()


func get_setup() -> DuelSetup:
	return _link.get_journal().setup


func get_journal() -> DuelJournal:
	return _link.get_journal()


func get_disconnection() -> String:
	return _disconnection


func is_remote() -> bool:
	return true


func close() -> void:
	_connection.close()


func _receive() -> Array[DuelEvent]:
	var events: Array[DuelEvent] = []
	_connection.poll()
	for message: RemoteMessage in _connection.take_messages():
		if _answers_pending_intent(message):
			_is_intent_pending = false
		events.append_array(_link.receive(message))
	_send_outgoing()
	_check_connection()
	return events


func _send_outgoing() -> void:
	for message: RemoteMessage in _link.take_outgoing():
		_connection.send(message)


# L'intention envoyée revient au journal de l'hôte, ou refusée ; un coup de l'autre joueur, reçu
# entre-temps (mulligans simultanés, 204.2), n'y répond pas.
func _answers_pending_intent(message: RemoteMessage) -> bool:
	if message.kind == RemoteMessage.Kind.INTENT_REJECTED:
		return true
	return (
		message.kind == RemoteMessage.Kind.JOURNAL_ENTRY
		and message.entry.is_intent()
		and message.entry.intent.player == VIEWER
	)


func _begin_batch(events: Array[DuelEvent]) -> void:
	if events.is_empty():
		return
	_unplayed_batch_count += 1
	_set_session_state(SessionState.PLAYING_EVENTS)


func _next_state() -> SessionState:
	var engine := _link.get_engine()
	if engine.get_state().is_ended():
		return SessionState.ENDED
	if engine.awaited_players().has(VIEWER) and not _is_intent_pending:
		return SessionState.AWAITING_VIEWER
	return SessionState.AWAITING_OTHER


# Après la fin du duel, le départ de l'hôte ne change plus rien à cet écran.
func _check_connection() -> void:
	if _session_state == SessionState.ENDED or _session_state == SessionState.DISCONNECTED:
		return
	var reason := _link.get_incompatibility()
	if reason.is_empty() and _connection.get_status() == RelayConnection.Status.CLOSED:
		reason = _connection.get_error()
	if reason.is_empty():
		return
	_disconnection = reason
	_connection.close()
	_set_session_state(SessionState.DISCONNECTED)


func _set_session_state(session_state: SessionState) -> void:
	_session_state = session_state
	session_state_changed.emit(session_state)
