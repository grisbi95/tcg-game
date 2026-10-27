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
## Coût fixe ; 0 quand le coût est X (`has_x_cost`).
var cost: int = 0
## 213.1.1, 213.1.12 : le coût s'écrit « X » dans le JSON, X seul sans partie fixe ; se lit par
## `ValueRules.current_cost`.
var has_x_cost: bool = false
var card_type: CardType = CardType.UNIT
## 202.1.4 : texte d'affichage, possiblement vide ; les effets ci-dessous font foi.
var text: String = ""
var force: int = NO_FORCE
var speed: SpellSpeed = SpellSpeed.NONE
## Valeur X de chaque mot-clé (210.1.3) ; 0 pour un mot-clé sans valeur.
var keywords: Dictionary[Keyword, int] = {}
## Décision 0064 : textes de la carte, dans l'ordre ; `StackEntry.text_index` d'un effet déclenché
## en est le rang. Un Spell porte au plus un texte, de timing RESOLVE.
var texts: Array[EffectText] = []
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
	card.has_x_cost = reader.is_x("cost")
	if not card.has_x_cost:
		card.cost = reader.read_int("cost", CatalogReader.NON_NEGATIVE_MINIMUM, 0)
	card.text = reader.read_string("text")
	card.force = reader.read_int("force", CatalogReader.NON_NEGATIVE_MINIMUM, NO_FORCE)
	var type_value := reader.read_enum("type", CardType)
	if type_value != CatalogReader.NOT_SET:
		card.card_type = type_value as CardType
	var speed_value := reader.read_enum("speed", SpellSpeed)
	if speed_value != CatalogReader.NOT_SET:
		card.speed = speed_value as SpellSpeed
	card._read_keywords(reader)
	card.texts = EffectText.read_all(reader, "texts")
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
	_check_x_cost(errors)
	_check_keywords(errors)
	_check_texts(errors)
	return errors


func _read_keywords(reader: CatalogReader) -> void:
	for entry: Dictionary in reader.read_objects("keywords"):
		_read_keyword(entry, reader)


func _read_keyword(entry: Dictionary, parent: CatalogReader) -> void:
	var keyword_reader := CatalogReader.new(entry)
	keyword_reader.require("keyword", "210")
	var keyword := keyword_reader.read_enum("keyword", Keyword)
	var value := keyword_reader.read_int("value", CatalogReader.NON_NEGATIVE_MINIMUM, 0)
	for message: String in keyword_reader.finish():
		parent.fail("mot-clé : " + message)
	if keyword == CatalogReader.NOT_SET:
		return
	if keywords.has(keyword as Keyword):
		parent.fail("210 : mot-clé « %s » en double" % Keyword.find_key(keyword))
		return
	keywords[keyword as Keyword] = value


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


# 213.1.2 : seul un Spell porte un coût X ; 213.1.3 : X choisi se lit sur un Spell à coût X.
func _check_x_cost(errors: PackedStringArray) -> void:
	if has_x_cost and card_type != CardType.SPELL:
		errors.append("213.1.2 : seul un Spell porte un coût X")
	var chosen_error := EffectValueChecks.chosen_x_error(texts, has_x_cost)
	if not chosen_error.is_empty():
		errors.append(chosen_error)


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
	var has_effect := texts.any(func(each: EffectText) -> bool: return each.trigger == event)
	var keyword_name := str(Keyword.find_key(keyword))
	if has_keyword(keyword) and not has_effect:
		errors.append("210.3 : %s exige un effet déclenché par ce mot-clé" % keyword_name)
	if has_effect and not has_keyword(keyword):
		errors.append("210.3 : un effet déclenché par %s exige le mot-clé" % keyword_name)


func _check_texts(errors: PackedStringArray) -> void:
	var allowed := _allowed_timings()
	errors.append_array(EffectText.find_all_errors(texts, "texte"))
	for index: int in texts.size():
		var effect_text := texts[index]
		_check_text_placement(errors, effect_text, "texte %d" % [index + 1], allowed)
	var count_error := EffectText.single_text_error(texts)
	if card_type == CardType.SPELL and not count_error.is_empty():
		errors.append(count_error)
	var is_unit_bearer := card_type in [CardType.UNIT, CardType.GEAR]
	var bearer_error := EffectValueChecks.bearer_grant_error(texts, is_unit_bearer)
	if not bearer_error.is_empty():
		errors.append(bearer_error)


# Réveiller un Building est exclu (205.5.6) ; endormir un Building « n'a pas lieu pour lui »
# (205.5.7b) : SLEEP sur la pièce source d'un Building reste donc valide.
func _check_text_placement(
	errors: PackedStringArray,
	effect_text: EffectText,
	label: String,
	allowed: Array[EffectDefinition.EffectTiming]
) -> void:
	for effect: EffectDefinition in effect_text.effects:
		var wakes_building := (
			card_type == CardType.BUILDING
			and effect.kind == EffectDefinition.EffectKind.WAKE
			and effect.subject == EffectDefinition.EffectSubject.SOURCE_PIECE
		)
		if wakes_building:
			errors.append("%s : 205.5.6, un Building ne se réveille pas" % label)
	if not allowed.has(effect_text.timing):
		var type_name := str(CardType.find_key(card_type)).to_lower()
		errors.append("%s : timing refusé pour %s" % [label, type_name])
	if (
		card_type == CardType.GEAR
		and effect_text.trigger == EffectDefinition.TriggerEvent.OTHER_PIECE_DESTROYED
	):
		errors.append(
			(
				"%s : en attente d'une question du ruleset (voir 207.3.12a, 207.3.15), " % label
				+ "un Gear ne porte pas de texte other_piece_destroyed"
			)
		)
	var attack_error := effect_text.destroys_defender_error(
		card_type in [CardType.UNIT, CardType.GEAR]
	)
	if not attack_error.is_empty():
		errors.append("%s : %s" % [label, attack_error])


# 202.2.20 : un Spell se résout ; 207.2.2, 207.3 : une pièce porte du statique et du déclenché ;
# 207.2.8, 207.3.12 : un Gear aussi.
func _allowed_timings() -> Array[EffectDefinition.EffectTiming]:
	if card_type == CardType.SPELL:
		return [EffectDefinition.EffectTiming.RESOLVE]
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
