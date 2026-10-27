class_name ValueRules
extends RefCounted
## Valeur X (213, décisions 0058 et 0065) : coût X d'une carte, valeur choisie à l'annonce d'un
## Spell, lecture unique des valeurs du jeu par les conditions et par X. SpellRules, CardRules et
## ActionRules lisent les coûts ici ; EffectRules et TriggerRules lisent conditions et X ici.

## 213.1.4 : valeur minimale de X.
const MIN_X_VALUE: int = 1
## Valeur d'une lecture qui n'a pas de résultat ; aucune valeur du jeu n'est négative.
const UNREADABLE: int = -1


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


## 213.1.8, 213.2.1 à 213.2.4, décision 0065 : valeur de `amount` de `effect` pour `entry`, lue une
## seule fois ; « X » vaut la valeur du jeu `effect.x_from`, avec pour cible l'unique pièce visée
## `pieces` s'il y en a une. UNREADABLE si la valeur ne peut pas être lue. Pur.
static func read_amount(
	state: DuelState, entry: StackEntry, effect: EffectDefinition, pieces: Array[Piece] = []
) -> int:
	if not effect.amount_is_x:
		return effect.amount
	var reading := ValueReading.of_entry(state, entry)
	if not pieces.is_empty():
		reading.target = pieces[0]
	return read_value(state, effect.x_from, reading)


## Décision 0065 : vrai si `amount`, lu par `read_amount` pour `effect`, est illisible (garde
## défensive) : l'effet n'a pas lieu. Un `amount` écrit en nombre n'est jamais illisible (-1 reste
## possible).
static func is_unreadable_amount(effect: EffectDefinition, amount: int) -> bool:
	return effect.amount_is_x and amount == UNREADABLE


## 207.3.13, 207.7.1, 213.2.1, décision 0065 : valeur du jeu `value` telle que la voit `reading`,
## seule lecture des conditions et de X. UNREADABLE est une garde défensive de la décision 0065 :
## pièce source, cible ou Spell de l'événement absent, ce que le catalogue interdit (source_force
## refusée, target_force exige sa cible, event_spell_cost exige un déclencheur de Spell). Pur.
static func read_value(state: DuelState, value: GameValue, reading: ValueReading) -> int:
	match value.kind:
		GameValue.Kind.HAND_SIZE:
			return state.get_player(reading.owner).hand.size()
		GameValue.Kind.PIECE_COUNT:
			return _count_pieces(state, value.piece_filter, reading)
		GameValue.Kind.SOURCE_FORCE:
			return _force_of(state, state.find_piece(reading.source_piece_id))
		GameValue.Kind.TARGET_FORCE:
			return _force_of(state, reading.target)
		GameValue.Kind.DISCARDED_BY_PREVIOUS_EFFECT:
			return state.previous_effect_discarded_count
		GameValue.Kind.CHOSEN_X:
			return reading.chosen_x
		GameValue.Kind.EVENT_SPELL_COST:
			return _event_spell_cost(state, reading.event_spell)
	return UNREADABLE


## 207.3.13, 207.3.13a, 207.7.1, 207.7.2, décision 0065 : vrai si `condition` est absente, ou si la
## valeur du jeu qu'elle compare, lue par `reading`, remplit sa comparaison. Une valeur illisible
## (garde défensive, décision 0065) ne la remplit pas. Pur.
static func condition_holds(
	state: DuelState, condition: EffectCondition, reading: ValueReading
) -> bool:
	if condition == null:
		return true
	var read := read_value(state, condition.value, reading)
	return read != UNREADABLE and condition.compares(read)


# Décision 0062, 0063 : pièces en jeu qui remplissent `filter` par rapport à la pièce qui porte
# l'effet ou au Hero du joueur.
static func _count_pieces(state: DuelState, filter: PieceFilter, reading: ValueReading) -> int:
	var anchor := ModifierRules.reference_anchor(
		state, filter, reading.owner, reading.source_piece_id, reading.source_cell
	)
	return ModifierRules.matching_pieces(state, filter, anchor).size()


# 213.2.3, 213.2.4 : Force actuelle, sans Assaut ni Rempart ; UNREADABLE sans pièce en jeu.
static func _force_of(state: DuelState, piece: Piece) -> int:
	if piece == null:
		return UNREADABLE
	return ForceRules.current_force(state, piece)


# 213.1.6 : coût actuel du Spell de l'événement, X compris.
static func _event_spell_cost(state: DuelState, spell: StackEntry) -> int:
	if spell == null:
		return UNREADABLE
	return current_cost(state.catalog.get_card(spell.card.definition_id), spell)
