class_name ScriptFields
extends RefCounted
## Champs déclarés par le script d'un objet, hérités compris, dans l'ordre de déclaration : lus
## par réflexion par le journal (décision 0022) et par les outils de test.


static func of(object: Object) -> PackedStringArray:
	var fields := PackedStringArray()
	for property: Dictionary in object.get_property_list():
		var usage: int = property["usage"]
		if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0:
			var field: String = property["name"]
			fields.append(field)
	return fields
