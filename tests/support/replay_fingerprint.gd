class_name ReplayFingerprint
extends RefCounted
## Empreinte d'un duel rejoué (décision 0022) : ses événements et son état final, décrits champ
## par champ par réflexion puis résumés par SHA-256, avec un résumé lisible pour les écarts.
## Les objets en lecture seule (catalogue, configuration) n'entrent pas dans l'empreinte.

var event_count: int = 0
var events_sha256: String = ""
var final_state_sha256: String = ""
var result: DuelState.DuelResult = DuelState.DuelResult.NONE
var turn_number: int = 0


static func of(events: Array[DuelEvent], state: DuelState) -> ReplayFingerprint:
	var fingerprint := ReplayFingerprint.new()
	fingerprint.event_count = events.size()
	fingerprint.events_sha256 = describe(events).sha256_text()
	fingerprint.final_state_sha256 = describe(state).sha256_text()
	fingerprint.result = state.result
	fingerprint.turn_number = state.turn_number
	return fingerprint


static func from_dict(data: Dictionary) -> ReplayFingerprint:
	var fingerprint := ReplayFingerprint.new()
	fingerprint.event_count = JsonValues.to_int(data.get("event_count", 0))
	fingerprint.events_sha256 = str(data.get("events_sha256", ""))
	fingerprint.final_state_sha256 = str(data.get("final_state_sha256", ""))
	fingerprint.result = JsonValues.to_int(data.get("result", 0)) as DuelState.DuelResult
	fingerprint.turn_number = JsonValues.to_int(data.get("turn_number", 0))
	return fingerprint


## Valeur décrite récursivement : objets par leurs champs de script, dans l'ordre déclaré.
static func describe(value: Variant) -> String:
	if value is Object:
		var object: Object = value
		return _describe_object(object)
	if value is Array:
		var parts := PackedStringArray()
		for item: Variant in value:
			parts.append(describe(item))
		return "[%s]" % ", ".join(parts)
	return var_to_str(value)


func to_dict() -> Dictionary:
	return {
		"event_count": event_count,
		"events_sha256": events_sha256,
		"final_state_sha256": final_state_sha256,
		"result": result,
		"turn_number": turn_number,
	}


## Écarts de cette empreinte par rapport à `expected` ; vide si elles sont égales.
func find_differences(expected: ReplayFingerprint) -> PackedStringArray:
	var differences := PackedStringArray()
	var actual_fields := to_dict()
	var expected_fields := expected.to_dict()
	for field: String in expected_fields:
		if actual_fields[field] != expected_fields[field]:
			differences.append(
				"%s : %s au lieu de %s" % [field, actual_fields[field], expected_fields[field]]
			)
	return differences


static func _describe_object(object: Object) -> String:
	if DeepCompare.is_shared_read_only(object):
		return "<lecture seule>"
	if object is RandomNumberGenerator:
		var rng: RandomNumberGenerator = object
		return "rng(%d, %d)" % [rng.seed, rng.state]
	var script: Script = object.get_script()
	var parts := PackedStringArray()
	for field: String in ScriptFields.of(object):
		parts.append("%s=%s" % [field, describe(object.get(field))])
	return "%s{%s}" % [script.get_global_name(), ", ".join(parts)]
