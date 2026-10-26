class_name MoveRules
extends RefCounted
## Déplacer une Unit par un effet (215). Les cibles (une Unit et sa case de destination, décision
## 0056) sont jugées par EffectRules (207.5) ; EffectRules.resolve_effect appelle `resolve`.
##
## Le déplacement n'endort ni ne réveille (215.2.1, 215.2.2), n'est pas l'action normale
## (215.2.3), ne fait pas arriver l'Unit et ne déclenche aucune Arrivée (215.2.4, 215.2.5), et
## n'est pas un combat (215.2.6) : rien ici ne touche à `is_awake`, à TriggerRules ni à
## CombatRules.


## 215.1.1, 215.1.2, 207.5.4, 207.5.5 : la case est jugée par rapport à la pièce ciblée restée
## valide (sans elle, une case relative à la pièce est invalide). Sans pièce valide ni case
## valide, l'effet n'a pas lieu et le dit ; avec une pièce valide et une case valide, la pièce
## se déplace (déplacement, PieceMoved) ; dans les autres cas, rien ne se passe.
static func resolve(context: EffectContext) -> void:
	var entry := context.entry
	var pieces := EffectRules.valid_pieces(context.state, entry, context.effect.target)
	var anchor: Piece = pieces[0] if not pieces.is_empty() else null
	var cells: Array[Vector2i] = []
	for cell: Vector2i in entry.target_cells:
		if EffectRules.is_legal_cell(
			context.state, entry.owner, context.effect.destination, cell, anchor
		):
			cells.append(cell)
	if pieces.is_empty() and cells.is_empty():
		EffectRules.lose_all_targets(entry, context.events)
	elif anchor != null and not cells.is_empty():
		ZoneRules.move_piece(anchor, cells[0], context.events)  # 215.1.2
