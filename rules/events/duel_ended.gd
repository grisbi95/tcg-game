class_name DuelEnded
extends DuelEvent
## 209.2.2, 209.2.7, 209.2.9, 209.3.1, 209.5.3 : la partie s'arrête aussitôt, avec son issue et
## la raison de l'arrêt (décision 0040).

var result: DuelState.DuelResult = DuelState.DuelResult.NONE
var reason: DuelState.EndReason = DuelState.EndReason.NONE


func _init(
	duel_result: DuelState.DuelResult = DuelState.DuelResult.NONE,
	end_reason: DuelState.EndReason = DuelState.EndReason.NONE
) -> void:
	result = duel_result
	reason = end_reason
