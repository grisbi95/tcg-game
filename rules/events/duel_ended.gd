class_name DuelEnded
extends DuelEvent
## 209.2.2, 209.2.7, 209.3.1 : la partie s'arrête aussitôt, avec son issue.

var result: DuelState.DuelResult = DuelState.DuelResult.NONE


func _init(duel_result: DuelState.DuelResult = DuelState.DuelResult.NONE) -> void:
	result = duel_result
