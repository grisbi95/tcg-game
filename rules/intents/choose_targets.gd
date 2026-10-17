class_name ChooseTargets
extends DuelIntent
## 207.5.1b, 207.5.2, décision 0017 : le joueur à qui appartient l'effet déclenché en cours
## d'ajout choisit ses cibles. Répond à l'attente CHOOSE_TARGETS ; les cibles se renseignent
## après la construction.

## 207.5.11 : pièces ciblées.
var target_piece_ids: Array[int] = []
## 202.4.12 : cases ciblées.
var target_cells: Array[Vector2i] = []
## 207.5.14 : Spells de la pile ciblés.
var target_stack_entry_ids: Array[int] = []
