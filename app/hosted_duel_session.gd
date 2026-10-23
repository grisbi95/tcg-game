class_name HostedDuelSession
extends DuelSession
## Duel qui tourne sur cet appareil, dans `DuelHost` (décisions 0020 et 0050) : deux humains sur un
## même écran, ou un humain contre un agent. Entre deux humains, le relais est confirmé aussitôt et
## l'écran passe au joueur attendu, sans rideau (décision 0048). Aucune règle ici.

var _host: DuelHost
var _engine: DuelEngine
var _setup: DuelSetup


## `host` n'a pas encore démarré de duel ; `duel_setup` le démarre à `start()`.
func _init(host: DuelHost, duel_setup: DuelSetup) -> void:
	_host = host
	_engine = host.get_engine()
	_setup = duel_setup
	_host.host_state_changed.connect(_on_host_state_changed)


func start() -> Array[DuelEvent]:
	return _host.start(_setup)


func tick() -> Array[DuelEvent]:
	return _host.tick()


func submit(intent: DuelIntent) -> Array[DuelEvent]:
	return _host.submit_human(intent)


func concede() -> Array[DuelEvent]:
	return _host.concede(get_viewer())


func begin_response() -> void:
	_host.begin_response()


# Décision 0048 : le relais suit l'affichage, seul moment où l'hôte le demande.
func confirm_events_played() -> void:
	_host.confirm_events_played()
	if _host.get_host_state() == DuelHost.HostState.RELAY:
		_host.confirm_relay()


func get_session_state() -> SessionState:
	return _session_state_of(_host.get_host_state())


func get_viewer() -> DuelState.PlayerSide:
	return _host.get_screen_player()


func is_response_window_open() -> bool:
	return _host.is_response_window_open()


func get_engine() -> DuelEngine:
	return _engine


func get_setup() -> DuelSetup:
	return _setup


func get_journal() -> DuelJournal:
	return _host.get_journal()


# Le relais (RELAY) est passager : l'hôte le quitte dès que la session le confirme.
func _session_state_of(host_state: DuelHost.HostState) -> SessionState:
	match host_state:
		DuelHost.HostState.NOT_STARTED:
			return SessionState.NOT_STARTED
		DuelHost.HostState.PLAYING_EVENTS:
			return SessionState.PLAYING_EVENTS
		DuelHost.HostState.AWAITING_HUMAN:
			return _awaiting_state_of_screen_player()
		DuelHost.HostState.ENDED:
			return SessionState.ENDED
	return SessionState.AWAITING_OTHER


func _on_host_state_changed(host_state: DuelHost.HostState) -> void:
	if host_state != DuelHost.HostState.RELAY:
		session_state_changed.emit(_session_state_of(host_state))


# Sur un même appareil, le joueur devant l'écran est toujours celui de l'écran.
func _awaiting_state_of_screen_player() -> SessionState:
	return SessionState.AWAITING_VIEWER
