class_name KeywordRules
extends RefCounted
## Mots-clés (210) : Avant-poste (210.2), Assaut et Rempart (210.4). Arrivée et Dernier souffle
## (210.3) sont des effets déclenchés, que TriggerRules met en attente.
##
## Les mots-clés se lisent sur la définition de la carte d'une pièce ; un Hero et un jeton n'en
## portent aucun (202.4.13), sauf Assaut et Rempart qu'un effet accorde à une Unit (202.4.13a).


## 210.4.1, 210.4.1a, 210.1.3 : Assaut X de `piece`, ajouté à sa Force quand elle attaque ; 0 sans
## le mot-clé. Somme la valeur de sa carte et celles que lui accordent des effets (décision 0058).
static func assault_value(state: DuelState, piece: Piece) -> int:
	return _keyword_value(state, piece, CardDefinition.Keyword.ASSAULT)


## 210.4.2, 210.4.2a, 210.1.3 : Rempart X de `piece`, ajouté à sa Force quand elle défend ; 0 sans
## le mot-clé. Somme la valeur de sa carte et celles que lui accordent des effets (décision 0058).
static func rampart_value(state: DuelState, piece: Piece) -> int:
	return _keyword_value(state, piece, CardDefinition.Keyword.RAMPART)


## 210.2.1, 210.2.1a, 205.1.2a : `cell` est adjacente à l'un des Buildings de `side` qui a
## Avant-poste, hors de la rangée centrale. Que la case soit libre se contrôle à part. Pur.
static func is_outpost_cell(state: DuelState, side: DuelState.PlayerSide, cell: Vector2i) -> bool:
	if BoardGeometry.is_in_central_row(cell):
		return false
	for piece: Piece in state.pieces:
		var is_own_building := piece.kind == Piece.PieceKind.BUILDING and piece.owner == side
		if not is_own_building or not BoardGeometry.are_adjacent(piece.cell, cell):
			continue
		if _has_keyword(state, piece, CardDefinition.Keyword.OUTPOST):
			return true
	return false


static func _keyword_value(state: DuelState, piece: Piece, keyword: CardDefinition.Keyword) -> int:
	var printed := 0
	if _carries_keywords(piece):
		printed = _definition_of(state, piece).keyword_value(keyword)
	return printed + _granted_value(state, piece, keyword)


# 202.4.13a, 210.4.1c, 210.4.2c : une Unit, jeton compris, reçoit Assaut ou Rempart d'un effet à
# durée, d'un effet statique de Gear ou d'une aura ; décision 0058.
static func _granted_value(state: DuelState, piece: Piece, keyword: CardDefinition.Keyword) -> int:
	if piece.kind != Piece.PieceKind.UNIT:
		return 0
	var kind := EffectDefinition.EffectKind.GRANT_KEYWORD
	return (
		ModifierRules.active_total(state, piece, kind, keyword)
		+ ModifierRules.total_for(state, piece, kind, keyword)
	)


static func _has_keyword(state: DuelState, piece: Piece, keyword: CardDefinition.Keyword) -> bool:
	return _carries_keywords(piece) and _definition_of(state, piece).has_keyword(keyword)


# 202.4.13 : un jeton ne porte aucun mot-clé ; 210.2.1, 210.3.1c, 210.3.2c, 210.4.1c, 210.4.2c :
# seuls une Unit ou un Building en portent, jamais un Hero.
static func _carries_keywords(piece: Piece) -> bool:
	return piece.kind != Piece.PieceKind.HERO and not piece.is_token()


static func _definition_of(state: DuelState, piece: Piece) -> CardDefinition:
	return state.catalog.get_card(piece.card.definition_id)
