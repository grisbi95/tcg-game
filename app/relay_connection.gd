class_name RelayConnection
extends RefCounted
## Connexion au relais du duel à distance (décisions 0043 et 0049, `tools/relay/`) : crée une
## partie et reçoit son code, ou rejoint une partie par son code, puis échange des
## `RemoteMessage` avec l'autre navigateur. WebSocket de Godot, sans thread : la scène appelle
## `poll()` à chaque image. Aucune règle ici.
##
## Messages de contrôle du relais, en JSON, reconnus à leur clé `relay` : le client envoie
## `create` ou `join` (avec `code`) ; le relais répond `created` (avec `code`), `paired`,
## `peer_left` ou `error` (avec `reason`). Une fois les deux navigateurs appariés, tout autre
## message passe tel quel de l'un à l'autre.

enum Status {
	IDLE,
	CONNECTING,
	WAITING_FOR_PEER,
	PAIRED,
	CLOSED,
}

const RELAY_KEY: String = "relay"
## Raisons d'erreur du relais, en texte à afficher.
const ERROR_TEXTS: Dictionary[String, String] = {
	"unknown_code": "aucune partie n'a ce code",
	"room_full": "cette partie a déjà deux joueurs",
	"bad_request": "demande refusée par le relais",
}

var _socket: WebSocketPeer = WebSocketPeer.new()
var _status: Status = Status.IDLE
## Demande `create` ou `join`, envoyée dès l'ouverture de la connexion.
var _opening_request: Dictionary = {}
var _room_code: String = ""
var _error: String = ""
## Reçus, en attente de `take_messages()` : la préparation les laisse au duel qui suit.
var _received: Array[RemoteMessage] = []


## Ouvre une partie sur le relais à `url` (`ws://` ou `wss://`) ; son code arrive par `poll()`.
func create_room(url: String) -> void:
	_open(url, {RELAY_KEY: "create"})


## Rejoint la partie de code `code` sur le relais à `url`.
func join_room(url: String, code: String) -> void:
	_open(url, {RELAY_KEY: "join", "code": code.strip_edges().to_upper()})


## À chaque image : fait avancer la connexion ; les messages reçus de l'autre navigateur
## attendent `take_messages()`. Un message illisible est ignoré.
func poll() -> void:
	if _status == Status.IDLE:
		return
	# Fermée, la connexion doit encore être interrogée pour achever la fermeture côté relais.
	_socket.poll()
	if _status == Status.CLOSED:
		return
	var socket_state := _socket.get_ready_state()
	if socket_state == WebSocketPeer.STATE_OPEN:
		_send_opening_request()
	# Le relais ferme juste après son dernier message (départ de l'autre joueur, erreur) : les
	# messages arrivés se lisent avant de constater la fermeture.
	_read_packets()
	if socket_state == WebSocketPeer.STATE_CLOSED and _status != Status.CLOSED:
		_close_with("connexion au relais perdue")


## Messages reçus de l'autre navigateur depuis le dernier appel, dans l'ordre.
func take_messages() -> Array[RemoteMessage]:
	var messages := _received
	_received = []
	return messages


## Envoie `message` à l'autre navigateur ; sans effet avant l'appariement.
func send(message: RemoteMessage) -> void:
	if _status == Status.PAIRED:
		_socket.send_text(message.to_json())


func close() -> void:
	_socket.close()
	_status = Status.CLOSED


func get_status() -> Status:
	return _status


## Code de la partie créée, à donner à l'autre joueur ; vide avant sa réception.
func get_room_code() -> String:
	return _room_code


## Raison, à afficher, de la fermeture de la connexion ; vide tant qu'elle n'est pas fermée.
func get_error() -> String:
	return _error


func _open(url: String, request: Dictionary) -> void:
	_error = ""
	_room_code = ""
	_opening_request = request
	if _socket.connect_to_url(url) != OK:
		_close_with("adresse du relais invalide")
		return
	_status = Status.CONNECTING


func _send_opening_request() -> void:
	if _opening_request.is_empty():
		return
	_socket.send_text(JSON.stringify(_opening_request))
	_opening_request = {}
	_status = Status.WAITING_FOR_PEER


func _read_packets() -> void:
	while _socket.get_available_packet_count() > 0:
		var text := _socket.get_packet().get_string_from_utf8()
		var control := _read_control(text)
		if not control.is_empty():
			_apply_control(control)
		elif _status == Status.PAIRED:
			var message := RemoteMessage.from_json(text)
			if message != null:
				_received.append(message)


# Dictionnaire vide si `text` n'est pas un message de contrôle du relais.
static func _read_control(text: String) -> Dictionary:
	var json := JSON.new()
	if json.parse(text) != OK or not json.data is Dictionary:
		return {}
	var data: Dictionary = json.data
	return data if data.has(RELAY_KEY) else {}


func _apply_control(control: Dictionary) -> void:
	match str(control[RELAY_KEY]):
		"created":
			_room_code = str(control.get("code", ""))
		"paired":
			_status = Status.PAIRED
		"peer_left":
			_close_with("l'autre joueur a quitté la partie")
		"error":
			var reason := str(control.get("reason", ""))
			var error_text: String = ERROR_TEXTS.get(reason, ERROR_TEXTS["bad_request"])
			_close_with(error_text)


func _close_with(error: String) -> void:
	_error = error
	_socket.close()
	_status = Status.CLOSED
