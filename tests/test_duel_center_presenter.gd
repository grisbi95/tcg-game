# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## DuelCenterPresenter sans scène : centre de la colonne, pendules et décompte de la fenêtre de
## réponse (décisions 0021, 0029 et 0032). `ColumnSpy` tient lieu de `DuelColumnView`.
##
## Deux montages : un état construit à la main pour le centre et les pendules ; un duel mené par
## `DuelHost` et `ManualClock` pour le décompte, qui lit l'hôte. Dans le second, A déploie une
## Unit à son premier tour ; B, qui peut alors répondre ou passer, reçoit sa fenêtre (208.6.1).

const RESPONSE_WINDOW_MSEC: int = 2_000  # 208.6.2, décision 0029 : PROVISOIRE
const LONG_WINDOW_MSEC: int = 3_500  # fenêtre d'une configuration autre que celle par défaut
const ELAPSED_MSEC: int = 500  # temps écoulé dans la fenêtre avant une relecture
const HANDOVER_MSEC: int = 5_000  # temps passé à se passer l'appareil
const CLOCK_A_MSEC: int = 300_000
const CLOCK_B_MSEC: int = 450_000
const CLOCK_STEP_MSEC: int = 1_000
const TURN_NUMBER: int = 3
const UNIT_COST: int = 2  # CatalogSamples.unit()
const UNIT: StringName = &"cp_unit"
const UNIT_FORCE: int = 3  # Force imprimée de la Unit d'essai
const SPELL: StringName = &"sample_spell"
const SPELL_NAME: String = "Spell d'essai"
const NO_ORDER: int = 0  # StackView.NO_ORDER

# Consignes et résultats de DuelViewModel recopiés pour contrôler la colonne (décision 0032).
const ORDER_INSTRUCTION: String = "Ordre des effets : clique-les dans l'ordre d'ajout à la pile"
const TARGET_INSTRUCTION: String = "Choisis la cible de l'effet"
const B_WINS_TEXT: String = "Victoire du joueur B"
const DRAW_TEXT: String = "Égalité"

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const HOST := DuelHost.HostState

var _catalog: Catalog
var _builder: DuelStateBuilder
var _spy: ColumnSpy
var _presenter: DuelCenterPresenter
var _engine: DuelEngine
var _clock: ManualClock
var _host: DuelHost


func before_test() -> void:
	_catalog = Catalog.new()
	SetupSamples.add_unit(_catalog, UNIT, UNIT_FORCE)
	_catalog.add_card(CardDefinition.from_dict(CatalogSamples.spell()))
	_catalog.add_hero(HeroDefinition.from_dict(CatalogSamples.hero()))
	_builder = DuelStateBuilder.new(DuelConfig.new(), _catalog)
	_spy = auto_free(ColumnSpy.new())
	_clock = ManualClock.new()


# --- Centre de la colonne (décision 0032) ---


func test_decision_0032_empty_stack_shows_the_turn_and_who_plays() -> void:
	_builder.with_turn_number(TURN_NUMBER).with_active_player(B)
	var shown := SelectionSnapshot.new()
	shown.can_end_turn = true
	_show_center(A, shown)
	assert_array(_spy.calls).contains_exactly(["show_turn"])
	assert_int(_spy.turn_number).is_equal(TURN_NUMBER)
	assert_int(_spy.turn_actor).is_equal(B)
	assert_bool(_spy.turn_can_end).is_true()


func test_decision_0032_end_turn_is_offered_only_when_the_selection_allows_it() -> void:
	_show_center(A, SelectionSnapshot.new())
	assert_bool(_spy.turn_can_end).is_false()


func test_decision_0032_stack_shows_its_lines_and_who_may_answer() -> void:
	var entry_id := _builder.push_spell(_builder.make_card_instance(A, SPELL))
	_builder.with_priority_player(B)
	var shown := SelectionSnapshot.new()
	shown.can_pass = true
	shown.legal_stack_entry_ids.assign([entry_id])
	_show_center(B, shown)
	assert_array(_spy.calls).contains_exactly(["show_stack", "hide_response"])
	assert_int(_spy.stack_lines.size()).is_equal(1)
	assert_int(_spy.stack_lines[0].stack_entry_id).is_equal(entry_id)
	assert_str(_spy.stack_lines[0].label).is_equal(SPELL_NAME)
	assert_array(_spy.stack_highlighted_ids).contains_exactly([entry_id])
	assert_int(_spy.stack_responder).is_equal(B)
	assert_bool(_spy.stack_can_pass).is_true()


func test_decision_0032_mulligan_asks_the_holder_of_the_device_to_confirm() -> void:
	_builder.with_pending_decision(_decision(PendingDecision.DecisionKind.MULLIGAN))
	var shown := SelectionSnapshot.new()
	shown.can_confirm = true
	_show_center(B, shown)
	assert_array(_spy.calls).contains_exactly(["show_mulligan"])
	assert_int(_spy.mulligan_player).is_equal(B)
	assert_bool(_spy.mulligan_can_confirm).is_true()


func test_decision_0032_trigger_order_is_chosen_in_the_stack_with_numbered_ranks() -> void:
	var base_id := _builder.push_spell(_builder.make_card_instance(A, SPELL))
	var first_id := _add_waiting_trigger(A, UNIT)
	var second_id := _add_waiting_trigger(A, UNIT)
	var decision := _decision(PendingDecision.DecisionKind.ORDER_TRIGGERS)
	decision.candidate_ids.assign([first_id, second_id])
	_builder.with_pending_decision(decision)
	var shown := SelectionSnapshot.new()
	shown.legal_stack_entry_ids.assign([first_id, second_id])
	shown.ordered_entry_ids.assign([second_id])
	_show_center(A, shown)
	assert_array(_spy.calls).contains_exactly(["show_choice"])
	assert_str(_spy.choice_instruction).is_equal(ORDER_INSTRUCTION)
	assert_array(_spy.choice_highlighted_ids).contains_exactly([first_id, second_id])
	assert_int(_spy.choice_lines.size()).is_equal(3)
	assert_int(_spy.choice_lines[0].stack_entry_id).is_equal(base_id)
	assert_int(_spy.choice_lines[1].stack_entry_id).is_equal(first_id)
	assert_int(_spy.choice_lines[2].stack_entry_id).is_equal(second_id)
	assert_int(_spy.choice_lines[0].order_number).is_equal(NO_ORDER)
	assert_int(_spy.choice_lines[1].order_number).is_equal(NO_ORDER)
	assert_int(_spy.choice_lines[2].order_number).is_equal(1)


func test_decision_0032_target_choice_shows_the_stack_without_waiting_triggers() -> void:
	var spell_id := _builder.push_spell(_builder.make_card_instance(A, SPELL))
	var waiting_id := _add_waiting_trigger(A, UNIT)
	var decision := _decision(PendingDecision.DecisionKind.CHOOSE_TARGETS)
	decision.candidate_ids.assign([spell_id, waiting_id])
	_builder.with_pending_decision(decision)
	var shown := SelectionSnapshot.new()
	shown.legal_stack_entry_ids.assign([spell_id])
	_show_center(A, shown)
	assert_array(_spy.calls).contains_exactly(["show_choice"])
	assert_str(_spy.choice_instruction).is_equal(TARGET_INSTRUCTION)
	assert_int(_spy.choice_lines.size()).is_equal(1)
	assert_int(_spy.choice_lines[0].stack_entry_id).is_equal(spell_id)
	assert_array(_spy.choice_highlighted_ids).contains_exactly([spell_id])


func test_decision_0032_ended_duel_is_announced_in_one_line() -> void:
	_builder.with_phase(DuelState.DuelPhase.ENDED).with_result(DuelState.DuelResult.PLAYER_B_WINS)
	_show_center(A, SelectionSnapshot.new())
	assert_array(_spy.calls).contains_exactly(["show_ended"])
	assert_str(_spy.ended_text).is_equal(B_WINS_TEXT)


func test_decision_0032_drawn_duel_is_announced_as_a_draw() -> void:
	_builder.with_phase(DuelState.DuelPhase.ENDED).with_result(DuelState.DuelResult.DRAW)
	_show_center(A, SelectionSnapshot.new())
	assert_str(_spy.ended_text).is_equal(DRAW_TEXT)


# --- Pendules (décision 0021) ---


func test_decision_0021_clocks_show_remaining_time_and_engine_clock_owners() -> void:
	_builder.with_clock_remaining(A, CLOCK_A_MSEC).with_clock_remaining(B, CLOCK_B_MSEC)
	_builder.with_active_player(A)
	_use_built_state()
	_presenter.refresh_clocks()
	assert_array(_spy.calls).contains_exactly(["show_clocks"])
	assert_int(_spy.clock_a_msec).is_equal(CLOCK_A_MSEC)
	assert_int(_spy.clock_b_msec).is_equal(CLOCK_B_MSEC)
	assert_array(_spy.clock_owners).contains_exactly([A])


func test_decision_0021_clock_runs_for_the_player_who_may_answer() -> void:
	_builder.push_spell(_builder.make_card_instance(A, SPELL))
	_builder.with_active_player(A).with_priority_player(B)
	_use_built_state()
	_presenter.refresh_clocks()
	assert_array(_spy.clock_owners).contains_exactly([B])


func test_decision_0021_no_clock_runs_during_the_mulligan() -> void:
	_builder.with_pending_decision(_decision(PendingDecision.DecisionKind.MULLIGAN))
	_use_built_state()
	_presenter.refresh_clocks()
	assert_array(_spy.clock_owners).is_empty()


func test_decision_0021_clocks_are_read_again_at_each_frame() -> void:
	_builder.with_clock_remaining(A, CLOCK_A_MSEC).with_active_player(A)
	_use_built_state()
	_presenter.refresh_clocks()
	_engine.advance_clock(CLOCK_STEP_MSEC)
	_presenter.refresh_clocks()
	assert_array(_spy.calls).contains_exactly(["show_clocks", "show_clocks"])
	assert_int(_spy.clock_a_msec).is_equal(CLOCK_A_MSEC - CLOCK_STEP_MSEC)


# --- Décompte de la fenêtre de réponse (décision 0029) ---


func test_decision_0029_countdown_is_shown_under_pass_as_soon_as_the_stack_is_shown() -> void:
	_reach_answer_of_b(DuelConfig.new())
	_show_center_of_duel(B)
	assert_array(_spy.calls).contains_exactly(["show_stack", "show_response_time"])
	assert_int(_spy.response_time_left_msec).is_equal(RESPONSE_WINDOW_MSEC)
	assert_int(_spy.response_window_msec).is_equal(RESPONSE_WINDOW_MSEC)


func test_decision_0029_countdown_is_read_from_the_host_at_each_frame() -> void:
	_reach_answer_of_b(DuelConfig.new())
	_show_center_of_duel(B)
	_clock.advance(ELAPSED_MSEC)
	_presenter.refresh_response_countdown()
	assert_int(_spy.count_calls("show_response_time")).is_equal(2)
	assert_int(_spy.response_time_left_msec).is_equal(RESPONSE_WINDOW_MSEC - ELAPSED_MSEC)
	assert_int(_spy.response_window_msec).is_equal(RESPONSE_WINDOW_MSEC)


func test_decision_0029_window_length_comes_from_the_configuration() -> void:
	var config := DuelConfig.new()
	config.response_window_msec = LONG_WINDOW_MSEC
	_reach_answer_of_b(config)
	_show_center_of_duel(B)
	assert_int(_spy.response_time_left_msec).is_equal(LONG_WINDOW_MSEC)
	assert_int(_spy.response_window_msec).is_equal(LONG_WINDOW_MSEC)


func test_decision_0029_started_response_stops_the_countdown_display() -> void:
	_reach_answer_of_b(DuelConfig.new())
	_show_center_of_duel(B)
	_host.begin_response()
	_presenter.refresh_response_countdown()
	assert_array(_spy.calls).contains_exactly(
		["show_stack", "show_response_time", "show_response_stopped"]
	)


func test_decision_0029_stopped_countdown_stays_stopped_while_time_passes() -> void:
	_reach_answer_of_b(DuelConfig.new())
	_show_center_of_duel(B)
	_host.begin_response()
	_clock.advance(RESPONSE_WINDOW_MSEC)
	_presenter.refresh_response_countdown()
	assert_int(_spy.count_calls("show_response_time")).is_equal(1)
	assert_int(_spy.count_calls("show_response_stopped")).is_equal(1)


func test_decision_0029_no_countdown_while_events_are_played() -> void:
	_reach_first_turn_of_a()
	_deploy_from_a()
	assert_int(_host.get_host_state()).is_equal(HOST.PLAYING_EVENTS)
	_show_center_of_duel(A)
	assert_array(_spy.calls).contains_exactly(["show_stack", "hide_response"])


func test_decision_0029_no_countdown_during_the_handover() -> void:
	_reach_first_turn_of_a()
	_deploy_from_a()
	_host.confirm_events_played()
	assert_int(_host.get_host_state()).is_equal(HOST.RELAY)
	_show_center_of_duel(A)
	_clock.advance(HANDOVER_MSEC)
	_presenter.refresh_response_countdown()
	assert_array(_spy.calls).contains_exactly(["show_stack", "hide_response", "hide_response"])


func test_decision_0029_countdown_is_left_alone_when_the_stack_is_not_shown() -> void:
	_use_built_state()
	_presenter.show_center(DuelViewModel.new(_engine.get_state(), _catalog, A), _shown())
	_presenter.refresh_response_countdown()
	assert_array(_spy.calls).contains_exactly(["show_turn"])


func test_decision_0029_countdown_is_left_alone_before_any_center_is_shown() -> void:
	_use_built_state()
	_presenter.refresh_response_countdown()
	assert_array(_spy.calls).is_empty()


# Montage à état construit : moteur et hôte (non démarré) sur l'état du builder.
func _use_built_state() -> void:
	_engine = DuelEngine.new(_catalog)
	_engine.start_from_state(_builder.build())
	_host = DuelHost.new(_engine, _clock)
	_presenter = DuelCenterPresenter.new()
	_presenter.setup(_spy, _engine, _host)


func _show_center(viewer: DuelState.PlayerSide, shown: SelectionSnapshot) -> void:
	_use_built_state()
	_presenter.show_center(DuelViewModel.new(_engine.get_state(), _catalog, viewer), shown)


func _shown() -> SelectionSnapshot:
	return SelectionSnapshot.new()


func _decision(kind: PendingDecision.DecisionKind) -> PendingDecision:
	var decision := PendingDecision.new()
	decision.kind = kind
	decision.awaited_players.assign(DuelState.SIDES)
	return decision


func _add_waiting_trigger(side: DuelState.PlayerSide, source: StringName) -> int:
	var state := _builder.build()
	var entry := StackEntry.new()
	entry.kind = StackEntry.StackEntryKind.TRIGGERED_EFFECT
	entry.owner = side
	entry.source_definition_id = source
	entry.stack_entry_id = state.allocate_stack_entry_id()
	state.waiting_triggers.append(entry)
	return entry.stack_entry_id


# Montage de duel mené : deux humains, A commence, présentateur câblé sur l'hôte.
func _show_center_of_duel(viewer: DuelState.PlayerSide) -> void:
	_presenter = DuelCenterPresenter.new()
	_presenter.setup(_spy, _engine, _host)
	var model := DuelViewModel.new(_engine.get_state(), _engine.get_state().catalog, viewer)
	_presenter.show_center(model, _shown())


func _reach_first_turn_of_a(config: DuelConfig = DuelConfig.new()) -> void:
	_start_duel(config)
	_host.confirm_events_played()
	_host.confirm_relay()
	ResponseWindowSamples.accept_mulligans(_host)


# 208.2.4 : A a annoncé un déploiement ; B a pris l'appareil et peut répondre ou passer.
func _reach_answer_of_b(config: DuelConfig) -> void:
	_reach_first_turn_of_a(config)
	_deploy_from_a()
	_host.confirm_events_played()
	_host.confirm_relay()
	assert_int(_host.get_host_state()).is_equal(HOST.AWAITING_HUMAN)


func _start_duel(config: DuelConfig) -> void:
	_engine = DuelEngine.new(SetupSamples.catalog(), config)
	_host = DuelHost.new(_engine, _clock)
	var setup := SetupSamples.setup()
	setup.impose_first_player(A)
	_host.start(setup)


func _deploy_from_a() -> void:
	for card: CardInstance in _engine.get_state().get_player(A).hand:
		if ResponseWindowSamples.try_deploy(_host, _engine, card, UNIT_COST):
			return
	fail("aucun déploiement légal pour A")
