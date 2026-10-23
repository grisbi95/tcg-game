class_name LoopbackConnection
extends RelayConnection
## Connexion au relais sans réseau (décision 0049) : deux connexions appariées l'une à l'autre se
## passent leurs messages, écrits puis relus en JSON comme par le relais. Fermer l'une ferme
## l'autre, qui l'apprend comme le départ de l'autre joueur.

const PEER_LEFT_TEXT: String = "l'autre joueur a quitté la partie"

var _peer: LoopbackConnection
var _inbox: Array[RemoteMessage] = []
var _is_closed: bool = false
var _close_reason: String = ""


## Deux connexions appariées : l'hôte puis le second écran.
static func pair() -> Array[LoopbackConnection]:
	var host := LoopbackConnection.new()
	var guest := LoopbackConnection.new()
	host._peer = guest
	guest._peer = host
	return [host, guest]


func poll() -> void:
	pass


func send(message: RemoteMessage) -> void:
	if not _is_closed:
		_peer._inbox.append(RemoteMessage.from_json(message.to_json()))


func take_messages() -> Array[RemoteMessage]:
	var messages := _inbox
	_inbox = []
	return messages


func close() -> void:
	if _is_closed:
		return
	_is_closed = true
	_peer._is_closed = true
	_peer._close_reason = PEER_LEFT_TEXT


func get_status() -> Status:
	return Status.CLOSED if _is_closed else Status.PAIRED


func get_error() -> String:
	return _close_reason
