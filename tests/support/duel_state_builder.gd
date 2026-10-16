# gdlint: disable=max-public-methods

class_name DuelStateBuilder
extends RefCounted
## Construit un DuelState pour les tests, sans passer par la préparation (204.1).
##
## Les identifiants viennent des compteurs de l'état. Par défaut : phase MAIN, tour 1,
## joueur A premier joueur, actif et avec la priorité, graine DEFAULT_SEED, Heroes sur leur
## case de départ avec DEFAULT_HERO_HEALTH PV, Sources et pendule de départ de la
## configuration, aucune carte en zone.
## Un builder ne sert qu'une fois : `build()` rend l'état qu'il a construit.

const DEFAULT_SEED: int = 1
const FIRST_TURN: int = 1
## 202.3.7 : les PV viennent de la carte Hero ; 15 est la valeur du Capitaine de test.
const DEFAULT_HERO_HEALTH: int = 15
const HERO_DEFINITION_ID: StringName = &"HERO_TEST"

var _state: DuelState


## Décision 0016 : `catalog` porte les définitions que lisent les règles (Force, coût, type).
func _init(config: DuelConfig = DuelConfig.new(), catalog: Catalog = null) -> void:
	_state = DuelState.create(config, catalog)
	_state.rng.seed = DEFAULT_SEED
	_state.phase = DuelState.DuelPhase.MAIN
	_state.turn_number = FIRST_TURN
	for player: PlayerState in _state.players:
		player.sources_upright = config.starting_sources
		player.sources_in_reserve = config.setup_sources_in_reserve
		player.fatigue_counter = config.starting_fatigue
		player.clock_remaining_msec = config.clock_duration_msec
		_place_hero(player.side)


## Convertit la notation de 201.2.4 (`"B2"`) en case.
static func cell(cell_name: String) -> Vector2i:
	return BoardGeometry.parse_cell(cell_name)


func with_seed(rng_seed: int) -> DuelStateBuilder:
	_state.rng.seed = rng_seed
	return self


func with_phase(phase: DuelState.DuelPhase) -> DuelStateBuilder:
	_state.phase = phase
	return self


func with_result(result: DuelState.DuelResult) -> DuelStateBuilder:
	_state.result = result
	return self


func with_first_player(side: DuelState.PlayerSide) -> DuelStateBuilder:
	_state.first_player = side
	return self


func with_active_player(side: DuelState.PlayerSide) -> DuelStateBuilder:
	_state.active_player = side
	return self


func with_priority_player(side: DuelState.PlayerSide) -> DuelStateBuilder:
	_state.priority_player = side
	return self


func with_turn_number(turn_number: int) -> DuelStateBuilder:
	_state.turn_number = turn_number
	return self


func with_consecutive_passes(passes: int) -> DuelStateBuilder:
	_state.consecutive_passes = passes
	return self


func with_pending_decision(decision: PendingDecision) -> DuelStateBuilder:
	_state.pending_decision = decision
	return self


func with_hero_health(side: DuelState.PlayerSide, health: int) -> DuelStateBuilder:
	_state.find_hero(side).health = health
	return self


func with_clock_remaining(side: DuelState.PlayerSide, remaining_msec: int) -> DuelStateBuilder:
	_state.get_player(side).clock_remaining_msec = remaining_msec
	return self


func with_fatigue(side: DuelState.PlayerSide, fatigue_counter: int) -> DuelStateBuilder:
	_state.get_player(side).fatigue_counter = fatigue_counter
	return self


## 203.5.1 : les Sources de la réserve ; `with_sources_in_play` règle celles du jeu.
func with_sources_in_reserve(side: DuelState.PlayerSide, count: int) -> DuelStateBuilder:
	_state.get_player(side).sources_in_reserve = count
	return self


func with_sources_in_play(
	side: DuelState.PlayerSide, upright: int, tilted: int
) -> DuelStateBuilder:
	var player := _state.get_player(side)
	player.sources_upright = upright
	player.sources_tilted = tilted
	return self


## 203.5.2 : les Sources de la Fonte.
func with_sources_in_fonte(side: DuelState.PlayerSide, count: int) -> DuelStateBuilder:
	_state.get_player(side).sources_in_fonte = count
	return self


func with_recycled_this_turn(side: DuelState.PlayerSide, count: int) -> DuelStateBuilder:
	_state.get_player(side).sources_recycled_this_turn = count
	return self


func with_hero_power_used(side: DuelState.PlayerSide, used: bool = true) -> DuelStateBuilder:
	_state.get_player(side).hero_power_used_this_turn = used
	return self


func with_normal_action_used(side: DuelState.PlayerSide, used: bool = true) -> DuelStateBuilder:
	_state.get_player(side).normal_action_used_this_turn = used
	return self


## Ajoute une carte au sommet du deck et renvoie son `card_instance_id`.
func add_to_deck(side: DuelState.PlayerSide, definition_id: StringName) -> int:
	return _add_card(_state.get_player(side).deck, side, definition_id)


func add_to_hand(side: DuelState.PlayerSide, definition_id: StringName) -> int:
	return _add_card(_state.get_player(side).hand, side, definition_id)


func add_to_discard(side: DuelState.PlayerSide, definition_id: StringName) -> int:
	return _add_card(_state.get_player(side).discard, side, definition_id)


## 201.3.9 : ajoute une carte à l'Écart de `side`.
func add_to_set_aside(side: DuelState.PlayerSide, definition_id: StringName) -> int:
	return _add_card(_state.get_player(side).set_aside, side, definition_id)


## Place une Unit de `definition_id` dans un état déjà construit et renvoie son `piece_id` :
## simule une pièce arrivée entre une annonce et sa résolution (Spell de l'étape 1.6).
static func place_unit_in(
	state: DuelState, side: DuelState.PlayerSide, definition_id: StringName, cell_name: String
) -> int:
	var card := CardInstance.new()
	card.card_instance_id = state.allocate_card_instance_id()
	card.definition_id = definition_id
	card.owner = side
	var piece := Piece.new()
	piece.piece_id = state.allocate_piece_id()
	piece.kind = Piece.PieceKind.UNIT
	piece.owner = side
	piece.cell = cell(cell_name)
	piece.card = card
	state.pieces.append(piece)
	return piece.piece_id


## Crée une instance hors zone, destinée à une pièce ou à une entrée de pile.
func make_card_instance(side: DuelState.PlayerSide, definition_id: StringName) -> CardInstance:
	var card := CardInstance.new()
	card.card_instance_id = _state.allocate_card_instance_id()
	card.definition_id = definition_id
	card.owner = side
	return card


## Place une pièce issue d'une carte sur une case libre et renvoie son `piece_id`.
## Aucune zone de déploiement n'est imposée : les tests placent où ils veulent.
func place_piece(
	side: DuelState.PlayerSide, kind: Piece.PieceKind, at_cell: Vector2i, definition_id: StringName
) -> int:
	var piece := _make_piece(side, kind, at_cell)
	if piece == null:
		return DuelState.NO_ID
	piece.card = make_card_instance(side, definition_id)
	return piece.piece_id


## Place un jeton (202.4.1) de Force `force` sur une case libre ; renvoie son `piece_id`.
func place_token(
	side: DuelState.PlayerSide, kind: Piece.PieceKind, at_cell: Vector2i, force: int
) -> int:
	var piece := _make_piece(side, kind, at_cell)
	if piece == null:
		return DuelState.NO_ID
	piece.token_force = force
	return piece.piece_id


## 202.2.8 : attache un Gear à une pièce ; renvoie le `card_instance_id` du Gear.
func attach_gear(piece_id: int, definition_id: StringName) -> int:
	var piece := _state.find_piece(piece_id)
	piece.attached_gear = make_card_instance(piece.owner, definition_id)
	return piece.attached_gear.card_instance_id


## Ajoute un effet à durée et renvoie son `effect_id`.
func add_active_effect(effect: ActiveEffect) -> int:
	effect.effect_id = _state.allocate_active_effect_id()
	_state.active_effects.append(effect)
	return effect.effect_id


## Empile `entry` au sommet de la pile en lui attribuant son `stack_entry_id`, renvoyé.
func push_stack_entry(entry: StackEntry) -> int:
	entry.stack_entry_id = _state.allocate_stack_entry_id()
	_state.stack.append(entry)
	return entry.stack_entry_id


## Empile le déploiement de `card` vers `at_cell`, comme une annonce déjà payée (203.3.2).
func push_deploy(card: CardInstance, at_cell: Vector2i) -> int:
	var entry := _make_entry(StackEntry.StackEntryKind.DEPLOY, card.owner)
	entry.card = card
	entry.target_cells.append(at_cell)
	return push_stack_entry(entry)


## Empile l'action normale de la pièce `piece_id` vers `at_cell`, comme une annonce déjà
## faite : l'action n'est pas marquée comme faite dans le tour (205.4.7).
func push_normal_action(piece_id: int, at_cell: Vector2i) -> int:
	var entry := _make_entry(
		StackEntry.StackEntryKind.NORMAL_ACTION, _state.find_piece(piece_id).owner
	)
	entry.source_piece_id = piece_id
	entry.target_cells.append(at_cell)
	return push_stack_entry(entry)


## Empile le Spell `card` et ses cibles, comme une annonce déjà payée (203.3.2).
func push_spell(card: CardInstance, target_piece_ids: Array[int] = []) -> int:
	var entry := _make_entry(StackEntry.StackEntryKind.SPELL, card.owner)
	entry.card = card
	entry.target_piece_ids.assign(target_piece_ids)
	return push_stack_entry(entry)


func build() -> DuelState:
	return _state


func _place_hero(side: DuelState.PlayerSide) -> void:
	var piece := _make_piece(side, Piece.PieceKind.HERO, BoardGeometry.hero_start_cell(side))
	piece.card = make_card_instance(side, HERO_DEFINITION_ID)
	piece.health = DEFAULT_HERO_HEALTH


func _make_piece(side: DuelState.PlayerSide, kind: Piece.PieceKind, at_cell: Vector2i) -> Piece:
	if not BoardGeometry.is_on_board(at_cell) or _state.piece_at(at_cell) != null:
		push_error("DuelStateBuilder : case %s hors plateau ou occupée (201.0.1)" % at_cell)
		return null
	var piece := Piece.new()
	piece.piece_id = _state.allocate_piece_id()
	piece.kind = kind
	piece.owner = side
	piece.cell = at_cell
	_state.pieces.append(piece)
	return piece


func _make_entry(kind: StackEntry.StackEntryKind, side: DuelState.PlayerSide) -> StackEntry:
	var entry := StackEntry.new()
	entry.kind = kind
	entry.owner = side
	return entry


func _add_card(
	zone: Array[CardInstance], side: DuelState.PlayerSide, definition_id: StringName
) -> int:
	var card := make_card_instance(side, definition_id)
	zone.append(card)
	return card.card_instance_id
