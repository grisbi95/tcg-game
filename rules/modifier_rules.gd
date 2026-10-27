class_name ModifierRules
extends RefCounted
## Effets à durée qui modifient une pièce (207.4) : Force modifiée (206.5.1) et mot-clé accordé
## (210.4, décision 0058). Appelé par EffectRules, qui juge les cibles et lit la valeur
## (ValueRules) ; les effets statiques se lisent dans StaticEffects.

## Valeur de `keyword` quand un total ne se filtre pas par mot-clé (effets de Force).
const ANY_KEYWORD: int = -1


## 207.4.2 : le modificateur de Force de valeur `amount` vit dans l'état avec sa durée.
static func add_force_modifier(context: EffectContext, piece: Piece, amount: int) -> void:
	var modifier := _add_active_effect(context, piece, amount)
	context.events.append(
		ForceModified.new(piece.owner, piece.piece_id, amount, modifier.effect_id)
	)


## 210.4, 207.4.2, décision 0058 : Assaut ou Rempart de valeur `amount` accordé vit dans l'état avec
## sa durée.
static func grant_keyword(context: EffectContext, piece: Piece, amount: int) -> void:
	var modifier := _add_active_effect(context, piece, amount)
	modifier.keyword = context.effect.keyword
	var granted := KeywordGranted.new(piece.owner, piece.piece_id, context.effect.keyword, amount)
	granted.effect_id = modifier.effect_id
	context.events.append(granted)


## 207.4.2 : somme des valeurs des effets à durée en cours de genre `kind` sur `piece`, de mot-clé
## `keyword` (ANY_KEYWORD : tous). Pur.
static func active_total(
	state: DuelState, piece: Piece, kind: EffectDefinition.EffectKind, keyword: int = ANY_KEYWORD
) -> int:
	var kind_name := EffectDefinition.kind_id(kind)
	var total := 0
	for effect: ActiveEffect in state.active_effects:
		var matches := (
			effect.affected_piece_id == piece.piece_id and effect.effect_kind == kind_name
		)
		if matches and (keyword == ANY_KEYWORD or effect.keyword == keyword):
			total += effect.amount
	return total


static func _add_active_effect(context: EffectContext, piece: Piece, amount: int) -> ActiveEffect:
	var entry := context.entry
	var modifier := ActiveEffect.new()
	modifier.effect_id = context.state.allocate_active_effect_id()
	modifier.duration = context.effect.duration
	modifier.owner = entry.owner
	modifier.source_card_instance_id = (
		entry.card.card_instance_id if entry.card != null else DuelState.NO_ID
	)
	modifier.affected_piece_id = piece.piece_id
	modifier.effect_kind = EffectDefinition.kind_id(context.effect.kind)
	modifier.amount = amount
	context.state.active_effects.append(modifier)
	return modifier
