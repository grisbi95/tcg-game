# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## Catalogue : valeurs du jeu, conditions par comparaison et objet des déclencheurs (ruleset 0.55,
## 207.3.1, 207.3.13, 207.7.1, 213 ; décision 0065). Ne résout aucun effet : ces tests vérifient que
## le catalogue lit le JSON et refuse une valeur qui n'a pas de sens à son moment de lecture.

const HAND_SIZE: Dictionary = {"kind": "hand_size"}


func _text_errors(text: Dictionary) -> PackedStringArray:
	return EffectText.from_dict(text).find_errors()


func _mentions(errors: PackedStringArray, fragment: String) -> bool:
	return CatalogSamples.mentions(errors, fragment)


func _with(data: Dictionary, key: String, value: Variant) -> Dictionary:
	return CatalogSamples.with_field(data, key, value)


## Texte déclenché par `trigger` qui pioche, avec `extra` (condition, objet).
func _triggered(trigger: String, extra: Dictionary = {}) -> Dictionary:
	return GameValueSamples.triggered_text(trigger, [GameValueSamples.draw()], extra)


## Texte d'un Spell dont l'effet est `effect`.
func _spell_text(effects: Array) -> Dictionary:
	return TextSamples.text_of(effects)


func _conditioned(value: Dictionary, comparison: String = "at_least") -> Dictionary:
	return GameValueSamples.conditioned(
		GameValueSamples.draw(), CatalogSamples.condition(value, comparison, 1)
	)


func test_decision_0065_the_sample_cards_are_valid() -> void:
	for data: Dictionary in GameValueSamples.card_data():
		assert_array(Array(CardDefinition.from_dict(data).find_errors())).is_empty()
	assert_array(Array(GameValueSamples.catalog().find_errors())).is_empty()


func test_decision_0065_game_value_kinds_are_appended_in_order() -> void:
	(
		assert_array(GameValue.Kind.keys())
		. contains_exactly(
			[
				"HAND_SIZE",
				"PIECE_COUNT",
				"SOURCE_FORCE",
				"TARGET_FORCE",
				"DISCARDED_BY_PREVIOUS_EFFECT",
				"CHOSEN_X",
				"EVENT_SPELL_COST",
			]
		)
	)
	assert_array(EffectCondition.Comparison.keys()).contains_exactly(["AT_LEAST", "AT_MOST"])


func test_decision_0065_a_game_value_is_a_closed_object() -> void:
	var unknown := GameValue.from_dict({"kind": "deck_size"})
	assert_bool(_mentions(unknown.find_errors(), "« deck_size » inconnu")).is_true()
	var missing := GameValue.from_dict({})
	assert_bool(_mentions(missing.find_errors(), "« kind » absent")).is_true()
	var extra := GameValue.from_dict({"kind": "hand_size", "unit": 1})
	assert_bool(_mentions(extra.find_errors(), "unit")).is_true()


func test_decision_0065_piece_count_names_a_filter_and_only_it_does() -> void:
	var bare := GameValue.from_dict({"kind": "piece_count"})
	assert_bool(_mentions(bare.find_errors(), "nomme les pièces comptées")).is_true()
	var stray := GameValue.from_dict({"kind": "hand_size", "filter": {"side": "ally"}})
	assert_bool(_mentions(stray.find_errors(), "filter ne vaut que pour piece_count")).is_true()
	var wrong := GameValue.from_dict({"kind": "piece_count", "filter": {"side": "nobody"}})
	assert_bool(_mentions(wrong.find_errors(), "« nobody » inconnu")).is_true()
	var good := GameValue.from_dict(GameValueSamples.allied_units())
	assert_array(Array(good.find_errors())).is_empty()


func test_207_3_13_event_condition_accepts_hand_size_and_piece_count() -> void:
	for value: Dictionary in [HAND_SIZE, GameValueSamples.allied_units()]:
		var text := _triggered(
			"start_of_own_turn", {"condition": CatalogSamples.condition(value, "at_most", 2)}
		)
		assert_array(Array(_text_errors(text))).is_empty()


func test_207_3_13_event_condition_refuses_a_value_without_meaning_at_the_event() -> void:
	var refused: Dictionary[String, Dictionary] = {
		"target_force": {"kind": "target_force"},
		"chosen_x": {"kind": "chosen_x"},
		"discarded": {"kind": "discarded_by_previous_effect"},
		"event_spell_cost": {"kind": "event_spell_cost"},
	}
	for label: String in refused:
		var condition := CatalogSamples.condition(refused[label], "at_least", 1)
		var text := _triggered("start_of_own_turn", {"condition": condition})
		assert_bool(_mentions(_text_errors(text), "0065")).override_failure_message(label).is_true()


func test_207_3_13_the_cost_of_the_spell_of_the_event_needs_a_spell_trigger() -> void:
	var condition := CatalogSamples.condition({"kind": "event_spell_cost"}, "at_least", 3)
	for trigger: String in ["own_spell_announced", "spell_countered"]:
		var text := _triggered(trigger, {"condition": condition})
		assert_array(Array(_text_errors(text))).is_empty()
	for trigger: String in ["arrival", "end_of_turn", "other_piece_destroyed"]:
		var text := _triggered(trigger, {"condition": condition})
		(
			assert_bool(_mentions(_text_errors(text), "0065"))
			. override_failure_message(trigger)
			. is_true()
		)


func test_207_7_1_step_condition_accepts_values_read_in_the_order_of_the_text() -> void:
	for value: Dictionary in [HAND_SIZE, GameValueSamples.enemy_units()]:
		assert_array(Array(_text_errors(_spell_text([_conditioned(value)])))).is_empty()


func test_207_7_1_step_condition_refuses_a_value_without_meaning_there() -> void:
	var refused: Dictionary[String, Dictionary] = {
		"target_force": {"kind": "target_force"},
		"event_spell_cost": {"kind": "event_spell_cost"},
		"discarded": {"kind": "discarded_by_previous_effect"},
	}
	for label: String in refused:
		var errors := _text_errors(_spell_text([_conditioned(refused[label])]))
		assert_bool(_mentions(errors, "0065")).override_failure_message(label).is_true()


func test_207_7_1_a_discarded_count_follows_an_effect_that_discards() -> void:
	var previous := CatalogSamples.condition(
		{"kind": "discarded_by_previous_effect"}, "at_least", 1
	)
	var follower := GameValueSamples.conditioned(GameValueSamples.draw(), previous)
	var after_discard := _spell_text([GameValueSamples.discard(), follower])
	assert_array(Array(_text_errors(after_discard))).is_empty()
	var after_draw := _spell_text([GameValueSamples.draw(), follower])
	assert_bool(_mentions(_text_errors(after_draw), "0065")).is_true()


func test_207_3_14_a_piece_count_relative_to_the_source_needs_a_triggered_text() -> void:
	var near := {"kind": "piece_count", "filter": {"side": "ally", "relation": "adjacent"}}
	var spell := _spell_text([_conditioned(near)])
	assert_bool(_mentions(_text_errors(spell), "207.3.14")).is_true()
	var hero_near := {
		"kind": "piece_count", "filter": {"relation": "adjacent", "relative_to": "own_hero"}
	}
	assert_array(Array(_text_errors(_spell_text([_conditioned(hero_near)])))).is_empty()
	var triggered := _triggered(
		"start_of_own_turn", {"condition": CatalogSamples.condition(near, "at_least", 1)}
	)
	assert_array(Array(_text_errors(triggered))).is_empty()


func test_213_2_1_amount_x_draws_and_discards_by_a_game_value() -> void:
	for kind: String in ["draw_cards", "discard_cards"]:
		var effect := {"kind": kind, "subject": "owner_player", "amount": "X", "x_from": HAND_SIZE}
		assert_array(Array(_text_errors(_spell_text([effect])))).is_empty()
		var without := CatalogSamples.without_field(effect, "x_from")
		assert_bool(_mentions(_text_errors(_spell_text([without])), "exige x_from")).is_true()


func test_213_2_1_a_game_value_of_x_is_refused_where_it_cannot_be_read() -> void:
	var refused: Dictionary[String, Dictionary] = {
		"event_spell_cost": {"kind": "event_spell_cost"},
		"target_force": {"kind": "target_force"},
		"discarded": {"kind": "discarded_by_previous_effect"},
		"source_force": {"kind": "source_force"},
	}
	for label: String in refused:
		var effect := GameValueSamples.draw(1, refused[label])
		var errors := _text_errors(_spell_text([GameValueSamples.draw(), effect]))
		var fragment := "en attente d'une question" if label == "source_force" else "0065"
		if label == "target_force":
			fragment = "213.2.3"
		assert_bool(_mentions(errors, fragment)).override_failure_message(label).is_true()


func test_213_1_3_the_chosen_x_of_a_condition_needs_an_x_cost() -> void:
	var condition := CatalogSamples.condition({"kind": "chosen_x"}, "at_least", 2)
	var spell := CatalogSamples.with_field(
		CatalogSamples.spell(),
		"texts",
		[_spell_text([GameValueSamples.conditioned(GameValueSamples.draw(), condition)])]
	)
	assert_bool(_mentions(CardDefinition.from_dict(spell).find_errors(), "213.1.3")).is_true()
	(
		assert_array(Array(CardDefinition.from_dict(_with(spell, "cost", "X")).find_errors()))
		. is_empty()
	)


func test_207_3_1_other_piece_destroyed_takes_a_filter_of_the_destroyed_piece() -> void:
	var allied_unit := {"side": "ally", "piece_kinds": ["unit"]}
	var text := EffectText.from_dict(_triggered("other_piece_destroyed", {"object": allied_unit}))
	assert_array(Array(text.find_errors())).is_empty()
	assert_int(text.event_object.side).is_equal(PieceFilter.SideFilter.ALLY)
	assert_object(EffectText.from_dict(_triggered("other_piece_destroyed")).event_object).is_null()


func test_207_3_1_another_unit_may_be_written_by_excluding_the_reference() -> void:
	var others := {"side": "ally", "piece_kinds": ["unit"], "include_reference": false}
	(
		assert_array(Array(_text_errors(_triggered("other_piece_destroyed", {"object": others}))))
		. is_empty()
	)
	var generic := PieceFilter.from_dict({"include_reference": false})
	assert_bool(_mentions(generic.find_errors(), "206.5.5")).is_true()


func test_207_3_1_the_object_is_read_relative_to_the_piece_that_carries_the_effect() -> void:
	var hero_relative := {"relation": "adjacent", "relative_to": "own_hero"}
	var errors := _text_errors(_triggered("other_piece_destroyed", {"object": hero_relative}))
	assert_bool(_mentions(errors, "0065 : object se lit par rapport")).is_true()


func test_207_6_4_spell_countered_takes_the_side_of_the_spell_only() -> void:
	for side: String in ["ally", "enemy", "any"]:
		var text := _triggered("spell_countered", {"object": {"side": side}})
		assert_array(Array(_text_errors(text))).is_empty()
	var typed := _triggered(
		"spell_countered", {"object": {"side": "enemy", "piece_kinds": ["unit"]}}
	)
	assert_bool(_mentions(_text_errors(typed), "side seul")).is_true()


func test_207_3_1_the_object_belongs_to_the_two_new_triggers_only() -> void:
	for trigger: String in ["arrival", "destroyed", "end_of_turn", "own_spell_announced"]:
		var text := _triggered(trigger, {"object": {"side": "ally"}})
		var errors := _text_errors(text)
		(
			assert_bool(_mentions(errors, "object ne vaut que pour"))
			. override_failure_message(trigger)
			. is_true()
		)


func test_207_3_1_the_object_is_for_a_triggered_text() -> void:
	var text := _spell_text([GameValueSamples.draw()])
	text["object"] = {"side": "ally"}
	assert_bool(_mentions(_text_errors(text), "object ne vaut que pour")).is_true()


func test_207_3_1_new_triggers_are_valid_for_the_pieces_that_carry_them() -> void:
	for trigger: String in ["other_piece_destroyed", "spell_countered"]:
		for base: Dictionary in _carriers_of(trigger):
			var data := _with(base, "texts", [_triggered(trigger)])
			assert_array(Array(CardDefinition.from_dict(data).find_errors())).is_empty()


func test_decision_0065_the_force_of_the_source_is_refused_for_every_text() -> void:
	# En attente d'une question du ruleset (voir 207.3.3, 213.2.3, 200.4.1) : jamais lue.
	var force := {"kind": "source_force"}
	var condition := CatalogSamples.condition(force, "at_least", 1)
	for trigger: String in ["arrival", "start_of_own_turn", "destroyed", "other_piece_destroyed"]:
		var conditioned := _triggered(trigger, {"condition": condition})
		var amount := GameValueSamples.triggered_text(trigger, [GameValueSamples.draw(1, force)])
		for text: Dictionary in [conditioned, amount]:
			var errors := _text_errors(text)
			assert_bool(_mentions(errors, "en attente d'une question du ruleset")).is_true()
	var spell := _spell_text([_conditioned(force)])
	assert_bool(_mentions(_text_errors(spell), "en attente d'une question du ruleset")).is_true()


func test_207_3_12a_a_gear_does_not_carry_an_other_piece_destroyed_text() -> void:
	# En attente d'une question du ruleset (voir 207.3.12a, 207.3.15).
	var data := _with(CatalogSamples.gear(), "texts", [_triggered("other_piece_destroyed")])
	var errors := CardDefinition.from_dict(data).find_errors()
	assert_bool(_mentions(errors, "en attente d'une question du ruleset")).is_true()
	for base: Dictionary in [CatalogSamples.unit(), CatalogSamples.building()]:
		var carried := _with(base, "texts", [_triggered("other_piece_destroyed")])
		assert_array(Array(CardDefinition.from_dict(carried).find_errors())).is_empty()


func _carriers_of(trigger: String) -> Array[Dictionary]:
	var carriers: Array[Dictionary] = [CatalogSamples.unit(), CatalogSamples.building()]
	if trigger == "spell_countered":
		carriers.append(CatalogSamples.gear())
	return carriers
