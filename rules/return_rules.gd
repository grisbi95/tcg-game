class_name ReturnRules
extends RefCounted
## Renvoyer une Unit dans la main (216). Les cibles sont jugées par EffectRules (207.5) ;
## EffectRules.resolve_effect appelle `resolve`. Un renvoi n'est pas une destruction (216.2.1) :
## rien ici n'appelle CombatRules.destroy_piece ni TriggerRules, aucun Dernier souffle (216.2.2).


## 207.5.4, 207.5.5 : renvoie chaque cible restée valide ; sans aucune, l'effet n'a pas lieu.
static func resolve(context: EffectContext) -> void:
	var pieces := EffectRules.valid_pieces(context.state, context.entry, context.effect.target)
	if pieces.is_empty():
		EffectRules.lose_all_targets(context.entry, context.events)
	for piece: Piece in pieces:
		return_to_hand(context.state, piece, context.events)


## 216.1.1 à 216.1.4, 207.4.7a : `piece` quitte le plateau. Sa carte revient dans la main de son
## joueur, ou dans sa défausse si la main est pleine (216.1.2, 216.1.2a) ; un jeton cesse
## d'exister (216.1.3) ; son Gear va dans la défausse de son joueur (216.1.4).
static func return_to_hand(state: DuelState, piece: Piece, events: Array[DuelEvent]) -> void:
	ZoneRules.remove_piece(state, piece)
	ModifierRules.end_effects_on_piece(state, piece, events)
	events.append(PieceReturnedToHand.new(piece.owner, piece.piece_id))
	if piece.card != null:
		ZoneRules.return_card_to_hand(state, piece.card, events)
	ZoneRules.discard_attached_gear(state, piece, events)
