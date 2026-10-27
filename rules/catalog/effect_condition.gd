class_name EffectCondition
extends RefCounted
## Condition « si » (207.3.13, 207.7.1, décision 0065) : une comparaison entre une valeur du jeu et
## un nombre. Le moteur la lit à l'événement pour un texte déclenché (jamais à la résolution,
## 207.3.13b), dans l'ordre du texte pour l'effet d'un Spell ou d'un Ordre (207.7.1a).

## Comparaison de la valeur au nombre. Enum journalisable : ajouter à la fin, sans réordonner.
enum Comparison {
	AT_LEAST,  # la valeur vaut `amount` ou plus
	AT_MOST,  # la valeur vaut `amount` ou moins
}

var value: GameValue = GameValue.new()
var comparison: Comparison = Comparison.AT_LEAST
var amount: int = 0
## Erreurs de lecture du JSON, reprises par `find_errors()`.
var parse_errors: PackedStringArray = PackedStringArray()


## Lit une condition depuis un objet JSON ; les erreurs de lecture vont dans `parse_errors`.
static func from_dict(data: Dictionary) -> EffectCondition:
	var condition := EffectCondition.new()
	var reader := CatalogReader.new(data)
	reader.require("value", "207.3.13")
	reader.require("comparison", "207.3.13")
	reader.require("amount", "207.3.13")
	condition.value = GameValue.from_dict(reader.read_object("value"))
	var comparison_value := reader.read_enum("comparison", Comparison)
	if comparison_value != CatalogReader.NOT_SET:
		condition.comparison = comparison_value as Comparison
	condition.amount = reader.read_int("amount", CatalogReader.NON_NEGATIVE_MINIMUM, 0)
	condition.parse_errors = reader.finish()
	return condition


## Vrai si `read_value`, la valeur lue, remplit la comparaison.
func compares(read_value: int) -> bool:
	match comparison:
		Comparison.AT_LEAST:
			return read_value >= amount
		Comparison.AT_MOST:
			return read_value <= amount
	return false


func find_errors() -> PackedStringArray:
	var errors := parse_errors.duplicate()
	for message: String in value.find_errors():
		errors.append("value : " + message)
	return errors
