class_name RemoteHostSession
extends HostedDuelSession
## Hôte d'un duel à distance (décisions 0043, 0049 et 0050) : le duel tourne ici, dans `DuelHost`.
## Le créateur de la partie joue A sur cet écran ; B joue depuis le second navigateur, par le
## relais : ses intentions passent par `RemoteHostLink`, et le journal part vers lui à chaque image.

const VIEWER: DuelState.PlayerSide = DuelState.PlayerSide.A
const REMOTE_SIDE: DuelState.PlayerSide = DuelState.PlayerSide.B

var _link: RemoteHostLink
var _connection: RelayConnection
var _clock: MonotonicClock
var _disconnection: String = ""


## `connection` est appariée au second navigateur ; `edition` est celle du catalogue d'ici.
func _init(
	host: DuelHost, duel_setup: DuelSetup, connection: RelayConnection, edition: String
) -> void:
	super(host, duel_setup)
	_connection = connection
	_clock = host.get_clock()
	_link = RemoteHostLink.new(host, REMOTE_SIDE, edition)


func start() -> Array[DuelEvent]:
	var events := super()
	_send_outgoing()
	return events


## Un seul lot par image : celui du temps écoulé, sinon celui d'une intention reçue.
func tick() -> Array[DuelEvent]:
	if not _disconnection.is_empty():
		return []
	_receive()
	var events := super()
	if events.is_empty():
		events = _link.submit_received()
	_send_outgoing()
	_check_connection()
	return events


func submit(intent: DuelIntent) -> Array[DuelEvent]:
	var events := super(intent)
	_send_outgoing()
	return events


func concede() -> Array[DuelEvent]:
	var events := super()
	_send_outgoing()
	return events


func begin_response() -> void:
	super()
	_send_outgoing()


func get_viewer() -> DuelState.PlayerSide:
	return VIEWER


func is_response_window_open() -> bool:
	return _host.get_screen_player() == VIEWER and _host.is_response_window_open()


func get_session_state() -> SessionState:
	if not _disconnection.is_empty():
		return SessionState.DISCONNECTED
	return super()


func get_disconnection() -> String:
	return _disconnection


func is_remote() -> bool:
	return true


func close() -> void:
	_connection.close()


func _receive() -> void:
	_connection.poll()
	for message: RemoteMessage in _connection.take_messages():
		_link.receive(message)


func _send_outgoing() -> void:
	for message: RemoteMessage in _link.take_outgoing(_clock.now_msec()):
		_connection.send(message)


# Après la fin du duel, même pas encore affichée, le départ de l'autre joueur ne change plus rien
# à cet écran : panneau de fin et fiche restent (décision 0050).
func _check_connection() -> void:
	var state := _engine.get_state()
	if state != null and state.is_ended():
		return
	var reason := _link.get_incompatibility()
	if reason.is_empty() and _connection.get_status() == RelayConnection.Status.CLOSED:
		reason = _connection.get_error()
	if reason.is_empty():
		return
	_disconnection = reason
	_connection.close()
	session_state_changed.emit(SessionState.DISCONNECTED)


# Entre les deux joueurs, l'hôte passe l'écran au joueur attendu : ici, ce n'est le joueur de
# l'écran que si c'est A.
func _awaiting_state_of_screen_player() -> SessionState:
	if _host.get_screen_player() == VIEWER:
		return SessionState.AWAITING_VIEWER
	return SessionState.AWAITING_OTHER
