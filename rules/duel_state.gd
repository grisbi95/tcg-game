class_name DuelState
extends RefCounted
## État complet d'un duel, unique source de vérité (décisions 0001, 0004, 0008, 0009).
##
## Seuls DuelEngine et ses modules de règles le modifient ; les requêtes en lecture sont
## publiques. `clone()` copie chaque champ : tout nouveau champ doit y figurer
## (test_duel_state_clone.gd le vérifie).

enum PlayerSide {
	A,
	B,
}

## Périodes du duel (204). Enum journalisable : ajouter à la fin, sans réordonner.
enum DuelPhase {
	NOT_STARTED,
	PREPARATION,  # 204.1, mulligan compris (204.1.10)
	TURN_START,  # 204.3
	MAIN,  # 204.4
	TURN_END,  # 204.5
	ENDED,
}

## 201.1, 209.2, 209.3 : issue du duel. Enum journalisable : ajouter à la fin.
enum DuelResult {
	NONE,
	PLAYER_A_WINS,
	PLAYER_B_WINS,
	DRAW,
}

const PLAYER_COUNT: int = 2  # 201.1.1
## Les compteurs d'identifiants commencent à FIRST_ID ; NO_ID désigne une absence.
const NO_ID: int = 0
const FIRST_ID: int = 1
const NO_TURN: int = 0

## Configuration partagée, en lecture seule.
var config: DuelConfig
var phase: DuelPhase = DuelPhase.NOT_STARTED
## Fixé quand la phase passe à ENDED.
var result: DuelResult = DuelResult.NONE
## 204.1.14, 204.3.4 : joueur du premier tour.
var first_player: PlayerSide = PlayerSide.A
## Unique source d'aléa du duel, initialisée par la graine.
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Indexé par PlayerSide.
var players: Array[PlayerState] = []
## Hero, Units, Buildings et jetons ; la case est portée par la pièce (201.0.1).
var pieces: Array[Piece] = []
## Base de la pile en premier, sommet en dernier (208.3.2).
var stack: Array[StackEntry] = []
## 207.4 : effets à durée en cours.
var active_effects: Array[ActiveEffect] = []
## Null hors attente d'un choix (décision 0009).
var pending_decision: PendingDecision
var active_player: PlayerSide = PlayerSide.A
## 208.2.4 : joueur qui peut répondre ou passer.
var priority_player: PlayerSide = PlayerSide.A
## 208.3.1 : passes consécutives depuis le dernier ajout à la pile.
var consecutive_passes: int = 0
## Numéro du tour global, commencé à 1.
var turn_number: int = NO_TURN
var next_card_instance_id: int = FIRST_ID
var next_piece_id: int = FIRST_ID
var next_stack_entry_id: int = FIRST_ID
var next_active_effect_id: int = FIRST_ID


## Crée un état vide avec ses deux joueurs ; les valeurs de départ relèvent de la préparation.
static func create(duel_config: DuelConfig) -> DuelState:
	var state := DuelState.new()
	state.config = duel_config
	for side: PlayerSide in [PlayerSide.A, PlayerSide.B]:
		var player := PlayerState.new()
		player.side = side
		state.players.append(player)
	return state


# 201.1.1
static func opponent_of(side: PlayerSide) -> PlayerSide:
	return PlayerSide.B if side == PlayerSide.A else PlayerSide.A


func get_player(side: PlayerSide) -> PlayerState:
	return players[side]


## Renvoie la pièce d'identifiant `piece_id`, ou null si elle n'est pas sur le plateau.
func find_piece(piece_id: int) -> Piece:
	for piece: Piece in pieces:
		if piece.piece_id == piece_id:
			return piece
	return null


## Renvoie la pièce qui occupe `cell`, ou null si la case est libre (201.0.1).
func piece_at(cell: Vector2i) -> Piece:
	for piece: Piece in pieces:
		if piece.cell == cell:
			return piece
	return null


## Renvoie le Hero de `side` (202.3.1), ou null avant la préparation.
func find_hero(side: PlayerSide) -> Piece:
	for piece: Piece in pieces:
		if piece.kind == Piece.PieceKind.HERO and piece.owner == side:
			return piece
	return null


## Renvoie l'entrée de pile `stack_entry_id`, ou null si elle n'est plus sur la pile.
func find_stack_entry(stack_entry_id: int) -> StackEntry:
	for entry: StackEntry in stack:
		if entry.stack_entry_id == stack_entry_id:
			return entry
	return null


## Identifiants jamais réutilisés pendant un duel (décision 0004).
func allocate_card_instance_id() -> int:
	next_card_instance_id += 1
	return next_card_instance_id - 1


func allocate_piece_id() -> int:
	next_piece_id += 1
	return next_piece_id - 1


func allocate_stack_entry_id() -> int:
	next_stack_entry_id += 1
	return next_stack_entry_id - 1


func allocate_active_effect_id() -> int:
	next_active_effect_id += 1
	return next_active_effect_id - 1


## Copie indépendante pour l'IA. Seule la configuration, en lecture seule, est partagée ; le
## RNG repart du même `seed` et du même `state`.
func clone() -> DuelState:
	var copy := DuelState.new()
	copy.config = config
	copy.phase = phase
	copy.result = result
	copy.first_player = first_player
	copy.rng = _clone_rng()
	for player: PlayerState in players:
		copy.players.append(player.clone())
	for piece: Piece in pieces:
		copy.pieces.append(piece.clone())
	for entry: StackEntry in stack:
		copy.stack.append(entry.clone())
	for effect: ActiveEffect in active_effects:
		copy.active_effects.append(effect.clone())
	copy.pending_decision = pending_decision.clone() if pending_decision != null else null
	copy.active_player = active_player
	copy.priority_player = priority_player
	copy.consecutive_passes = consecutive_passes
	copy.turn_number = turn_number
	copy.next_card_instance_id = next_card_instance_id
	copy.next_piece_id = next_piece_id
	copy.next_stack_entry_id = next_stack_entry_id
	copy.next_active_effect_id = next_active_effect_id
	return copy


func _clone_rng() -> RandomNumberGenerator:
	var copy := RandomNumberGenerator.new()
	copy.seed = rng.seed
	# Affecter seed réinitialise state : state doit être copié ensuite.
	copy.state = rng.state
	return copy
