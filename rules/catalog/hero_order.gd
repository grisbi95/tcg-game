class_name HeroOrder
extends RefCounted
## Un Ordre que porte la carte Hero (211.1, décisions 0055 et 0002) : vitesse, coût en Essence et
## effets à la résolution.
##
## Une définition qui renvoie des erreurs ne doit jamais servir au moteur.

## 211.1.2 : vitesse de l'Ordre, Action ou Réaction (même enum que celle des Spells, 207.1.2).
var speed: CardDefinition.SpellSpeed = CardDefinition.SpellSpeed.ACTION
## 211.1.3 : Essence que la carte indique pour cet Ordre, nulle si elle n'en indique pas.
var cost: int = 0
var effects: Array[EffectDefinition] = []
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
	for entry: Dictionary in reader.read_objects("effects"):
		order.effects.append(EffectDefinition.from_dict(entry))
	order.parse_errors = reader.finish()
	return order


# 211.1.2 : une vitesse ; décision 0055, 207.4.1 : les effets se résolvent comme ceux d'un Spell
# (timing RESOLVE seulement, comme CardDefinition) ; le coût est lu par `read_int` (au moins 0).
func find_errors() -> PackedStringArray:
	var errors := parse_errors.duplicate()
	if speed == CardDefinition.SpellSpeed.NONE:
		errors.append("211.1.2 : un Ordre porte une vitesse (action ou reaction)")
	for index: int in effects.size():
		for message: String in effects[index].find_errors():
			errors.append("effet %d : %s" % [index + 1, message])
		if effects[index].timing != EffectDefinition.EffectTiming.RESOLVE:
			errors.append("effet %d : timing refusé pour un Ordre" % (index + 1))
	return errors
