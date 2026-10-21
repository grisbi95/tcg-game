class_name CatalogReader
extends RefCounted
## Lecture typée d'un objet JSON du catalogue (décisions 0002 et 0010).
##
## Une lecture invalide ajoute un message à `errors` et renvoie la valeur de repli ; un champ
## jamais lu est signalé par `finish()`, ce qui attrape les fautes de frappe. Aucune règle de
## jeu ici : les définitions portent leurs règles dans `find_errors()`.

## Renvoyé par `read_enum()` si le champ est absent ou invalide.
const NOT_SET: int = -1
const NON_NEGATIVE_MINIMUM: int = 0  # coûts, PV, Forces et comptes ne sont jamais négatifs

var errors: PackedStringArray = PackedStringArray()
var _data: Dictionary
var _known_keys: PackedStringArray = PackedStringArray()


func _init(data: Dictionary) -> void:
	_data = data


func has(key: String) -> bool:
	return _data.has(key)


func fail(message: String) -> void:
	errors.append(message)


## Signale l'absence de `key`, citée avec l'identifiant de la règle qui l'exige.
func require(key: String, rule: String) -> void:
	if not _data.has(key):
		fail("%s : champ « %s » absent" % [rule, key])


## Déclare `key` lue, pour un champ que la définition traite elle-même.
func mark_known(key: String) -> void:
	if not _known_keys.has(key):
		_known_keys.append(key)


func read_string(key: String) -> String:
	mark_known(key)
	if not _data.has(key):
		return ""
	var value: Variant = _data[key]
	if typeof(value) != TYPE_STRING:
		fail("« %s » doit être un texte" % key)
		return ""
	return str(value)


## Entier relatif de JSON (lu comme nombre) ; `fallback` si absent ou invalide.
func read_signed_int(key: String, fallback: int) -> int:
	mark_known(key)
	if not _data.has(key):
		return fallback
	var value: Variant = _data[key]
	var is_number := typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT
	var number: float = value if is_number else 0.0
	if not is_number or number != floorf(number):
		fail("« %s » doit être un entier" % key)
		return fallback
	return int(number)


## Entier de JSON au moins égal à `minimum` ; `fallback` si absent ou invalide.
func read_int(key: String, minimum: int, fallback: int) -> int:
	var error_count := errors.size()
	var value := read_signed_int(key, fallback)
	if errors.size() == error_count and _data.has(key) and value < minimum:
		fail("« %s » doit être un entier au moins égal à %d" % [key, minimum])
		return fallback
	return value


## Booléen de JSON ; `fallback` si absent ou invalide.
func read_bool(key: String, fallback: bool) -> bool:
	mark_known(key)
	if not _data.has(key):
		return fallback
	var value: Variant = _data[key]
	if typeof(value) != TYPE_BOOL:
		fail("« %s » doit être vrai ou faux" % key)
		return fallback
	var flag: bool = value
	return flag


## Valeur d'un enum nommée en minuscules dans le JSON (`"last_breath"`) ; NOT_SET si absente.
func read_enum(key: String, values: Dictionary) -> int:
	var text := read_string(key)
	if not _data.has(key) or text.is_empty():
		return NOT_SET
	var lookup := enum_value(values, text)
	if lookup == NOT_SET:
		fail("« %s » : « %s » inconnu (valeurs : %s)" % [key, text, ", ".join(enum_names(values))])
	return lookup


## Objet JSON de `key`, vide si absent ; un autre type est une erreur.
func read_object(key: String) -> Dictionary:
	mark_known(key)
	if not _data.has(key):
		return {}
	var value: Variant = _data[key]
	if typeof(value) != TYPE_DICTIONARY:
		fail("« %s » doit être un objet" % key)
		return {}
	var object: Dictionary = value
	return object


## Tableau JSON de `key`, vide si absent ; un autre type est une erreur.
func read_array(key: String) -> Array:
	mark_known(key)
	if not _data.has(key):
		return []
	var value: Variant = _data[key]
	if typeof(value) != TYPE_ARRAY:
		fail("« %s » doit être un tableau" % key)
		return []
	var array: Array = value
	return array


## Termine la lecture : ajoute un message par champ jamais lu, puis renvoie toutes les erreurs.
func finish() -> PackedStringArray:
	for key: String in _data:
		if not _known_keys.has(key):
			fail("champ « %s » inconnu" % key)
	return errors


## Valeur de `values` dont le nom en minuscules est `text` ; NOT_SET sinon.
static func enum_value(values: Dictionary, text: String) -> int:
	for name: String in values:
		if name.to_lower() == text:
			var value: int = values[name]
			return value
	return NOT_SET


## Noms en minuscules d'un enum, tels qu'écrits dans le JSON.
static func enum_names(values: Dictionary) -> PackedStringArray:
	var names := PackedStringArray()
	for name: String in values:
		names.append(name.to_lower())
	return names
