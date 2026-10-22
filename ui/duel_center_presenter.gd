class_name DuelCenterPresenter
extends RefCounted
## Centre et pendules de la colonne de duel (décisions 0021, 0029 et 0032) : choisit ce que la
## colonne montre d'après l'état du moteur, et relit à chaque image la pendule, qui avance au
## temps réel sans événement. Aucune règle ici.

var _column: DuelColumnView
var _engine: DuelEngine
var _host: DuelHost
var _center_state: DuelColumnView.CenterState = DuelColumnView.CenterState.TURN


## `column` est la colonne pilotée ; `engine` et `host` donnent l'état et le temps réel.
func setup(column: DuelColumnView, engine: DuelEngine, host: DuelHost) -> void:
	_column = column
	_engine = engine
	_host = host


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


## Décision 0021 : la pendule est relue à chaque image sans événement ; la colonne ne redessine
## une pendule que si ses secondes changent.
func refresh_clocks() -> void:
	var state := _engine.get_state()
	_column.show_clocks(
		state.get_player(DuelState.PlayerSide.A).clock_remaining_msec,
		state.get_player(DuelState.PlayerSide.B).clock_remaining_msec,
		_engine.clock_owners()
	)


## Décision 0029 : la mention de la fenêtre de réponse (208.6.1) se montre sous la pile tant que
## l'hôte attend un humain qui peut répondre ou passer ; elle n'a pas d'échéance (208.6.2).
func refresh_response_window() -> void:
	if _center_state != DuelColumnView.CenterState.STACK:
		return
	var is_awaiting_human := _host.get_host_state() == DuelHost.HostState.AWAITING_HUMAN
	if is_awaiting_human and _host.is_response_window_open():
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
