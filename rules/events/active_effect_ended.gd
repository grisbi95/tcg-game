class_name ActiveEffectEnded
extends DuelEvent
## 204.5.7 : un effet qui durait jusqu'à la fin du tour prend fin.

var effect_id: int = DuelState.NO_ID


func _init(ended_effect_id: int = DuelState.NO_ID) -> void:
	effect_id = ended_effect_id
