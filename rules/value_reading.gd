class_name ValueReading
extends RefCounted
## Ce qu'une lecture de valeur du jeu connaît (décision 0065) : le joueur à qui appartient l'effet,
## la pièce qui le porte et sa case, le X choisi, la cible et le Spell de l'événement. Construit à
## chaque lecture par EffectRules et TriggerRules, jamais conservé ni cloné.

var owner: DuelState.PlayerSide = DuelState.PlayerSide.A
## NO_ID sans pièce qui porte l'effet (Spell).
var source_piece_id: int = DuelState.NO_ID
## Case de la pièce qui porte l'effet, sa dernière si elle a quitté le plateau (207.3.14).
var source_cell: Vector2i = BoardGeometry.NO_CELL
## 213.1.8 : X choisi à l'annonce du Spell, 0 sans coût X.
var chosen_x: int = 0
## 213.2.3 : l'unique Unit ciblée, null sans cible lue.
var target: Piece
## 207.3.13 : Spell annoncé ou contrecarré qui déclenche le texte, null sinon.
var event_spell: StackEntry


## 207.7.1a, 213.1.8 : lecture pour l'entrée de pile `entry` quand elle se résout.
static func of_entry(state: DuelState, entry: StackEntry) -> ValueReading:
	var reading := ValueReading.new()
	reading.owner = entry.owner
	reading.source_piece_id = entry.source_piece_id
	reading.source_cell = state.cell_of_piece(entry.source_piece_id)
	reading.chosen_x = entry.x_value
	return reading


## 207.3.13 : lecture à l'événement pour un texte de `piece`, qui appartient à `owner` ; `spell` est
## le Spell de l'événement, ou null.
static func of_event(
	owner_side: DuelState.PlayerSide, piece: Piece, spell: StackEntry
) -> ValueReading:
	var reading := ValueReading.new()
	reading.owner = owner_side
	reading.source_piece_id = piece.piece_id
	reading.source_cell = piece.cell
	reading.event_spell = spell
	return reading
