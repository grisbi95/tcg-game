# gdlint: disable=max-public-methods

class_name DuelStateBuilder
extends RefCounted
## Construit un DuelState pour les tests, sans passer par la préparation (204.1).
##
## Les identifiants viennent des compteurs de l'état. Par défaut : phase MAIN, tour 1,
## joueur A premier joueur, actif et avec la priorité, graine DEFAULT_SEED, Heroes sur leur
## case de départ avec DEFAULT_HERO_HEALTH PV, Sources et pendule de départ de la
## configuration, aucune carte en zone.
## Les Units, jetons et Heroes placés (`place_piece`, `place_token`, `place_unit_in`) sont
## éveillés par défaut, jamais un Building (205.5.6), car un état construit représente un
## moment de partie où ils ont déjà pu agir (205.5.3) ; `with_piece_awake` les endort. Les
## pièces créées par le moteur naissent endormies (205.5.4).
## Un builder ne sert qu'une fois : `build()` rend l'état qu'il a construit.

const DEFAULT_SEED: int = 1
const FIRST_TURN: int = 1
## 202.3.7 : les PV viennent de la carte Hero ; 15 est la valeur du Capitaine de test.
const DEFAULT_HERO_HEALTH: int = 15
## Hero sans passif, ajouté au catalogue s'il n'y est pas (décision 0016).
const HERO_DEFINITION_ID: StringName = &"builder_hero"

var _state: DuelState


## Décision 0016 : `catalog` porte les définitions que lisent les règles (Force, coût, type).
func _init(config: DuelConfig = DuelConfig.new(), catalog: Catalog = null) -> void:
	_state = DuelState.create(config, catalog)
	_register_default_hero()
	_state.rng.seed = DEFAULT_SEED
	_state.phase = DuelState.DuelPhase.MAIN
	_state.turn_number = FIRST_TURN
	for player: PlayerState in _state.players:
		player.sources_upright = config.starting_sources
		player.sources_in_reserve = config.setup_sources_in_reserve
		player.fatigue_counter = config.starting_fatigue
		player.turn_time_remaining_msec = config.turn_time_msec
		player.response_time_remaining_msec = config.response_time_msec
		_place_hero(player.side)


## Convertit la notation de 201.2.4 (`"B2"`) en case.
static func cell(cell_name: String) -> Vector2i:
	return BoardGeometry.parse_cell(cell_name)


## 202.3.4 : le Hero de `side` est la carte Hero `definition_id` du catalogue.
func with_hero_definition(
	side: DuelState.PlayerSide, definition_id: StringName
) -> DuelStateBuilder:
	_state.find_hero(side).card.definition_id = definition_id
	return self


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


func with_pending_decision(decision: PendingDecision) -> DuelStateBuilder:
	_state.pending_decision = decision
	return self


func with_hero_health(side: DuelState.PlayerSide, health: int) -> DuelStateBuilder:
	_state.find_hero(side).health = health
	return self


func with_turn_time_remaining(side: DuelState.PlayerSide, remaining_msec: int) -> DuelStateBuilder:
	_state.get_player(side).turn_time_remaining_msec = remaining_msec
	return self


func with_response_time_remaining(
	side: DuelState.PlayerSide, remaining_msec: int
) -> DuelStateBuilder:
	_state.get_player(side).response_time_remaining_msec = remaining_msec
	return self


func with_idle_turns(side: DuelState.PlayerSide, idle_turns: int) -> DuelStateBuilder:
	_state.get_player(side).idle_turns = idle_turns
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


func with_essence_reserve(side: DuelState.PlayerSide, essence: int) -> DuelStateBuilder:
	_state.get_player(side).essence_reserve = essence
	return self


func with_recycled_this_turn(side: DuelState.PlayerSide, count: int) -> DuelStateBuilder:
	_state.get_player(side).sources_recycled_this_turn = count
	return self


## 205.5.1, 205.5.2 : règle l'état endormi ou éveillé d'une pièce déjà placée.
func with_piece_awake(piece_id: int, awake: bool = true) -> DuelStateBuilder:
	_state.find_piece(piece_id).is_awake = awake
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
	if state.piece_at(cell(cell_name)) != null:
		push_error("DuelStateBuilder : case %s occupée (201.0.1)" % cell_name)
		return DuelState.NO_ID
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
	piece.is_awake = true
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
## `allows_response` faux pose l'étiquette d'une annonce sans réponse (208.7.3), que le moteur
## résout à sa prochaine soumission.
func push_deploy(card: CardInstance, at_cell: Vector2i, allows_response: bool = true) -> int:
	var entry := _make_entry(StackEntry.StackEntryKind.DEPLOY, card.owner)
	entry.card = card
	entry.allows_response = allows_response
	entry.target_cells.append(at_cell)
	return push_stack_entry(entry)


## Empile l'action normale de la pièce `piece_id` vers `at_cell`, comme une annonce déjà
## faite : l'action n'est pas marquée comme faite dans le tour (205.4.7). `allows_response` faux
## pose l'étiquette d'une action vers une case libre (208.7.4).
func push_normal_action(piece_id: int, at_cell: Vector2i, allows_response: bool = true) -> int:
	var entry := _make_entry(
		StackEntry.StackEntryKind.NORMAL_ACTION, _state.find_piece(piece_id).owner
	)
	entry.source_piece_id = piece_id
	entry.allows_response = allows_response
	entry.target_cells.append(at_cell)
	return push_stack_entry(entry)


## Empile le Spell `card` et ses cibles, comme une annonce déjà payée (203.3.2).
func push_spell(card: CardInstance, target_piece_ids: Array[int] = [], x_value: int = 0) -> int:
	var entry := _make_entry(StackEntry.StackEntryKind.SPELL, card.owner)
	entry.card = card
	entry.x_value = x_value
	entry.target_piece_ids.assign(target_piece_ids)
	return push_stack_entry(entry)


func build() -> DuelState:
	return _state


func _register_default_hero() -> void:
	if _state.catalog.get_hero(HERO_DEFINITION_ID) != null:
		return
	var data := CatalogSamples.with_field(CatalogSamples.hero(), "id", String(HERO_DEFINITION_ID))
	data = CatalogSamples.with_flats(data, "passive", [])
	_state.catalog.add_hero(HeroDefinition.from_dict(data))


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
	piece.is_awake = kind != Piece.PieceKind.BUILDING  # 205.5.6
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
