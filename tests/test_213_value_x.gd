# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## Valeur X (ruleset 0.53, chapitre 213 ; 209.4.4h et 209.4.11b ; décision 0058). Le coût X est
## choisi avec l'intention `CastSpell.x_value`, avant les cibles : le moteur ne l'attend pas par une
## attente, le temps de tour s'écoule donc tant que l'annonce n'est pas soumise (209.4.4h) et une
## annonce jamais soumise ne change rien (209.4.11b), comme pour les cibles (209.4.4d, 209.4.11).
## Cartes d'essai : ValueSamples (Exécution, Bénédiction, Furie, Sève).

const TURN_MSEC: int = 90_000  # 209.4.3
const STEP_MSEC: int = 1_000
const SOURCES: int = ValueSamples.SOURCES_IN_PLAY
const FORCE: int = ValueSamples.UNIT_FORCE
const EXECUTION: StringName = ValueSamples.EXECUTION
const BLESSING: StringName = ValueSamples.BLESSING
const FURY: StringName = ValueSamples.FURY
const SAP: StringName = ValueSamples.SAP

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const REASON := IntentRejected.RejectReason
const KIND := DuelState.ClockKind

var _builder: DuelStateBuilder
var _engine: DuelEngine


func before_test() -> void:
	var catalog := ValueSamples.catalog()
	_builder = ValueSamples.builder(catalog)
	_engine = DuelEngine.new(catalog)


# --- 213.1 : coût X ---


func test_213_1_1_the_cost_of_a_spell_can_be_x() -> void:
	var execution := CardDefinition.from_dict(_card(EXECUTION))
	assert_array(Array(execution.find_errors())).is_empty()
	assert_bool(execution.has_x_cost).is_true()
	assert_int(execution.cost).is_equal(0)
	var fixed := CardDefinition.from_dict(CatalogSamples.spell())
	assert_bool(fixed.has_x_cost).is_false()


func test_213_1_2_only_a_spell_has_an_x_cost() -> void:
	for sample: Dictionary in [
		CatalogSamples.unit(), CatalogSamples.building(), CatalogSamples.gear()
	]:
		var data := CatalogSamples.with_field(sample, "cost", "X")
		var errors := CardDefinition.from_dict(data).find_errors()
		assert_bool(CatalogSamples.mentions(errors, "213.1.2")).is_true()


func test_213_1_2_a_spell_without_x_cost_takes_no_value_of_x() -> void:
	var card_id := _builder.add_to_hand(A, FURY)
	_start()
	var intent := ValueSamples.cast_fixed(A, card_id, ValueSamples.FURY_COST)
	intent.x_value = 1
	(
		assert_array(
			Array(DuelChecks.rejection_defects(_engine, intent, REASON.UNEXPECTED_X_VALUE))
		)
		. is_empty()
	)


func test_213_1_3_the_player_chooses_x_when_announcing_the_spell() -> void:
	var card_id := _builder.add_to_hand(A, EXECUTION)
	var enemy_id := _place(B, "C4")
	_start()
	var events := _engine.submit(ValueSamples.cast(A, card_id, FORCE, [enemy_id]))
	assert_array(EventLog.describe(events)).contains_exactly(
		[
			"SourceInclined:A",
			"SourceInclined:A",
			"SourceInclined:A",
			"SpellAnnounced:A",
			"StackEntryAdded:A"
		]
	)
	assert_int(_engine.get_state().stack[0].x_value).is_equal(FORCE)


func test_213_1_4_x_is_at_least_one() -> void:
	var card_id := _builder.add_to_hand(A, BLESSING)
	var ally_id := _place(A, "B2")
	_start()
	for chosen: int in [0, -1]:
		var intent := ValueSamples.cast(A, card_id, 0, [ally_id])
		intent.x_value = chosen
		var defects := DuelChecks.rejection_defects(_engine, intent, REASON.X_VALUE_TOO_LOW)
		assert_array(Array(defects)).is_empty()
	var accepted := _engine.submit(ValueSamples.cast(A, card_id, 1, [ally_id]))
	assert_array(EventLog.describe(accepted)).contains_exactly(
		["SourceInclined:A", "SpellAnnounced:A", "StackEntryAdded:A"]
	)


func test_213_1_5_x_essence_is_paid_when_announcing() -> void:
	var card_id := _builder.add_to_hand(A, BLESSING)
	var ally_id := _place(A, "B2")
	_start()
	var short := ValueSamples.cast(A, card_id, 3, [ally_id])
	short.payment = EssencePayment.new(2)
	var defects := DuelChecks.rejection_defects(_engine, short, REASON.PAYMENT_DOES_NOT_MATCH_COST)
	assert_array(Array(defects)).is_empty()
	_engine.submit(ValueSamples.cast(A, card_id, 3, [ally_id]))
	var player := _engine.get_state().get_player(A)
	assert_int(player.sources_upright).is_equal(SOURCES - 3)
	assert_int(player.sources_tilted).is_equal(3)
	assert_int(player.essence_reserve).is_equal(0)


func test_213_1_6_the_cost_on_the_stack_is_the_chosen_x() -> void:
	var card_id := _builder.add_to_hand(A, BLESSING)
	var ally_id := _place(A, "B2")
	_start()
	_engine.submit(ValueSamples.cast(A, card_id, 4, [ally_id]))
	var entry := _engine.get_state().stack[0]
	var definition := _engine.get_state().catalog.get_card(BLESSING)
	assert_int(ValueRules.current_cost(definition, entry)).is_equal(4)


func test_213_1_7_x_is_zero_outside_the_stack() -> void:
	var catalog := ValueSamples.catalog()
	var definition := catalog.get_card(BLESSING)
	assert_int(ValueRules.current_cost(definition)).is_equal(0)
	var fixed := catalog.get_card(FURY)
	assert_int(ValueRules.current_cost(fixed)).is_equal(ValueSamples.FURY_COST)
	var card_id := _builder.add_to_hand(A, BLESSING)
	var ally_id := _place(A, "B2")
	_start()
	_engine.submit(ValueSamples.cast(A, card_id, 4, [ally_id]))
	DuelChecks.pass_until_stack_empty(_engine)
	var discard_card := _engine.get_state().get_player(A).discard[0]
	var in_discard := _engine.get_state().catalog.get_card(discard_card.definition_id)
	assert_int(ValueRules.current_cost(in_discard)).is_equal(0)


func test_213_1_8_x_keeps_its_value_until_the_end_of_the_resolution() -> void:
	var card_id := _builder.add_to_hand(A, BLESSING)
	var ally_id := _place(A, "B2")
	_start()
	_engine.submit(ValueSamples.cast(A, card_id, 4, [ally_id]))
	var state := _engine.get_state()
	assert_int(state.stack[0].x_value).is_equal(4)
	DuelChecks.pass_until_stack_empty(_engine)
	assert_int(ForceRules.current_force(state, state.find_piece(ally_id))).is_equal(FORCE + 4)
	assert_int(state.active_effects[0].amount).is_equal(4)


func test_213_1_9_x_is_chosen_before_the_targets() -> void:
	var card_id := _builder.add_to_hand(A, EXECUTION)
	var enemy_id := _place(B, "C4")
	_start()
	var bad_x := ValueSamples.cast(A, card_id, 0, [DuelState.NO_ID])
	bad_x.x_value = 0
	var defects := DuelChecks.rejection_defects(_engine, bad_x, REASON.X_VALUE_TOO_LOW)
	assert_array(Array(defects)).is_empty()
	var bad_target := ValueSamples.cast(A, card_id, FORCE, [DuelState.NO_ID])
	defects = DuelChecks.rejection_defects(_engine, bad_target, REASON.ILLEGAL_TARGET)
	assert_array(Array(defects)).is_empty()
	var good := ValueSamples.cast(A, card_id, FORCE, [enemy_id])
	assert_int(_engine.validate(good)).is_equal(REASON.NONE)


func test_213_1_10_legal_targets_are_read_with_the_chosen_x() -> void:
	var card_id := _builder.add_to_hand(A, EXECUTION)
	var enemy_id := _place(B, "C4")
	_start()
	var too_small := ValueSamples.cast(A, card_id, FORCE - 1, [enemy_id])
	var defects := DuelChecks.rejection_defects(_engine, too_small, REASON.ILLEGAL_TARGET)
	assert_array(Array(defects)).is_empty()
	assert_int(_engine.validate(ValueSamples.cast(A, card_id, FORCE, [enemy_id]))).is_equal(
		REASON.NONE
	)
	assert_int(_engine.validate(ValueSamples.cast(A, card_id, FORCE + 2, [enemy_id]))).is_equal(
		REASON.NONE
	)


func test_213_1_11_target_validity_at_resolution_uses_the_x_of_the_announcement() -> void:
	var card_id := _builder.add_to_hand(A, EXECUTION)
	var enemy_id := _place(B, "C4")
	_start()
	_engine.submit(ValueSamples.cast(A, card_id, FORCE, [enemy_id]))
	var state := _engine.get_state()
	var events := DuelChecks.pass_until_stack_empty(_engine)
	assert_object(state.find_piece(enemy_id)).is_null()
	assert_array(EventLog.describe(events)).contains(["PieceDestroyed:B"])


func test_213_1_11_a_target_that_no_longer_fits_x_loses_the_effect() -> void:
	var card_id := _builder.add_to_hand(A, EXECUTION)
	var enemy_id := _place(B, "C4")
	_start()
	_engine.submit(ValueSamples.cast(A, card_id, FORCE, [enemy_id]))
	_add_force(_engine.get_state(), enemy_id, 1)
	var events := DuelChecks.pass_until_stack_empty(_engine)
	assert_array(EventLog.describe(events)).contains(["EffectLostAllTargets:A"])
	assert_object(_engine.get_state().find_piece(enemy_id)).is_not_null()


func test_213_1_12_a_cost_x_is_x_alone() -> void:
	for text: String in ["X+1", "1X", "x", "X "]:
		var data := CatalogSamples.with_field(CatalogSamples.spell(), "cost", text)
		assert_bool(CardDefinition.from_dict(data).find_errors().is_empty()).is_false()
	var plain := CatalogSamples.with_field(CatalogSamples.spell(), "cost", "X")
	assert_array(Array(CardDefinition.from_dict(plain).find_errors())).is_empty()
	var card_id := _builder.add_to_hand(A, BLESSING)
	var ally_id := _place(A, "B2")
	_start()
	var upright_before := _engine.get_state().get_player(A).sources_upright
	_engine.submit(ValueSamples.cast(A, card_id, 2, [ally_id]))
	assert_int(upright_before - _engine.get_state().get_player(A).sources_upright).is_equal(2)


# --- 213.2 : X défini par un texte ---


func test_213_2_1_x_is_read_once_when_the_entry_resolves() -> void:
	var card_id := _builder.add_to_hand(A, FURY)
	var ally_id := _place(A, "B2")
	_start()
	_engine.submit(ValueSamples.cast_fixed(A, card_id, ValueSamples.FURY_COST, [ally_id]))
	_add_force(_engine.get_state(), ally_id, 2)
	DuelChecks.pass_until_stack_empty(_engine)
	var state := _engine.get_state()
	assert_int(KeywordRules.assault_value(state, state.find_piece(ally_id))).is_equal(FORCE + 2)


func test_213_2_2_x_no_longer_changes_after_it_is_read() -> void:
	var card_id := _builder.add_to_hand(A, FURY)
	var ally_id := _place(A, "B2")
	_start()
	_engine.submit(ValueSamples.cast_fixed(A, card_id, ValueSamples.FURY_COST, [ally_id]))
	DuelChecks.pass_until_stack_empty(_engine)
	var state := _engine.get_state()
	_add_force(state, ally_id, 2)
	assert_int(KeywordRules.assault_value(state, state.find_piece(ally_id))).is_equal(FORCE)
	assert_int(ForceRules.current_force(state, state.find_piece(ally_id))).is_equal(FORCE + 2)


func test_213_2_3_x_is_the_current_force_with_every_modifier() -> void:
	var card_id := _builder.add_to_hand(A, FURY)
	var ally_id := _place(A, "B2")
	_builder.attach_gear(ally_id, ValueSamples.FORCE_GEAR)
	_start()
	_add_force(_engine.get_state(), ally_id, 2)
	_engine.submit(ValueSamples.cast_fixed(A, card_id, ValueSamples.FURY_COST, [ally_id]))
	DuelChecks.pass_until_stack_empty(_engine)
	var state := _engine.get_state()
	var expected := FORCE + 2 + ValueSamples.GEAR_FORCE_BONUS
	assert_int(KeywordRules.assault_value(state, state.find_piece(ally_id))).is_equal(expected)


func test_213_2_4_assault_and_rampart_never_count_in_the_force_read() -> void:
	var fury_id := _builder.add_to_hand(A, FURY)
	var raider_id := _place_raider(A, "B2")
	_start()
	_engine.submit(ValueSamples.cast_fixed(A, fury_id, ValueSamples.FURY_COST, [raider_id]))
	DuelChecks.pass_until_stack_empty(_engine)
	var state := _engine.get_state()
	var printed := ValueSamples.RAIDER_ASSAULT
	var granted_total := KeywordRules.assault_value(state, state.find_piece(raider_id))
	assert_int(granted_total).is_equal(printed + FORCE)


func test_213_2_4_rampart_does_not_count_either() -> void:
	var guard_id := _place_guard(A, "B2")
	var sap_id := _builder.add_to_hand(A, SAP)
	_start()
	_engine.submit(ValueSamples.cast_fixed(A, sap_id, ValueSamples.SAP_COST, [guard_id]))
	DuelChecks.pass_until_stack_empty(_engine)
	var state := _engine.get_state()
	var expected := ValueSamples.GUARD_RAMPART + FORCE
	assert_int(KeywordRules.rampart_value(state, state.find_piece(guard_id))).is_equal(expected)


func test_213_2_5_the_player_does_not_choose_a_text_defined_x() -> void:
	var card_id := _builder.add_to_hand(A, FURY)
	var ally_id := _place(A, "B2")
	_start()
	var intent := ValueSamples.cast_fixed(A, card_id, ValueSamples.FURY_COST, [ally_id])
	intent.x_value = 2
	(
		assert_array(
			Array(DuelChecks.rejection_defects(_engine, intent, REASON.UNEXPECTED_X_VALUE))
		)
		. is_empty()
	)
	var fury := CardDefinition.from_dict(_card(FURY))
	assert_bool(fury.has_x_cost).is_false()
	assert_int(fury.cost).is_equal(ValueSamples.FURY_COST)


# --- 209.4.4h, 209.4.11b : le temps pendant le choix de X ---


func test_209_4_4h_turn_time_runs_while_x_is_being_chosen() -> void:
	var card_id := _builder.add_to_hand(A, EXECUTION)
	_start()
	assert_array(_engine.clock_owners()).contains_exactly([A])
	assert_int(_engine.clock_kind(A)).is_equal(KIND.TURN)
	assert_array(_engine.advance_clock(STEP_MSEC)).is_empty()
	assert_int(_engine.running_time_remaining_msec(A)).is_equal(TURN_MSEC - STEP_MSEC)
	var state := _engine.get_state()
	assert_object(state.pending_decision).is_null()
	assert_bool(DuelChecks.card_ids(state.get_player(A).hand).has(card_id)).is_true()


func test_209_4_11b_expiry_while_choosing_x_abandons_the_announcement() -> void:
	var card_id := _builder.add_to_hand(A, EXECUTION)
	_start()
	_engine.get_state().get_player(A).turn_time_remaining_msec = STEP_MSEC
	var events := _engine.advance_clock(STEP_MSEC)
	var labels := EventLog.describe(events)
	assert_array(labels.slice(0, 2)).contains_exactly(["TimeExpired:A", "TurnEnded:A"])
	assert_array(labels).not_contains(["SpellAnnounced:A"])
	var state := _engine.get_state()
	assert_bool(state.stack.is_empty()).is_true()
	assert_bool(DuelChecks.card_ids(state.get_player(A).hand).has(card_id)).is_true()
	assert_int(state.get_player(A).sources_upright).is_equal(SOURCES)
	assert_int(state.get_player(A).sources_tilted).is_equal(0)


# --- montage ---


func _start() -> void:
	_engine.start_from_state(_builder.build())


func _card(card_id: StringName) -> Dictionary:
	for data: Dictionary in ValueSamples.card_data():
		if data["id"] == String(card_id):
			return data
	return {}


func _place(side: DuelState.PlayerSide, cell_name: String) -> int:
	return _builder.place_piece(
		side, Piece.PieceKind.UNIT, DuelStateBuilder.cell(cell_name), ValueSamples.SOLDIER
	)


func _place_raider(side: DuelState.PlayerSide, cell_name: String) -> int:
	return _builder.place_piece(
		side, Piece.PieceKind.UNIT, DuelStateBuilder.cell(cell_name), ValueSamples.RAIDER
	)


func _place_guard(side: DuelState.PlayerSide, cell_name: String) -> int:
	return _builder.place_piece(
		side, Piece.PieceKind.UNIT, DuelStateBuilder.cell(cell_name), ValueSamples.GUARD
	)


# Modificateur de Force en cours sur la pièce, comme un effet résolu entre-temps (207.4.2).
func _add_force(state: DuelState, piece_id: int, amount: int) -> void:
	var effect := ActiveEffect.new()
	effect.effect_id = state.allocate_active_effect_id()
	effect.affected_piece_id = piece_id
	effect.effect_kind = EffectDefinition.kind_id(EffectDefinition.EffectKind.MODIFY_FORCE)
	effect.amount = amount
	state.active_effects.append(effect)
