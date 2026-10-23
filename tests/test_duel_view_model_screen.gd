# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## DuelViewModel sans scène, état de l'écran : centre de la colonne, Essence et Sources montrées,
## lignes de la pile (ruleset 0.36, 201.4 ; décisions 0030 et 0032).

const UNIT: StringName = &"vm_unit"
const UNIT_NAME: String = "Carte vm_unit"
const BUILDING: StringName = &"vm_building"
const BUILDING_NAME: String = "Carte vm_building"
const SPELL: StringName = &"sample_spell"
const SPELL_NAME: String = "Spell d'essai"
const UNKNOWN_CARD_ID: int = 9999

# Libellés de la pile : valeurs de DuelViewModel recopiées pour contrôler la vue (décision 0028).
const NORMAL_ACTION_LABEL: String = "Action normale"
const TRIGGERED_EFFECT_LABEL: String = "Effet déclenché"
const ORDER_INSTRUCTION: String = "Ordre des effets : clique-les dans l'ordre d'ajout à la pile"
const TARGET_INSTRUCTION: String = "Choisis la cible de l'effet"
const ENDED_TEXT: String = "Duel terminé"

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const CENTER := DuelColumnView.CenterState

var _catalog: Catalog
var _builder: DuelStateBuilder


func before_test() -> void:
	_catalog = Catalog.new()
	SetupSamples.add_unit(_catalog, UNIT, 3)
	SetupSamples.add_building(_catalog, BUILDING, 5)
	_catalog.add_card(CardDefinition.from_dict(CatalogSamples.spell()))
	_catalog.add_card(CardDefinition.from_dict(CatalogSamples.gear()))
	_catalog.add_hero(HeroDefinition.from_dict(CatalogSamples.hero()))
	_builder = DuelStateBuilder.new(DuelConfig.new(), _catalog)


# --- Centre de la colonne ---


func test_decision_0032_center_is_turn_by_default() -> void:
	assert_int(DuelViewModel.center_state_of(_builder.build())).is_equal(CENTER.TURN)


func test_decision_0032_center_is_stack_when_the_stack_is_not_empty() -> void:
	_builder.push_spell(_builder.make_card_instance(A, SPELL))
	assert_int(DuelViewModel.center_state_of(_builder.build())).is_equal(CENTER.STACK)


func test_decision_0032_center_is_mulligan_during_a_mulligan_decision() -> void:
	_builder.with_pending_decision(_decision(PendingDecision.DecisionKind.MULLIGAN))
	assert_int(DuelViewModel.center_state_of(_builder.build())).is_equal(CENTER.MULLIGAN)


func test_decision_0032_center_is_choice_for_engine_choices() -> void:
	for kind: PendingDecision.DecisionKind in [
		PendingDecision.DecisionKind.ORDER_TRIGGERS, PendingDecision.DecisionKind.CHOOSE_TARGETS
	]:
		var builder := DuelStateBuilder.new(DuelConfig.new(), _catalog)
		builder.with_pending_decision(_decision(kind))
		assert_int(DuelViewModel.center_state_of(builder.build())).is_equal(CENTER.CHOICE)


func test_decision_0032_choice_wins_over_a_non_empty_stack() -> void:
	_builder.push_spell(_builder.make_card_instance(A, SPELL))
	_builder.with_pending_decision(_decision(PendingDecision.DecisionKind.CHOOSE_TARGETS))
	assert_int(DuelViewModel.center_state_of(_builder.build())).is_equal(CENTER.CHOICE)


func test_decision_0032_end_wins_over_stack_and_decision() -> void:
	_builder.push_spell(_builder.make_card_instance(A, SPELL))
	_builder.with_pending_decision(_decision(PendingDecision.DecisionKind.ORDER_TRIGGERS))
	_builder.with_phase(DuelState.DuelPhase.ENDED)
	assert_int(DuelViewModel.center_state_of(_builder.build())).is_equal(CENTER.ENDED)


func test_decision_0032_choice_instruction_per_kind() -> void:
	(
		assert_str(DuelViewModel.choice_instruction(PendingDecision.DecisionKind.ORDER_TRIGGERS))
		. is_equal(ORDER_INSTRUCTION)
	)
	(
		assert_str(DuelViewModel.choice_instruction(PendingDecision.DecisionKind.CHOOSE_TARGETS))
		. is_equal(TARGET_INSTRUCTION)
	)


func test_decision_0032_result_text_per_result() -> void:
	assert_str(DuelViewModel.result_text(DuelState.DuelResult.PLAYER_A_WINS)).is_equal(
		"Victoire du joueur A"
	)
	assert_str(DuelViewModel.result_text(DuelState.DuelResult.PLAYER_B_WINS)).is_equal(
		"Victoire du joueur B"
	)
	assert_str(DuelViewModel.result_text(DuelState.DuelResult.DRAW)).is_equal("Égalité")
	assert_str(DuelViewModel.result_text(DuelState.DuelResult.NONE)).is_equal(ENDED_TEXT)


# --- Essence et Sources montrées (décision 0032 point 4) ---


func test_decision_0032_essence_in_own_turn_is_the_real_reserve() -> void:
	_builder.with_active_player(A).with_essence_reserve(A, 4).with_essence_reserve(B, 1)
	var shown := _drafting_snapshot(false, EssencePayment.new(2, 1))
	assert_int(_model(A).essence_shown(A, shown)).is_equal(4)


func test_decision_0032_essence_in_opponent_turn_is_the_draft_payment() -> void:
	_builder.with_active_player(B).with_essence_reserve(A, 4)
	var shown := _drafting_snapshot(true, EssencePayment.new(2, 1))
	assert_int(_model(A).essence_shown(A, shown)).is_equal(3)


func test_decision_0032_empty_draft_shows_zero_in_opponent_turn() -> void:
	_builder.with_active_player(B).with_essence_reserve(A, 4)
	var shown := _drafting_snapshot(true, EssencePayment.new())
	assert_int(_model(A).essence_shown(A, shown)).is_equal(0)


func test_decision_0032_other_player_shows_his_real_reserve() -> void:
	_builder.with_active_player(A).with_essence_reserve(B, 5)
	var shown := _drafting_snapshot(false, EssencePayment.new(2, 1))
	assert_int(_model(A).essence_shown(B, shown)).is_equal(5)


func test_decision_0032_other_player_in_his_own_turn_shows_his_real_reserve() -> void:
	_builder.with_active_player(B).with_essence_reserve(B, 2)
	var shown := _drafting_snapshot(true, EssencePayment.new(2, 1))
	assert_int(_model(A).essence_shown(B, shown)).is_equal(2)


func test_decision_0032_viewer_b_drafts_in_the_turn_of_a() -> void:
	_builder.with_active_player(A).with_essence_reserve(B, 6)
	var shown := _drafting_snapshot(true, EssencePayment.new(1, 1))
	assert_int(_model(B).essence_shown(B, shown)).is_equal(2)
	assert_int(_model(B).essence_shown(A, shown)).is_equal(0)


func test_decision_0032_draft_is_ignored_when_the_snapshot_is_not_drafting() -> void:
	_builder.with_active_player(B).with_essence_reserve(A, 4)
	var shown := _drafting_snapshot(false, EssencePayment.new(2, 1))
	assert_int(_model(A).essence_shown(A, shown)).is_equal(4)


func test_decision_0032_viewer_sources_come_from_the_snapshot() -> void:
	_builder.with_sources_in_play(A, 3, 2).with_sources_in_play(B, 4, 1)
	var shown := SelectionSnapshot.new()
	shown.shown_upright_sources = 1
	shown.shown_tilted_sources = 4
	var model := _model(A)
	assert_int(model.upright_sources(A, shown)).is_equal(1)
	assert_int(model.tilted_sources(A, shown)).is_equal(4)


func test_decision_0032_other_player_sources_come_from_the_state() -> void:
	_builder.with_sources_in_play(A, 3, 2).with_sources_in_play(B, 4, 1)
	var shown := SelectionSnapshot.new()
	shown.shown_upright_sources = 1
	shown.shown_tilted_sources = 4
	var model := _model(A)
	assert_int(model.upright_sources(B, shown)).is_equal(4)
	assert_int(model.tilted_sources(B, shown)).is_equal(1)


# --- Pile (201.4.7) ---


func test_201_4_7_empty_stack_has_no_line() -> void:
	assert_array(_model(A).stack_lines()).is_empty()


func test_201_4_7_lines_go_from_base_to_top_with_owner_and_tint() -> void:
	var unit_id := _builder.push_deploy(
		_builder.make_card_instance(A, UNIT), DuelStateBuilder.cell("B1")
	)
	var spell_id := _builder.push_spell(_builder.make_card_instance(B, SPELL))
	var lines := _model(A).stack_lines()
	assert_int(lines.size()).is_equal(2)
	assert_int(lines[0].stack_entry_id).is_equal(unit_id)
	assert_str(lines[0].label).is_equal(UNIT_NAME)
	assert_int(lines[0].tint).is_equal(DuelPalette.Tint.UNIT)
	assert_int(lines[0].owner).is_equal(A)
	assert_int(lines[1].stack_entry_id).is_equal(spell_id)
	assert_str(lines[1].label).is_equal(SPELL_NAME)
	assert_int(lines[1].tint).is_equal(DuelPalette.Tint.SPELL)
	assert_int(lines[1].owner).is_equal(B)


func test_201_4_7_lines_are_visible_whoever_holds_the_device() -> void:
	_builder.push_spell(_builder.make_card_instance(B, SPELL))
	assert_str(_model(A).stack_lines()[0].label).is_equal(SPELL_NAME)
	assert_str(_model(B).stack_lines()[0].label).is_equal(SPELL_NAME)


func test_201_4_8_announced_card_is_shown_with_its_own_tint() -> void:
	_builder.push_deploy(_builder.make_card_instance(A, BUILDING), DuelStateBuilder.cell("B1"))
	var line := _model(B).stack_lines()[0]
	assert_str(line.label).is_equal(BUILDING_NAME)
	assert_int(line.tint).is_equal(DuelPalette.Tint.BUILDING)


func test_208_1_2_normal_action_line_has_its_label_and_no_card() -> void:
	var piece_id := _builder.place_piece(A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B2"), UNIT)
	_builder.push_normal_action(piece_id, DuelStateBuilder.cell("B3"))
	var model := _model(A)
	assert_str(model.stack_lines()[0].label).is_equal(NORMAL_ACTION_LABEL)
	assert_object(model.entry_definition(_builder.build().stack[0])).is_null()


func test_207_3_2_triggered_effect_line_names_its_source_card() -> void:
	var entry_id := _push_trigger(A, UNIT)
	var line := _model(A).stack_lines()[0]
	assert_int(line.stack_entry_id).is_equal(entry_id)
	assert_str(line.label).is_equal("Effet : %s" % UNIT_NAME)
	assert_int(line.tint).is_equal(DuelPalette.Tint.UNIT)


func test_decision_0030_triggered_effect_of_an_unknown_source_has_a_plain_label() -> void:
	_push_trigger(A, &"vm_vanished_source")
	var line := _model(A).stack_lines()[0]
	assert_str(line.label).is_equal(TRIGGERED_EFFECT_LABEL)
	assert_int(line.tint).is_equal(DuelPalette.Tint.SPELL)


func test_208_4_6_lines_carry_no_order_number_without_a_choice() -> void:
	_builder.push_spell(_builder.make_card_instance(A, SPELL))
	assert_int(_model(A).stack_lines()[0].order_number).is_equal(StackView.NO_ORDER)


func test_208_4_6_waiting_triggers_join_the_top_and_get_their_rank() -> void:
	var base_id := _builder.push_spell(_builder.make_card_instance(A, SPELL))
	var first_id := _add_waiting_trigger(A, UNIT)
	var second_id := _add_waiting_trigger(A, BUILDING)
	var extra: Array[int] = [first_id, second_id]
	var ordered: Array[int] = [second_id, first_id]
	var lines := _model(A).stack_lines(extra, ordered)
	assert_int(lines.size()).is_equal(3)
	assert_int(lines[0].stack_entry_id).is_equal(base_id)
	assert_int(lines[0].order_number).is_equal(StackView.NO_ORDER)
	assert_int(lines[1].stack_entry_id).is_equal(first_id)
	assert_int(lines[1].order_number).is_equal(2)
	assert_int(lines[2].stack_entry_id).is_equal(second_id)
	assert_int(lines[2].order_number).is_equal(1)


func test_208_4_6_partly_ordered_triggers_number_only_the_chosen_ones() -> void:
	var first_id := _add_waiting_trigger(A, UNIT)
	var second_id := _add_waiting_trigger(A, BUILDING)
	var extra: Array[int] = [first_id, second_id]
	var ordered: Array[int] = [second_id]
	var lines := _model(A).stack_lines(extra, ordered)
	assert_int(lines[0].order_number).is_equal(StackView.NO_ORDER)
	assert_int(lines[1].order_number).is_equal(1)


func test_208_4_6_waiting_trigger_outside_the_extra_ids_is_not_shown() -> void:
	var shown_id := _add_waiting_trigger(A, UNIT)
	_add_waiting_trigger(A, BUILDING)
	var extra: Array[int] = [shown_id]
	var lines := _model(A).stack_lines(extra)
	assert_int(lines.size()).is_equal(1)
	assert_int(lines[0].stack_entry_id).is_equal(shown_id)


func test_208_4_6_waiting_triggers_are_ignored_without_extra_ids() -> void:
	_add_waiting_trigger(A, UNIT)
	assert_array(_model(A).stack_lines()).is_empty()


func test_208_4_6_find_entry_looks_in_the_stack_then_in_waiting_triggers() -> void:
	var stacked_id := _builder.push_spell(_builder.make_card_instance(A, SPELL))
	var waiting_id := _add_waiting_trigger(A, UNIT)
	var model := _model(A)
	assert_int(model.find_entry(stacked_id).stack_entry_id).is_equal(stacked_id)
	assert_int(model.find_entry(waiting_id).stack_entry_id).is_equal(waiting_id)
	assert_object(model.find_entry(UNKNOWN_CARD_ID)).is_null()


func test_201_4_8_entry_definition_is_the_announced_card() -> void:
	_builder.push_spell(_builder.make_card_instance(A, SPELL))
	var entry := _builder.build().stack[0]
	assert_str(_model(B).entry_definition(entry).card_name).is_equal(SPELL_NAME)


func _model(viewer: DuelState.PlayerSide) -> DuelViewModel:
	return DuelViewModel.new(_builder.build(), _catalog, viewer)


func _drafting_snapshot(is_drafting: bool, draft: EssencePayment) -> SelectionSnapshot:
	var shown := SelectionSnapshot.new()
	shown.is_drafting_payment = is_drafting
	shown.draft_payment = draft
	return shown


func _decision(kind: PendingDecision.DecisionKind) -> PendingDecision:
	var decision := PendingDecision.new()
	decision.kind = kind
	decision.awaited_players.assign(DuelState.SIDES)
	return decision


func _make_trigger(side: DuelState.PlayerSide, source: StringName) -> StackEntry:
	var entry := StackEntry.new()
	entry.kind = StackEntry.StackEntryKind.TRIGGERED_EFFECT
	entry.owner = side
	entry.source_definition_id = source
	return entry


func _push_trigger(side: DuelState.PlayerSide, source: StringName) -> int:
	return _builder.push_stack_entry(_make_trigger(side, source))


func _add_waiting_trigger(side: DuelState.PlayerSide, source: StringName) -> int:
	var state := _builder.build()
	var entry := _make_trigger(side, source)
	entry.stack_entry_id = state.allocate_stack_entry_id()
	state.waiting_triggers.append(entry)
	return entry.stack_entry_id
