class_name RemoteMessage
extends RefCounted
## Message du duel à distance entre l'hôte et le second écran (décisions 0043 et 0049), écrit en
## texte JSON pour le relais. L'hôte envoie la préparation puis les entrées de son journal, que
## le second écran rejoue ; le second écran envoie les intentions et les réponses commencées de
## son joueur, que l'hôte seul soumet. Aucune règle ici.

## Sortes de messages, écrites en JSON par leurs clés, jamais par leur numéro.
enum Kind {
	HELLO,
	SETUP,
	JOURNAL_ENTRY,
	INTENT,
	RESPONSE_BEGUN,
	INTENT_REJECTED,
}

## Version de ce format ; deux navigateurs de versions différentes ne jouent pas ensemble.
const PROTOCOL_VERSION: int = 1
const KIND_KEY: String = "kind"

var kind: Kind = Kind.HELLO
## HELLO : version du format et édition du ruleset de l'expéditeur.
var protocol_version: int = PROTOCOL_VERSION
var ruleset_edition: String = ""
## SETUP.
var setup: DuelSetup = null
## JOURNAL_ENTRY : une entrée nouvelle, ou le temps ajouté depuis l'envoi de la dernière.
var entry: DuelJournal.Entry = null
## INTENT : intention du joueur du second écran, que l'hôte soumet.
var intent: DuelIntent = null
## INTENT_REJECTED : raison du refus de la dernière intention reçue.
var reject_reason: IntentRejected.RejectReason = IntentRejected.RejectReason.NONE


static func hello(edition: String) -> RemoteMessage:
	var message := RemoteMessage.new()
	message.ruleset_edition = edition
	return message


static func of_setup(duel_setup: DuelSetup) -> RemoteMessage:
	var message := _of_kind(Kind.SETUP)
	message.setup = duel_setup
	return message


static func of_entry(journal_entry: DuelJournal.Entry) -> RemoteMessage:
	var message := _of_kind(Kind.JOURNAL_ENTRY)
	message.entry = journal_entry
	return message


static func of_intent(duel_intent: DuelIntent) -> RemoteMessage:
	var message := _of_kind(Kind.INTENT)
	message.intent = duel_intent
	return message


static func response_begun() -> RemoteMessage:
	return _of_kind(Kind.RESPONSE_BEGUN)


static func rejected(reason: IntentRejected.RejectReason) -> RemoteMessage:
	var message := _of_kind(Kind.INTENT_REJECTED)
	message.reject_reason = reason
	return message


## Décision 0049 : raison, à afficher, pour laquelle l'expéditeur de ce HELLO ne peut pas jouer
## avec un navigateur d'édition `edition` ; vide s'ils sont compatibles.
func find_incompatibility(edition: String) -> String:
	if protocol_version != PROTOCOL_VERSION:
		return "version du jeu différente chez l'autre joueur"
	if ruleset_edition != edition:
		return "édition des règles %s chez l'autre joueur, %s ici" % [ruleset_edition, edition]
	return ""


func to_json() -> String:
	var data := _encode_payload()
	data[KIND_KEY] = Kind.find_key(kind)
	return JSON.stringify(data)


## Message lu dans `text`, ou null si sa sorte est inconnue ou si un champ manque ou est mal formé.
static func from_json(text: String) -> RemoteMessage:
	# JSON.parse_string() signalerait une erreur du moteur pour chaque texte illisible reçu.
	var json := JSON.new()
	if json.parse(text) != OK or not json.data is Dictionary:
		return null
	var data: Dictionary = json.data
	var kind_name := str(data.get(KIND_KEY, ""))
	if not Kind.has(kind_name):
		return null
	var message_kind: Kind = Kind[kind_name]
	var message := _of_kind(message_kind)
	return message if message._decode_payload(data) else null


static func _of_kind(message_kind: Kind) -> RemoteMessage:
	var message := RemoteMessage.new()
	message.kind = message_kind
	return message


func _encode_payload() -> Dictionary:
	match kind:
		Kind.HELLO:
			return {"protocol_version": protocol_version, "ruleset_edition": ruleset_edition}
		Kind.SETUP:
			return {"setup": DuelJournal.encode_setup(setup)}
		Kind.JOURNAL_ENTRY:
			return {"entry": DuelJournal.encode_entry(entry)}
		Kind.INTENT:
			return {"intent": IntentCodec.encode(intent)}
		Kind.INTENT_REJECTED:
			return {"reject_reason": IntentRejected.RejectReason.find_key(reject_reason)}
	return {}


func _decode_payload(data: Dictionary) -> bool:
	match kind:
		Kind.HELLO:
			return _decode_hello(data)
		Kind.SETUP:
			setup = DuelJournal.decode_setup(data.get("setup"))
			return setup != null
		Kind.JOURNAL_ENTRY:
			entry = DuelJournal.decode_entry(data.get("entry"))
			return entry != null
		Kind.INTENT:
			return _decode_intent(data)
		Kind.INTENT_REJECTED:
			return _decode_reject_reason(data)
	return true


func _decode_hello(data: Dictionary) -> bool:
	var version: Variant = data.get("protocol_version")
	var edition: Variant = data.get("ruleset_edition")
	if not (JsonValues.is_number(version) and edition is String):
		return false
	protocol_version = JsonValues.to_int(version)
	ruleset_edition = edition
	return true


func _decode_intent(data: Dictionary) -> bool:
	var intent_data: Variant = data.get("intent")
	if not intent_data is Dictionary:
		return false
	var intent_fields: Dictionary = intent_data
	intent = IntentCodec.decode(intent_fields)
	return intent != null


func _decode_reject_reason(data: Dictionary) -> bool:
	var reason_name := str(data.get("reject_reason", ""))
	if not IntentRejected.RejectReason.has(reason_name):
		return false
	reject_reason = IntentRejected.RejectReason[reason_name]
	return true
