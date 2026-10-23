class_name DuelCenterPresenter
extends RefCounted
## Centre et temps de la colonne de duel (décisions 0021, 0029, 0032 et 0045) : choisit ce que la
## colonne montre d'après l'état du moteur, et relit à chaque image les temps, qui avancent au
## temps réel sans événement. Aucune règle ici.

var _column: DuelColumnView
var _engine: DuelEngine
var _session: DuelSession
var _center_state: DuelColumnView.CenterState = DuelColumnView.CenterState.TURN


## `column` est la colonne pilotée ; `session` donne l'état, le temps réel et la fenêtre de
## réponse (décision 0050).
func setup(column: DuelColumnView, session: DuelSession) -> void:
	_column = column
	_engine = session.get_engine()
	_session = session


## Recale le centre sur l'état du moteur, `model` pour la pile et `shown` pour les boutons.
func show_center(model: DuelViewModel, shown: SelectionSnapshot) -> void:
	var state := _engine.get_state()
	_center_state = DuelViewModel.center_state_of(state)
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


## Décision 0021 : les temps sont relus à chaque image sans événement ; la colonne ne redessine un
## temps que si son affichage change. Chaque joueur voit le temps qui compte pour lui
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
		_column.show_clock(
			side, ClockReading.new(kind, remaining_msec, running_owners.has(side), paused_msec)
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
	var instruction := DuelViewModel.choice_instruction(decision.kind)
	_column.show_choice(instruction, lines, shown.legal_stack_entry_ids)
