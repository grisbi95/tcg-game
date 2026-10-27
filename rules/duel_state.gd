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

## 209.2.2, 209.5.3, 209.2.6, 209.2.10, 209.3.1 : pourquoi la partie s'arrête ; NONE tant
## qu'elle dure. Enum journalisable : ajouter à la fin (décision 0040). TIME_EXPIRED n'est plus
## produite depuis l'édition 0.40 (décision de design 0205) ; sa valeur reste pour les journaux.
enum EndReason {
	NONE,
	HERO_HEALTH_ZERO,
	HERO_HEALTH_ZERO_BY_FATIGUE,
	CONCEDED,
	TIME_EXPIRED,
	IDLE_TURNS,
}

## 209.4.3, 209.4.6 : le temps qui s'écoule pour un joueur attendu. Enum journalisable : ajouter
## à la fin.
enum ClockKind {
	TURN,
	RESPONSE,
}

const PLAYER_COUNT: int = 2  # 201.1.1
## Ordre fixe des joueurs quand les deux agissent tour à tour : il fixe l'ordre des tirages de
## `rng` (mélanges de 204.1.6, mulligans de la décision 0015).
const SIDES: Array[PlayerSide] = [PlayerSide.A, PlayerSide.B]
## Les compteurs d'identifiants commencent à FIRST_ID ; NO_ID désigne une absence.
const NO_ID: int = 0
const FIRST_ID: int = 1
const NO_TURN: int = 0

## Configuration partagée, en lecture seule.
var config: DuelConfig
## Décision 0016 : définitions des cartes et des Heroes, partagées en lecture seule.
var catalog: Catalog
var phase: DuelPhase = DuelPhase.NOT_STARTED
## Fixé quand la phase passe à ENDED.
var result: DuelResult = DuelResult.NONE
## 204.1.14, 204.3.4 : joueur du premier tour ; sans premier joueur imposé, significatif
## seulement après FirstPlayerChosen (204.1.16).
var first_player: PlayerSide = PlayerSide.A
## Décision 0012 : premier joueur imposé par DuelSetup, sans tirage après le mulligan.
var first_player_imposed: bool = false
## Unique source d'aléa du duel, initialisée par la graine.
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Indexé par PlayerSide.
var players: Array[PlayerState] = []
## Hero, Units, Buildings et jetons ; la case est portée par la pièce (201.0.1).
var pieces: Array[Piece] = []
## 207.3.14 : dernière case occupée par chaque pièce sortie du plateau, par `piece_id` (jamais
## réutilisé). Une entrée par pièce sortie, jamais retirée : la taille est bornée par le nombre de
## pièces créées pendant le duel.
var departed_cells: Dictionary[int, Vector2i] = {}
## Base de la pile en premier, sommet en dernier (208.3.2).
var stack: Array[StackEntry] = []
## 207.4 : effets à durée en cours.
var active_effects: Array[ActiveEffect] = []
## Décision 0017 ; 208.4.2 : effets déclenchés en attente, pas encore ordonnés.
var waiting_triggers: Array[StackEntry] = []
## Décision 0017 ; 208.4.6, 208.4.7 : effets déclenchés ordonnés, en cours d'ajout à la pile.
var triggers_to_add: Array[StackEntry] = []
## 207.3.6, 207.3.7, 207.3.7c, 207.3.10 : effets « une fois par tour » ajoutés à la pile pendant
## le tour. Chaque clé est un `Vector2i` : x = `card_instance_id` de la carte qui porte l'effet,
## y = rang du texte sur cette carte (`TriggerRules.once_per_turn_key`). Remis à zéro au début de
## chaque tour (207.3.9).
var once_per_turn_texts: Array[Vector2i] = []
## 208.7.8 à 208.7.11, 208.7.15, 208.7.16 : étiquette que reçoit un effet déclenché qui survient
## maintenant, celle de l'annonce ou de l'entrée en cours de résolution ; faux au début et à la
## fin du tour. Vrai tant qu'aucune entrée n'a fixé l'étiquette. Fixée par `add_to_stack`, par la
## prise de chaque entrée à résoudre, `start_turn` et `apply_end_turn` ; elle garde la valeur de la
## dernière entrée résolue jusqu'à la prochaine fixation, et ne se lit que quand un effet se
## déclenche, toujours après l'une d'elles.
var triggers_allow_response: bool = true
## Null hors attente d'un choix (décision 0009).
var pending_decision: PendingDecision
## Décision 0057 ; 208.3.2 : entrée sortie de la pile et en cours de résolution, null hors
## résolution. Elle reste en place pendant une attente posée par l'un de ses effets (212.1.3,
## 217.1.2), jusqu'à la fin de ses effets.
var resolving_entry: StackEntry
## Décision 0057 : rang du prochain effet de `resolving_entry` à appliquer ; 0 hors résolution.
var resolving_effect_index: int = 0
## Décision 0064 ; 207.7.6a : le dernier effet du texte en cours de résolution a eu lieu, au moins
## en partie ; lu par l'effet « si vous le faites » qui le suit, y compris après une attente (0057).
## Faux hors résolution.
var previous_effect_took_place: bool = false
var active_player: PlayerSide = PlayerSide.A
## 208.2.4 : joueur qui peut répondre ou passer.
var priority_player: PlayerSide = PlayerSide.A
## Numéro du tour global, commencé à 1.
var turn_number: int = NO_TURN
var next_card_instance_id: int = FIRST_ID
var next_piece_id: int = FIRST_ID
var next_stack_entry_id: int = FIRST_ID
var next_active_effect_id: int = FIRST_ID


## Crée un état vide avec ses deux joueurs ; les valeurs de départ relèvent de la préparation.
## Sans catalogue, l'état en reçoit un vide.
static func create(duel_config: DuelConfig, card_catalog: Catalog = null) -> DuelState:
	var state := DuelState.new()
	state.config = duel_config
	state.catalog = card_catalog if card_catalog != null else Catalog.new()
	for side: PlayerSide in SIDES:
		var player := PlayerState.new()
		player.side = side
		state.players.append(player)
	return state


# 201.1.1
static func opponent_of(side: PlayerSide) -> PlayerSide:
	return PlayerSide.B if side == PlayerSide.A else PlayerSide.A


# 209.2.2 : la partie est arrêtée.
func is_ended() -> bool:
	return phase == DuelPhase.ENDED


func get_player(side: PlayerSide) -> PlayerState:
	return players[side]


## Renvoie la pièce d'identifiant `piece_id`, ou null si elle n'est pas sur le plateau.
func find_piece(piece_id: int) -> Piece:
	for piece: Piece in pieces:
		if piece.piece_id == piece_id:
			return piece
	return null


## 207.3.14 : case de la pièce `piece_id` si elle est sur le plateau, sinon la dernière qu'elle a
## occupée ; NO_CELL pour une pièce inconnue.
func cell_of_piece(piece_id: int) -> Vector2i:
	var piece := find_piece(piece_id)
	if piece != null:
		return piece.cell
	return departed_cells.get(piece_id, BoardGeometry.NO_CELL)


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


## Copie indépendante pour l'IA. Seuls la configuration et le catalogue, en lecture seule, sont
## partagés ; le RNG repart du même `seed` et du même `state`.
func clone() -> DuelState:
	var copy := DuelState.new()
	copy.config = config
	copy.catalog = catalog
	copy.phase = phase
	copy.result = result
	copy.first_player = first_player
	copy.first_player_imposed = first_player_imposed
	copy.rng = _clone_rng()
	for player: PlayerState in players:
		copy.players.append(player.clone())
	for piece: Piece in pieces:
		copy.pieces.append(piece.clone())
	copy.departed_cells.merge(departed_cells)
	copy.stack = _clone_entries(stack)
	for effect: ActiveEffect in active_effects:
		copy.active_effects.append(effect.clone())
	copy.waiting_triggers = _clone_entries(waiting_triggers)
	copy.triggers_to_add = _clone_entries(triggers_to_add)
	copy.once_per_turn_texts.assign(once_per_turn_texts)
	copy.triggers_allow_response = triggers_allow_response
	copy.pending_decision = pending_decision.clone() if pending_decision != null else null
	copy.resolving_entry = resolving_entry.clone() if resolving_entry != null else null
	copy.resolving_effect_index = resolving_effect_index
	copy.previous_effect_took_place = previous_effect_took_place
	copy.active_player = active_player
	copy.priority_player = priority_player
	copy.turn_number = turn_number
	copy.next_card_instance_id = next_card_instance_id
	copy.next_piece_id = next_piece_id
	copy.next_stack_entry_id = next_stack_entry_id
	copy.next_active_effect_id = next_active_effect_id
	return copy


static func _clone_entries(entries: Array[StackEntry]) -> Array[StackEntry]:
	var copies: Array[StackEntry] = []
	for entry: StackEntry in entries:
		copies.append(entry.clone())
	return copies


func _clone_rng() -> RandomNumberGenerator:
	var copy := RandomNumberGenerator.new()
	copy.seed = rng.seed
	# Affecter seed réinitialise state : state doit être copié ensuite.
	copy.state = rng.state
	return copy
