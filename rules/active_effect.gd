class_name ActiveEffect
extends RefCounted
## Effet à durée qui modifie une pièce (207.4) ; un exemplaire par pièce modifiée (207.4.7a).
##
## Les effets statiques et les auras ne sont pas stockés : ils se lisent sur les pièces en jeu
## (207.2, 206.5.4).

## 207.4.2 : durées écrites sur une carte. Enum journalisable : ajouter à la fin.
enum EffectDuration {
	UNTIL_END_OF_TURN,
	WHILE_PIECE_IN_PLAY,
}

var effect_id: int = DuelState.NO_ID
var duration: EffectDuration = EffectDuration.UNTIL_END_OF_TURN
## 201.5.1 : joueur à qui appartient la carte qui a produit l'effet.
var owner: DuelState.PlayerSide = DuelState.PlayerSide.A
## Carte source (Spell, Gear) ; NO_ID si la source est un jeton ou une pièce du plateau.
var source_card_instance_id: int = DuelState.NO_ID
var affected_piece_id: int = DuelState.NO_ID
## Genre d'effet du vocabulaire fermé de la décision 0002 (introduit à l'étape 1.2).
var effect_kind: StringName = &""
## Valeur du modificateur, par exemple +2 de Force (206.5.1).
var amount: int = 0


func clone() -> ActiveEffect:
	var copy := ActiveEffect.new()
	copy.effect_id = effect_id
	copy.duration = duration
	copy.owner = owner
	copy.source_card_instance_id = source_card_instance_id
	copy.affected_piece_id = affected_piece_id
	copy.effect_kind = effect_kind
	copy.amount = amount
	return copy
