class_name CardDefinition
extends RefCounted
## Définition d'une carte de deck : Unit, Building, Spell ou Gear (202.1, 202.2, décision 0002).
##
## Le Hero est une autre carte, hors deck (202.3.5) : voir HeroDefinition. Une définition qui
## renvoie des erreurs ne doit jamais servir au moteur.

## 202.2.1 : types de carte de deck. Enum journalisable : ajouter à la fin.
enum CardType {
	UNIT,
	BUILDING,
	SPELL,
	GEAR,
}

## 207.1.2 : vitesse d'un Spell. NONE pour les autres types.
enum SpellSpeed {
	NONE,
	ACTION,
	REACTION,
}

## 210 : mots-clés. Enum journalisable : ajouter à la fin.
enum Keyword {
	OUTPOST,  # 210.2.1 : Avant-poste
	ARRIVAL,  # 210.3.1 : Arrivée
	LAST_BREATH,  # 210.3.2 : Dernier souffle
	ASSAULT,  # 210.4.1 : Assaut X
	RAMPART,  # 210.4.2 : Rempart X
}

## Décision 0010 : valeur d'un mot-clé qui n'en porte pas (210.1.1).
const NO_KEYWORD_VALUE: int = 0
## Valeur de `force` d'une carte sans Force (202.1.7, 202.1.8).
const NO_FORCE: int = -1
const _ID_PATTERN: String = "^[a-z][a-z0-9_]*$"

var id: StringName = &""
var card_name: String = ""
var cost: int = 0
var card_type: CardType = CardType.UNIT
## 202.1.4 : texte d'affichage, possiblement vide ; les effets ci-dessous font foi.
var text: String = ""
var force: int = NO_FORCE
var speed: SpellSpeed = SpellSpeed.NONE
## Valeur X de chaque mot-clé (210.1.3) ; 0 pour un mot-clé sans valeur.
var keywords: Dictionary[Keyword, int] = {}
var effects: Array[EffectDefinition] = []
## Erreurs de lecture du JSON, reprises par `find_errors()`.
var parse_errors: PackedStringArray = PackedStringArray()


## Lit une carte depuis un objet JSON ; les erreurs de lecture vont dans `parse_errors`.
static func from_dict(data: Dictionary) -> CardDefinition:
	var card := CardDefinition.new()
	var reader := CatalogReader.new(data)
	reader.require("cost", "202.1.2")
	reader.require("type", "202.1.3")
	reader.require("text", "202.1.4")
	card.id = StringName(reader.read_string("id"))
	card.card_name = reader.read_string("name")
	card.cost = reader.read_int("cost", 0, 0)
	card.text = reader.read_string("text")
	card.force = reader.read_int("force", 0, NO_FORCE)
	var type_value := reader.read_enum("type", CardType)
	if type_value != CatalogReader.NOT_SET:
		card.card_type = type_value as CardType
	var speed_value := reader.read_enum("speed", SpellSpeed)
	if speed_value != CatalogReader.NOT_SET:
		card.speed = speed_value as SpellSpeed
	card._read_keywords(reader)
	card._read_effects(reader)
	card.parse_errors = reader.finish()
	return card


## Valeur X du mot-clé ; NO_KEYWORD_VALUE s'il est absent ou sans valeur.
func keyword_value(keyword: Keyword) -> int:
	return keywords.get(keyword, NO_KEYWORD_VALUE)


func has_keyword(keyword: Keyword) -> bool:
	return keywords.has(keyword)


# 202.1.1 à 202.1.8, 207.1.1, 210 : champs obligatoires par type, Force seulement pour Unit et
# Building, vitesse seulement pour Spell, mots-clés cohérents avec les effets.
func find_errors() -> PackedStringArray:
	var errors := parse_errors.duplicate()
	if not RegEx.create_from_string(_ID_PATTERN).search(String(id)):
		errors.append("id en snake_case ASCII exigé (« %s »)" % id)
	if card_name.is_empty():
		errors.append("202.1.1 : nom absent")
	if cost < 0:
		errors.append("202.1.2 : le coût est au moins 0")
	_check_force(errors)
	_check_speed(errors)
	_check_keywords(errors)
	_check_effects(errors)
	return errors


func _read_keywords(reader: CatalogReader) -> void:
	for entry: Variant in reader.read_array("keywords"):
		if typeof(entry) != TYPE_DICTIONARY:
			reader.fail("« keywords » : chaque entrée est un objet")
			continue
		var entry_dict: Dictionary = entry
		_read_keyword(entry_dict, reader)


func _read_keyword(entry: Dictionary, parent: CatalogReader) -> void:
	var keyword_reader := CatalogReader.new(entry)
	keyword_reader.require("keyword", "210")
	var keyword_value := keyword_reader.read_enum("keyword", Keyword)
	var value := keyword_reader.read_int("value", 0, 0)
	for message: String in keyword_reader.finish():
		parent.fail("mot-clé : " + message)
	if keyword_value == CatalogReader.NOT_SET:
		return
	if keywords.has(keyword_value as Keyword):
		parent.fail("210 : mot-clé « %s » en double" % Keyword.find_key(keyword_value))
		return
	keywords[keyword_value as Keyword] = value


func _read_effects(reader: CatalogReader) -> void:
	for entry: Variant in reader.read_array("effects"):
		if typeof(entry) != TYPE_DICTIONARY:
			reader.fail("« effects » : chaque entrée est un objet")
			continue
		var entry_dict: Dictionary = entry
		effects.append(EffectDefinition.from_dict(entry_dict))


func _check_force(errors: PackedStringArray) -> void:
	match card_type:
		CardType.UNIT:
			if force == NO_FORCE:
				errors.append("202.1.5 : une Unit porte une Force")
		CardType.BUILDING:
			if force == NO_FORCE:
				errors.append("202.1.6 : un Building porte une Force")
		CardType.SPELL:
			if force != NO_FORCE:
				errors.append("202.1.7 : un Spell ne porte pas de Force")
		CardType.GEAR:
			if force != NO_FORCE:
				errors.append("202.1.8 : un Gear ne porte pas de Force")


func _check_speed(errors: PackedStringArray) -> void:
	if card_type == CardType.SPELL and speed == SpellSpeed.NONE:
		errors.append("207.1.1 : un Spell porte une vitesse (action ou reaction)")
	if card_type != CardType.SPELL and speed != SpellSpeed.NONE:
		errors.append("207.1.1 : seul un Spell porte une vitesse")


func _check_keywords(errors: PackedStringArray) -> void:
	for keyword: Keyword in keywords:
		var keyword_name := str(Keyword.find_key(keyword))
		if not _allowed_types(keyword).has(card_type):
			errors.append("210 : %s est refusé pour ce type de carte" % keyword_name)
		var has_value := keywords[keyword] != 0
		if _takes_value(keyword) == has_value:
			continue
		errors.append("210.1.1 : valeur X de %s %s" % [keyword_name, _value_hint(keyword)])
	_check_trigger_keyword(errors, Keyword.ARRIVAL, EffectDefinition.TriggerEvent.ARRIVAL)
	_check_trigger_keyword(errors, Keyword.LAST_BREATH, EffectDefinition.TriggerEvent.DESTROYED)


# 210.3.1b, 210.3.2a : Arrivée et Dernier souffle sont des effets déclenchés.
func _check_trigger_keyword(
	errors: PackedStringArray, keyword: Keyword, event: EffectDefinition.TriggerEvent
) -> void:
	var has_effect := false
	for effect: EffectDefinition in effects:
		has_effect = has_effect or effect.trigger == event
	var keyword_name := str(Keyword.find_key(keyword))
	if has_keyword(keyword) and not has_effect:
		errors.append("210.3 : %s exige un effet déclenché par ce mot-clé" % keyword_name)
	if has_effect and not has_keyword(keyword):
		errors.append("210.3 : un effet déclenché par %s exige le mot-clé" % keyword_name)


func _check_effects(errors: PackedStringArray) -> void:
	var allowed := _allowed_timings()
	for index: int in effects.size():
		var effect := effects[index]
		for message: String in effect.find_errors():
			errors.append("effet %d : %s" % [index + 1, message])
		if not allowed.has(effect.timing):
			var type_name := str(CardType.find_key(card_type)).to_lower()
			errors.append("effet %d : timing refusé pour %s" % [index + 1, type_name])
	_check_once_per_turn(errors)


# 207.3.5, 207.3.7 : la mention « une fois par tour » est portée par la carte et décomptée par
# carte ; le ruleset ne dit rien d'une carte à plusieurs effets déclenchés, qui est refusée.
func _check_once_per_turn(errors: PackedStringArray) -> void:
	var triggered := effects.filter(
		func(effect: EffectDefinition) -> bool:
			return effect.timing == EffectDefinition.EffectTiming.TRIGGERED
	)
	var marked := triggered.any(func(effect: EffectDefinition) -> bool: return effect.once_per_turn)
	if marked and triggered.size() > 1:
		errors.append("207.3.5 : « une fois par tour » exige un seul effet déclenché sur la carte")


# 202.2.20 : un Spell se résout ; 207.2.2, 207.3 : une pièce porte du statique et du déclenché ;
# 207.2.8 : un Gear porte du statique.
func _allowed_timings() -> Array[EffectDefinition.EffectTiming]:
	match card_type:
		CardType.SPELL:
			return [EffectDefinition.EffectTiming.RESOLVE]
		CardType.GEAR:
			return [EffectDefinition.EffectTiming.STATIC]
	return [EffectDefinition.EffectTiming.STATIC, EffectDefinition.EffectTiming.TRIGGERED]


# 210.2.1 (Building), 210.3.1c, 210.3.2c (Unit ou Building), 210.4.1c, 210.4.2c (Unit).
func _allowed_types(keyword: Keyword) -> Array[CardType]:
	match keyword:
		Keyword.OUTPOST:
			return [CardType.BUILDING]
		Keyword.ASSAULT, Keyword.RAMPART:
			return [CardType.UNIT]
	return [CardType.UNIT, CardType.BUILDING]


# 210.1.1, 210.4.1, 210.4.2 : Assaut et Rempart portent une valeur X.
func _takes_value(keyword: Keyword) -> bool:
	return keyword == Keyword.ASSAULT or keyword == Keyword.RAMPART


func _value_hint(keyword: Keyword) -> String:
	return "au moins 1 exigée" if _takes_value(keyword) else "sans objet"
