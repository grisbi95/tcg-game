class_name DecisionResolvedAutomatically
extends PlayerEvent
## Décision 0004 : un seul choix était légal pour le joueur ; le moteur l'a pris sans demander.

var kind: PendingDecision.DecisionKind = PendingDecision.DecisionKind.ORDER_TRIGGERS


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A,
	decision_kind: PendingDecision.DecisionKind = PendingDecision.DecisionKind.ORDER_TRIGGERS
) -> void:
	super(concerned_player)
	kind = decision_kind
