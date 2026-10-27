class_name PendingDecision
extends RefCounted
## Attente d'un choix de joueur (décisions 0004 et 0009).
##
## `DuelState.pending_decision` vaut null hors attente. Pendant une attente, seule l'intention
## qui y répond est acceptée, et la pendule des joueurs attendus tourne (209.4.4).

## Enum journalisable : ajouter à la fin, sans réordonner.
enum DecisionKind {
	MULLIGAN,  # 204.2.2, 209.4.2d
	ORDER_TRIGGERS,  # 208.4.6, 208.4.7, 209.4.4c
	CHOOSE_TARGETS,  # 207.5.1b, 207.5.2, 209.4.4d
	CHOOSE_DISCARD,  # 212.1.3, 212.2.3, 209.4.7c : pendant la résolution (décision 0057)
	CHOOSE_TOP_CARD_PLACE,  # 217.1.2, 217.1.3, 209.4.7d : pendant la résolution (décision 0057)
}

var kind: DecisionKind = DecisionKind.MULLIGAN
## Joueurs dont on attend une réponse ; les deux pour le mulligan simultané (204.2.2).
var awaited_players: Array[DuelState.PlayerSide] = []
## Entrée de la pile dont on choisit les cibles ou qui, en cours de résolution, attend un choix
## (décision 0057) ; NO_ID sinon.
var subject_stack_entry_id: int = DuelState.NO_ID
## Identifiants parmi lesquels répondre : effets déclenchés à ordonner, pièces et Spells de
## la pile ciblables (selon la cible de l'effet), cartes de la main à défausser (CHOOSE_DISCARD) ou
## carte du dessus du deck regardée (CHOOSE_TOP_CARD_PLACE).
var candidate_ids: Array[int] = []
## Cases parmi lesquelles répondre, quand le choix porte sur une case (202.4.12a).
var candidate_cells: Array[Vector2i] = []
## 212.1.7 : nombre de cartes à choisir pour CHOOSE_DISCARD, le plus petit de `amount` et de la
## taille de la main ; 0 sinon.
var required_count: int = 0
## Décision 0013 : cartes à écarter déjà choisies, tous joueurs confondus ; chaque carte est
## dans la main de son joueur. Choix cachés : ni la vue ni l'IA ne les lisent (204.2.3).
var set_aside_card_ids: Array[int] = []


## Décision 0009 : raison du refus d'une réponse de `player` à une attente de genre `kind`, ou
## NONE ; `decision` vaut null hors attente. Pur.
static func validate_answer(
	decision: PendingDecision, expected_kind: DecisionKind, player: DuelState.PlayerSide
) -> IntentRejected.RejectReason:
	if decision == null or decision.kind != expected_kind:
		return IntentRejected.RejectReason.NOT_THE_PENDING_DECISION
	if not decision.awaited_players.has(player):
		return IntentRejected.RejectReason.PLAYER_NOT_AWAITED
	return IntentRejected.RejectReason.NONE


## Décision 0057 : attente d'un choix pendant la résolution de `entry` (212.1.3, 217.1.2), du
## genre `choice_kind`, que fait seul le joueur à qui l'entrée appartient ; `choice_candidate_ids`
## sont les cartes parmi lesquelles il répond.
static func for_resolution(
	choice_kind: DecisionKind, entry: StackEntry, choice_candidate_ids: Array[int]
) -> PendingDecision:
	var decision := PendingDecision.new()
	decision.kind = choice_kind
	decision.awaited_players.append(entry.owner)
	decision.subject_stack_entry_id = entry.stack_entry_id
	decision.candidate_ids.assign(choice_candidate_ids)
	return decision


func clone() -> PendingDecision:
	var copy := PendingDecision.new()
	copy.kind = kind
	copy.awaited_players.assign(awaited_players)
	copy.subject_stack_entry_id = subject_stack_entry_id
	copy.required_count = required_count
	copy.candidate_ids.assign(candidate_ids)
	copy.candidate_cells.assign(candidate_cells)
	copy.set_aside_card_ids.assign(set_aside_card_ids)
	return copy
