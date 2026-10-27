class_name EffectCondition
extends RefCounted
## Condition « si » d'un effet déclenché (207.3.13, décision 0060) : vocabulaire fermé, une valeur
## de ConditionKind et son nombre. Le moteur la lit à l'événement (TriggerRules), jamais à la
## résolution (207.3.13b).

## 207.3.13 : conditions connues. Enum journalisable : ajouter à la fin, sans réordonner.
enum ConditionKind {
	HAND_SIZE_AT_MOST,  # la main du joueur à qui appartient l'effet compte `amount` cartes au plus
}

var kind: ConditionKind = ConditionKind.HAND_SIZE_AT_MOST
var amount: int = 0
## Erreurs de lecture du JSON, reprises par `find_errors()`.
var parse_errors: PackedStringArray = PackedStringArray()


## Lit une condition depuis un objet JSON ; les erreurs de lecture vont dans `parse_errors`.
static func from_dict(data: Dictionary) -> EffectCondition:
	var condition := EffectCondition.new()
	var reader := CatalogReader.new(data)
	reader.require("kind", "207.3.13")
	reader.require("amount", "207.3.13")
	var kind_value := reader.read_enum("kind", ConditionKind)
	if kind_value != CatalogReader.NOT_SET:
		condition.kind = kind_value as ConditionKind
	condition.amount = reader.read_int("amount", CatalogReader.NON_NEGATIVE_MINIMUM, 0)
	condition.parse_errors = reader.finish()
	return condition


func find_errors() -> PackedStringArray:
	return parse_errors.duplicate()
