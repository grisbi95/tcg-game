class_name HeroOrder
extends RefCounted
## Un Ordre que porte la carte Hero (211.1, décisions 0055 et 0002) : vitesse, coût en Essence et
## texte à la résolution.
##
## Une définition qui renvoie des erreurs ne doit jamais servir au moteur.

## 211.1.2 : vitesse de l'Ordre, Action ou Réaction (même enum que celle des Spells, 207.1.2).
var speed: CardDefinition.SpellSpeed = CardDefinition.SpellSpeed.ACTION
## 211.1.3 : Essence que la carte indique pour cet Ordre, nulle si elle n'en indique pas.
var cost: int = 0
## Décision 0064 : l'Ordre porte au plus un texte, de timing RESOLVE (211.1.5).
var texts: Array[EffectText] = []
## Erreurs de lecture du JSON, reprises par `find_errors()`.
var parse_errors: PackedStringArray = PackedStringArray()


## Lit un Ordre depuis un objet JSON ; les erreurs de lecture vont dans `parse_errors`.
static func from_dict(data: Dictionary) -> HeroOrder:
	var order := HeroOrder.new()
	var reader := CatalogReader.new(data)
	reader.require("speed", "211.1.2")
	var speed_value := reader.read_enum("speed", CardDefinition.SpellSpeed)
	if speed_value != CatalogReader.NOT_SET:
		order.speed = speed_value as CardDefinition.SpellSpeed
	order.cost = reader.read_int("cost", CatalogReader.NON_NEGATIVE_MINIMUM, 0)
	order.texts = EffectText.read_all(reader, "texts")
	order.parse_errors = reader.finish()
	return order


# 211.1.2 : une vitesse ; décision 0055, 207.4.1, 211.1.5 : le texte se résout comme celui d'un
# Spell (timing RESOLVE seulement) ; le coût est lu par `read_int` (au moins 0).
func find_errors() -> PackedStringArray:
	var errors := parse_errors.duplicate()
	if speed == CardDefinition.SpellSpeed.NONE:
		errors.append("211.1.2 : un Ordre porte une vitesse (action ou reaction)")
	errors.append_array(EffectText.find_all_errors(texts, "texte"))
	for index: int in texts.size():
		if texts[index].timing != EffectDefinition.EffectTiming.RESOLVE:
			errors.append("texte %d : timing refusé pour un Ordre" % (index + 1))
	var count_error := EffectText.single_text_error(texts)
	if not count_error.is_empty():
		errors.append(count_error)
	var chosen_error := EffectValueChecks.chosen_x_error(texts, false)
	if not chosen_error.is_empty():
		errors.append(chosen_error)
	return errors
