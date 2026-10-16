class_name IntentRejected
extends DuelEvent
## Refus d'une intention illégale : unique événement renvoyé, état inchangé (décision 0001).

## Raison du refus ; NONE signifie qu'une intention est légale.
## Enum journalisable : ajouter les valeurs à la fin, sans réordonner, commentées par leur
## identifiant de règle.
enum RejectReason {
	NONE,
	DUEL_NOT_STARTED,  # aucune intention avant le démarrage du duel
	WRONG_PHASE,  # 204.4.1 : intention hors de la période où elle est permise
	NOT_YOUR_TURN,  # 204.4.2 : intention réservée au joueur actif
	DECISION_PENDING,  # 209.4.4 : un choix est attendu, une autre intention est refusée
	UNKNOWN_INTENT,  # classe d'intention que le moteur n'aiguille pas
	NEGATIVE_PAYMENT,  # 203.2.1, 203.2.2 : nombre de Sources négatif
	PAYMENT_DOES_NOT_MATCH_COST,  # 203.3.1, décision 0003 : Essence produite différente du coût
	NOT_ENOUGH_UPRIGHT_SOURCES,  # 203.2.1
	NOT_ENOUGH_TILTED_SOURCES,  # 203.2.2, 203.2.6, 203.2.7
	RECYCLE_LIMIT_REACHED,  # 203.4.2
	DUEL_ENDED,  # 209.2 : aucune intention après la fin du duel
	NOT_THE_PENDING_DECISION,  # décision 0009 : réponse à une attente absente ou d'un autre genre
	PLAYER_NOT_AWAITED,  # 204.2.1, décision 0013 : joueur non attendu ou ayant déjà répondu
	CARD_NOT_IN_HAND,  # 204.2.4 : carte écartée hors de la main du joueur
	DUPLICATE_CARD,  # décision 0013 : même carte citée deux fois
	STACK_NOT_EMPTY,  # 204.4.7 : terminer son tour exige une pile vide (convention 1.3)
}

## Intention refusée, telle que soumise ; null si le refus ne vient pas d'une intention.
var intent: DuelIntent
var reason: RejectReason = RejectReason.NONE


func _init(
	rejected_intent: DuelIntent = null, reject_reason: RejectReason = RejectReason.NONE
) -> void:
	intent = rejected_intent
	reason = reject_reason
