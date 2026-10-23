class_name RemoteGuestLink
extends RefCounted
## Côté second écran du duel à distance (décisions 0043 et 0049) : rejoue la préparation et les
## entrées du journal reçues de l'hôte dans une copie locale du moteur, que les vues lisent, et
## envoie à l'hôte les intentions et les réponses commencées de son joueur. La copie ne fait
## jamais autorité : seule l'intention soumise par l'hôte compte. Aucune règle ici ; aucune
## connexion non plus : la scène porte les messages entre ce lien et le relais.

var _engine: DuelEngine
var _side: DuelState.PlayerSide
var _edition: String
var _journal: DuelJournal = DuelJournal.new()
var _outgoing: Array[RemoteMessage] = []
var _is_started: bool = false
var _incompatibility: String = ""


## `engine` n'a pas démarré de duel, avec le catalogue et la configuration de l'hôte ; `side`
## joue sur cet écran ; `edition` est celle de son catalogue.
func _init(engine: DuelEngine, side: DuelState.PlayerSide, edition: String) -> void:
	_engine = engine
	_side = side
	_edition = edition
	_outgoing.append(RemoteMessage.hello(edition))


## Applique un message de l'hôte et renvoie les événements à afficher : ceux de la copie locale,
## identiques à ceux de l'hôte (décision 0001), ou le refus de la dernière intention envoyée.
func receive(message: RemoteMessage) -> Array[DuelEvent]:
	var events: Array[DuelEvent] = []
	match message.kind:
		RemoteMessage.Kind.HELLO:
			_incompatibility = message.find_incompatibility(_edition)
		RemoteMessage.Kind.SETUP:
			events = _start(message.setup)
		RemoteMessage.Kind.JOURNAL_ENTRY:
			if _is_started:
				_journal.record(message.entry)
				events = DuelJournal.replay_entry(_engine, message.entry)
		RemoteMessage.Kind.INTENT_REJECTED:
			events.append(IntentRejected.new(null, message.reject_reason))
	return events


## Intention du joueur de cet écran, que l'hôte soumettra s'il l'attend.
func send_intent(intent: DuelIntent) -> void:
	_outgoing.append(RemoteMessage.of_intent(intent))


## Décision 0042 : le joueur de cet écran commence une réponse pendant sa fenêtre (208.6.2).
func begin_response() -> void:
	_outgoing.append(RemoteMessage.response_begun())


## Messages à envoyer à l'hôte depuis le dernier appel, dans l'ordre.
func take_outgoing() -> Array[RemoteMessage]:
	var messages := _outgoing
	_outgoing = []
	return messages


## Copie locale du duel, en lecture pour les vues et `DuelSelection`.
func get_engine() -> DuelEngine:
	return _engine


## Journal tel que l'hôte le tient, à l'identique, rebâti des messages reçus.
func get_journal() -> DuelJournal:
	return _journal


func get_side() -> DuelState.PlayerSide:
	return _side


func is_started() -> bool:
	return _is_started


## Raison pour laquelle cet écran ne peut pas jouer avec l'hôte ; vide sinon.
func get_incompatibility() -> String:
	return _incompatibility


# Une seconde préparation est ignorée : un lien sert un seul duel.
func _start(setup: DuelSetup) -> Array[DuelEvent]:
	if _is_started:
		return []
	_is_started = true
	_journal = DuelJournal.new(setup, _edition)
	return _engine.start_new_duel(setup)
