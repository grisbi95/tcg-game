class_name ForceRules
extends RefCounted
## Force actuelle d'une pièce, calculée à la demande, jamais stockée (209.1, 206.5.1).
##
## Les auras et les autres effets statiques (206.5.4, 207.2) s'ajouteront à l'étape 1.6.


## 209.1.1, 209.1.1a, 209.1.2, 206.2.3, 206.5.1 : Force imprimée (ou donnée au jeton) plus
## les modificateurs en cours, jamais sous 0. Un Hero n'a pas de Force (202.3.9) : 0.
static func current_force(state: DuelState, piece: Piece) -> int:
	if piece.kind == Piece.PieceKind.HERO:
		return 0
	var modify_force := EffectDefinition.kind_id(EffectDefinition.EffectKind.MODIFY_FORCE)
	var total := _printed_force(state, piece)
	for effect: ActiveEffect in state.active_effects:
		if effect.affected_piece_id == piece.piece_id and effect.effect_kind == modify_force:
			total += effect.amount
	return maxi(total, 0)


# 202.1.5, 202.1.6, 209.1.1a
static func _printed_force(state: DuelState, piece: Piece) -> int:
	if piece.is_token():
		return piece.token_force
	return state.catalog.get_card(piece.card.definition_id).force
