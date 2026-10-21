class_name HeroDefinition
extends RefCounted
## Définition d'une carte Hero : PV, texte, passif et pouvoir (202.3, décision 0002).
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
## 202.3.13 : coût en Essence du pouvoir.
var power_cost: int = 0
## 202.3.11, 202.3.18 : effets statiques.
var passive: Array[EffectDefinition] = []
## 202.3.12 : effets du pouvoir, résolus par la pile.
var power: Array[EffectDefinition] = []
## Erreurs de lecture du JSON, reprises par `find_errors()`.
var parse_errors: PackedStringArray = PackedStringArray()


## Lit un Hero depuis un objet JSON ; les erreurs de lecture vont dans `parse_errors`.
static func from_dict(data: Dictionary) -> HeroDefinition:
	var hero := HeroDefinition.new()
	var reader := CatalogReader.new(data)
	reader.require("health", "202.3.7")
	reader.require("text", "202.3.8")
	reader.require("power_cost", "202.3.13")
	if reader.has("force"):
		reader.mark_known("force")
		reader.fail("202.3.9 : la carte Hero ne porte pas de Force")
	hero.id = StringName(reader.read_string("id"))
	hero.hero_name = reader.read_string("name")
	hero.health = reader.read_int("health", CatalogReader.NON_NEGATIVE_MINIMUM, 0)
	hero.text = reader.read_string("text")
	hero.power_cost = reader.read_int("power_cost", CatalogReader.NON_NEGATIVE_MINIMUM, 0)
	hero.passive = hero._read_effects(reader, "passive")
	hero.power = hero._read_effects(reader, "power")
	hero.parse_errors = reader.finish()
	return hero


# 202.3.6 à 202.3.13, 202.3.18 : nom, PV, texte, coût du pouvoir, passif statique et pouvoir
# résolu par la pile.
func find_errors() -> PackedStringArray:
	var errors := parse_errors.duplicate()
	if not RegEx.create_from_string(_ID_PATTERN).search(String(id)):
		errors.append("id en snake_case ASCII exigé (« %s »)" % id)
	if hero_name.is_empty():
		errors.append("202.3.6 : nom absent")
	if health < _MIN_HEALTH:
		errors.append("202.3.7 : un Hero a au moins %d PV" % _MIN_HEALTH)
	if power_cost < 0:
		errors.append("202.3.13 : le coût du pouvoir est au moins 0")
	_check_effects(errors, passive, "passive", EffectDefinition.EffectTiming.STATIC)
	_check_effects(errors, power, "power", EffectDefinition.EffectTiming.RESOLVE)
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


# 202.3.11 et 202.3.12 : le texte porte un passif et un pouvoir ; 202.3.18 : le passif est
# statique ; 208.1.4 : le pouvoir passe par la pile.
func _check_effects(
	errors: PackedStringArray,
	effects: Array[EffectDefinition],
	label: String,
	expected_timing: EffectDefinition.EffectTiming
) -> void:
	if effects.is_empty():
		errors.append("202.3.11 : le Hero porte un passif et un pouvoir, %s est vide" % label)
	for index: int in effects.size():
		for message: String in effects[index].find_errors():
			errors.append("%s %d : %s" % [label, index + 1, message])
		if effects[index].timing != expected_timing:
			errors.append("%s %d : timing refusé pour le Hero" % [label, index + 1])
