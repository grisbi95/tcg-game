class_name HeroDefinition
extends RefCounted
## Définition d'une carte Hero : PV, texte, passif, effets déclenchés et Ordres (202.3, 211,
## décisions 0002 et 0055).
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
## 202.3.11, 202.3.18 : textes statiques, facultatifs.
var passive: Array[EffectText] = []
## 202.3.20 : textes déclenchés (indexés par `StackEntry.text_index`, voir Catalog).
var triggered: Array[EffectText] = []
## 202.3.19, 202.3.21 : Ordres, dans l'ordre du texte ; l'intention désigne un Ordre par son rang.
var orders: Array[HeroOrder] = []
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
	hero.passive = EffectText.read_all(reader, "passive")
	hero.triggered = EffectText.read_all(reader, "triggered")
	hero._read_orders(reader)
	hero.parse_errors = reader.finish()
	return hero


# 202.3.6 à 202.3.8, 202.3.11, 202.3.18 à 202.3.22 : nom, PV, texte, capacités du Hero.
func find_errors() -> PackedStringArray:
	var errors := parse_errors.duplicate()
	if not RegEx.create_from_string(_ID_PATTERN).search(String(id)):
		errors.append("id en snake_case ASCII exigé (« %s »)" % id)
	if hero_name.is_empty():
		errors.append("202.3.6 : nom absent")
	if health < _MIN_HEALTH:
		errors.append("202.3.7 : un Hero a au moins %d PV" % _MIN_HEALTH)
	_check_passive(errors)
	_check_triggered(errors)
	_check_orders(errors)
	_check_no_chosen_x(errors)
	if passive.is_empty() and triggered.is_empty() and orders.is_empty():
		errors.append("202.3.22 : le Hero porte au moins un passif, un Ordre ou un effet déclenché")
	return errors


func _read_orders(reader: CatalogReader) -> void:
	for entry: Dictionary in reader.read_objects("orders"):
		orders.append(HeroOrder.from_dict(entry))


# 202.3.11 : le passif est facultatif ; 202.3.18 : il est statique.
func _check_passive(errors: PackedStringArray) -> void:
	errors.append_array(EffectText.find_all_errors(passive, "passive"))
	for index: int in passive.size():
		if passive[index].timing != EffectDefinition.EffectTiming.STATIC:
			errors.append("passive %d : timing refusé pour le Hero" % (index + 1))
		for effect: EffectDefinition in passive[index].effects:
			if _touches_hero_force(effect):
				errors.append(
					"passive %d : 202.3.9, Q-097 : ni Force ni destruction du Hero" % (index + 1)
				)


# 202.3.20, 207.3.1 : textes déclenchés ; Q-097 : la pièce source d'un effet du Hero est le Hero,
# que ni la Force ni la destruction ne visent.
func _check_triggered(errors: PackedStringArray) -> void:
	errors.append_array(EffectText.find_all_errors(triggered, "triggered"))
	for index: int in triggered.size():
		var label := "triggered %d" % (index + 1)
		if triggered[index].timing != EffectDefinition.EffectTiming.TRIGGERED:
			errors.append("%s : timing refusé pour un effet déclenché" % label)
		var attack_error := triggered[index].destroys_defender_error(false)
		if not attack_error.is_empty():
			errors.append("%s : %s" % [label, attack_error])
		if triggered[index].effects.any(_aims_source_hero):
			errors.append("%s : 202.3.9, Q-097 : ni Force ni destruction du Hero" % label)


# Q-097 : un passif de Force à portée « porteur » modifierait la Force du Hero.
func _touches_hero_force(effect: EffectDefinition) -> bool:
	var kind := EffectDefinition.EffectKind.MODIFY_FORCE
	return (
		effect.kind == kind
		and effect.scope != null
		and effect.scope.relation == PieceFilter.Relation.SELF
	)


func _aims_source_hero(effect: EffectDefinition) -> bool:
	var kinds: Array[EffectDefinition.EffectKind] = [
		EffectDefinition.EffectKind.MODIFY_FORCE, EffectDefinition.EffectKind.DESTROY
	]
	return effect.subject == EffectDefinition.EffectSubject.SOURCE_PIECE and effect.kind in kinds


# 213.1.2 : un Hero n'a pas de coût X, ses effets ne lisent pas de X choisi ; 210.4.1c : il n'est
# pas une Unit, son passif n'accorde pas de mot-clé à son porteur .
func _check_no_chosen_x(errors: PackedStringArray) -> void:
	var carried: Array[EffectText] = passive.duplicate()
	carried.append_array(triggered)
	var chosen_error := EffectValueChecks.chosen_x_error(carried, false)
	if not chosen_error.is_empty():
		errors.append(chosen_error)
	var bearer_error := EffectValueChecks.bearer_grant_error(carried, false)
	if not bearer_error.is_empty():
		errors.append(bearer_error)


# 202.3.19, 211.1 : chaque Ordre se contrôle lui-même.
func _check_orders(errors: PackedStringArray) -> void:
	for index: int in orders.size():
		for message: String in orders[index].find_errors():
			errors.append("order %d : %s" % [index + 1, message])
