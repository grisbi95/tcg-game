# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## DuelCenterPresenter sans scène : centre de la colonne, temps des joueurs et mention de la
## fenêtre de réponse (ruleset 0.41 ; décisions 0021, 0029, 0032, 0045 et 0046). `ColumnSpy` tient
## lieu de `DuelColumnView`, `TimerBarSpy` de `TurnTimerBar`.
##
## Deux montages : un état construit à la main pour le centre et les temps ; un duel mené par
## `DuelHost` et `ManualClock` pour la fenêtre, qui lit l'hôte. Dans le second, A annonce un
## Spell à son premier tour ; B, qui peut alors répondre ou passer, reçoit sa fenêtre (208.6.1).

const LONG_WAIT_MSEC: int = 60_000  # fenêtre laissée ouverte longtemps (208.6.2)
const HANDOVER_MSEC: int = 5_000  # temps passé à se passer l'appareil
const CLOCK_A_MSEC: int = 300_000
const CLOCK_B_MSEC: int = 450_000
const RESPONSE_B_MSEC: int = 20_000
const RESPONSE_MSEC: int = 30_000  # 209.4.6 : temps de réponse complet
const CLOCK_STEP_MSEC: int = 1_000
const TURN_NUMBER: int = 3
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
var _bars: Dictionary[DuelState.PlayerSide, TurnTimerBar] = {}
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
	for side: DuelState.PlayerSide in DuelState.SIDES:
		_bars[side] = auto_free(TimerBarSpy.new())
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


func test_205_6_pending_combat_without_card_is_a_candidate_labeled_combat() -> void:
	var combat_id := _add_waiting_combat(A)
	var trigger_id := _add_waiting_trigger(A, UNIT)
	var decision := _decision(PendingDecision.DecisionKind.ORDER_TRIGGERS)
	decision.candidate_ids.assign([combat_id, trigger_id])
	_builder.with_pending_decision(decision)
	var shown := SelectionSnapshot.new()
	shown.legal_stack_entry_ids.assign([combat_id, trigger_id])
	_show_center(A, shown)
	assert_int(_spy.choice_lines.size()).is_equal(2)
	assert_str(_spy.choice_lines[0].label).is_equal("Combat")


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
	assert_int(_spy.choice_chooser).is_equal(A)
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


# --- Temps des joueurs (décisions 0021 et 0045) ---


func test_209_4_7_active_player_sees_turn_time_and_the_other_one_response_time() -> void:
	_builder.with_turn_time_remaining(A, CLOCK_A_MSEC).with_response_time_remaining(
		B, RESPONSE_B_MSEC
	)
	_builder.with_active_player(A)
	_use_built_state()
	_presenter.refresh_clocks()
	assert_int(_readings_count(A)).is_equal(1)
	assert_int(_readings_count(B)).is_equal(1)
	assert_int(_reading(A).kind).is_equal(DuelState.ClockKind.TURN)
	assert_int(_reading(A).remaining_msec).is_equal(CLOCK_A_MSEC)
	assert_bool(_reading(A).is_running).is_true()
	assert_int(_reading(B).kind).is_equal(DuelState.ClockKind.RESPONSE)
	# 209.4.6 : B, qui n'est pas attendu, recevra un temps de réponse complet.
	assert_int(_reading(B).remaining_msec).is_equal(RESPONSE_MSEC)
	assert_bool(_reading(B).is_running).is_false()


func test_209_4_4_response_time_runs_for_the_player_who_may_answer() -> void:
	_builder.push_spell(_builder.make_card_instance(A, SPELL))
	_builder.with_active_player(A).with_priority_player(B)
	_builder.with_response_time_remaining(B, RESPONSE_B_MSEC)
	_use_built_state()
	_presenter.refresh_clocks()
	assert_bool(_reading(B).is_running).is_true()
	assert_int(_reading(B).remaining_msec).is_equal(RESPONSE_B_MSEC)
	assert_bool(_reading(A).is_running).is_false()


func test_209_4_8a_active_player_keeps_the_paused_turn_time_while_the_stack_is_not_empty() -> void:
	_builder.push_spell(_builder.make_card_instance(A, SPELL))
	_builder.with_turn_time_remaining(A, CLOCK_A_MSEC)
	_builder.with_active_player(A).with_priority_player(B)
	_use_built_state()
	_presenter.refresh_clocks()
	assert_bool(_reading(A).has_paused_turn()).is_true()
	assert_int(_reading(A).paused_turn_msec).is_equal(CLOCK_A_MSEC)
	assert_bool(_reading(B).has_paused_turn()).is_false()


func test_209_4_8a_no_turn_time_is_paused_with_an_empty_stack() -> void:
	_builder.with_active_player(A)
	_use_built_state()
	_presenter.refresh_clocks()
	assert_bool(_reading(A).has_paused_turn()).is_false()


func test_209_4_2d_no_time_runs_during_the_mulligan() -> void:
	_builder.with_pending_decision(_decision(PendingDecision.DecisionKind.MULLIGAN))
	_use_built_state()
	_presenter.refresh_clocks()
	assert_bool(_reading(A).is_running).is_false()
	assert_bool(_reading(B).is_running).is_false()


func test_decision_0021_clocks_are_read_again_at_each_frame() -> void:
	_builder.with_turn_time_remaining(A, CLOCK_A_MSEC).with_active_player(A)
	_use_built_state()
	_presenter.refresh_clocks()
	_engine.advance_clock(CLOCK_STEP_MSEC)
	_presenter.refresh_clocks()
	assert_int(_readings_count(A)).is_equal(2)
	assert_int(_readings_count(B)).is_equal(2)
	assert_int(_reading(A).remaining_msec).is_equal(CLOCK_A_MSEC - CLOCK_STEP_MSEC)


func _reading(side: DuelState.PlayerSide) -> ClockReading:
	return (_bars[side] as TimerBarSpy).last_reading()


func _readings_count(side: DuelState.PlayerSide) -> int:
	return (_bars[side] as TimerBarSpy).readings.size()


# --- Fenêtre de réponse (208.6, décision 0029) ---


func test_208_6_1_open_window_is_shown_under_pass_as_soon_as_the_stack_is_shown() -> void:
	_reach_answer_of_b(DuelConfig.new())
	_show_center_of_duel(B)
	assert_array(_spy.calls).contains_exactly(["show_stack", "show_response_open"])


func test_208_6_2_window_stays_the_same_after_a_response_begins() -> void:
	_reach_answer_of_b(DuelConfig.new())
	_show_center_of_duel(B)
	_host.begin_response()
	_presenter.refresh_response_window()
	assert_int(_spy.count_calls("hide_response")).is_equal(0)
	assert_str(_spy.calls[-1]).is_equal("show_response_open")


func test_208_6_2_window_stays_the_same_after_a_long_wait() -> void:
	_reach_answer_of_b(DuelConfig.new())
	_show_center_of_duel(B)
	_clock.advance(LONG_WAIT_MSEC)
	_presenter.refresh_response_window()
	assert_int(_spy.count_calls("hide_response")).is_equal(0)
	assert_str(_spy.calls[-1]).is_equal("show_response_open")


func test_208_6_1_no_window_while_events_are_played() -> void:
	_reach_first_turn_of_a()
	_announce_from_a()
	assert_int(_host.get_host_state()).is_equal(HOST.PLAYING_EVENTS)
	_show_center_of_duel(A)
	assert_array(_spy.calls).contains_exactly(["show_stack", "hide_response"])


func test_208_6_1_no_window_during_the_handover() -> void:
	_reach_first_turn_of_a()
	_announce_from_a()
	_host.confirm_events_played()
	assert_int(_host.get_host_state()).is_equal(HOST.RELAY)
	_show_center_of_duel(A)
	_clock.advance(HANDOVER_MSEC)
	_presenter.refresh_response_window()
	assert_array(_spy.calls).contains_exactly(["show_stack", "hide_response", "hide_response"])


func test_208_6_1_window_is_left_alone_when_the_stack_is_not_shown() -> void:
	_use_built_state()
	_presenter.show_center(DuelViewModel.new(_engine.get_state(), _catalog, A), _shown())
	_presenter.refresh_response_window()
	assert_array(_spy.calls).contains_exactly(["show_turn"])


func test_208_6_1_window_is_left_alone_before_any_center_is_shown() -> void:
	_use_built_state()
	_presenter.refresh_response_window()
	assert_array(_spy.calls).is_empty()


# Montage à état construit : moteur et hôte (non démarré) sur l'état du builder.
func _use_built_state() -> void:
	_engine = DuelEngine.new(_catalog)
	_engine.start_from_state(_builder.build())
	_host = DuelHost.new(_engine, _clock)
	_presenter = DuelCenterPresenter.new()
	_presenter.setup(_spy, _bars, HostedDuelSession.new(_host, SetupSamples.setup()))


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


func _add_waiting_combat(side: DuelState.PlayerSide) -> int:
	var state := _builder.build()
	var entry := StackEntry.new()
	entry.kind = StackEntry.StackEntryKind.PENDING_COMBAT
	entry.owner = side
	entry.stack_entry_id = state.allocate_stack_entry_id()
	state.waiting_triggers.append(entry)
	return entry.stack_entry_id


# Montage de duel mené : deux humains, A commence, présentateur câblé sur l'hôte.
func _show_center_of_duel(viewer: DuelState.PlayerSide) -> void:
	_presenter = DuelCenterPresenter.new()
	_presenter.setup(_spy, _bars, HostedDuelSession.new(_host, SetupSamples.setup()))
	var model := DuelViewModel.new(_engine.get_state(), _engine.get_state().catalog, viewer)
	_presenter.show_center(model, _shown())


func _reach_first_turn_of_a(config: DuelConfig = DuelConfig.new()) -> void:
	_start_duel(config)
	_host.confirm_events_played()
	_host.confirm_relay()
	ResponseWindowSamples.accept_mulligans(_host)


# 208.7.1, 208.2.4 : A a annoncé un Spell ; B a pris l'appareil et peut répondre ou passer.
func _reach_answer_of_b(config: DuelConfig) -> void:
	_reach_first_turn_of_a(config)
	_announce_from_a()
	_host.confirm_events_played()
	_host.confirm_relay()
	assert_int(_host.get_host_state()).is_equal(HOST.AWAITING_HUMAN)


func _start_duel(config: DuelConfig) -> void:
	var catalog := ResponseWindowSamples.catalog_with_reaction(ResponseWindowSamples.REACTION_ID)
	_engine = DuelEngine.new(catalog, config)
	_host = DuelHost.new(_engine, _clock)
	var setup := SetupSamples.setup()
	setup.impose_first_player(A)
	_host.start(setup)


func _announce_from_a() -> void:
	assert_bool(ResponseWindowSamples.announce_reaction(_host, _engine)).is_true()
