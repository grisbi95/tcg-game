class_name ForceRules
extends RefCounted
## Force actuelle d'une pièce, calculée à la demande, jamais stockée (209.1, 206.5).
##
## Elle additionne la Force imprimée, les effets à durée en cours (ActiveEffect) et les effets
## statiques des pièces en jeu, auras comprises (207.2, 206.5.4) ; ces derniers ne sont jamais
## stockés : ils se lisent sur les pièces qui les portent.


## 209.1.1, 209.1.1a, 209.1.2, 206.2.3, 206.5.1 : Force imprimée (ou donnée au jeton) plus
## les modificateurs en cours, jamais sous 0. Un Hero n'a pas de Force (202.3.9) : le moteur
## rend 0 par convention, aucune règle ne compare encore la Force d'un Hero (206.2.1a).
static func current_force(state: DuelState, piece: Piece) -> int:
	if piece.kind == Piece.PieceKind.HERO:
		return 0
	var total := _printed_force(state, piece)
	total += _active_modifiers(state, piece)
	total += _static_modifiers(state, piece)
	return maxi(total, 0)


# 202.1.5, 202.1.6, 209.1.1a
static func _printed_force(state: DuelState, piece: Piece) -> int:
	if piece.is_token():
		return piece.token_force
	return state.catalog.get_card(piece.card.definition_id).force


# 207.4.2 : effets à durée en cours qui modifient `piece`.
static func _active_modifiers(state: DuelState, piece: Piece) -> int:
	var modify_force := EffectDefinition.kind_id(EffectDefinition.EffectKind.MODIFY_FORCE)
	var total := 0
	for effect: ActiveEffect in state.active_effects:
		if effect.affected_piece_id == piece.piece_id and effect.effect_kind == modify_force:
			total += effect.amount
	return total


# 207.2.1, 207.2.2, 207.2.4 : effets statiques des pièces en jeu qui touchent `piece`.
static func _static_modifiers(state: DuelState, piece: Piece) -> int:
	var total := 0
	for bearer: Piece in state.pieces:
		if not BoardGeometry.is_on_board(bearer.cell):
			continue
		for effect: EffectDefinition in _static_force_effects(state, bearer):
			if _scope_touches(effect.scope, bearer, piece):
				total += effect.amount
	return total


# 207.2.8, 207.2.9, 202.3.18 ; 202.4.5 : un jeton ne porte aucun effet. Un Hero absent du
# catalogue (état de test) n'a pas de passif.
static func _static_force_effects(state: DuelState, bearer: Piece) -> Array[EffectDefinition]:
	var carried: Array[EffectDefinition] = []
	if bearer.kind == Piece.PieceKind.HERO:
		var hero := state.catalog.get_hero(bearer.card.definition_id)
		if hero != null:
			carried.append_array(hero.passive)
	elif bearer.card != null:
		carried.append_array(state.catalog.get_card(bearer.card.definition_id).effects)
	if bearer.attached_gear != null:
		carried.append_array(state.catalog.get_card(bearer.attached_gear.definition_id).effects)
	var force_effects: Array[EffectDefinition] = []
	for effect: EffectDefinition in carried:
		var is_static := effect.timing == EffectDefinition.EffectTiming.STATIC
		if is_static and effect.kind == EffectDefinition.EffectKind.MODIFY_FORCE:
			force_effects.append(effect)
	return force_effects


# 206.5.5 : une aura ne touche une pièce que tant qu'elle remplit sa condition de position.
static func _scope_touches(
	scope: EffectDefinition.StaticScope, bearer: Piece, piece: Piece
) -> bool:
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
