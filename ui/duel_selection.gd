class_name DuelSelection
extends RefCounted
## Sélection d'un joueur à l'écran (décisions 0023, 0024 et 0031) : machine à états qui traduit ses
## gestes en intentions, pas à pas, et n'émet que celles que DuelEngine.validate() accepte ;
## `snapshot()` dit aux vues quoi surligner.
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
	TARGET_PENDING,  # Spell, Gear ou pouvoir du Hero choisi, en attente de sa cible
}

## Ce qu'annonce la sélection en TARGET_PENDING.
enum AnnouncementSubject {
	CARD,  # Spell ou Gear de la main
	HERO_POWER,  # 202.3.13
}

const DECISION := PendingDecision.DecisionKind

var _engine: DuelEngine
var _side: DuelState.PlayerSide = DuelState.PlayerSide.A
var _selection_state: SelectionState = SelectionState.IDLE
var _subject: AnnouncementSubject = AnnouncementSubject.CARD
var _card_id: int = DuelState.NO_ID
var _piece_id: int = DuelState.NO_ID
## Décision 0023 : paiement préparé pendant le tour adverse ; vide pendant son tour.
var _draft_payment: EssencePayment = EssencePayment.new()
## 204.2.4 : cartes à écarter, pendant le mulligan.
var _set_aside_card_ids: Array[int] = []
## 208.4.6 : effets déclenchés dans l'ordre choisi, pendant ORDER_TRIGGERS.
var _ordered_entry_ids: Array[int] = []


## `engine` est lu, jamais modifié ; `side` est le joueur devant l'écran.
func setup(engine: DuelEngine, side: DuelState.PlayerSide) -> void:
	_engine = engine
	_side = side
	reset()


## Le joueur devant l'écran change (relais, décision 0020).
func set_player(side: DuelState.PlayerSide) -> void:
	_side = side
	reset()


## Abandonne la sélection en cours et le paiement préparé, par exemple après des événements.
func reset() -> void:
	_enter(SelectionState.IDLE, DuelState.NO_ID, DuelState.NO_ID)
	_draft_payment = EssencePayment.new()
	_set_aside_card_ids.clear()
	_ordered_entry_ids.clear()
	selection_changed.emit()


func press_card(card_id: int) -> void:
	if _is_awaiting(DECISION.MULLIGAN):
		_toggle_set_aside(card_id)
	elif _has_pending_decision():
		return
	elif card_id == _card_id and _selection_state != SelectionState.IDLE:
		reset()
	elif _player().find_card_in_hand(card_id) != null:
		if _is_answering() and _candidates().is_card_playable(card_id):
			response_started.emit()
		_choose_card(card_id)


func press_piece(piece_id: int) -> void:
	var target := SelectionTarget.of_piece(piece_id)
	if _is_awaiting(DECISION.CHOOSE_TARGETS):
		_emit_if_legal(_candidates().targets_answer(target))
	elif _selection_state == SelectionState.TARGET_PENDING:
		_choose_target(target)
	elif piece_id == _piece_id:
		reset()
	elif not _has_pending_decision() and not _candidates().move_cells(piece_id).is_empty():
		_enter(SelectionState.PIECE_CHOSEN, DuelState.NO_ID, piece_id)


## Décision 0030 : un clic sur une pièce est un geste sur sa case. La case compte d'abord quand la
## sélection la propose (déploiement, action normale, cible) ; sinon, sa pièce.
func press_cell(cell: Vector2i) -> void:
	var piece := _engine.get_state().piece_at(cell)
	if piece != null and not snapshot().legal_cells.has(cell):
		press_piece(piece.piece_id)
		return
	if _is_awaiting(DECISION.CHOOSE_TARGETS):
		_emit_if_legal(_candidates().targets_answer(SelectionTarget.of_cell(cell)))
		return
	match _selection_state:
		SelectionState.CARD_CHOSEN:
			_emit_if_legal(_candidates().deploy(_card_id, cell))
		SelectionState.PIECE_CHOSEN:
			_emit_if_legal(_candidates().normal_action(_piece_id, cell))
		SelectionState.TARGET_PENDING:
			_choose_target(SelectionTarget.of_cell(cell))


func press_stack_entry(stack_entry_id: int) -> void:
	var target := SelectionTarget.of_stack_entry(stack_entry_id)
	if _is_awaiting(DECISION.ORDER_TRIGGERS):
		_add_to_order(stack_entry_id)
	elif _is_awaiting(DECISION.CHOOSE_TARGETS):
		_emit_if_legal(_candidates().targets_answer(target))
	elif _selection_state == SelectionState.TARGET_PENDING:
		_choose_target(target)


## Décision 0023 : `is_tilted` dit si la Source pressée est inclinée (elle se recycle) ou
## redressée (elle s'incline).
func press_source(is_tilted: bool) -> void:
	if _is_answering():
		response_started.emit()
	var produced := EssencePayment.new(0, 1) if is_tilted else EssencePayment.new(1, 0)
	if _is_own_turn():
		_emit_if_legal(ProduceEssence.new(_side, produced))
	elif (_shown_tilted_sources() if is_tilted else _shown_upright_sources()) > 0:
		_draft_payment.incline_count += produced.incline_count
		_draft_payment.recycle_count += produced.recycle_count
		selection_changed.emit()


func press_hero_power() -> void:
	if _has_pending_decision():
		return
	if _is_hero_power_chosen():
		reset()
	else:
		_choose_announcement(AnnouncementSubject.HERO_POWER, DuelState.NO_ID)


func press_pass() -> void:
	_emit_if_legal(PassPriority.new(_side))


func press_end_turn() -> void:
	_emit_if_legal(EndTurn.new(_side))


## Décision 0031 : seul le mulligan se confirme ; une annonce part dès qu'elle est complète.
func press_confirm() -> void:
	if _is_awaiting(DECISION.MULLIGAN):
		_emit_if_legal(ChooseMulligan.new(_side, _set_aside_card_ids.duplicate()))


func press_cancel() -> void:
	reset()


## Ce que les vues montrent maintenant.
func snapshot() -> SelectionSnapshot:
	var candidates := _candidates()
	var shown := SelectionSnapshot.new()
	shown.selection_state = _selection_state
	shown.chosen_card_id = _card_id
	shown.chosen_piece_id = _piece_id
	shown.playable_card_ids = _playable_card_ids(candidates)
	shown.set_aside_card_ids = _set_aside_card_ids.duplicate()
	shown.ordered_entry_ids = _ordered_entry_ids.duplicate()
	_fill_board_highlights(shown, candidates)
	shown.draft_payment = _copy_draft()
	shown.shown_upright_sources = _shown_upright_sources()
	shown.shown_tilted_sources = _shown_tilted_sources()
	shown.can_pass = candidates.is_legal(PassPriority.new(_side))
	shown.can_end_turn = candidates.is_legal(EndTurn.new(_side))
	shown.can_confirm = _can_confirm(candidates)
	shown.can_use_hero_power = (
		_selection_state == SelectionState.IDLE
		and not _has_pending_decision()
		and candidates.is_hero_power_possible()
	)
	shown.is_hero_power_chosen = _is_hero_power_chosen()
	shown.is_drafting_payment = not _is_own_turn()
	return shown


func _choose_card(card_id: int) -> void:
	if _candidates().is_announced_card(card_id):
		_choose_announcement(AnnouncementSubject.CARD, card_id)
	elif _candidates().is_card_playable(card_id):
		_enter(SelectionState.CARD_CHOSEN, card_id, DuelState.NO_ID)


# Décision 0031 : une annonce sans cible part aussitôt ; avec cible, elle attend sa cible.
func _choose_announcement(subject: AnnouncementSubject, card_id: int) -> void:
	_subject = subject
	_card_id = card_id
	var candidates := _candidates()
	var untargeted := _announcement(candidates, SelectionTarget.new())
	if candidates.is_legal(untargeted):
		_emit_if_legal(untargeted)
	elif not _announcement_targets(candidates).is_empty():
		_enter(SelectionState.TARGET_PENDING, card_id, DuelState.NO_ID)


# Décision 0031 : l'annonce part dès que sa cible est choisie.
func _choose_target(target: SelectionTarget) -> void:
	_emit_if_legal(_announcement(_candidates(), target))


func _toggle_set_aside(card_id: int) -> void:
	if _set_aside_card_ids.has(card_id):
		_set_aside_card_ids.erase(card_id)
	elif _player().find_card_in_hand(card_id) != null:
		_set_aside_card_ids.append(card_id)
	selection_changed.emit()


func _add_to_order(stack_entry_id: int) -> void:
	var candidate_ids := _engine.get_state().pending_decision.candidate_ids
	if not candidate_ids.has(stack_entry_id) or _ordered_entry_ids.has(stack_entry_id):
		return
	_ordered_entry_ids.append(stack_entry_id)
	selection_changed.emit()
	if _ordered_entry_ids.size() == candidate_ids.size():
		_emit_if_legal(OrderTriggers.new(_side, _ordered_entry_ids))


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
		if _is_awaiting(DECISION.MULLIGAN):
			card_ids.append(card_id)
		elif not _has_pending_decision() and candidates.is_card_playable(card_id):
			card_ids.append(card_id)
	return card_ids


func _fill_board_highlights(shown: SelectionSnapshot, candidates: SelectionCandidates) -> void:
	if _is_awaiting(DECISION.CHOOSE_TARGETS):
		_show_targets(shown, candidates.decision_targets())
	elif _selection_state == SelectionState.TARGET_PENDING:
		_show_targets(shown, _announcement_targets(candidates))
	elif _is_awaiting(DECISION.ORDER_TRIGGERS):
		for entry_id: int in _engine.get_state().pending_decision.candidate_ids:
			if not _ordered_entry_ids.has(entry_id):
				shown.legal_stack_entry_ids.append(entry_id)
	elif _selection_state == SelectionState.CARD_CHOSEN:
		shown.legal_cells = candidates.deploy_cells(_card_id)
	elif _selection_state == SelectionState.PIECE_CHOSEN:
		shown.legal_cells = candidates.move_cells(_piece_id)
	elif not _has_pending_decision():
		for piece: Piece in _engine.get_state().pieces:
			if not candidates.move_cells(piece.piece_id).is_empty():
				shown.legal_piece_ids.append(piece.piece_id)


func _show_targets(shown: SelectionSnapshot, targets: Array[SelectionTarget]) -> void:
	for target: SelectionTarget in targets:
		shown.legal_piece_ids.append_array(target.piece_ids)
		shown.legal_cells.append_array(target.cells)
		shown.legal_stack_entry_ids.append_array(target.stack_entry_ids)


func _announcement(candidates: SelectionCandidates, target: SelectionTarget) -> DuelIntent:
	match _subject:
		AnnouncementSubject.HERO_POWER:
			return candidates.hero_power_announcement(target)
		_:
			return candidates.card_announcement(_card_id, target)


func _announcement_targets(candidates: SelectionCandidates) -> Array[SelectionTarget]:
	match _subject:
		AnnouncementSubject.HERO_POWER:
			return candidates.hero_power_targets()
		_:
			return candidates.card_targets(_card_id)


func _can_confirm(candidates: SelectionCandidates) -> bool:
	if not _is_awaiting(DECISION.MULLIGAN):
		return false
	return candidates.is_legal(ChooseMulligan.new(_side, _set_aside_card_ids.duplicate()))


# Décision 0023 : pendant son tour, le coût est pris dans la réserve d'Essence.
func _candidates() -> SelectionCandidates:
	var payment := EssencePayment.new() if _is_own_turn() else _copy_draft()
	return SelectionCandidates.new(_engine, _side, payment)


# 203.2.1, 203.2.2 : le moteur dit ce que le paiement préparé laisse de Sources.
func _shown_upright_sources() -> int:
	return _engine.upright_sources_after_payment(_side, _draft_payment)


func _shown_tilted_sources() -> int:
	return _engine.tilted_sources_after_payment(_side, _draft_payment)


func _copy_draft() -> EssencePayment:
	return EssencePayment.new(_draft_payment.incline_count, _draft_payment.recycle_count)


func _is_hero_power_chosen() -> bool:
	return (
		_selection_state == SelectionState.TARGET_PENDING
		and _subject == AnnouncementSubject.HERO_POWER
	)


func _is_own_turn() -> bool:
	return _engine.get_state().active_player == _side


# 208.6.1 : le moteur accepterait que le joueur passe.
func _is_answering() -> bool:
	return _candidates().is_legal(PassPriority.new(_side))


func _has_pending_decision() -> bool:
	return _engine.get_state().pending_decision != null


func _is_awaiting(kind: PendingDecision.DecisionKind) -> bool:
	var decision := _engine.get_state().pending_decision
	return decision != null and decision.kind == kind and decision.awaited_players.has(_side)


func _player() -> PlayerState:
	return _engine.get_state().get_player(_side)
