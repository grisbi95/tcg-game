class_name SelectionPicks
extends RefCounted
## Choix cliqués un à un par le joueur, en attendant qu'ils forment une réponse (décisions 0013,
## 0032 et 0068) : cartes à écarter (mulligan, 204.2.4) ou à défausser (212.1.3), et rangs donnés
## aux effets déclenchés (208.4.6). Aucune règle ici : `DuelSelection` fait juger la réponse par le
## moteur.

var _card_ids: Array[int] = []
var _entry_ids: Array[int] = []


func clear() -> void:
	_card_ids.clear()
	_entry_ids.clear()


## Cartes choisies, dans l'ordre des clics.
func card_ids() -> Array[int]:
	return _card_ids.duplicate()


## Effets déclenchés rangés, dans l'ordre des clics.
func entry_ids() -> Array[int]:
	return _entry_ids.duplicate()


func has_entry(stack_entry_id: int) -> bool:
	return _entry_ids.has(stack_entry_id)


## Un clic sur `card_id` : la carte est choisie, ou retirée du choix ; seule une carte de `hand` se
## choisit.
func toggle_card(card_id: int, player: PlayerState) -> void:
	if _card_ids.has(card_id):
		_card_ids.erase(card_id)
	elif player.find_card_in_hand(card_id) != null:
		_card_ids.append(card_id)


## Un clic sur l'effet `stack_entry_id`, parmi `candidate_ids` ; rend vrai s'il est rangé.
func add_entry(stack_entry_id: int, candidate_ids: Array[int]) -> bool:
	if not candidate_ids.has(stack_entry_id) or _entry_ids.has(stack_entry_id):
		return false
	_entry_ids.append(stack_entry_id)
	return true


## Chaque effet de `candidate_ids` est rangé.
func is_ordering_complete(candidate_ids: Array[int]) -> bool:
	return _entry_ids.size() == candidate_ids.size()
