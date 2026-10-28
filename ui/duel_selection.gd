class_name DuelSelection
extends RefCounted
## Sélection d'un joueur à l'écran (décisions 0023, 0024 et 0031) : machine à états qui traduit ses
## gestes en intentions, pas à pas, et n'émet que celles que DuelEngine.validate() accepte ;
## `snapshot()` dit aux vues quoi surligner.
##
## Les annonces en plusieurs temps (X, plusieurs cibles, Ordre du Hero) sont déléguées à
## `AnnouncementAssistant` (décision 0068) ; cet objet garde les autres gestes.
##
## Aucune règle ici et aucun état qui fait foi : la sélection lit le moteur sans le modifier, et
## l'écran transmet les intentions émises à DuelHost. Pendant son tour, un clic sur une Source
## produit de l'Essence ; pendant le tour adverse, il prépare le paiement de la réponse (0023).

signal intent_chosen(intent: DuelIntent)
signal selection_changed
## 208.6.2, décision 0042 : le joueur qui peut répondre ou passer a choisi une carte ou pressé
## une Source ; l'écran le transmet à DuelHost, qui le note au journal pour le relevé.
signal response_started

## Enum journalisable : ajouter à la fin, sans réordonner.
enum SelectionState {
	IDLE,
	CARD_CHOSEN,  # Unit ou Building choisi, en attente de sa case
	PIECE_CHOSEN,  # pièce choisie, en attente de la case de son action normale
	TARGET_PENDING,  # annonce commencée (Spell, Gear, Ordre), en attente de son X ou de sa cible
}

const DECISION := PendingDecision.DecisionKind

var _engine: DuelEngine
var _side: DuelState.PlayerSide = DuelState.PlayerSide.A
var _selection_state: SelectionState = SelectionState.IDLE
var _card_id: int = DuelState.NO_ID
var _piece_id: int = DuelState.NO_ID
## Décision 0023 : paiement préparé pendant le tour adverse ; vide pendant son tour.
var _draft: SelectionDraft = SelectionDraft.new()
## 204.2.4, 212.1.3, 208.4.6 : cartes à écarter ou à défausser, effets déclenchés rangés.
var _picks: SelectionPicks = SelectionPicks.new()
## Décision 0068 : assistant de l'annonce commencée, ou de la réponse à CHOOSE_TARGETS ; null sinon.
var _assistant: AnnouncementAssistant


## `engine` est lu, jamais modifié ; `side` est le joueur devant l'écran.
func setup(engine: DuelEngine, side: DuelState.PlayerSide) -> void:
	_engine = engine
	_side = side
	_draft.setup(engine, side)
	reset()


## Le joueur devant l'écran change (relais, décision 0020).
func set_player(side: DuelState.PlayerSide) -> void:
	_side = side
	_draft.setup(_engine, side)
	reset()


## Abandonne la sélection en cours et le paiement préparé, par exemple après des événements.
func reset() -> void:
	_draft.clear()
	_picks.clear()
	_assistant = null
	_ensure_answer_assistant()
	_enter(SelectionState.IDLE, DuelState.NO_ID, DuelState.NO_ID)


## Recale la sélection sur l'état du moteur : abandonne l'annonce que l'expiration du temps a
## défaite (209.4.11, 211.2.2a) et prépare la réponse à CHOOSE_TARGETS. Appelé par les gestes et
## par l'écran après des événements ; `snapshot()` reste une lecture.
func resync() -> void:
	if _assistant != null and _assistant.is_stale():
		_clear_announcement()
	_ensure_answer_assistant()


func press_card(card_id: int) -> void:
	resync()
	if _is_awaiting(DECISION.MULLIGAN):
		_toggle_card(card_id)
	elif _is_awaiting(DECISION.CHOOSE_DISCARD):
		_toggle_discard(card_id)
	elif _has_pending_decision():
		return
	elif card_id == _card_id and _selection_state != SelectionState.IDLE:
		reset()
	elif _player().find_card_in_hand(card_id) != null:
		if _is_answering() and _candidates().is_card_playable(card_id):
			response_started.emit()
		_choose_card(card_id)


func press_piece(piece_id: int) -> void:
	resync()
	var target := SelectionTarget.of_piece(piece_id)
	if _is_awaiting(DECISION.CHOOSE_TARGETS):
		_choose_answer_target(target)
	elif _assistant != null and _assistant.is_candidate(target):
		_choose_target(target)
	elif piece_id == _piece_id:
		reset()
	elif _selection_state == SelectionState.TARGET_PENDING or _has_pending_decision():
		return
	elif _candidates().has_piece_gesture(piece_id):
		_enter(SelectionState.PIECE_CHOSEN, DuelState.NO_ID, piece_id)


## Décision 0030 : un clic sur une pièce est un geste sur sa case. La case compte d'abord quand la
## sélection la propose (déploiement, action normale, cible) ; sinon, sa pièce.
func press_cell(cell: Vector2i) -> void:
	resync()
	var piece := _engine.get_state().piece_at(cell)
	if piece != null and not _board_highlights().legal_cells.has(cell):
		press_piece(piece.piece_id)
		return
	var target := SelectionTarget.of_cell(cell)
	if _is_awaiting(DECISION.CHOOSE_TARGETS):
		_choose_answer_target(target)
		return
	match _selection_state:
		SelectionState.CARD_CHOSEN:
			_emit_if_legal(_candidates().deploy(_card_id, cell))
		SelectionState.PIECE_CHOSEN:
			_emit_if_legal(_candidates().normal_action(_piece_id, cell))
		SelectionState.TARGET_PENDING:
			if _assistant != null and _assistant.is_candidate(target):
				_choose_target(target)


func press_stack_entry(stack_entry_id: int) -> void:
	resync()
	var target := SelectionTarget.of_stack_entry(stack_entry_id)
	if _is_awaiting(DECISION.ORDER_TRIGGERS):
		_add_to_order(stack_entry_id)
	elif _is_awaiting(DECISION.CHOOSE_TARGETS):
		_choose_answer_target(target)
	elif _assistant != null and _assistant.is_candidate(target):
		_choose_target(target)


## Décision 0023 : `is_tilted` dit si la Source pressée est inclinée (elle se recycle) ou
## redressée (elle s'incline).
func press_source(is_tilted: bool) -> void:
	if _is_answering():
		response_started.emit()
	var produced := EssencePayment.new(0, 1) if is_tilted else EssencePayment.new(1, 0)
	if _is_own_turn():
		_emit_if_legal(ProduceEssence.new(_side, produced))
	elif _draft.add_source(is_tilted):
		selection_changed.emit()


func press_pass() -> void:
	_emit_if_legal(PassPriority.new(_side))


func press_end_turn() -> void:
	_emit_if_legal(EndTurn.new(_side))


## Décision 0031 : seul le mulligan se confirme ; une annonce part dès qu'elle est complète.
func press_confirm() -> void:
	if _is_awaiting(DECISION.MULLIGAN):
		_emit_if_legal(ChooseMulligan.new(_side, _picks.card_ids()))


func press_cancel() -> void:
	reset()


## Décision 0068 : le choix de X recule d'une valeur que le moteur accepte.
func press_x_decrease() -> void:
	if _assistant != null:
		_assistant.decrease_x()
		selection_changed.emit()


func press_x_increase() -> void:
	if _assistant != null:
		_assistant.increase_x()
		selection_changed.emit()


## Décision 0068 : annonce sans cible dont X est choisi ; elle part si le moteur l'accepte.
func press_x_confirm() -> void:
	if _assistant != null:
		var intent := _assistant.confirm_x()
		if intent != null:
			_emit_if_legal(intent)


## Décision 0068 : le bouton `index` de `SelectionSnapshot.choice_values` ; un Ordre du Hero choisi
## (211) ou la place de la carte regardée (217.1.2, 217.1.3).
func press_choice(index: int) -> void:
	resync()
	var values := _candidates().choice_values(_chosen_hero_id())
	if index < 0 or index >= values.size():
		return
	if _is_awaiting(DECISION.CHOOSE_TOP_CARD_PLACE):
		var place := values[index] as ChooseTopCardPlace.TopCardPlace
		_emit_if_legal(ChooseTopCardPlace.new(_side, place))
	elif _selection_state == SelectionState.PIECE_CHOSEN:
		if _is_answering():
			response_started.emit()
		_begin_assistant(_candidates().order_assistant(values[index]), DuelState.NO_ID, _piece_id)


## Ce que les vues montrent maintenant.
func snapshot() -> SelectionSnapshot:
	var candidates := _candidates()
	var shown := SelectionSnapshot.new()
	shown.selection_state = _selection_state
	shown.chosen_card_id = _card_id
	shown.chosen_piece_id = _piece_id
	shown.playable_card_ids = _playable_card_ids(candidates)
	shown.picked_card_ids = _picks.card_ids()
	shown.ordered_entry_ids = _picks.entry_ids()
	_fill_board_highlights(shown, candidates)
	shown.draft_payment = _draft.payment()
	shown.shown_upright_sources = _draft.shown_upright_sources()
	shown.shown_tilted_sources = _draft.shown_tilted_sources()
	shown.shown_fonte_sources = _draft.shown_fonte_sources()
	shown.can_pass = candidates.is_legal(PassPriority.new(_side))
	shown.can_end_turn = candidates.is_legal(EndTurn.new(_side))
	shown.can_confirm = _can_confirm(candidates)
	shown.is_drafting_payment = not _is_own_turn()
	if _assistant != null:
		shown.show_announcement(_assistant, _selection_state == SelectionState.TARGET_PENDING)
	shown.show_choice(candidates, _chosen_hero_id())
	return shown


func _choose_card(card_id: int) -> void:
	if _candidates().is_announced_card(card_id):
		_begin_assistant(_candidates().card_assistant(card_id), card_id, DuelState.NO_ID)
	elif _candidates().is_card_playable(card_id):
		_enter(SelectionState.CARD_CHOSEN, card_id, DuelState.NO_ID)


# Décisions 0031 et 0068 : une annonce sans X ni cible part aussitôt ; sinon l'assistant demande
# ce qui manque, et l'intention part dès qu'elle est complète.
func _begin_assistant(assistant: AnnouncementAssistant, card_id: int, piece_id: int) -> void:
	_clear_announcement()
	var complete := assistant.start()
	if complete != null:
		_emit_if_legal(complete)
	elif assistant.get_step() != AnnouncementAssistant.Step.NONE:
		_assistant = assistant
		_enter(SelectionState.TARGET_PENDING, card_id, piece_id)


func _choose_target(target: SelectionTarget) -> void:
	var intent := _assistant.choose(target)
	if intent != null:
		_emit_if_legal(intent)
	elif _assistant.get_step() == AnnouncementAssistant.Step.NONE:
		reset()
	else:
		selection_changed.emit()


func _choose_answer_target(target: SelectionTarget) -> void:
	if _assistant != null and _assistant.is_candidate(target):
		_choose_target(target)


# CHOOSE_TARGETS : l'assistant sert aussi à répondre, sans « annonce » à commencer.
func _ensure_answer_assistant() -> void:
	if _assistant != null or _engine == null or not _is_awaiting(DECISION.CHOOSE_TARGETS):
		return
	var assistant := _candidates().answer_assistant()
	assistant.start()
	if assistant.get_step() != AnnouncementAssistant.Step.NONE:
		_assistant = assistant


func _clear_announcement() -> void:
	_assistant = null
	_enter(SelectionState.IDLE, DuelState.NO_ID, DuelState.NO_ID)


# 212.1.3 : les cartes à défausser se cliquent dans la main ; le choix part quand le moteur
# l'accepte, au nombre demandé.
func _toggle_discard(card_id: int) -> void:
	_toggle_card(card_id)
	_emit_if_legal(ChooseDiscard.new(_side, _picks.card_ids()))


func _toggle_card(card_id: int) -> void:
	_picks.toggle_card(card_id, _player())
	selection_changed.emit()


func _add_to_order(stack_entry_id: int) -> void:
	var candidate_ids := _engine.get_state().pending_decision.candidate_ids
	if not _picks.add_entry(stack_entry_id, candidate_ids):
		return
	selection_changed.emit()
	if _picks.is_ordering_complete(candidate_ids):
		_emit_if_legal(OrderTriggers.new(_side, _picks.entry_ids()))


func _enter(selection_state: SelectionState, card_id: int, piece_id: int) -> void:
	_selection_state = selection_state
	_card_id = card_id
	_piece_id = piece_id
	selection_changed.emit()


# L'intention est émise après le retour à IDLE ; le paiement préparé ne sert qu'une fois.
func _emit_if_legal(intent: DuelIntent) -> void:
	if not _candidates().is_legal(intent):
		return
	reset()
	intent_chosen.emit(intent)


# Une sélection en cours éteint les marques « jouable » : seul ce qui est choisi reste marqué.
func _playable_card_ids(candidates: SelectionCandidates) -> Array[int]:
	var card_ids: Array[int] = []
	if _selection_state != SelectionState.IDLE:
		return card_ids
	for card: CardInstance in _player().hand:
		var card_id := card.card_instance_id
		if _is_awaiting(DECISION.MULLIGAN) or _is_awaiting(DECISION.CHOOSE_DISCARD):
			card_ids.append(card_id)
		elif not _has_pending_decision() and candidates.is_card_playable(card_id):
			card_ids.append(card_id)
	return card_ids


func _fill_board_highlights(shown: SelectionSnapshot, candidates: SelectionCandidates) -> void:
	if _assistant != null:
		shown.show_targets(_assistant.get_candidates())
	elif _is_awaiting(DECISION.ORDER_TRIGGERS):
		for entry_id: int in _engine.get_state().pending_decision.candidate_ids:
			if not _picks.has_entry(entry_id):
				shown.legal_stack_entry_ids.append(entry_id)
	elif _selection_state == SelectionState.CARD_CHOSEN:
		shown.legal_cells = candidates.deploy_cells(_card_id)
	elif _selection_state == SelectionState.PIECE_CHOSEN:
		shown.legal_cells = candidates.move_cells(_piece_id)
	elif not _has_pending_decision():
		for piece: Piece in _engine.get_state().pieces:
			if candidates.has_piece_gesture(piece.piece_id):
				shown.legal_piece_ids.append(piece.piece_id)


func _board_highlights() -> SelectionSnapshot:
	var shown := SelectionSnapshot.new()
	_fill_board_highlights(shown, _candidates())
	return shown


# Le Hero dont on choisit l'Ordre, sinon NO_ID.
func _chosen_hero_id() -> int:
	return _piece_id if _selection_state == SelectionState.PIECE_CHOSEN else DuelState.NO_ID


func _can_confirm(candidates: SelectionCandidates) -> bool:
	if not _is_awaiting(DECISION.MULLIGAN):
		return false
	return candidates.is_legal(ChooseMulligan.new(_side, _picks.card_ids()))


# Décision 0023 : pendant son tour, le coût est pris dans la réserve d'Essence.
func _candidates() -> SelectionCandidates:
	var payment := EssencePayment.new() if _is_own_turn() else _draft.payment()
	return SelectionCandidates.new(_engine, _side, payment)


func _is_own_turn() -> bool:
	return _engine.get_state().active_player == _side


func _is_answering() -> bool:
	return _candidates().is_legal(PassPriority.new(_side))


func _has_pending_decision() -> bool:
	return _engine.get_state().pending_decision != null


func _is_awaiting(kind: PendingDecision.DecisionKind) -> bool:
	var decision := _engine.get_state().pending_decision
	return decision != null and decision.kind == kind and decision.awaited_players.has(_side)


func _player() -> PlayerState:
	return _engine.get_state().get_player(_side)
