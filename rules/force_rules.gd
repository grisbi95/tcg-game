class_name ForceRules
extends RefCounted
## Force actuelle d'une pièce, calculée à la demande, jamais stockée (209.1, 206.5).
##
## Elle additionne la Force imprimée, les effets à durée en cours (ActiveEffect) et les effets
## statiques des pièces en jeu, auras comprises (207.2, 206.5.4) ; ces derniers ne sont jamais
## stockés : ils se lisent sur les pièces qui les portent.

## 206.1.1, 206.1.2 : rôle d'une pièce dans un combat, pour Assaut et Rempart (210.4).
enum CombatRole {
	ATTACKER,
	DEFENDER,
}

const FORCE_KIND: EffectDefinition.EffectKind = EffectDefinition.EffectKind.MODIFY_FORCE


## 209.1.1, 209.1.1a, 209.1.2, 206.2.3, 206.5.1 : Force imprimée (ou donnée au jeton) plus
## les modificateurs en cours, jamais sous 0. Un Hero n'a pas de Force (202.3.9) : le moteur
## rend 0 par convention, aucune règle ne compare encore la Force d'un Hero (206.2.1a).
static func current_force(state: DuelState, piece: Piece) -> int:
	if piece.kind == Piece.PieceKind.HERO:
		return 0
	return maxi(_force_before_floor(state, piece), 0)


## 206.2.2, 206.2.3 : Force lue au moment d'un combat ; 210.4.1a, 210.4.2a : Assaut X pour
## l'attaquant, Rempart X pour le défenseur, s'additionne aux autres modificateurs avant le
## plancher de 209.1.2. Un Hero rend 0, comme pour `current_force`.
static func combat_force(state: DuelState, piece: Piece, role: CombatRole) -> int:
	if piece.kind == Piece.PieceKind.HERO:
		return 0
	var keyword_bonus := (
		KeywordRules.assault_value(state, piece)
		if role == CombatRole.ATTACKER
		else KeywordRules.rampart_value(state, piece)
	)
	return maxi(_force_before_floor(state, piece) + keyword_bonus, 0)


# 209.1.1
static func _force_before_floor(state: DuelState, piece: Piece) -> int:
	return (
		_printed_force(state, piece)
		+ ModifierRules.active_total(state, piece, FORCE_KIND)
		+ ModifierRules.total_for(state, piece, FORCE_KIND)
	)


# 202.1.5, 202.1.6, 209.1.1a
static func _printed_force(state: DuelState, piece: Piece) -> int:
	if piece.is_token():
		return piece.token_force
	return state.catalog.get_card(piece.card.definition_id).force
