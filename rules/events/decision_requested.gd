class_name DecisionRequested
extends PlayerEvent
## Décisions 0009 et 0017 : le moteur attend un choix du joueur, décrit par
## `DuelState.pending_decision`.

var kind: PendingDecision.DecisionKind = PendingDecision.DecisionKind.ORDER_TRIGGERS


func _init(
	concerned_player: DuelState.PlayerSide = DuelState.PlayerSide.A,
	decision_kind: PendingDecision.DecisionKind = PendingDecision.DecisionKind.ORDER_TRIGGERS
) -> void:
	super(concerned_player)
	kind = decision_kind
