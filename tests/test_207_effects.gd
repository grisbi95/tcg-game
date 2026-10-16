# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## EffectRules : cibles et validité, application des effets, Contrecarrer (ruleset 0.32,
## sections 207.4 à 207.6 ; 202.4 pour les jetons).

const UNIT_ID: StringName = &"effect_unit"
const BIG_ID: StringName = &"big_unit"
const BUILDING_ID: StringName = &"effect_building"
const SPELL_ID: StringName = &"sample_spell"
const UNIT_FORCE: int = 3
const BIG_FORCE: int = 6
const BOOST: int = 2  # CatalogSamples.modify_force_resolve()
const DESTROY_MAX_FORCE: int = 3  # CatalogSamples.destroy_effect()
const TOKEN_FORCE: int = 2  # CatalogSamples.create_token_effect()

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const REASON := IntentRejected.RejectReason

var _builder: DuelStateBuilder
var _events: Array[DuelEvent]


func before_test() -> void:
	var catalog := Catalog.new()
	SetupSamples.add_unit(catalog, UNIT_ID, UNIT_FORCE)
	SetupSamples.add_unit(catalog, BIG_ID, BIG_FORCE)
	SetupSamples.add_building(catalog, BUILDING_ID, 4)
	catalog.add_card(CardDefinition.from_dict(CatalogSamples.spell()))
	_builder = DuelStateBuilder.new(DuelConfig.new(), catalog)
	_events = []


func test_207_5_11_ally_unit_target_accepts_only_allied_units() -> void:
	var ally_id := _place(A, UNIT_ID, "B2")
	var enemy_id := _place(B, UNIT_ID, "B4")
	var building_id := _builder.place_piece(
		A, Piece.PieceKind.BUILDING, DuelStateBuilder.cell("D2"), BUILDING_ID
	)
	var state := _builder.build()
	var spec := _boost().target
	assert_bool(EffectRules.is_legal_piece(state, A, spec, state.find_piece(ally_id))).is_true()
	assert_bool(EffectRules.is_legal_piece(state, A, spec, state.find_piece(enemy_id))).is_false()
	(
		assert_bool(EffectRules.is_legal_piece(state, A, spec, state.find_piece(building_id)))
		. is_false()
	)
	assert_bool(EffectRules.is_legal_piece(state, A, spec, state.find_hero(A))).is_false()


func test_207_5_11a_hero_can_be_targeted() -> void:
	var state := _builder.build()
	var spec := TargetSpec.new()
	assert_bool(EffectRules.is_legal_piece(state, A, spec, state.find_hero(B))).is_true()


func test_207_5_11b_token_can_be_targeted() -> void:
	var token_id := _builder.place_token(A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B2"), 1)
	var state := _builder.build()
	var spec := _boost().target
	assert_bool(EffectRules.is_legal_piece(state, A, spec, state.find_piece(token_id))).is_true()


func test_207_5_6_force_condition_read_on_current_force() -> void:
	var small_id := _place(B, UNIT_ID, "B4")
	var big_id := _place(B, BIG_ID, "D4")
	var state := _builder.build()
	var spec := _destroy().target
	assert_bool(EffectRules.is_legal_piece(state, A, spec, state.find_piece(small_id))).is_true()
	assert_bool(EffectRules.is_legal_piece(state, A, spec, state.find_piece(big_id))).is_false()


func test_202_4_12_token_targets_free_cell_of_own_first_row() -> void:
	var state := _builder.build()
	var spec := _token().target
	assert_bool(EffectRules.is_legal_cell(state, A, spec, DuelStateBuilder.cell("B1"))).is_true()
	assert_bool(EffectRules.is_legal_cell(state, A, spec, DuelStateBuilder.cell("C1"))).is_false()
	assert_bool(EffectRules.is_legal_cell(state, A, spec, DuelStateBuilder.cell("B2"))).is_false()


func test_207_5_14_spell_on_stack_can_be_targeted() -> void:
	var spell_id := _builder.push_spell(_builder.make_card_instance(B, SPELL_ID))
	var state := _builder.build()
	var spec := _counter().target
	var spell := state.find_stack_entry(spell_id)
	assert_bool(EffectRules.is_legal_spell(spec, spell, DuelState.NO_ID)).is_true()


func test_207_5_15_deploy_on_stack_cannot_be_targeted() -> void:
	var deploy_id := _builder.push_deploy(
		_builder.make_card_instance(B, UNIT_ID), DuelStateBuilder.cell("B5")
	)
	var state := _builder.build()
	var spec := _counter().target
	var deploy := state.find_stack_entry(deploy_id)
	assert_bool(EffectRules.is_legal_spell(spec, deploy, DuelState.NO_ID)).is_false()


func test_207_5_16_entry_never_targets_itself() -> void:
	var spell_id := _builder.push_spell(_builder.make_card_instance(B, SPELL_ID))
	var state := _builder.build()
	var spell := state.find_stack_entry(spell_id)
	assert_bool(EffectRules.is_legal_spell(_counter().target, spell, spell_id)).is_false()


func test_207_5_10_target_count_must_fit_the_card() -> void:
	var ally_id := _place(A, UNIT_ID, "B2")
	var state := _builder.build()
	var spec := _boost().target
	var none := _entry(A, [] as Array[int])
	var two := _entry(A, [ally_id, ally_id] as Array[int])
	assert_int(EffectRules.validate_targets(state, none, spec)).is_equal(REASON.WRONG_TARGET_COUNT)
	assert_int(EffectRules.validate_targets(state, two, spec)).is_equal(REASON.WRONG_TARGET_COUNT)


func test_207_5_8_spell_needs_a_legal_target() -> void:
	var enemy_id := _place(B, UNIT_ID, "B4")
	var state := _builder.build()
	var spec := _boost().target
	assert_int(EffectRules.legal_target_count(state, A, spec)).is_equal(0)
	var entry := _entry(A, [enemy_id] as Array[int])
	assert_int(EffectRules.validate_targets(state, entry, spec)).is_equal(REASON.ILLEGAL_TARGET)


func test_same_target_twice_rejected() -> void:
	var first_id := _place(A, UNIT_ID, "B2")
	var state := _builder.build()
	var spec := _boost().target
	spec.count_max = 2
	var entry := _entry(A, [first_id, first_id] as Array[int])
	assert_int(EffectRules.validate_targets(state, entry, spec)).is_equal(REASON.DUPLICATE_TARGET)


func test_207_5_2_targets_are_judged_for_the_entry_owner() -> void:
	var unit_id := _place(B, UNIT_ID, "B4")
	var state := _builder.build()
	var spec := _boost().target
	var entry := _entry(B, [unit_id] as Array[int])
	assert_int(EffectRules.validate_targets(state, entry, spec)).is_equal(REASON.NONE)


func test_207_4_2_force_modifier_lasts_with_its_duration() -> void:
	var ally_id := _place(A, UNIT_ID, "B2")
	var state := _builder.build()
	var applied := EffectRules.resolve_effect(
		state, _entry(A, [ally_id] as Array[int]), _boost(), _events
	)
	assert_bool(applied).is_true()
	assert_array(EventLog.describe(_events)).contains_exactly(["ForceModified:A"])
	assert_int(ForceRules.current_force(state, state.find_piece(ally_id))).is_equal(
		UNIT_FORCE + BOOST
	)
	var modifier := state.active_effects[0]
	assert_int(modifier.duration).is_equal(ActiveEffect.EffectDuration.UNTIL_END_OF_TURN)


func test_207_5_4_effect_applies_to_each_target_still_valid() -> void:
	var first_id := _place(A, UNIT_ID, "B2")
	var second_id := _place(A, UNIT_ID, "D2")
	var state := _builder.build()
	var effect := _boost()
	effect.target.count_max = 2
	var entry := _entry(A, [first_id, second_id] as Array[int])
	state.pieces.erase(state.find_piece(first_id))
	EffectRules.resolve_effect(state, entry, effect, _events)
	assert_array(EventLog.describe(_events)).contains_exactly(["ForceModified:A"])
	assert_int((_events[0] as ForceModified).piece_id).is_equal(second_id)


func test_207_5_3_target_gone_is_lost() -> void:
	var ally_id := _place(A, UNIT_ID, "B2")
	var state := _builder.build()
	var entry := _entry(A, [ally_id] as Array[int])
	state.pieces.erase(state.find_piece(ally_id))
	assert_bool(EffectRules.resolve_effect(state, entry, _boost(), _events)).is_false()


func test_207_5_5_effect_without_any_valid_target_does_not_happen() -> void:
	var ally_id := _place(A, UNIT_ID, "B2")
	var state := _builder.build()
	var entry := _entry(A, [ally_id] as Array[int])
	state.pieces.erase(state.find_piece(ally_id))
	EffectRules.resolve_effect(state, entry, _boost(), _events)
	assert_array(EventLog.describe(_events)).contains_exactly(["EffectLostAllTargets:A"])
	assert_array(state.active_effects).is_empty()


func test_207_5_6a_target_no_longer_meeting_conditions_is_invalid() -> void:
	var enemy_id := _place(B, UNIT_ID, "B4")
	var boost := ActiveEffect.new()
	boost.affected_piece_id = enemy_id
	boost.effect_kind = EffectDefinition.kind_id(EffectDefinition.EffectKind.MODIFY_FORCE)
	boost.amount = DESTROY_MAX_FORCE
	_builder.add_active_effect(boost)
	var state := _builder.build()
	EffectRules.resolve_effect(state, _entry(A, [enemy_id] as Array[int]), _destroy(), _events)
	assert_object(state.find_piece(enemy_id)).is_not_null()
	assert_array(EventLog.describe(_events)).contains_exactly(["EffectLostAllTargets:A"])


func test_206_3_1_destroy_effect_sends_unit_to_discard() -> void:
	var enemy_id := _place(B, UNIT_ID, "B4")
	var state := _builder.build()
	EffectRules.resolve_effect(state, _entry(A, [enemy_id] as Array[int]), _destroy(), _events)
	assert_object(state.find_piece(enemy_id)).is_null()
	assert_int(state.get_player(B).discard.size()).is_equal(1)
	assert_array(EventLog.describe(_events)).contains_exactly(["PieceDestroyed:B"])


func test_202_4_1_create_token_effect_creates_a_piece() -> void:
	var state := _builder.build()
	var entry := _cell_entry(A, "B1")
	EffectRules.resolve_effect(state, entry, _token(), _events)
	assert_array(EventLog.describe(_events)).contains_exactly(["TokenCreated:A"])
	var token := state.piece_at(DuelStateBuilder.cell("B1"))
	assert_bool(token.is_token()).is_true()


func test_202_4_8_token_type_given_by_its_effect() -> void:
	var state := _builder.build()
	EffectRules.resolve_effect(state, _cell_entry(A, "B1"), _token(), _events)
	assert_int(state.piece_at(DuelStateBuilder.cell("B1")).kind).is_equal(Piece.PieceKind.UNIT)


func test_202_4_9_token_force_given_by_its_effect() -> void:
	var state := _builder.build()
	EffectRules.resolve_effect(state, _cell_entry(A, "B1"), _token(), _events)
	var token := state.piece_at(DuelStateBuilder.cell("B1"))
	assert_int(ForceRules.current_force(state, token)).is_equal(TOKEN_FORCE)


func test_201_5_4_token_belongs_to_owner_of_creating_entry() -> void:
	var state := _builder.build()
	EffectRules.resolve_effect(state, _cell_entry(B, "B5"), _token(), _events)
	assert_int(state.piece_at(DuelStateBuilder.cell("B5")).owner).is_equal(B)


func test_202_4_12c_token_not_created_when_cell_taken_at_resolution() -> void:
	var state := _builder.build()
	var entry := _cell_entry(A, "B1")
	DuelStateBuilder.place_unit_in(state, B, UNIT_ID, "B1")
	EffectRules.resolve_effect(state, entry, _token(), _events)
	assert_array(EventLog.describe(_events)).contains_exactly(["EffectLostAllTargets:A"])


func test_207_6_4_countered_spell_does_not_happen() -> void:
	var spell_id := _builder.push_spell(_builder.make_card_instance(B, SPELL_ID))
	var state := _builder.build()
	EffectRules.resolve_effect(state, _spell_entry(A, spell_id), _counter(), _events)
	assert_object(state.find_stack_entry(spell_id)).is_null()
	assert_array(EventLog.describe(_events)).contains_exactly(["SpellCountered:B"])


func test_207_6_5_countered_spell_goes_to_owner_discard() -> void:
	var card := _builder.make_card_instance(B, SPELL_ID)
	var spell_id := _builder.push_spell(card)
	var state := _builder.build()
	EffectRules.resolve_effect(state, _spell_entry(A, spell_id), _counter(), _events)
	var discard := state.get_player(B).discard
	assert_int(discard[0].card_instance_id).is_equal(card.card_instance_id)


func test_207_6_6_countered_spell_cost_stays_spent() -> void:
	_builder.with_sources_in_play(B, 1, 1)
	var spell_id := _builder.push_spell(_builder.make_card_instance(B, SPELL_ID))
	var state := _builder.build()
	EffectRules.resolve_effect(state, _spell_entry(A, spell_id), _counter(), _events)
	assert_int(state.get_player(B).sources_tilted).is_equal(1)


func test_207_4_7a_effect_ends_for_piece_leaving_the_board() -> void:
	var ally_id := _place(A, UNIT_ID, "B2")
	var other_id := _place(A, UNIT_ID, "D2")
	var state := _builder.build()
	var effect := _boost()
	effect.duration = ActiveEffect.EffectDuration.WHILE_PIECE_IN_PLAY
	effect.target.count_max = 2
	EffectRules.resolve_effect(state, _entry(A, [ally_id, other_id] as Array[int]), effect, _events)
	CombatRules.destroy_piece(state, state.find_piece(ally_id), _events)
	assert_int(state.active_effects.size()).is_equal(1)
	assert_int(state.active_effects[0].affected_piece_id).is_equal(other_id)


func test_207_4_7b_effect_continues_for_pieces_still_on_board() -> void:
	var ally_id := _place(A, UNIT_ID, "B2")
	var other_id := _place(A, UNIT_ID, "D2")
	var state := _builder.build()
	var effect := _boost()
	effect.duration = ActiveEffect.EffectDuration.WHILE_PIECE_IN_PLAY
	effect.target.count_max = 2
	EffectRules.resolve_effect(state, _entry(A, [ally_id, other_id] as Array[int]), effect, _events)
	CombatRules.destroy_piece(state, state.find_piece(ally_id), _events)
	assert_int(ForceRules.current_force(state, state.find_piece(other_id))).is_equal(
		UNIT_FORCE + BOOST
	)


func _place(side: DuelState.PlayerSide, definition_id: StringName, cell_name: String) -> int:
	return _builder.place_piece(
		side, Piece.PieceKind.UNIT, DuelStateBuilder.cell(cell_name), definition_id
	)


func _entry(side: DuelState.PlayerSide, piece_ids: Array[int]) -> StackEntry:
	var entry := StackEntry.new()
	entry.kind = StackEntry.StackEntryKind.SPELL
	entry.owner = side
	entry.target_piece_ids.assign(piece_ids)
	return entry


func _cell_entry(side: DuelState.PlayerSide, cell_name: String) -> StackEntry:
	var entry := _entry(side, [] as Array[int])
	entry.target_cells.append(DuelStateBuilder.cell(cell_name))
	return entry


func _spell_entry(side: DuelState.PlayerSide, spell_id: int) -> StackEntry:
	var entry := _entry(side, [] as Array[int])
	entry.target_stack_entry_ids.append(spell_id)
	return entry


func _boost() -> EffectDefinition:
	return EffectDefinition.from_dict(CatalogSamples.modify_force_resolve())


func _destroy() -> EffectDefinition:
	return EffectDefinition.from_dict(CatalogSamples.destroy_effect())


func _token() -> EffectDefinition:
	return EffectDefinition.from_dict(CatalogSamples.create_token_effect())


func _counter() -> EffectDefinition:
	return EffectDefinition.from_dict(CatalogSamples.counter_spell_effect())
