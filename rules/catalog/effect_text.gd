class_name EffectText
extends RefCounted
## Un texte d'une carte, d'un passif ou d'un Ordre (décision 0064) : un timing, ses effets dans
## l'ordre où le texte les écrit (207.7.4) et, pour un texte déclenché, son événement, la mention
## « une fois par tour » et la condition lue à l'événement (207.3.13).
##
## Une entrée de pile d'effet déclenché, un Spell ou un Ordre résout un texte. Un texte statique
## porte un seul effet : chaque statique se calcule seul, en continu (207.2, 207.4.11b).

var timing: EffectDefinition.EffectTiming = EffectDefinition.EffectTiming.RESOLVE
var trigger: EffectDefinition.TriggerEvent = EffectDefinition.TriggerEvent.NONE
## 207.3.5 : mention « une fois par tour », pour un texte déclenché seulement.
var once_per_turn: bool = false
## 207.3.13 : condition « si » lue quand survient l'événement, pour un texte déclenché seulement ;
## null sans condition.
var condition: EffectCondition
var effects: Array[EffectDefinition] = []
## Erreurs de lecture du JSON, reprises par `find_errors()`.
var parse_errors: PackedStringArray = PackedStringArray()


## Lit un texte depuis un objet JSON ; les erreurs de lecture vont dans `parse_errors`.
static func from_dict(data: Dictionary) -> EffectText:
	var text := EffectText.new()
	var reader := CatalogReader.new(data)
	reader.require("timing", "207")
	reader.require("effects", "207.7.4")
	var timing_value := reader.read_enum("timing", EffectDefinition.EffectTiming)
	if timing_value != CatalogReader.NOT_SET:
		text.timing = timing_value as EffectDefinition.EffectTiming
	var trigger_value := reader.read_enum("trigger", EffectDefinition.TriggerEvent)
	if trigger_value != CatalogReader.NOT_SET:
		text.trigger = trigger_value as EffectDefinition.TriggerEvent
	text.once_per_turn = reader.read_bool("once_per_turn", false)
	if reader.has("condition"):
		text.condition = EffectCondition.from_dict(reader.read_object("condition"))
	for entry: Dictionary in reader.read_objects("effects"):
		text.effects.append(EffectDefinition.from_dict(entry))
	text.parse_errors = reader.finish()
	return text


## Les textes de `texts` lus d'un seul tenant, effets dans l'ordre.
static func all_effects(texts: Array[EffectText]) -> Array[EffectDefinition]:
	var all: Array[EffectDefinition] = []
	for text: EffectText in texts:
		all.append_array(text.effects)
	return all


## Lit un tableau de textes `key` de l'objet de `reader`.
static func read_all(reader: CatalogReader, key: String) -> Array[EffectText]:
	var texts: Array[EffectText] = []
	for entry: Dictionary in reader.read_objects(key):
		texts.append(EffectText.from_dict(entry))
	return texts


## Erreurs de chaque texte de `texts`, préfixées par `label` et le rang du texte.
static func find_all_errors(texts: Array[EffectText], label: String) -> PackedStringArray:
	var errors := PackedStringArray()
	for index: int in texts.size():
		for message: String in texts[index].find_errors():
			errors.append("%s %d : %s" % [label, index + 1, message])
	return errors


## Décision 0064 : le texte que résout un Spell ou un Ordre, null s'il n'en a pas.
static func resolution_of(texts: Array[EffectText]) -> EffectText:
	return null if texts.is_empty() else texts[0]


## Décision 0064 : les effets de `text`, aucun si `text` est null.
static func effects_of(text: EffectText) -> Array[EffectDefinition]:
	var listed: Array[EffectDefinition] = []
	if text != null:
		listed.assign(text.effects)
	return listed


## Limite en attente d'une question du ruleset (décision 0064, voir 207.7.4) : message d'erreur si
## `texts`, ceux d'un Spell ou d'un Ordre, compte plusieurs textes, le ruleset ne fixant pas
## comment ils se résolvent. Vide sinon.
static func single_text_error(texts: Array[EffectText]) -> String:
	if texts.size() > 1:
		return (
			"0064 : en attente d'une question du ruleset (voir 207.7.4), "
			+ "un Spell ou un Ordre porte au plus un texte"
		)
	return ""


# 207.3.1, 207.3.5, 207.3.13, 207.7.4, 207.7.6 : le timing exige ou interdit déclencheur, mention et
# condition à l'événement ; les effets se contrôlent selon le timing du texte.
func find_errors() -> PackedStringArray:
	var errors := parse_errors.duplicate()
	var triggered := timing == EffectDefinition.EffectTiming.TRIGGERED
	if triggered and trigger == EffectDefinition.TriggerEvent.NONE:
		errors.append("207.3.1 : un texte déclenché nomme son événement dans trigger")
	if not triggered and trigger != EffectDefinition.TriggerEvent.NONE:
		errors.append("207.3.1 : trigger ne vaut que pour un texte déclenché")
	if not triggered and once_per_turn:
		errors.append("207.3.5 : once_per_turn ne vaut que pour un texte déclenché")
	if not triggered and condition != null:
		errors.append("207.3.13 : condition ne vaut que pour un texte déclenché")
	if condition != null:
		for message: String in condition.find_errors():
			errors.append("condition : " + message)
	_check_effects(errors)
	return errors


## 206.3.7, 207.3.12 : message d'erreur si le texte se déclenche quand l'Unit détruit son défenseur
## alors que sa carte n'est ni une Unit ni un Gear (`can_attack` faux), vide sinon.
func destroys_defender_error(can_attack: bool) -> String:
	if trigger == EffectDefinition.TriggerEvent.DESTROYS_DEFENDER and not can_attack:
		return "206.3.7 : seule une Unit ou un Gear détruit un défenseur"
	return ""


## Décision 0064, 207.5.1 : l'effet du texte qui porte les cibles ; null si aucun n'en a.
func targeting_effect() -> EffectDefinition:
	for effect: EffectDefinition in effects:
		if effect.target != null:
			return effect
	return null


func _check_effects(errors: PackedStringArray) -> void:
	if effects.is_empty():
		errors.append("207.7.4 : un texte porte au moins un effet")
	if timing == EffectDefinition.EffectTiming.STATIC and effects.size() > 1:
		errors.append("0064 : un texte statique porte un seul effet")
	if not effects.is_empty() and effects[0].if_you_do:
		errors.append(
			"207.7.6 : « si vous le faites » dépend de l'effet précédent, jamais du premier"
		)
	_check_dependencies(errors)
	var targeting := effects.filter(
		func(effect: EffectDefinition) -> bool: return effect.target != null
	)
	if timing == EffectDefinition.EffectTiming.TRIGGERED and targeting.size() > 1:
		errors.append("0064 : un texte déclenché cible par un seul de ses effets")
	for index: int in effects.size():
		for message: String in effects[index].find_errors(timing):
			errors.append("effet %d : %s" % [index + 1, message])


# 207.7.6a, 200.4.1, 200.4.2 : le ruleset n'écrit pas quand réveiller une pièce déjà éveillée, ni un
# ensemble vide, « a eu lieu » ; un « si vous le faites » ne les suit donc pas (décision 0064).
func _check_dependencies(errors: PackedStringArray) -> void:
	for index: int in range(1, effects.size()):
		var before := effects[index - 1]
		var undefined := (
			before.kind == EffectDefinition.EffectKind.WAKE
			or before.subject == EffectDefinition.EffectSubject.MATCHING_PIECES
		)
		if effects[index].if_you_do and undefined:
			errors.append(
				(
					(
						"effet %d : 0064 : en attente d'une question du ruleset (voir 207.7.6a), "
						+ "« si vous le faites » ne suit ni réveiller ni un ensemble sans cible"
					)
					% [index + 1]
				)
			)
