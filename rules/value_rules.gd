class_name ValueRules
extends RefCounted
## Valeur X (213, décision 0058) : coût X d'une carte, valeur choisie à l'annonce d'un Spell, valeur
## d'un effet lue à la résolution. SpellRules, CardRules et ActionRules lisent les coûts ici ;
## EffectRules lit X des effets ici.

## 213.1.4 : valeur minimale de X.
const MIN_X_VALUE: int = 1


## 213.1.5 à 213.1.7, 202.1.2 : coût d'une carte. Un coût X vaut la valeur choisie quand la carte
## est sur la pile, dont `entry` est l'entrée du Spell, et 0 dans toute autre zone (`entry` null) ;
## un coût fixe ne dépend pas de la zone. Seul un Spell porte un coût X (213.1.2). Pur.
static func current_cost(definition: CardDefinition, entry: StackEntry = null) -> int:
	return cost_with_x(definition, 0 if entry == null else entry.x_value)


## 213.1.5, 213.1.6 : coût de `definition` si X vaut `x_value` ; X Essence pour un coût X, son coût
## fixe sinon. Pur.
static func cost_with_x(definition: CardDefinition, x_value: int) -> int:
	return x_value if definition.has_x_cost else definition.cost


## 213.1.2, 213.1.3, 213.1.4, 213.2.5 : raison du refus de la valeur `x_value` choisie pour
## `definition` : au moins 1 pour un coût X, 0 pour tout autre Spell (X défini par un texte, ou
## sans X, n'est pas choisi). Pur.
static func validate_x_value(
	definition: CardDefinition, x_value: int
) -> IntentRejected.RejectReason:
	if definition.has_x_cost and x_value < MIN_X_VALUE:
		return IntentRejected.RejectReason.X_VALUE_TOO_LOW
	if not definition.has_x_cost and x_value != 0:
		return IntentRejected.RejectReason.UNEXPECTED_X_VALUE
	return IntentRejected.RejectReason.NONE


## 213.1.8, 213.2.1 à 213.2.4 : valeur de `amount` de `effect` pour `entry`, lue une seule fois ;
## « X » vaut la valeur choisie à l'annonce, ou la Force actuelle (sans Assaut ni Rempart) de
## l'unique pièce visée `pieces`. Pur.
static func read_amount(
	state: DuelState, entry: StackEntry, effect: EffectDefinition, pieces: Array[Piece]
) -> int:
	if not effect.amount_is_x:
		return effect.amount
	if effect.x_source == EffectDefinition.XSource.TARGET_FORCE:
		return ForceRules.current_force(state, pieces[0])
	return entry.x_value
