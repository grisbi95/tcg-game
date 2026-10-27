class_name ModifierRules
extends RefCounted
## Effets qui modifient une pièce : effets statiques en jeu (207.2), que ForceRules et KeywordRules
## lisent sans jamais les stocker, et effets à durée (207.4) : Force modifiée (206.5.1) et mot-clé
## accordé (210.4, décision 0058). Les seconds sont appliqués par EffectRules, qui juge les cibles
## et lit la valeur (ValueRules).

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


## 207.2.8, 207.2.9, 202.3.18 ; 202.4.5 : effets statiques de genre `kind` que porte `bearer`
## (sa carte, son passif de Hero, son Gear) ; un jeton n'en porte aucun.
static func of_kind(
	state: DuelState, bearer: Piece, kind: EffectDefinition.EffectKind
) -> Array[EffectDefinition]:
	var carried: Array[EffectDefinition] = []
	if bearer.kind == Piece.PieceKind.HERO:
		carried.append_array(state.catalog.get_hero(bearer.card.definition_id).passive)
	elif bearer.card != null:
		carried.append_array(state.catalog.get_card(bearer.card.definition_id).effects)
	if bearer.attached_gear != null:
		carried.append_array(state.catalog.get_card(bearer.attached_gear.definition_id).effects)
	var matching: Array[EffectDefinition] = []
	for effect: EffectDefinition in carried:
		if effect.timing == EffectDefinition.EffectTiming.STATIC and effect.kind == kind:
			matching.append(effect)
	return matching


## 207.2.1, 207.2.2, 207.2.4 : somme des valeurs des effets statiques de genre `kind` des pièces
## en jeu qui touchent `piece`, de mot-clé `keyword` (ANY_KEYWORD : tous). Pur.
static func total_for(
	state: DuelState, piece: Piece, kind: EffectDefinition.EffectKind, keyword: int = ANY_KEYWORD
) -> int:
	var total := 0
	for bearer: Piece in state.pieces:
		if not BoardGeometry.is_on_board(bearer.cell):
			continue
		for effect: EffectDefinition in of_kind(state, bearer, kind):
			var keyword_matches := keyword == ANY_KEYWORD or effect.keyword == keyword
			if keyword_matches and scope_touches(effect.scope, bearer, piece):
				total += effect.amount
	return total


## 206.5.5 : un effet statique ne touche une pièce que tant qu'elle remplit la condition de
## position de sa portée par rapport à `bearer`.
static func scope_touches(scope: EffectDefinition.StaticScope, bearer: Piece, piece: Piece) -> bool:
	match scope:
		EffectDefinition.StaticScope.BEARER:
			return piece == bearer
		EffectDefinition.StaticScope.ADJACENT_ALLIED_UNITS:
			return (
				piece.kind == Piece.PieceKind.UNIT
				and piece.owner == bearer.owner
				and BoardGeometry.are_adjacent(bearer.cell, piece.cell)
			)
	return false


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
