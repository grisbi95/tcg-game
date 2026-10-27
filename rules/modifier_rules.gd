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
	var carried: Array[EffectText] = []
	if bearer.kind == Piece.PieceKind.HERO:
		carried.append_array(state.catalog.get_hero(bearer.card.definition_id).passive)
	elif bearer.card != null:
		carried.append_array(state.catalog.get_card(bearer.card.definition_id).texts)
	if bearer.attached_gear != null:
		carried.append_array(state.catalog.get_card(bearer.attached_gear.definition_id).texts)
	var matching: Array[EffectDefinition] = []
	for text: EffectText in carried:
		if text.timing != EffectDefinition.EffectTiming.STATIC:
			continue
		for effect: EffectDefinition in text.effects:
			if effect.kind == kind:
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


## 206.5.5, 207.2.8, décision 0062 : un effet statique ne touche une pièce que tant qu'elle remplit
## le filtre `scope` par rapport à `bearer`, la pièce qui le porte (pour un Gear, l'Unit qui le
## porte), dont le joueur est celui à qui appartient l'effet. Pur.
static func scope_touches(scope: PieceFilter, bearer: Piece, piece: Piece) -> bool:
	var anchor := FilterAnchor.new(bearer.owner, bearer.piece_id, bearer.cell)
	return matches_filter(scope, anchor, piece)


## 207.4.11, 207.4.11a, 207.4.11c, décision 0064 : pièces en jeu qui remplissent `filter` par
## rapport à `anchor` à l'instant de l'appel, dans l'ordre de `state.pieces`. L'ensemble d'un effet
## qui ne cible pas se calcule ainsi une seule fois, à la résolution ; il ne se recalcule jamais
## (un effet statique, lui, se lit en continu : `total_for`, 207.4.11b). Pur.
static func matching_pieces(
	state: DuelState, filter: PieceFilter, anchor: FilterAnchor
) -> Array[Piece]:
	var matching: Array[Piece] = []
	for piece: Piece in state.pieces:
		if BoardGeometry.is_on_board(piece.cell) and matches_filter(filter, anchor, piece):
			matching.append(piece)
	return matching


## 207.4.7a : un effet « tant que la pièce est en jeu » cesse pour `piece`, qui quitte le
## plateau ; un effet « jusqu'à la fin du tour » attend 207.4.3.
static func end_effects_on_piece(state: DuelState, piece: Piece, events: Array[DuelEvent]) -> void:
	var remaining: Array[ActiveEffect] = []
	for effect: ActiveEffect in state.active_effects:
		var lasting := effect.duration == ActiveEffect.EffectDuration.WHILE_PIECE_IN_PLAY
		if lasting and effect.affected_piece_id == piece.piece_id:
			events.append(ActiveEffectEnded.new(effect.effect_id))
		else:
			remaining.append(effect)
	state.active_effects = remaining


## 207.5.6, 206.5.5, 202.4.1, 205.1.2 à 205.1.4, décision 0062 : `piece` remplit `filter` par
## rapport à `anchor` (côté, genre, jeton, zone, relation, « autres »). Seule évaluation d'un
## PieceFilter, pour une cible comme pour une portée. Pur.
static func matches_filter(filter: PieceFilter, anchor: FilterAnchor, piece: Piece) -> bool:
	if not is_on_side(filter.side, anchor.owner, piece.owner):
		return false
	if not filter.piece_kinds.is_empty() and not filter.piece_kinds.has(piece.kind):
		return false
	if filter.tokens == PieceFilter.TokenFilter.NON_TOKEN and piece.is_token():
		return false
	if not is_in_row_zone(filter.row, anchor.owner, piece.cell):
		return false
	if not filter.include_reference and piece.piece_id == anchor.piece_id:
		return false
	return _has_relation(filter.relation, anchor, piece)


## 205.1.2 à 205.1.4 : `cell` est dans la zone nommée `zone`, relative au joueur `side`.
static func is_in_row_zone(
	zone: PieceFilter.RowZone, side: DuelState.PlayerSide, cell: Vector2i
) -> bool:
	match zone:
		PieceFilter.RowZone.OWN_FIRST:
			return BoardGeometry.is_in_first_row(side, cell)
		PieceFilter.RowZone.OWN_NEAR:
			return BoardGeometry.is_in_near_rows(side, cell)
		PieceFilter.RowZone.CENTRAL:
			return BoardGeometry.is_in_central_row(cell)
		PieceFilter.RowZone.NOT_CENTRAL:
			return BoardGeometry.is_on_board(cell) and not BoardGeometry.is_in_central_row(cell)
	return true


## Glossaire (Allié, Ennemi) : `other` est du côté `side` par rapport au joueur `owner`, à qui
## appartient l'effet. Pur.
static func is_on_side(
	side: PieceFilter.SideFilter, owner: DuelState.PlayerSide, other: DuelState.PlayerSide
) -> bool:
	match side:
		PieceFilter.SideFilter.ALLY:
			return other == owner
		PieceFilter.SideFilter.ENEMY:
			return other != owner
	return true


## 205.2.5, 207.3.14, décision 0062 : point de référence de `filter` pour un effet du joueur `owner`
## porté par la pièce `piece_id` sur la case `cell` : le Hero du joueur pour un filtre `own_hero`,
## cette pièce sinon. Pur.
static func reference_anchor(
	state: DuelState,
	filter: PieceFilter,
	owner: DuelState.PlayerSide,
	piece_id: int,
	cell: Vector2i
) -> FilterAnchor:
	if filter.relative_to != PieceFilter.RelativeTo.OWN_HERO:
		return FilterAnchor.new(owner, piece_id, cell)
	var hero := state.find_hero(owner)
	if hero == null:
		return FilterAnchor.new(owner)
	return FilterAnchor.new(owner, hero.piece_id, hero.cell)


# 205.2.5, 201.2.3 : relation de `piece` à la pièce de l'ancre, par sa case ou son identifiant.
static func _has_relation(
	relation: PieceFilter.Relation, anchor: FilterAnchor, piece: Piece
) -> bool:
	match relation:
		PieceFilter.Relation.SELF:
			return piece.piece_id == anchor.piece_id
		PieceFilter.Relation.ADJACENT:
			return BoardGeometry.are_adjacent(anchor.cell, piece.cell)
		PieceFilter.Relation.SAME_ROW:
			return BoardGeometry.are_in_same_row(anchor.cell, piece.cell)
	return true


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
