class_name DuelCenterPresenter
extends RefCounted
## Centre de la colonne de duel et barres de temps (décisions 0021, 0029, 0032, 0045 et 0053) :
## choisit ce que la colonne montre d'après l'état du moteur, et relit à chaque image les temps,
## qui avancent au temps réel sans événement. Aucune règle ici.

var _column: DuelColumnView
var _timer_bars: Dictionary[DuelState.PlayerSide, TurnTimerBar] = {}
var _engine: DuelEngine
var _session: DuelSession
var _center_state: DuelColumnView.CenterState = DuelColumnView.CenterState.TURN


## `column` est la colonne pilotée ; `timer_bars` range par joueur les barres de temps (le parent
## échange les entrées pour le second écran, décision 0050) ; `session` donne l'état, le temps
## réel et la fenêtre de réponse.
func setup(
	column: DuelColumnView,
	timer_bars: Dictionary[DuelState.PlayerSide, TurnTimerBar],
	session: DuelSession
) -> void:
	_column = column
	_timer_bars = timer_bars
	_engine = session.get_engine()
	_session = session


## Recale le centre sur l'état du moteur, `model` pour la pile et `shown` pour les boutons.
func show_center(model: DuelViewModel, shown: SelectionSnapshot) -> void:
	var state := _engine.get_state()
	_center_state = DuelViewModel.center_state_of(state)
	_column.set_viewer(model.get_viewer())
	match _center_state:
		DuelColumnView.CenterState.TURN:
			_column.show_turn(state.turn_number, state.active_player, shown.can_end_turn)
		DuelColumnView.CenterState.STACK:
			var lines := model.stack_lines()
			_column.show_stack(
				lines, shown.legal_stack_entry_ids, state.priority_player, shown.can_pass
			)
			refresh_response_window()
		DuelColumnView.CenterState.MULLIGAN:
			_column.show_mulligan(model.get_viewer(), shown.can_confirm)
		DuelColumnView.CenterState.CHOICE:
			_show_choice(model, shown)
		DuelColumnView.CenterState.ENDED:
			_column.show_ended(DuelViewModel.result_text(state.result))
	_show_announcement(model, shown)


## Décision 0021 : les temps sont relus à chaque image sans événement ; une barre ne se redessine
## que si son affichage change. Chaque joueur voit le temps qui compte pour lui
## (`clock_kind`), et le joueur actif garde son temps de tour en pause tant que la pile n'est pas
## vide (209.4.8a).
func refresh_clocks() -> void:
	var state := _engine.get_state()
	var running_owners := _engine.clock_owners()
	for side: DuelState.PlayerSide in DuelState.SIDES:
		var kind := _engine.clock_kind(side)
		var remaining_msec := _engine.running_time_remaining_msec(side)
		var paused_msec := ClockReading.NO_PAUSED_TURN
		if _engine.is_turn_time_paused(side):
			paused_msec = state.get_player(side).turn_time_remaining_msec
		_timer_bars[side].show_reading(
			ClockReading.new(kind, remaining_msec, running_owners.has(side), paused_msec)
		)


## Décision 0029 : la mention de la fenêtre de réponse (208.6.1) se montre sous la pile tant que
## le joueur de l'écran peut répondre ou passer ; elle n'a pas d'échéance (208.6.2).
func refresh_response_window() -> void:
	if _center_state != DuelColumnView.CenterState.STACK:
		return
	var is_awaiting_viewer := (
		_session.get_session_state() == DuelSession.SessionState.AWAITING_VIEWER
	)
	if is_awaiting_viewer and _session.is_response_window_open():
		_column.show_response_open()
	else:
		_column.hide_response()


# Décision 0032, point 6 : l'ordre des effets déclenchés se choisit dans la pile, leurs rangs
# numérotés au fil des clics.
func _show_choice(model: DuelViewModel, shown: SelectionSnapshot) -> void:
	var decision := _engine.get_state().pending_decision
	var ordered_candidate_ids: Array[int] = []
	if decision.kind == PendingDecision.DecisionKind.ORDER_TRIGGERS:
		ordered_candidate_ids.assign(decision.candidate_ids)
	var lines := model.stack_lines(ordered_candidate_ids, shown.ordered_entry_ids)
	var instruction := _instruction_of(model, decision)
	_column.show_choice(instruction, model.chooser_of(decision), lines, shown.legal_stack_entry_ids)


# Décision 0068 : X, boutons de choix et abandon de l'annonce commencée, sous la pile.
func _show_announcement(model: DuelViewModel, shown: SelectionSnapshot) -> void:
	if shown.has_x_choice:
		_column.show_x_choice(shown.x_value, shown.x_min, shown.x_max)
		_column.show_x_controls(shown.can_decrease_x, shown.can_increase_x, shown.can_confirm_x)
	else:
		_column.hide_x_choice()
	var labels := _choice_labels(model, shown)
	if labels.is_empty():
		_column.hide_choices()
	else:
		_column.show_choices(labels)
	_column.show_cancel(shown.can_cancel)


func _choice_labels(model: DuelViewModel, shown: SelectionSnapshot) -> Array[String]:
	var labels: Array[String] = []
	for value: int in shown.choice_values:
		match shown.choice_kind:
			SelectionSnapshot.ChoiceKind.ORDER:
				var order := model.hero_definition(model.get_viewer()).orders[value]
				labels.append(CardText.order_button_text(value, order))
			SelectionSnapshot.ChoiceKind.TOP_CARD_PLACE:
				var place := value as ChooseTopCardPlace.TopCardPlace
				labels.append(CardText.top_card_place_label(place))
	return labels


# 217.1.5 : l'adversaire ne voit pas la carte regardée ; la décision 0068 étend ce masquage à la
# consigne de défausse : l'autre joueur voit seulement qu'un choix est en cours.
func _instruction_of(model: DuelViewModel, decision: PendingDecision) -> String:
	var is_private := (
		decision.kind == PendingDecision.DecisionKind.CHOOSE_DISCARD
		or decision.kind == PendingDecision.DecisionKind.CHOOSE_TOP_CARD_PLACE
	)
	if is_private and model.chooser_of(decision) != model.get_viewer():
		return DuelViewModel.WAITING_CHOICE_INSTRUCTION
	return DuelViewModel.choice_instruction(decision.kind, decision.required_count)
