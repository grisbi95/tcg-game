# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## Catalogue : valeur « X » d'un champ, source de X et mot-clé accordé (ruleset 0.53, chapitre 213
## et 210.4 ; décisions 0002, 0010 et 0058). Ne résout aucun effet : ces tests vérifient que le
## catalogue refuse une définition incohérente (les règles de jeu sont dans test_213_value_x.gd et
## test_keyword_grants.gd).

const SOURCE_PIECE_ID: int = 7


func _effect_errors(data: Dictionary) -> PackedStringArray:
	return CatalogSamples.effect_errors(data)


func _card_errors(data: Dictionary) -> PackedStringArray:
	return CardDefinition.from_dict(data).find_errors()


func _mentions(errors: PackedStringArray, fragment: String) -> bool:
	return CatalogSamples.mentions(errors, fragment)


func _with(data: Dictionary, key: String, value: Variant) -> Dictionary:
	return CatalogSamples.with_field(data, key, value)


func _unit_target() -> Dictionary:
	return CatalogSamples.ally_unit_target()


func test_decision_0058_the_sample_cards_are_valid() -> void:
	for data: Dictionary in ValueSamples.card_data():
		assert_array(Array(_card_errors(data))).is_empty()


func test_decision_0058_an_x_field_needs_a_source_of_x() -> void:
	var without_source := ValueSamples.blessing_effect()
	without_source.erase("x_source")
	assert_bool(_mentions(_effect_errors(without_source), "exige x_source")).is_true()
	var target := _unit_target()
	target["max_force"] = "X"
	var limit := {"kind": "destroy", "timing": "resolve", "target": target}
	assert_bool(_mentions(_effect_errors(limit), "exige x_source")).is_true()


func test_decision_0058_a_source_of_x_needs_an_x_field() -> void:
	var effect := CatalogSamples.modify_force_resolve({"x_source": "chosen"})
	assert_bool(_mentions(_effect_errors(effect), "x_source exige un champ")).is_true()


func test_decision_0058_the_x_of_a_force_limit_is_the_chosen_one() -> void:
	var effect := ValueSamples.execution_effect()
	effect["x_source"] = "target_force"
	assert_bool(_mentions(_effect_errors(effect), "max_force « X » exige")).is_true()


func test_decision_0058_the_force_of_the_target_needs_one_non_hero_piece() -> void:
	var two := ValueSamples.fury_effect("assault")
	two["target"] = _with(_unit_target(), "count_max", 2)
	assert_bool(_mentions(_effect_errors(two), "213.2.3")).is_true()
	var hero := ValueSamples.fury_effect("assault")
	hero["target"] = CatalogSamples.with_filter_field(
		_unit_target(), "piece_kinds", ["unit", "hero"]
	)
	assert_bool(_mentions(_effect_errors(hero), "213.2.3")).is_true()


func test_decision_0058_a_static_effect_has_no_x() -> void:
	var effect := CatalogSamples.modify_force_static({"amount": "X", "x_source": "chosen"})
	assert_bool(_mentions(_effect_errors(effect), "213.2.1")).is_true()


func test_decision_0058_amount_x_is_for_force_and_keywords_only() -> void:
	var draw := HandEffectSamples.draw_effect(1)
	draw["amount"] = "X"
	draw["x_source"] = "chosen"
	assert_bool(_mentions(_effect_errors(draw), "amount « X »")).is_true()


func test_decision_0058_a_text_other_than_x_is_not_a_number() -> void:
	var effect := CatalogSamples.modify_force_resolve({"amount": "x"})
	assert_bool(_mentions(_effect_errors(effect), "doit être un entier")).is_true()


func test_decision_0058_chosen_x_is_refused_without_an_x_cost() -> void:
	var spell := CatalogSamples.with_effects(
		CatalogSamples.spell(), [ValueSamples.blessing_effect()]
	)
	assert_bool(_mentions(_card_errors(spell), "213.1.3")).is_true()
	var order := {
		"speed": "action",
		"cost": 0,
		"texts": CatalogSamples.texts_of([ValueSamples.blessing_effect()])
	}
	assert_bool(_mentions(HeroOrder.from_dict(order).find_errors(), "213.1.3")).is_true()
	var hero := CatalogSamples.with_flats(CatalogSamples.hero(), "passive", [])
	var triggered := CatalogSamples.triggered("end_of_turn", {"amount": "X", "x_source": "chosen"})
	hero["triggered"] = CatalogSamples.texts_of([triggered])
	assert_bool(_mentions(HeroDefinition.from_dict(hero).find_errors(), "213.1.3")).is_true()


func test_decision_0058_target_spec_with_x_binds_the_limit() -> void:
	var target_data: Dictionary = ValueSamples.execution_effect()["target"]
	var target := TargetSpec.from_dict(target_data)
	assert_bool(target.max_force_is_x).is_true()
	assert_bool(target.has_force_limit()).is_true()
	var bound := target.with_x(4)
	assert_int(bound.max_force).is_equal(4)
	assert_bool(bound.max_force_is_x).is_false()
	assert_bool(target.max_force_is_x).is_true()
	var plain := TargetSpec.from_dict(_unit_target())
	assert_object(plain.with_x(4)).is_same(plain)


func test_decision_0058_grant_keyword_names_assault_or_rampart() -> void:
	var missing := ValueSamples.fury_effect("assault")
	missing.erase("keyword")
	assert_bool(_mentions(_effect_errors(missing), "nomme son mot-clé")).is_true()
	var outpost := ValueSamples.fury_effect("outpost")
	assert_bool(_mentions(_effect_errors(outpost), "n'accorde qu'Assaut ou Rempart")).is_true()
	var stray := CatalogSamples.modify_force_resolve({"keyword": "assault"})
	assert_bool(_mentions(_effect_errors(stray), "keyword ne vaut que")).is_true()


func test_decision_0058_grant_keyword_has_a_value_of_at_least_one() -> void:
	var zero := ValueSamples.watch_effect()
	zero["amount"] = 0
	assert_bool(_mentions(_effect_errors(zero), "210.1.1")).is_true()


func test_decision_0058_grant_keyword_targets_units_only() -> void:
	for kinds: Array in [["building"], ["hero"], ["unit", "building"]]:
		var effect := ValueSamples.watch_effect()
		effect["target"] = CatalogSamples.with_filter_field(_unit_target(), "piece_kinds", kinds)
		assert_bool(_mentions(_effect_errors(effect), "210.4.1c")).is_true()


func test_decision_0058_grant_keyword_takes_the_forms_of_modify_force() -> void:
	var no_duration := ValueSamples.watch_effect()
	no_duration.erase("duration")
	assert_bool(_mentions(_effect_errors(no_duration), "207.4.2")).is_true()
	var static_effect := ValueSamples.static_grant("assault", 1, CatalogSamples.bearer_scope())
	assert_array(Array(_effect_errors(static_effect))).is_empty()
	var aura := ValueSamples.static_grant("rampart", 1, CatalogSamples.adjacent_allied_scope())
	assert_array(Array(_effect_errors(aura))).is_empty()
	var lasting_static := _with(static_effect, "duration", "while_piece_in_play")
	assert_bool(_mentions(_effect_errors(lasting_static), "207.4.10")).is_true()


func test_decision_0058_with_x_copies_every_field_of_the_target_spec() -> void:
	var data := {
		"what": "cell",
		"filter": {"side": "enemy", "piece_kinds": ["unit"]},
		"max_force": "X",
		"row": "own_first",
		"adjacent_to": "target_piece",
		"distinct": true,
		"spell_max_cost": 2,
		"spell_speeds": ["reaction"],
		"count_min": 2,
		"count_max": 3,
	}
	var spec := TargetSpec.from_dict(data)
	var fresh := TargetSpec.new()
	var bound := spec.with_x(4)
	# source_cell : valeur d'exécution, jamais lue du JSON (207.3.14).
	var rebound := ["max_force", "max_force_is_x", "parse_errors", "source_cell", "source_piece_id"]
	for field: String in ScriptFields.of(spec):
		if rebound.has(field):
			continue
		var message := "« %s » : champ non renseigné par le test ou non recopié" % field
		assert_bool(spec.get(field) != fresh.get(field)).override_failure_message(message).is_true()
		assert_bool(bound.get(field) == spec.get(field)).override_failure_message(message).is_true()
	assert_int(bound.max_force).is_equal(4)


func test_207_3_14_with_source_copies_every_field_of_the_target_spec() -> void:
	var data := {
		"what": "cell",
		"filter": {"side": "enemy", "piece_kinds": ["unit"]},
		"max_force": "X",
		"row": "own_first",
		"adjacent_to": "source_piece",
		"distinct": true,
		"spell_max_cost": 2,
		"spell_speeds": ["reaction"],
		"count_min": 2,
		"count_max": 3,
	}
	var spec := TargetSpec.from_dict(data)
	var fresh := TargetSpec.new()
	var cell := DuelStateBuilder.cell("C3")
	var bound := spec.with_source(SOURCE_PIECE_ID, cell)
	var rebound := ["source_cell", "source_piece_id", "parse_errors", "max_force"]
	for field: String in ScriptFields.of(spec):
		if rebound.has(field):
			continue
		var message := "« %s » : champ non renseigné par le test ou non recopié" % field
		assert_bool(spec.get(field) != fresh.get(field)).override_failure_message(message).is_true()
		assert_bool(bound.get(field) == spec.get(field)).override_failure_message(message).is_true()
	assert_int(bound.max_force).is_equal(spec.max_force)
	assert_vector(bound.source_cell).is_equal(cell)
	assert_int(bound.source_piece_id).is_equal(SOURCE_PIECE_ID)


func test_decision_0058_an_unresolved_x_limit_admits_no_piece() -> void:
	var catalog := ValueSamples.catalog()
	var builder := ValueSamples.builder(catalog)
	var enemy_id := builder.place_piece(
		DuelState.PlayerSide.B,
		Piece.PieceKind.UNIT,
		DuelStateBuilder.cell("C4"),
		ValueSamples.SOLDIER
	)
	var state := builder.build()
	var target_data: Dictionary = ValueSamples.execution_effect()["target"]
	var spec := TargetSpec.from_dict(target_data)
	var caster := DuelState.PlayerSide.A
	var piece := state.find_piece(enemy_id)
	assert_bool(EffectRules.is_legal_piece(state, caster, spec, piece)).is_false()
	assert_bool(EffectRules.is_legal_piece(state, caster, spec.with_x(9), piece)).is_true()


func test_decision_0058_cost_with_x_pays_x_only_for_an_x_cost() -> void:
	var catalog := ValueSamples.catalog()
	assert_int(ValueRules.cost_with_x(catalog.get_card(ValueSamples.EXECUTION), 5)).is_equal(5)
	var fury := catalog.get_card(ValueSamples.FURY)
	assert_int(ValueRules.cost_with_x(fury, 5)).is_equal(ValueSamples.FURY_COST)


func test_decision_0058_a_keyword_cannot_be_granted_to_a_bearer_that_is_not_a_unit() -> void:
	var grant := ValueSamples.static_grant("assault", 1, CatalogSamples.bearer_scope())
	var building := CatalogSamples.with_effects(CatalogSamples.building(), [grant])
	assert_bool(_mentions(_card_errors(building), "210.4.1c")).is_true()
	var unit := CatalogSamples.with_effects(CatalogSamples.unit(), [grant])
	assert_array(Array(_card_errors(unit))).is_empty()
	var aura := ValueSamples.static_grant("assault", 1, CatalogSamples.adjacent_allied_scope())
	var aura_building := CatalogSamples.with_effects(CatalogSamples.building(), [aura])
	assert_array(Array(_card_errors(aura_building))).is_empty()
	var hero := CatalogSamples.with_flats(CatalogSamples.hero(), "passive", [grant])
	assert_bool(_mentions(HeroDefinition.from_dict(hero).find_errors(), "210.4.1c")).is_true()


func test_decision_0058_the_force_of_the_target_is_read_on_units_only() -> void:
	var building := ValueSamples.fury_effect("assault")
	building["target"] = CatalogSamples.with_filter_field(
		_unit_target(), "piece_kinds", ["building"]
	)
	assert_bool(_mentions(_effect_errors(building), "213.2.3")).is_true()
