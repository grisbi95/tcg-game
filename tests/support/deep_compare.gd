class_name DeepCompare
extends RefCounted
## Comparaison par réflexion des objets d'état, pour vérifier `clone()` (décisions 0001 et 0008).
##
## Les objets en lecture seule (Resources, DuelConfig, Catalog) doivent être partagés ; tout autre
## objet doit être copié. Le RNG se compare par `seed` et `state`.


## Renvoie les défauts d'une copie : valeur différente, objet mutable partagé avec
## l'original, ou objet en lecture seule dupliqué. Vide si la copie est fidèle.
static func find_clone_defects(original: Object, copy: Object) -> PackedStringArray:
	var defects := PackedStringArray()
	_compare_values(original, copy, _class_name_of(original), defects)
	return defects


## Renvoie les champs « Classe.champ » restés à leur valeur par défaut dans toutes les
## instances atteintes depuis `root`. Un tel champ ne prouve pas que `clone()` le copie.
static func find_fields_never_set(root: Object) -> PackedStringArray:
	var coverage := _collect_field_coverage(root)
	var never_set := PackedStringArray()
	for field_path: String in coverage:
		if not coverage[field_path]:
			never_set.append(field_path)
	return never_set


## Renvoie les noms des classes de script atteintes depuis `root`, hors lecture seule.
static func find_reached_classes(root: Object) -> PackedStringArray:
	var classes := PackedStringArray()
	for field_path: String in _collect_field_coverage(root):
		var class_label := field_path.get_slice(".", 0)
		if not classes.has(class_label):
			classes.append(class_label)
	return classes


static func _compare_values(
	original: Variant, copy: Variant, path: String, defects: PackedStringArray
) -> void:
	if typeof(original) != typeof(copy):
		defects.append("%s : types différents" % path)
		return
	match typeof(original):
		TYPE_ARRAY:
			var original_array: Array = original
			var copy_array: Array = copy
			_compare_arrays(original_array, copy_array, path, defects)
		TYPE_OBJECT:
			var original_object: Object = original
			var copy_object: Object = copy
			_compare_objects(original_object, copy_object, path, defects)
		_:
			if original != copy:
				defects.append("%s : %s au lieu de %s" % [path, copy, original])


static func _compare_arrays(
	original: Array, copy: Array, path: String, defects: PackedStringArray
) -> void:
	if original.size() != copy.size():
		defects.append("%s : %d éléments au lieu de %d" % [path, copy.size(), original.size()])
		return
	for index: int in original.size():
		_compare_values(original[index], copy[index], "%s[%d]" % [path, index], defects)


static func _compare_objects(
	original: Object, copy: Object, path: String, defects: PackedStringArray
) -> void:
	if _is_shared_read_only(original):
		if original != copy:
			defects.append("%s : objet en lecture seule dupliqué" % path)
		return
	if original == copy:
		defects.append("%s : objet mutable partagé avec l'original" % path)
		return
	if original is RandomNumberGenerator:
		_compare_rngs(
			original as RandomNumberGenerator, copy as RandomNumberGenerator, path, defects
		)
		return
	if original.get_script() != copy.get_script():
		defects.append("%s : classes différentes" % path)
		return
	for field: String in _script_fields(original):
		_compare_values(original.get(field), copy.get(field), "%s.%s" % [path, field], defects)


static func _compare_rngs(
	original: RandomNumberGenerator,
	copy: RandomNumberGenerator,
	path: String,
	defects: PackedStringArray
) -> void:
	if original.seed != copy.seed or original.state != copy.state:
		defects.append("%s : seed ou state différent" % path)


## Associe « Classe.champ » à vrai si au moins une instance a une valeur non par défaut.
static func _collect_field_coverage(root: Object) -> Dictionary[String, bool]:
	var coverage: Dictionary[String, bool] = {}
	_visit_value(root, coverage)
	return coverage


static func _visit_value(value: Variant, coverage: Dictionary[String, bool]) -> void:
	if value is Array:
		var array: Array = value
		for element: Variant in array:
			_visit_value(element, coverage)
	elif value is Object:
		var object: Object = value
		if object.get_script() != null and not _is_shared_read_only(object):
			_visit_object(object, coverage)


static func _visit_object(object: Object, coverage: Dictionary[String, bool]) -> void:
	var script: GDScript = object.get_script()
	var default_object: Object = script.new()
	var class_label := _class_name_of(object)
	for field: String in _script_fields(object):
		var field_path := "%s.%s" % [class_label, field]
		var value: Variant = object.get(field)
		var is_set := _differs_from_default(value, default_object.get(field))
		var already_set: bool = coverage.get(field_path, false)
		coverage[field_path] = already_set or is_set
		_visit_value(value, coverage)


static func _differs_from_default(value: Variant, default_value: Variant) -> bool:
	if value is Object or default_value is Object:
		return not is_same(value, default_value)
	return value != default_value


static func _script_fields(object: Object) -> Array[String]:
	var fields: Array[String] = []
	for property: Dictionary in object.get_property_list():
		var usage: int = property["usage"]
		if usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var field_name: String = property["name"]
			fields.append(field_name)
	return fields


static func _is_shared_read_only(object: Object) -> bool:
	return object is Resource or object is DuelConfig or object is Catalog


static func _class_name_of(object: Object) -> String:
	var script: Script = object.get_script()
	return String(script.get_global_name()) if script != null else object.get_class()
