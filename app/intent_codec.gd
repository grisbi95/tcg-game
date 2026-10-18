class_name IntentCodec
extends RefCounted
## Intentions ↔ dictionnaires du journal JSON (décision 0022) : un nom par classe d'intention,
## puis ses champs typés, lus et écrits par réflexion. Une case s'écrit [colonne, rangée].

const TYPE_KEY: String = "type"
const INTENT_SCRIPTS: Dictionary[StringName, GDScript] = {
	&"AttachGear": preload("res://rules/intents/attach_gear.gd"),
	&"CastSpell": preload("res://rules/intents/cast_spell.gd"),
	&"ChooseMulligan": preload("res://rules/intents/choose_mulligan.gd"),
	&"ChooseTargets": preload("res://rules/intents/choose_targets.gd"),
	&"Concede": preload("res://rules/intents/concede.gd"),
	&"DeployCard": preload("res://rules/intents/deploy_card.gd"),
	&"EndTurn": preload("res://rules/intents/end_turn.gd"),
	&"OrderTriggers": preload("res://rules/intents/order_triggers.gd"),
	&"PassPriority": preload("res://rules/intents/pass_priority.gd"),
	&"ProduceEssence": preload("res://rules/intents/produce_essence.gd"),
	&"TakeNormalAction": preload("res://rules/intents/take_normal_action.gd"),
	&"UseHeroPower": preload("res://rules/intents/use_hero_power.gd"),
}


static func encode(intent: DuelIntent) -> Dictionary:
	var script: Script = intent.get_script()
	var data := _encode_fields(intent)
	data[TYPE_KEY] = String(script.get_global_name())
	return data


## Intention décrite par `data`, ou null si son type est inconnu ou si un champ manque ou est
## mal formé.
static func decode(data: Dictionary) -> DuelIntent:
	var script: GDScript = INTENT_SCRIPTS.get(StringName(str(data.get(TYPE_KEY, ""))))
	if script == null:
		return null
	var intent: DuelIntent = script.new()
	if not _decode_fields(intent, data):
		return null
	return intent


static func _encode_fields(object: Object) -> Dictionary:
	var data: Dictionary = {}
	for field: String in ScriptFields.of(object):
		data[field] = _encode_value(object.get(field))
	return data


static func _encode_value(value: Variant) -> Variant:
	if value is Vector2i:
		var cell: Vector2i = value
		return [cell.x, cell.y]
	if value is Array:
		var encoded: Array = []
		for item: Variant in value:
			encoded.append(_encode_value(item))
		return encoded
	if value is Object:
		var object: Object = value
		return _encode_fields(object)
	return value


static func _decode_fields(object: Object, data: Dictionary) -> bool:
	for field: String in ScriptFields.of(object):
		if not data.has(field) or not _decode_field(object, field, data[field]):
			return false
	return true


# Le type attendu est celui de la valeur par défaut du champ ; un tableau typé se remplit en place.
static func _decode_field(object: Object, field: String, encoded: Variant) -> bool:
	var current: Variant = object.get(field)
	if current is int and JsonValues.is_number(encoded):
		object.set(field, JsonValues.to_int(encoded))
	elif current is Vector2i and _is_cell(encoded):
		object.set(field, _to_cell(encoded))
	elif current is Array and encoded is Array:
		var target: Array = current
		var items: Array = encoded
		return _decode_array(target, items)
	elif current is Object and encoded is Dictionary:
		var nested: Object = current
		var nested_data: Dictionary = encoded
		return _decode_fields(nested, nested_data)
	else:
		return false
	return true


static func _decode_array(target: Array, encoded: Array) -> bool:
	var items: Array = []
	for item: Variant in encoded:
		match target.get_typed_builtin():
			TYPE_INT when JsonValues.is_number(item):
				items.append(JsonValues.to_int(item))
			TYPE_VECTOR2I when _is_cell(item):
				items.append(_to_cell(item))
			_:
				return false
	target.assign(items)
	return true


static func _is_cell(value: Variant) -> bool:
	if not value is Array:
		return false
	var pair: Array = value
	return pair.size() == 2 and JsonValues.is_number(pair[0]) and JsonValues.is_number(pair[1])


static func _to_cell(encoded: Variant) -> Vector2i:
	var pair: Array = encoded
	return Vector2i(JsonValues.to_int(pair[0]), JsonValues.to_int(pair[1]))
