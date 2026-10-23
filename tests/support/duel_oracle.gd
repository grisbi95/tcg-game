class_name DuelOracle
extends RefCounted
## Oracle des duels aléatoires (étape 1.10, tests/CLAUDE.md) : recalcule depuis l'état, sans
## `validate()`, des conditions du ruleset et des invariants du moteur. Chaque écart est décrit
## par une phrase qui cite sa règle.

const HAND_LIMIT: int = 7  # 201.3.4
const TOTAL_SOURCES: int = 10  # 203.5.7
const DECK_SIZE: int = 30  # 201.6.1
const BOARD_ROWS: int = 5  # 201.0.2
const HERO_ROWS: int = 2  # 205.3.2


## Écarts de `state` ; vide si l'état respecte toutes les conditions vérifiées.
static func find_violations(state: DuelState) -> PackedStringArray:
	var violations := PackedStringArray()
	_check_zones(state, violations)
	_check_players(state, violations)
	_check_board(state, violations)
	_check_stack_and_waits(state, violations)
	return violations


# 201.3 ; rules/CLAUDE.md : chaque carte est dans une seule zone, et aucune ne se perd.
static func _check_zones(state: DuelState, violations: PackedStringArray) -> void:
	var seen: Dictionary[int, bool] = {}
	for card: CardInstance in _all_cards(state):
		if seen.has(card.card_instance_id):
			violations.append("201.3 : carte %d dans deux zones" % card.card_instance_id)
		seen[card.card_instance_id] = true
	var expected := DuelState.PLAYER_COUNT * (DECK_SIZE + 1)
	if seen.size() != expected:
		violations.append("201.3 : %d cartes au lieu de %d" % [seen.size(), expected])


# 201.3.4, 203.5.7, 209.2.2, 209.2.4, 209.2.10, 209.4.3, 209.4.6
static func _check_players(state: DuelState, violations: PackedStringArray) -> void:
	for player: PlayerState in state.players:
		var side := str(DuelState.PlayerSide.find_key(player.side))
		if player.hand.size() > HAND_LIMIT:
			violations.append("201.3.4 : main de %s à %d cartes" % [side, player.hand.size()])
		_check_sources(player, side, violations)
		if player.turn_time_remaining_msec < 0 or player.response_time_remaining_msec < 0:
			violations.append("209.4 : temps de %s sous 0" % side)
		if player.idle_turns >= state.config.idle_turns_limit and not state.is_ended():
			violations.append("209.2.10 : %s inactif trop longtemps, partie non arrêtée" % side)
		var health := state.find_hero(player.side).health
		if health < 0:
			violations.append("209.2.4 : Hero de %s à %d PV" % [side, health])
		if health == 0 and not state.is_ended():
			violations.append("209.2.2 : Hero de %s à 0 PV, partie non arrêtée" % side)


# 203.5.7 : 10 Sources en tout, et aucun emplacement négatif.
static func _check_sources(
	player: PlayerState, side: String, violations: PackedStringArray
) -> void:
	if player.total_sources() != TOTAL_SOURCES:
		violations.append("203.5.7 : %s a %d Sources" % [side, player.total_sources()])
	var counts: Array[int] = [
		player.sources_in_reserve,
		player.sources_upright,
		player.sources_tilted,
		player.sources_in_fonte,
		player.sources_recycled_this_turn
	]
	if counts.any(func(count: int) -> bool: return count < 0):
		violations.append("203.5.7 : %s a un compte de Sources négatif" % side)


# 201.0.1, 205.3.2, 205.5.6 : une pièce par case, sur le plateau ; le Hero reste dans ses deux
# rangées, recalculées ici : A compte depuis la rangée 0, B depuis la dernière (201.2.5) ; un
# Building n'est jamais éveillé.
static func _check_board(state: DuelState, violations: PackedStringArray) -> void:
	var occupied: Dictionary[Vector2i, bool] = {}
	for piece: Piece in state.pieces:
		if not BoardGeometry.is_on_board(piece.cell) or occupied.has(piece.cell):
			violations.append("201.0.1 : pièce %d sur la case %s" % [piece.piece_id, piece.cell])
		occupied[piece.cell] = true
		var own_first_row := 0 if piece.owner == DuelState.PlayerSide.A else BOARD_ROWS - 1
		var is_hero := piece.kind == Piece.PieceKind.HERO
		if is_hero and absi(piece.cell.y - own_first_row) >= HERO_ROWS:
			violations.append("205.3.2 : Hero hors de ses deux rangées")
		if piece.kind == Piece.PieceKind.BUILDING and piece.is_awake:
			violations.append("205.5.6 : Building %d éveillé" % piece.piece_id)


# 208.3.1, 208.5.1, 209.2.2, décisions 0009 et 0017
static func _check_stack_and_waits(state: DuelState, violations: PackedStringArray) -> void:
	var waiting := not state.waiting_triggers.is_empty() or not state.triggers_to_add.is_empty()
	if waiting and state.pending_decision == null:
		violations.append("décision 0017 : effets en attente sans choix attendu")
	if state.is_ended():
		if state.result == DuelState.DuelResult.NONE:
			violations.append("209.2.2 : partie arrêtée sans issue")
		return
	var settled := state.stack.is_empty() and state.pending_decision == null
	if settled and state.phase != DuelState.DuelPhase.MAIN:
		violations.append("204.4.1 : pile vide hors phase principale")
	if settled and state.priority_player != state.active_player:
		violations.append("208.5.1 : pile vide, la main n'est pas au joueur actif")


static func _all_cards(state: DuelState) -> Array[CardInstance]:
	var cards: Array[CardInstance] = []
	for player: PlayerState in state.players:
		for zone: Array[CardInstance] in [
			player.deck, player.hand, player.discard, player.set_aside
		]:
			cards.append_array(zone)
	for entries: Array[StackEntry] in [state.stack, state.waiting_triggers, state.triggers_to_add]:
		for entry: StackEntry in entries:
			if entry.card != null:
				cards.append(entry.card)
	for piece: Piece in state.pieces:
		if piece.card != null:
			cards.append(piece.card)
		if piece.attached_gear != null:
			cards.append(piece.attached_gear)
	return cards
