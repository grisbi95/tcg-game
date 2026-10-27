# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## Catalogue : filtres de pièces, portées, sujet « pièce source » et Endormir (ruleset 0.55,
## 205.5.7, 206.5.5, 207.2.2, 207.2.8, 207.3.14, 207.5.6, 207.5.10, 207.5.14 ; Q-097 ; décisions
## 0010 et 0062). Ne résout aucun effet : ces tests vérifient lecture et refus du JSON.


func _mentions(errors: PackedStringArray, fragment: String) -> bool:
	return CatalogSamples.mentions(errors, fragment)


func _filter_errors(data: Dictionary) -> PackedStringArray:
	return PieceFilter.from_dict(data).find_errors()


func _target_errors(data: Dictionary) -> PackedStringArray:
	return TargetSpec.from_dict(data).find_errors()


func _effect_errors(data: Dictionary) -> PackedStringArray:
	return CatalogSamples.effect_errors(data)


func _triggered(kind: String, extra: Dictionary = {}) -> Dictionary:
	var effect := {
		"kind": kind,
		"timing": "triggered",
		"trigger": "end_of_turn",
		"subject": "source_piece",
		"amount": 1,
		"duration": "until_end_of_turn",
	}
	if kind != "modify_force":
		effect.erase("amount")
		effect.erase("duration")
	effect.merge(extra, true)
	return effect


func test_decision_0062_the_sample_cards_are_valid() -> void:
	for data: Dictionary in FilterSamples.card_data():
		assert_array(Array(CardDefinition.from_dict(data).find_errors())).is_empty()


func test_207_5_6_piece_filter_reads_every_field() -> void:
	var filter := (
		PieceFilter
		. from_dict(
			{
				"side": "enemy",
				"piece_kinds": ["unit", "building"],
				"relation": "same_row",
				"relative_to": "source_piece",
				"include_reference": false,
				"tokens": "non_token",
				"row": "own_near",
			}
		)
	)
	assert_array(Array(filter.find_errors())).is_empty()
	assert_int(filter.side).is_equal(PieceFilter.SideFilter.ENEMY)
	assert_array(filter.piece_kinds).contains_exactly(
		[Piece.PieceKind.UNIT, Piece.PieceKind.BUILDING]
	)
	assert_int(filter.relation).is_equal(PieceFilter.Relation.SAME_ROW)
	assert_bool(filter.include_reference).is_false()
	assert_int(filter.tokens).is_equal(PieceFilter.TokenFilter.NON_TOKEN)
	assert_int(filter.row).is_equal(PieceFilter.RowZone.OWN_NEAR)


func test_207_5_6_piece_filter_defaults_admit_every_piece() -> void:
	var filter := PieceFilter.from_dict({})
	assert_bool(filter.is_default()).is_true()
	assert_bool(filter.include_reference).is_true()
	assert_array(Array(filter.find_errors())).is_empty()


func test_207_5_6_piece_filter_enums_are_closed() -> void:
	for field: String in ["side", "relation", "relative_to", "tokens", "row"]:
		var errors := _filter_errors({field: "nowhere"})
		assert_bool(_mentions(errors, "« nowhere » inconnu")).is_true()
	assert_bool(_mentions(_filter_errors({"piece_kinds": ["spell"]}), "spell inconnu")).is_true()
	assert_bool(_mentions(_filter_errors({"colour": "red"}), "champ « colour » inconnu")).is_true()


func test_206_5_5_row_zones_are_those_of_205_1() -> void:
	var names := CatalogReader.enum_names(PieceFilter.RowZone)
	assert_array(Array(names)).contains_exactly(
		["any", "own_first", "own_near", "central", "not_central"]
	)


func test_207_5_6_others_needs_a_relation_and_one_piece_left() -> void:
	var without_relation := _filter_errors({"include_reference": false})
	assert_bool(_mentions(without_relation, "exige une relation")).is_true()
	var nobody := _filter_errors({"relation": "self", "include_reference": false})
	assert_bool(_mentions(nobody, "aucune pièce ne convient")).is_true()
	var others := _filter_errors({"relation": "adjacent", "include_reference": false})
	assert_array(Array(others)).is_empty()


func test_205_2_5_hero_reference_is_for_adjacency_only() -> void:
	var adjacent := {"relation": "adjacent", "relative_to": "own_hero"}
	assert_array(Array(_filter_errors(adjacent))).is_empty()
	var same_row := {"relation": "same_row", "relative_to": "own_hero"}
	assert_bool(_mentions(_filter_errors(same_row), "205.2.5")).is_true()
	var bare := {"relative_to": "own_hero"}
	assert_bool(_mentions(_filter_errors(bare), "relative_to exige une relation")).is_true()


func test_207_5_6_target_reads_its_filter_and_validates_it() -> void:
	var spec := TargetSpec.from_dict({"what": "piece", "filter": {"piece_kinds": ["unit"]}})
	assert_array(Array(spec.find_errors())).is_empty()
	var bad := _target_errors({"what": "piece", "filter": {"piece_kinds": ["unit"], "row": "x"}})
	assert_bool(_mentions(bad, "filter : ")).is_true()


func test_207_5_6_piece_row_is_given_to_the_filter_not_to_the_target() -> void:
	var errors := _target_errors(
		{"what": "piece", "filter": {"piece_kinds": ["unit"]}, "row": "own_first"}
	)
	assert_bool(_mentions(errors, "row de la cible ne vaut que pour une case")).is_true()


func test_207_5_11_adjacent_to_is_for_cells_only() -> void:
	var errors := _target_errors(
		{"what": "piece", "filter": {"piece_kinds": ["unit"]}, "adjacent_to": "source_piece"}
	)
	assert_bool(_mentions(errors, "adjacent_to ne vaut que pour une case")).is_true()
	var cell := _target_errors(
		{"what": "cell", "adjacent_to": "source_piece", "row": "not_central"}
	)
	assert_array(Array(cell)).is_empty()
	var hero_cell := _target_errors({"what": "cell", "adjacent_to": "own_hero"})
	assert_array(Array(hero_cell)).is_empty()
	var hero_piece := _target_errors(
		{"what": "piece", "filter": {"piece_kinds": ["unit"]}, "adjacent_to": "own_hero"}
	)
	assert_bool(_mentions(hero_piece, "adjacent_to ne vaut que pour une case")).is_true()


func test_205_1_4_cell_target_reads_the_named_zones() -> void:
	for zone: String in ["own_first", "own_near", "central", "not_central"]:
		var spec := TargetSpec.from_dict({"what": "cell", "row": zone})
		assert_array(Array(spec.find_errors())).is_empty()
		assert_str(PieceFilter.RowZone.find_key(spec.row)).is_equal(zone.to_upper())


func test_207_5_6_distinct_needs_several_targets_and_a_piece_or_a_cell() -> void:
	var one := _target_errors({"what": "cell", "distinct": true})
	assert_bool(_mentions(one, "distinct exige count_max au moins 2")).is_true()
	var two := TargetSpec.from_dict(
		{"what": "cell", "distinct": true, "count_min": 2, "count_max": 2}
	)
	assert_array(Array(two.find_errors())).is_empty()
	assert_bool(two.distinct).is_true()
	var spell := _target_errors(
		{"what": "spell_on_stack", "distinct": true, "count_min": 2, "count_max": 2}
	)
	assert_bool(_mentions(spell, "distinct ne vaut que pour des pièces ou des cases")).is_true()
	assert_bool(TargetSpec.from_dict({"what": "cell"}).distinct).is_false()


func test_207_5_6_spell_filters_are_read_and_belong_to_a_spell_target() -> void:
	var spec := TargetSpec.from_dict(
		{"what": "spell_on_stack", "spell_max_cost": 3, "spell_speeds": ["action", "reaction"]}
	)
	assert_array(Array(spec.find_errors())).is_empty()
	assert_int(spec.spell_max_cost).is_equal(3)
	assert_array(spec.spell_speeds).contains_exactly(
		[CardDefinition.SpellSpeed.ACTION, CardDefinition.SpellSpeed.REACTION]
	)
	assert_int(TargetSpec.from_dict({"what": "spell_on_stack"}).spell_max_cost).is_equal(
		TargetSpec.NO_COST_LIMIT
	)
	for what: String in ["piece", "cell"]:
		var filter := {"piece_kinds": ["unit"]} if what == "piece" else {}
		var misplaced := _target_errors(
			{"what": what, "filter": filter, "spell_max_cost": 2, "spell_speeds": ["action"]}
		)
		assert_bool(_mentions(misplaced, "ne valent que pour un Spell")).is_true()


func test_207_1_2_spell_speed_filter_names_action_or_reaction() -> void:
	for speed: String in ["none", "slow", "ACTION"]:
		var errors := _target_errors({"what": "spell_on_stack", "spell_speeds": [speed]})
		assert_bool(_mentions(errors, "spell_speeds")).is_true()
	var cost := _target_errors({"what": "spell_on_stack", "spell_max_cost": -1})
	assert_bool(_mentions(cost, "spell_max_cost")).is_true()


func test_207_5_14_spell_target_takes_no_piece_filter_nor_zone() -> void:
	var filtered := _target_errors({"what": "spell_on_stack", "filter": {"side": "ally"}})
	assert_bool(_mentions(filtered, "207.5.14")).is_true()
	var zone := _target_errors({"what": "spell_on_stack", "row": "central"})
	assert_bool(_mentions(zone, "207.5.14")).is_true()


func test_207_5_11_cell_target_takes_no_piece_filter() -> void:
	var errors := _target_errors({"what": "cell", "filter": {"piece_kinds": ["unit"]}})
	assert_bool(_mentions(errors, "207.5.11")).is_true()


func test_207_3_14_relation_to_the_source_piece_is_for_triggered_effects() -> void:
	var data := CatalogSamples.destroy_effect()
	var target: Dictionary = data["target"]
	target["filter"]["relation"] = "adjacent"
	assert_bool(_mentions(_effect_errors(data), "207.3.14")).is_true()
	var own_hero := CatalogSamples.destroy_effect()
	var hero_target: Dictionary = own_hero["target"]
	var hero_filter: Dictionary = hero_target["filter"]
	hero_filter.merge({"relation": "adjacent", "relative_to": "own_hero"})
	assert_array(Array(_effect_errors(own_hero))).is_empty()


func test_206_5_5_scope_is_a_filter_relative_to_the_bearer() -> void:
	var data := CatalogSamples.modify_force_static(
		{"scope": CatalogSamples.adjacent_allied_scope()}
	)
	var effect := CatalogSamples.effect_from(data)
	assert_array(Array(CatalogSamples.effect_errors(data))).is_empty()
	assert_int(effect.scope.relation).is_equal(PieceFilter.Relation.ADJACENT)
	assert_int(effect.scope.side).is_equal(PieceFilter.SideFilter.ALLY)
	var bearer := CatalogSamples.effect_from(CatalogSamples.modify_force_static())
	assert_int(bearer.scope.relation).is_equal(PieceFilter.Relation.SELF)


func test_207_2_8_scope_cannot_be_relative_to_the_hero() -> void:
	var scope := {"piece_kinds": ["unit"], "relation": "adjacent", "relative_to": "own_hero"}
	var errors := _effect_errors(CatalogSamples.modify_force_static({"scope": scope}))
	assert_bool(_mentions(errors, "207.2.8")).is_true()


func test_206_5_5_scope_names_its_kinds_except_for_the_bearer_itself() -> void:
	var scope := {"side": "ally", "relation": "adjacent"}
	var errors := _effect_errors(CatalogSamples.modify_force_static({"scope": scope}))
	assert_bool(_mentions(errors, "206.5.5")).is_true()


func test_202_3_9_static_force_scope_never_touches_a_hero() -> void:
	var scope := {"piece_kinds": ["unit", "hero"], "relation": "adjacent"}
	var errors := _effect_errors(CatalogSamples.modify_force_static({"scope": scope}))
	assert_bool(_mentions(errors, "202.3.9")).is_true()


func test_207_2_2_scope_is_a_json_object() -> void:
	var errors := _effect_errors(CatalogSamples.modify_force_static({"scope": "bearer"}))
	assert_bool(_mentions(errors, "« scope » doit être un objet")).is_true()


func test_decision_0062_source_piece_subject_of_force_and_destruction() -> void:
	for kind: String in ["modify_force", "destroy"]:
		assert_array(Array(_effect_errors(_triggered(kind)))).is_empty()


func test_decision_0062_source_piece_subject_is_for_triggered_effects() -> void:
	for kind: String in ["modify_force", "destroy", "sleep"]:
		var effect := _triggered(kind, {"timing": "resolve"})
		effect.erase("trigger")
		assert_bool(_mentions(_effect_errors(effect), "source_piece ne vaut que")).is_true()


func test_decision_0062_source_piece_subject_names_no_target() -> void:
	var effect := _triggered("destroy", {"target": CatalogSamples.ally_unit_target()})
	assert_bool(_mentions(_effect_errors(effect), "0057")).is_true()


func test_decision_0062_other_kinds_refuse_the_source_piece_subject() -> void:
	var effect := _triggered("create_token", {"token_piece_kind": "unit", "token_force": 1})
	assert_bool(_mentions(_effect_errors(effect), "n'admet pas le sujet source_piece")).is_true()


func test_202_3_9_hero_card_force_or_destruction_of_the_source_piece_is_refused() -> void:
	for kind: String in ["modify_force", "destroy"]:
		var hero := CatalogSamples.with_flats(CatalogSamples.hero(), "passive", [])
		hero["triggered"] = CatalogSamples.texts_of([_triggered(kind)])
		var errors := HeroDefinition.from_dict(hero).find_errors()
		assert_bool(_mentions(errors, "Q-097")).is_true()
	var sleeping := CatalogSamples.with_flats(CatalogSamples.hero(), "passive", [])
	sleeping["triggered"] = CatalogSamples.texts_of([_triggered("sleep")])
	assert_array(Array(HeroDefinition.from_dict(sleeping).find_errors())).is_empty()


func test_202_3_9_hero_target_of_force_or_destruction_stays_refused() -> void:
	var effect := CatalogSamples.destroy_effect()
	var target: Dictionary = effect["target"]
	effect["target"] = CatalogSamples.with_filter_field(target, "piece_kinds", ["hero"])
	assert_bool(_mentions(_effect_errors(effect), "202.3.9")).is_true()


func test_205_5_7_sleep_targets_a_unit_a_hero_or_a_building() -> void:
	for kinds: Array in [["unit"], ["hero"], ["unit", "hero"], ["building"]]:
		var target := CatalogSamples.with_filter_field(
			CatalogSamples.ally_unit_target(), "piece_kinds", kinds
		)
		var effect := {"kind": "sleep", "timing": "resolve", "target": target}
		assert_array(Array(_effect_errors(effect))).is_empty()


func test_205_5_7_sleep_needs_a_target_or_the_source_piece() -> void:
	var bare := {"kind": "sleep", "timing": "resolve"}
	assert_bool(_mentions(_effect_errors(bare), "207.5.1")).is_true()
	assert_array(Array(_effect_errors(_triggered("sleep")))).is_empty()


func test_205_5_7_sleep_has_no_amount_nor_duration() -> void:
	var effect := HandEffectSamples.sleep_effect()
	effect["amount"] = 1
	assert_bool(_mentions(_effect_errors(effect), "amount")).is_true()
	var lasting := HandEffectSamples.sleep_effect()
	lasting["duration"] = "until_end_of_turn"
	assert_bool(_mentions(_effect_errors(lasting), "207.4.9")).is_true()


func test_205_5_7_sleep_is_never_a_static_effect() -> void:
	var effect := _triggered("sleep", {"timing": "static", "scope": {"relation": "self"}})
	effect.erase("trigger")
	effect.erase("subject")
	assert_bool(_mentions(_effect_errors(effect), "n'admet pas le timing")).is_true()


func test_207_3_7c_a_hero_may_mark_several_triggered_effects_once_per_turn() -> void:
	var first := _triggered("modify_force", {"once_per_turn": true, "subject": "owner_player"})
	first.erase("subject")
	first["target"] = CatalogSamples.ally_unit_target()
	var second := first.duplicate(true)
	var hero := CatalogSamples.with_flats(CatalogSamples.hero(), "passive", [])
	hero["triggered"] = CatalogSamples.texts_of([first, second])
	assert_array(Array(HeroDefinition.from_dict(hero).find_errors())).is_empty()


func test_202_3_9_hero_passive_force_on_the_bearer_is_refused() -> void:
	var bearer := CatalogSamples.modify_force_static()
	var hero := CatalogSamples.with_flats(CatalogSamples.hero(), "passive", [bearer])
	assert_bool(_mentions(HeroDefinition.from_dict(hero).find_errors(), "Q-097")).is_true()
	var aura := CatalogSamples.with_flats(CatalogSamples.hero(), "passive", [])
	aura["passive"] = CatalogSamples.texts_of(
		[CatalogSamples.modify_force_static({"scope": CatalogSamples.adjacent_allied_scope()})]
	)
	assert_array(Array(HeroDefinition.from_dict(aura).find_errors())).is_empty()
