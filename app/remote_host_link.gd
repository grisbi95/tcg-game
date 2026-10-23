class_name RemoteHostLink
extends RefCounted
## Côté hôte du duel à distance (décisions 0043 et 0049) : envoie au second écran la préparation
## puis chaque entrée du journal de `DuelHost`, dans l'ordre, et soumet à l'hôte les intentions
## reçues de son joueur quand l'hôte les attend. Aucune règle ici ; aucune connexion non plus :
## la scène porte les messages entre ce lien et le relais.

## Le temps seul ne part pas plus souvent : le second écran recale ses pendules à ce rythme.
const TIME_SEND_INTERVAL_MSEC: int = 100

var _host: DuelHost
var _remote_side: DuelState.PlayerSide
var _edition: String
var _outgoing: Array[RemoteMessage] = []
## Intentions et réponses commencées reçues, appliquées dans l'ordre quand l'hôte attend le
## joueur distant.
var _received: Array[RemoteMessage] = []
var _has_sent_setup: bool = false
var _sent_entry_count: int = 0
## Temps de la dernière entrée envoyée, tel qu'envoyé : le journal cumule les temps consécutifs.
var _sent_last_elapsed_msec: int = 0
var _last_time_send_msec: int = 0
var _incompatibility: String = ""


## `remote_side` joue sur le second écran ; `edition` est celle du catalogue de l'hôte.
func _init(host: DuelHost, remote_side: DuelState.PlayerSide, edition: String) -> void:
	_host = host
	_remote_side = remote_side
	_edition = edition
	_outgoing.append(RemoteMessage.hello(edition))


func receive(message: RemoteMessage) -> void:
	match message.kind:
		RemoteMessage.Kind.HELLO:
			_incompatibility = message.find_incompatibility(_edition)
		RemoteMessage.Kind.INTENT, RemoteMessage.Kind.RESPONSE_BEGUN:
			_received.append(message)


## À chaque image, après `DuelHost.tick()` : abandon reçu, où qu'il soit dans la file (209.2.5,
## à tout moment), sinon, quand l'hôte attend le joueur distant, réponses commencées et
## intentions reçues dans l'ordre, jusqu'à la première intention acceptée. Renvoie un seul lot
## d'événements, à afficher par la scène de l'hôte, ou rien : un refus part au second écran et ne
## s'affiche pas ici.
func submit_received() -> Array[DuelEvent]:
	var concede_index := _received.find_custom(_is_concede)
	if concede_index != -1:
		_received.clear()
		return _host.concede(_remote_side)
	while not _received.is_empty() and _is_remote_player_awaited():
		var message: RemoteMessage = _received.pop_front()
		if message.kind == RemoteMessage.Kind.RESPONSE_BEGUN:
			_host.begin_response()
			continue
		var events := _submit(message.intent)
		if not events.is_empty():
			return events
	return []


## Messages à envoyer au second écran depuis le dernier appel, dans l'ordre. Le temps écoulé
## seul attend `TIME_SEND_INTERVAL_MSEC` ; une intention ou une réponse commencée part aussitôt,
## précédée du temps.
func take_outgoing(now_msec: int) -> Array[RemoteMessage]:
	_collect_journal(now_msec)
	var messages := _outgoing
	_outgoing = []
	return messages


## Raison pour laquelle le second écran ne peut pas jouer avec cet hôte ; vide sinon.
func get_incompatibility() -> String:
	return _incompatibility


func _is_remote_player_awaited() -> bool:
	return (
		_host.get_host_state() == DuelHost.HostState.AWAITING_HUMAN
		and _host.get_screen_player() == _remote_side
	)


static func _is_concede(message: RemoteMessage) -> bool:
	return message.kind == RemoteMessage.Kind.INTENT and message.intent is Concede


# Un refus, comme une intention d'un autre joueur que le joueur distant, n'est renvoyé qu'au
# second écran, qui attend la réponse à son intention.
func _submit(intent: DuelIntent) -> Array[DuelEvent]:
	if intent.player != _remote_side:
		_outgoing.append(RemoteMessage.rejected(IntentRejected.RejectReason.PLAYER_NOT_AWAITED))
		return []
	var events := _host.submit_human(intent)
	if events.size() == 1 and events[0] is IntentRejected:
		var rejection: IntentRejected = events[0]
		_outgoing.append(RemoteMessage.rejected(rejection.reason))
		return []
	return events


func _collect_journal(now_msec: int) -> void:
	if _host.get_host_state() == DuelHost.HostState.NOT_STARTED:
		return
	var journal := _host.get_journal()
	if not _has_sent_setup:
		_outgoing.append(RemoteMessage.of_setup(journal.setup))
		_has_sent_setup = true
	if not _has_unsent_event(journal) and now_msec - _last_time_send_msec < TIME_SEND_INTERVAL_MSEC:
		return
	_last_time_send_msec = now_msec
	_send_time_added_to_last_entry(journal)
	for index: int in range(_sent_entry_count, journal.entries.size()):
		_send_entry(journal.entries[index])


# Une intention ou une réponse commencée ne se fait pas attendre ; un temps, si.
func _has_unsent_event(journal: DuelJournal) -> bool:
	for index: int in range(_sent_entry_count, journal.entries.size()):
		if not journal.entries[index].counts_time():
			return true
	return false


# Seule la dernière entrée envoyée peut encore grandir : le temps ajouté part comme une entrée
# de même sorte, que le second écran cumule de même.
func _send_time_added_to_last_entry(journal: DuelJournal) -> void:
	if _sent_entry_count == 0:
		return
	var last_entry: DuelJournal.Entry = journal.entries[_sent_entry_count - 1]
	if not last_entry.counts_time() or last_entry.elapsed_msec == _sent_last_elapsed_msec:
		return
	var added := DuelJournal.Entry.new()
	added.kind = last_entry.kind
	added.player = last_entry.player
	added.elapsed_msec = last_entry.elapsed_msec - _sent_last_elapsed_msec
	_outgoing.append(RemoteMessage.of_entry(added))
	_sent_last_elapsed_msec = last_entry.elapsed_msec


# Une copie : l'entrée du journal peut encore grandir après l'envoi.
func _send_entry(entry: DuelJournal.Entry) -> void:
	_outgoing.append(
		RemoteMessage.of_entry(DuelJournal.decode_entry(DuelJournal.encode_entry(entry)))
	)
	_sent_entry_count += 1
	_sent_last_elapsed_msec = entry.elapsed_msec
