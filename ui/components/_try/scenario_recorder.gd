class_name ScenarioRecorder
extends RefCounted
## Outil de développement : joue un duel à blanc par les gestes d'un joueur, comme le ferait
## l'écran, et garde les intentions que `DuelSelection` a émises (donc que `validate()` a
## acceptées). Aucune règle ici : chaque geste est tenté, et il est réussi ou non selon le moteur.
## Les intentions gardées rejouent le même duel (même graine, même configuration) sur l'écran.

const MAX_STACK_PASSES: int = 12
const MAX_ESSENCE_PER_CARD: int = 10

var _engine: DuelEngine
var _selection: DuelSelection = DuelSelection.new()
var _intents: Array[DuelIntent] = []


## `engine` a déjà démarré son duel ; il sert de terrain à blanc.
func _init(engine: DuelEngine) -> void:
	_engine = engine
	_selection.setup(engine, DuelState.PlayerSide.A)
	_selection.intent_chosen.connect(_record)


## Intentions acceptées jusqu'ici, dans l'ordre.
func get_intents() -> Array[DuelIntent]:
	return _intents


func state() -> DuelState:
	return _engine.get_state()


## Les deux joueurs gardent leur main, A puis B.
func confirm_mulligans() -> bool:
	var is_done := true
	for side: DuelState.PlayerSide in DuelState.SIDES:
		_selection.set_player(side)
		is_done = _try(_selection.press_confirm) and is_done
	return is_done


## Les joueurs passent tour à tour jusqu'à la résolution de la pile, ou jusqu'à un choix attendu du
## moteur.
func resolve_stack() -> bool:
	for _pass_index: int in MAX_STACK_PASSES:
		if state().stack.is_empty() or state().pending_decision != null:
			return true
		_selection.set_player(state().priority_player)
		if not _try(_selection.press_pass):
			return false
	return state().stack.is_empty()


## Termine le tour de `side`.
func end_turn(side: DuelState.PlayerSide) -> bool:
	_selection.set_player(side)
	return _try(_selection.press_end_turn)


## `side` abandonne.
func concede(side: DuelState.PlayerSide) -> bool:
	var intent := Concede.new(side)
	if _engine.validate(intent) != IntentRejected.RejectReason.NONE:
		return false
	_record(intent)
	return true


## `side` produit `count` Essence en inclinant ses Sources redressées.
func produce_essence(side: DuelState.PlayerSide, count: int) -> bool:
	_selection.set_player(side)
	for _index: int in count:
		if not _try(_selection.press_source.bind(false)):
			return false
	return true


## `side` déploie sa carte `definition_id` sur la première case que le moteur propose, après avoir
## produit l'Essence qu'il faut.
func deploy(side: DuelState.PlayerSide, definition_id: StringName) -> bool:
	var card_id := _prepare_card(side, definition_id)
	if card_id == DuelState.NO_ID:
		return false
	_selection.press_card(card_id)
	var cells := _selection.snapshot().legal_cells
	if cells.is_empty():
		return false
	return _try(_selection.press_cell.bind(cells[0]))


## `side` annonce sa carte `definition_id` (Spell ou Gear) sur la première cible que le moteur
## propose.
func announce(side: DuelState.PlayerSide, definition_id: StringName) -> bool:
	var card_id := _prepare_card(side, definition_id)
	if card_id == DuelState.NO_ID:
		return false
	return _try(_press_card_then_target.bind(card_id))


# Produit de l'Essence, une à la fois, jusqu'à ce que la carte soit jouable ; rend son identifiant.
func _prepare_card(side: DuelState.PlayerSide, definition_id: StringName) -> int:
	_selection.set_player(side)
	var card_id := _find_in_hand(side, definition_id)
	for _index: int in MAX_ESSENCE_PER_CARD:
		if card_id == DuelState.NO_ID or _selection.snapshot().playable_card_ids.has(card_id):
			break
		_try(_selection.press_source.bind(false))
	return card_id


func _find_in_hand(side: DuelState.PlayerSide, definition_id: StringName) -> int:
	for card: CardInstance in state().get_player(side).hand:
		if card.definition_id == definition_id:
			return card.card_instance_id
	return DuelState.NO_ID


func _press_card_then_target(card_id: int) -> void:
	_selection.press_card(card_id)
	_press_first_target()


# La case de la première pièce ciblable, sinon la première case ciblable.
func _press_first_target() -> void:
	var shown := _selection.snapshot()
	if shown.selection_state != DuelSelection.SelectionState.TARGET_PENDING:
		return
	if not shown.legal_piece_ids.is_empty():
		var piece := state().find_piece(shown.legal_piece_ids[0])
		_selection.press_cell(piece.cell)
	elif not shown.legal_cells.is_empty():
		_selection.press_cell(shown.legal_cells[0])


# Vrai quand le geste a produit une intention.
func _try(gesture: Callable) -> bool:
	var count_before := _intents.size()
	gesture.call()
	return _intents.size() > count_before


func _record(intent: DuelIntent) -> void:
	_intents.append(intent)
	var events := _engine.submit(intent)
	if events.size() == 1 and events[0] is IntentRejected:
		push_error("ScenarioRecorder : intention refusée après validation")
