class_name StaticEffects
extends RefCounted
## Effets statiques en jeu (207.2) : lesquels une pièce porte et quelles pièces ils touchent.
## ForceRules (modificateurs de Force, auras) et KeywordRules (mots-clés accordés) les lisent ;
## ils ne se stockent jamais dans l'état.


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
## en jeu qui touchent `piece`, de mot-clé `keyword` (ModifierRules.ANY_KEYWORD : tous). Pur.
static func total_for(
	state: DuelState,
	piece: Piece,
	kind: EffectDefinition.EffectKind,
	keyword: int = ModifierRules.ANY_KEYWORD
) -> int:
	var total := 0
	for bearer: Piece in state.pieces:
		if not BoardGeometry.is_on_board(bearer.cell):
			continue
		for effect: EffectDefinition in of_kind(state, bearer, kind):
			var keyword_matches := keyword == ModifierRules.ANY_KEYWORD or effect.keyword == keyword
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
