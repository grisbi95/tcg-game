class_name EventLog
extends RefCounted
## Lecture des événements renvoyés par DuelEngine, pour des assertions lisibles.

## Renvoyé par `rejection_reason()` si les événements ne sont pas un refus unique.
const NOT_A_SINGLE_REJECTION: int = -1


## Décrit chaque événement par « Classe » ou « Classe:joueur », dans l'ordre.
static func describe(events: Array[DuelEvent]) -> Array[String]:
	var descriptions: Array[String] = []
	for event: DuelEvent in events:
		var script: Script = event.get_script()
		var label := String(script.get_global_name())
		if event is PlayerEvent:
			label += ":" + str(DuelState.PlayerSide.find_key((event as PlayerEvent).player))
		descriptions.append(label)
	return descriptions


## Renvoie `count` fois `description`, pour composer une séquence attendue.
static func repeat(description: String, count: int) -> Array[String]:
	var descriptions: Array[String] = []
	for index: int in count:
		descriptions.append(description)
	return descriptions


## Raison du refus si `events` est un unique IntentRejected, sinon NOT_A_SINGLE_REJECTION.
static func rejection_reason(events: Array[DuelEvent]) -> int:
	if events.size() != 1 or not events[0] is IntentRejected:
		return NOT_A_SINGLE_REJECTION
	return (events[0] as IntentRejected).reason


## Décrit une intention par sa classe, son joueur et ses champs, pour rapporter un écart :
## « DeployCard:A card_instance_id=12 cell=(1, 0) payment=2+0 ».
static func describe_intent(intent: DuelIntent) -> String:
	var script: Script = intent.get_script()
	var side := str(DuelState.PlayerSide.find_key(intent.player))
	var parts := PackedStringArray(["%s:%s" % [script.get_global_name(), side]])
	for field: String in ScriptFields.of(intent):
		if field == "player":
			continue
		parts.append("%s=%s" % [field, _describe_value(intent.get(field))])
	return " ".join(parts)


static func _describe_value(value: Variant) -> String:
	if value is EssencePayment:
		var payment: EssencePayment = value
		return "%d+%d" % [payment.incline_count, payment.recycle_count]
	return str(value)
