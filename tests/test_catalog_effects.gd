# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## Catalogue : effets, cibles et mots-clés (ruleset 0.53, décisions 0002, 0010, 0056 et 0057).
## Ne résout aucun effet : ces tests vérifient que le catalogue refuse une définition incohérente.


func _effect_errors(data: Dictionary) -> PackedStringArray:
	return EffectDefinition.from_dict(data).find_errors()


func _target_errors(data: Dictionary) -> PackedStringArray:
	return TargetSpec.from_dict(data).find_errors()


func _card_errors(data: Dictionary) -> PackedStringArray:
	return CardDefinition.from_dict(data).find_errors()


func _mentions(errors: PackedStringArray, fragment: String) -> bool:
	return CatalogSamples.mentions(errors, fragment)


func _with_effects(card: Dictionary, effects: Array) -> Dictionary:
	return CatalogSamples.with_field(card, "effects", effects)


func _with_keywords(card: Dictionary, keywords: Array) -> Dictionary:
	return CatalogSamples.with_field(card, "keywords", keywords)


func test_every_effect_kind_has_a_valid_sample() -> void:
	var samples: Array[Dictionary] = [
		CatalogSamples.modify_force_resolve(),
		CatalogSamples.destroy_effect(),
		CatalogSamples.counter_spell_effect(),
		CatalogSamples.create_token_effect(),
		CatalogSamples.swap_cells_effect(),
		CatalogSamples.move_unit_effect(),
		CatalogSamples.return_to_hand_effect(),
	]
	samples.append_array(HandEffectSamples.effect_samples())
	assert_int(EffectDefinition.EffectKind.size()).is_equal(samples.size())
	for sample: Dictionary in samples:
		assert_array(Array(_effect_errors(sample))).is_empty()


func test_effect_kind_ids_match_active_effect_kind_names() -> void:
	assert_str(EffectDefinition.kind_id(EffectDefinition.EffectKind.MODIFY_FORCE)).is_equal(
		"modify_force"
	)
	assert_str(EffectDefinition.kind_id(EffectDefinition.EffectKind.CREATE_TOKEN)).is_equal(
		"create_token"
	)


func test_202_3_9_force_or_destroy_effect_never_targets_a_hero() -> void:
	for sample: Dictionary in [
		CatalogSamples.modify_force_resolve(), CatalogSamples.destroy_effect()
	]:
		var target: Dictionary = sample["target"]
		target["piece_kinds"] = ["unit", "hero"]
		assert_bool(_mentions(_effect_errors(sample), "202.3.9")).is_true()


func test_effect_kind_is_required_and_closed() -> void:
	var missing := _effect_errors(
		CatalogSamples.without_field(CatalogSamples.destroy_effect(), "kind")
	)
	var unknown := _effect_errors(
		CatalogSamples.with_field(CatalogSamples.destroy_effect(), "kind", "draw_card")
	)
	assert_bool(_mentions(missing, "« kind » absent")).is_true()
	assert_bool(_mentions(unknown, "« draw_card » inconnu")).is_true()


func test_207_3_1_triggered_effect_names_its_event() -> void:
	var data := CatalogSamples.triggered("arrival")
	data.erase("trigger")
	assert_bool(_mentions(_effect_errors(data), "207.3.1")).is_true()


func test_207_3_1_trigger_is_only_for_triggered_effects() -> void:
	var data := CatalogSamples.with_field(CatalogSamples.destroy_effect(), "trigger", "arrival")
	assert_bool(_mentions(_effect_errors(data), "207.3.1")).is_true()


func test_207_3_1_trigger_events_are_a_closed_list() -> void:
	for trigger: String in ["arrival", "destroyed", "end_of_turn"]:
		assert_array(Array(_effect_errors(CatalogSamples.triggered(trigger)))).is_empty()
	var unknown := _effect_errors(CatalogSamples.triggered("moved"))
	assert_bool(_mentions(unknown, "« moved » inconnu")).is_true()


func test_204_5_3_end_of_turn_is_a_trigger_event() -> void:
	assert_array(Array(_effect_errors(CatalogSamples.triggered("end_of_turn")))).is_empty()


func test_207_3_5_once_per_turn_is_read_for_a_triggered_effect() -> void:
	var data := CatalogSamples.triggered("arrival", {"once_per_turn": true})
	var effect := EffectDefinition.from_dict(data)
	assert_array(Array(effect.find_errors())).is_empty()
	assert_bool(effect.once_per_turn).is_true()
	(
		assert_bool(EffectDefinition.from_dict(CatalogSamples.triggered("arrival")).once_per_turn)
		. is_false()
	)


func test_207_3_5_once_per_turn_card_has_a_single_triggered_effect() -> void:
	var marked := CatalogSamples.triggered("arrival", {"once_per_turn": true})
	var second := CatalogSamples.triggered("destroyed")
	var keywords := [{"keyword": "arrival"}, {"keyword": "last_breath"}]
	var card := _with_keywords(_with_effects(CatalogSamples.unit(), [marked, second]), keywords)
	var single := _with_keywords(_with_effects(CatalogSamples.unit(), [marked]), [keywords[0]])
	assert_bool(_mentions(_card_errors(card), "207.3.5")).is_true()
	assert_array(Array(_card_errors(single))).is_empty()


func test_207_3_5_once_per_turn_is_only_for_triggered_effects() -> void:
	var data := CatalogSamples.modify_force_resolve({"once_per_turn": true})
	assert_bool(_mentions(_effect_errors(data), "207.3.5")).is_true()


func test_207_3_5_once_per_turn_is_a_boolean() -> void:
	var data := CatalogSamples.triggered("arrival", {"once_per_turn": "oui"})
	(
		assert_bool(_mentions(_effect_errors(data), "« once_per_turn » doit être vrai ou faux"))
		. is_true()
	)


func test_207_2_2_static_effect_names_its_scope() -> void:
	var data := CatalogSamples.without_field(CatalogSamples.modify_force_static(), "scope")
	assert_bool(_mentions(_effect_errors(data), "207.2.2")).is_true()


func test_207_2_1_scope_is_only_for_static_effects() -> void:
	var data := CatalogSamples.with_field(CatalogSamples.modify_force_resolve(), "scope", "bearer")
	assert_bool(_mentions(_effect_errors(data), "207.2.1")).is_true()


func test_207_5_1_static_effect_has_no_target() -> void:
	var data := CatalogSamples.with_field(
		CatalogSamples.modify_force_static(), "target", CatalogSamples.ally_unit_target()
	)
	assert_bool(_mentions(_effect_errors(data), "207.5.1")).is_true()


func test_207_5_1_stack_effect_has_a_target() -> void:
	var data := CatalogSamples.without_field(CatalogSamples.modify_force_resolve(), "target")
	assert_bool(_mentions(_effect_errors(data), "207.5.1")).is_true()


func test_207_4_10_static_effect_has_no_duration() -> void:
	var data := CatalogSamples.with_field(
		CatalogSamples.modify_force_static(), "duration", "until_end_of_turn"
	)
	assert_bool(_mentions(_effect_errors(data), "207.4.10")).is_true()


func test_207_4_2_force_effect_off_the_static_path_has_a_duration() -> void:
	var data := CatalogSamples.without_field(CatalogSamples.modify_force_resolve(), "duration")
	assert_bool(_mentions(_effect_errors(data), "207.4.2")).is_true()


func test_207_4_2_durations_are_end_of_turn_and_while_in_play() -> void:
	for duration: String in ["until_end_of_turn", "while_piece_in_play"]:
		var data := CatalogSamples.with_field(
			CatalogSamples.modify_force_resolve(), "duration", duration
		)
		assert_array(Array(_effect_errors(data))).is_empty()
	var unknown := CatalogSamples.with_field(
		CatalogSamples.modify_force_resolve(), "duration", "forever"
	)
	assert_bool(_mentions(_effect_errors(unknown), "« forever » inconnu")).is_true()


func test_207_4_9_effect_without_duration_is_a_one_shot() -> void:
	var data := CatalogSamples.with_field(
		CatalogSamples.destroy_effect(), "duration", "until_end_of_turn"
	)
	assert_bool(_mentions(_effect_errors(data), "207.4.9")).is_true()


func test_206_5_1_modify_force_has_a_non_zero_amount() -> void:
	var missing := CatalogSamples.without_field(CatalogSamples.modify_force_resolve(), "amount")
	var zero := CatalogSamples.with_field(CatalogSamples.modify_force_resolve(), "amount", 0)
	var stray := CatalogSamples.with_field(CatalogSamples.destroy_effect(), "amount", 2)
	assert_bool(_mentions(_effect_errors(missing), "206.5.1")).is_true()
	assert_bool(_mentions(_effect_errors(zero), "206.5.1")).is_true()
	assert_bool(_mentions(_effect_errors(stray), "206.5.1")).is_true()


func test_206_5_1_modify_force_accepts_a_negative_amount() -> void:
	var data := CatalogSamples.with_field(CatalogSamples.modify_force_resolve(), "amount", -1)
	assert_array(Array(_effect_errors(data))).is_empty()


func test_202_4_7_static_effect_creates_no_token() -> void:
	var data := CatalogSamples.with_field(CatalogSamples.create_token_effect(), "timing", "static")
	assert_bool(_mentions(_effect_errors(data), "202.4.7")).is_true()


func test_202_4_8_token_is_a_unit_or_a_building() -> void:
	var missing := CatalogSamples.without_field(
		CatalogSamples.create_token_effect(), "token_piece_kind"
	)
	var hero := CatalogSamples.with_field(
		CatalogSamples.create_token_effect(), "token_piece_kind", "hero"
	)
	var building := CatalogSamples.with_field(
		CatalogSamples.create_token_effect(), "token_piece_kind", "building"
	)
	assert_bool(_mentions(_effect_errors(missing), "202.4.8")).is_true()
	assert_bool(_mentions(_effect_errors(hero), "202.4.8")).is_true()
	assert_array(Array(_effect_errors(building))).is_empty()


func test_202_4_9_token_has_a_force() -> void:
	var missing := CatalogSamples.without_field(CatalogSamples.create_token_effect(), "token_force")
	var zero := CatalogSamples.with_field(CatalogSamples.create_token_effect(), "token_force", 0)
	assert_bool(_mentions(_effect_errors(missing), "202.4.9")).is_true()
	assert_array(Array(_effect_errors(zero))).is_empty()


func test_202_4_1_token_fields_are_only_for_create_token() -> void:
	var data := CatalogSamples.with_field(CatalogSamples.destroy_effect(), "token_force", 2)
	assert_bool(_mentions(_effect_errors(data), "202.4.1")).is_true()


func test_202_4_12_token_targets_a_cell() -> void:
	var data := CatalogSamples.with_field(
		CatalogSamples.create_token_effect(), "target", CatalogSamples.ally_unit_target()
	)
	assert_bool(_mentions(_effect_errors(data), "202.4.12")).is_true()


func test_207_6_2_counter_spell_targets_a_spell_on_the_stack() -> void:
	var data := CatalogSamples.with_field(
		CatalogSamples.counter_spell_effect(), "target", CatalogSamples.ally_unit_target()
	)
	assert_bool(_mentions(_effect_errors(data), "207.6.2")).is_true()


func test_207_5_11_piece_effect_targets_a_piece() -> void:
	var data := CatalogSamples.with_field(
		CatalogSamples.destroy_effect(), "target", {"what": "cell"}
	)
	assert_bool(_mentions(_effect_errors(data), "207.5.11")).is_true()


func test_207_5_11_target_what_is_required_and_closed() -> void:
	var missing := _target_errors({"piece_kinds": ["unit"]})
	var unknown := _target_errors({"what": "deck"})
	assert_bool(_mentions(missing, "207.5.11 : champ « what » absent")).is_true()
	assert_bool(_mentions(unknown, "« deck » inconnu")).is_true()


func test_207_5_11_piece_target_names_its_kinds() -> void:
	var errors := _target_errors({"what": "piece", "side": "enemy"})
	assert_bool(_mentions(errors, "piece_kinds")).is_true()


func test_207_5_11a_hero_and_token_pieces_can_be_targeted() -> void:
	var spec := TargetSpec.from_dict({"what": "piece", "piece_kinds": ["hero", "unit", "building"]})
	assert_array(Array(spec.find_errors())).is_empty()
	assert_array(spec.piece_kinds).contains_exactly(
		[Piece.PieceKind.HERO, Piece.PieceKind.UNIT, Piece.PieceKind.BUILDING]
	)


func test_207_5_11_cell_target_takes_no_piece_filter() -> void:
	var errors := _target_errors({"what": "cell", "side": "ally"})
	assert_bool(_mentions(errors, "207.5.11")).is_true()


func test_207_5_14_spell_target_takes_no_piece_filter() -> void:
	var errors := _target_errors({"what": "spell_on_stack", "max_force": 2})
	assert_bool(_mentions(errors, "207.5.14")).is_true()


func test_202_3_9_max_force_excludes_the_hero_kind() -> void:
	var errors := _target_errors({"what": "piece", "piece_kinds": ["hero"], "max_force": 3})
	assert_bool(_mentions(errors, "202.3.9")).is_true()


func test_207_5_10_target_count_bounds() -> void:
	var valid := _target_errors({"what": "piece", "piece_kinds": ["unit"], "count_max": 2})
	var inverted := _target_errors(
		{"what": "piece", "piece_kinds": ["unit"], "count_min": 2, "count_max": 1}
	)
	var zero := _target_errors({"what": "piece", "piece_kinds": ["unit"], "count_min": 0})
	assert_array(Array(valid)).is_empty()
	assert_bool(_mentions(inverted, "207.5.10")).is_true()
	assert_bool(_mentions(zero, "207.5.10")).is_true()


func test_target_defaults_to_exactly_one() -> void:
	var spec := TargetSpec.from_dict({"what": "piece", "piece_kinds": ["unit"]})
	assert_int(spec.count_min).is_equal(1)
	assert_int(spec.count_max).is_equal(1)
	assert_int(spec.max_force).is_equal(TargetSpec.NO_FORCE_LIMIT)


func test_target_errors_surface_through_the_effect() -> void:
	var data := CatalogSamples.with_field(
		CatalogSamples.destroy_effect(), "target", {"what": "piece"}
	)
	assert_bool(_mentions(_effect_errors(data), "cible : 207.5.11")).is_true()


func test_210_1_1_valued_keywords_need_a_value() -> void:
	var assault := _with_keywords(CatalogSamples.unit(), [{"keyword": "assault"}])
	var zero := _with_keywords(CatalogSamples.unit(), [{"keyword": "rampart", "value": 0}])
	assert_bool(_mentions(_card_errors(assault), "210.1.1")).is_true()
	assert_bool(_mentions(_card_errors(zero), "210.1.1")).is_true()


func test_210_1_3_the_card_fixes_the_value() -> void:
	var card := CardDefinition.from_dict(
		_with_keywords(CatalogSamples.unit(), [{"keyword": "assault", "value": 2}])
	)
	assert_array(Array(card.find_errors())).is_empty()
	assert_int(card.keyword_value(CardDefinition.Keyword.ASSAULT)).is_equal(2)
	assert_bool(card.has_keyword(CardDefinition.Keyword.RAMPART)).is_false()


func test_210_1_1_valueless_keywords_take_no_value() -> void:
	var data := _with_keywords(CatalogSamples.building(), [{"keyword": "outpost", "value": 1}])
	assert_bool(_mentions(_card_errors(data), "210.1.1")).is_true()


func test_210_2_1_outpost_is_a_building_keyword() -> void:
	var building := _with_keywords(CatalogSamples.building(), [{"keyword": "outpost"}])
	var unit := _with_keywords(CatalogSamples.unit(), [{"keyword": "outpost"}])
	assert_array(Array(_card_errors(building))).is_empty()
	assert_bool(_mentions(_card_errors(unit), "OUTPOST est refusé")).is_true()


func test_210_3_1c_arrival_is_for_units_and_buildings() -> void:
	var spell := _with_keywords(CatalogSamples.spell(), [{"keyword": "arrival"}])
	var gear := _with_keywords(CatalogSamples.gear(), [{"keyword": "last_breath"}])
	assert_bool(_mentions(_card_errors(spell), "ARRIVAL est refusé")).is_true()
	assert_bool(_mentions(_card_errors(gear), "LAST_BREATH est refusé")).is_true()


func test_210_4_1c_assault_and_rampart_are_for_units_only() -> void:
	var building := _with_keywords(CatalogSamples.building(), [{"keyword": "assault", "value": 1}])
	var rampart := _with_keywords(CatalogSamples.building(), [{"keyword": "rampart", "value": 1}])
	assert_bool(_mentions(_card_errors(building), "ASSAULT est refusé")).is_true()
	assert_bool(_mentions(_card_errors(rampart), "RAMPART est refusé")).is_true()


func test_210_3_1b_arrival_is_a_triggered_effect() -> void:
	var complete := _with_effects(
		_with_keywords(CatalogSamples.unit(), [{"keyword": "arrival"}]),
		[CatalogSamples.triggered("arrival")]
	)
	var keyword_only := _with_keywords(CatalogSamples.unit(), [{"keyword": "arrival"}])
	var effect_only := _with_effects(CatalogSamples.unit(), [CatalogSamples.triggered("arrival")])
	assert_array(Array(_card_errors(complete))).is_empty()
	assert_bool(_mentions(_card_errors(keyword_only), "ARRIVAL exige un effet")).is_true()
	assert_bool(_mentions(_card_errors(effect_only), "exige le mot-clé")).is_true()


func test_210_3_2a_last_breath_is_a_triggered_effect() -> void:
	var complete := _with_effects(
		_with_keywords(CatalogSamples.unit(), [{"keyword": "last_breath"}]),
		[CatalogSamples.triggered("destroyed")]
	)
	var keyword_only := _with_keywords(CatalogSamples.unit(), [{"keyword": "last_breath"}])
	var wrong_event := _with_effects(
		_with_keywords(CatalogSamples.unit(), [{"keyword": "last_breath"}]),
		[CatalogSamples.triggered("arrival")]
	)
	assert_array(Array(_card_errors(complete))).is_empty()
	assert_bool(_mentions(_card_errors(keyword_only), "LAST_BREATH exige un effet")).is_true()
	assert_bool(_mentions(_card_errors(wrong_event), "LAST_BREATH exige un effet")).is_true()


func test_210_unknown_or_duplicate_keyword_is_refused() -> void:
	var unknown := _with_keywords(CatalogSamples.unit(), [{"keyword": "flying"}])
	var duplicated := _with_keywords(
		CatalogSamples.unit(),
		[{"keyword": "assault", "value": 1}, {"keyword": "assault", "value": 2}]
	)
	assert_bool(_mentions(_card_errors(unknown), "« flying » inconnu")).is_true()
	assert_bool(_mentions(_card_errors(duplicated), "en double")).is_true()


func test_effect_errors_name_the_effect_index() -> void:
	var data := _with_effects(
		CatalogSamples.spell(),
		[
			CatalogSamples.modify_force_resolve(),
			CatalogSamples.without_field(CatalogSamples.destroy_effect(), "target")
		]
	)
	assert_bool(_mentions(_card_errors(data), "effet 2 : 207.5.1")).is_true()
