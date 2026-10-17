class_name OrderTriggers
extends DuelIntent
## 208.4.6, 208.4.7, décision 0017 : le joueur attendu donne l'ordre d'ajout à la pile de ses
## effets déclenchés, le premier ajouté en tête. Répond à l'attente ORDER_TRIGGERS.

## Chaque effet attendu (`PendingDecision.candidate_ids`), une fois chacun.
var ordered_stack_entry_ids: Array[int] = []


func _init(
	author: DuelState.PlayerSide = DuelState.PlayerSide.A, entry_ids: Array[int] = []
) -> void:
	super(author)
	ordered_stack_entry_ids.assign(entry_ids)
