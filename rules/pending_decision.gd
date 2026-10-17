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
}

var kind: DecisionKind = DecisionKind.MULLIGAN
## Joueurs dont on attend une réponse ; les deux pour le mulligan simultané (204.2.2).
var awaited_players: Array[DuelState.PlayerSide] = []
## Entrée de la pile dont on choisit les cibles ; NO_ID sinon.
var subject_stack_entry_id: int = DuelState.NO_ID
## Identifiants parmi lesquels répondre : effets déclenchés à ordonner, ou pièces et Spells de
## la pile ciblables (selon la cible de l'effet).
var candidate_ids: Array[int] = []
## Cases parmi lesquelles répondre, quand le choix porte sur une case (202.4.12a).
var candidate_cells: Array[Vector2i] = []
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


func clone() -> PendingDecision:
	var copy := PendingDecision.new()
	copy.kind = kind
	copy.awaited_players.assign(awaited_players)
	copy.subject_stack_entry_id = subject_stack_entry_id
	copy.candidate_ids.assign(candidate_ids)
	copy.candidate_cells.assign(candidate_cells)
	copy.set_aside_card_ids.assign(set_aside_card_ids)
	return copy
