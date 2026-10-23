class_name HeroDefinition
extends RefCounted
## Définition d'une carte Hero : PV, texte et passif (202.3, décision 0002).
##
## Le Hero est une carte hors du deck (202.3.4, 202.3.5), sans Force (202.3.9). Une définition
## qui renvoie des erreurs ne doit jamais servir au moteur.

const _ID_PATTERN: String = "^[a-z][a-z0-9_]*$"
const _MIN_HEALTH: int = 1

var id: StringName = &""
var hero_name: String = ""
## 202.3.7
var health: int = 0
## 202.3.8
var text: String = ""
## 202.3.11, 202.3.18 : effets statiques.
var passive: Array[EffectDefinition] = []
## Erreurs de lecture du JSON, reprises par `find_errors()`.
var parse_errors: PackedStringArray = PackedStringArray()


## Lit un Hero depuis un objet JSON ; les erreurs de lecture vont dans `parse_errors`.
static func from_dict(data: Dictionary) -> HeroDefinition:
	var hero := HeroDefinition.new()
	var reader := CatalogReader.new(data)
	reader.require("health", "202.3.7")
	reader.require("text", "202.3.8")
	if reader.has("force"):
		reader.mark_known("force")
		reader.fail("202.3.9 : la carte Hero ne porte pas de Force")
	hero.id = StringName(reader.read_string("id"))
	hero.hero_name = reader.read_string("name")
	hero.health = reader.read_int("health", CatalogReader.NON_NEGATIVE_MINIMUM, 0)
	hero.text = reader.read_string("text")
	hero.passive = hero._read_effects(reader, "passive")
	hero.parse_errors = reader.finish()
	return hero


# 202.3.6 à 202.3.8, 202.3.11, 202.3.18 : nom, PV, texte et passif statique.
func find_errors() -> PackedStringArray:
	var errors := parse_errors.duplicate()
	if not RegEx.create_from_string(_ID_PATTERN).search(String(id)):
		errors.append("id en snake_case ASCII exigé (« %s »)" % id)
	if hero_name.is_empty():
		errors.append("202.3.6 : nom absent")
	if health < _MIN_HEALTH:
		errors.append("202.3.7 : un Hero a au moins %d PV" % _MIN_HEALTH)
	_check_passive(errors)
	return errors


func _read_effects(reader: CatalogReader, key: String) -> Array[EffectDefinition]:
	var effects: Array[EffectDefinition] = []
	for entry: Variant in reader.read_array(key):
		if typeof(entry) != TYPE_DICTIONARY:
			reader.fail("« %s » : chaque entrée est un objet" % key)
			continue
		var entry_dict: Dictionary = entry
		effects.append(EffectDefinition.from_dict(entry_dict))
	return effects


# 202.3.11 : le texte porte un passif ; 202.3.18 : le passif est statique.
func _check_passive(errors: PackedStringArray) -> void:
	if passive.is_empty():
		errors.append("202.3.11 : le Hero porte un passif, passive est vide")
	for index: int in passive.size():
		for message: String in passive[index].find_errors():
			errors.append("passive %d : %s" % [index + 1, message])
		if passive[index].timing != EffectDefinition.EffectTiming.STATIC:
			errors.append("passive %d : timing refusé pour le Hero" % (index + 1))
