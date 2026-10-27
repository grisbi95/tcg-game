# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## Catalogue : textes d'effets, suite d'effets et ensemble touché sans cible (ruleset 0.55 ;
## 207.3.13, 207.4.11, 207.5.18, 207.7.1, 207.7.4, 207.7.6 à 207.7.6b, 211.1.5 ; décisions 0010 et
## 0064). Ne résout aucun effet : ces tests vérifient que le catalogue lit et refuse.

const SUBJECT := EffectDefinition.EffectSubject


func _text_errors(data: Dictionary) -> PackedStringArray:
	return EffectText.from_dict(data).find_errors()


func _card_errors(data: Dictionary) -> PackedStringArray:
	return CardDefinition.from_dict(data).find_errors()


func _mentions(errors: PackedStringArray, fragment: String) -> bool:
	return CatalogSamples.mentions(errors, fragment)


func _draw() -> Dictionary:
	return CatalogSamples.plain_effect(HandEffectSamples.draw_effect(1))


func _matching(kind: String, affected: Dictionary, extra: Dictionary = {}) -> Dictionary:
	var effect := {"kind": kind, "subject": "matching_pieces", "affected": affected}
	effect.merge(extra, true)
	return effect


func _resolve_text(effects: Array) -> Dictionary:
	return TextSamples.text_of(effects)


func test_decision_0064_a_text_is_read_with_its_ordered_effects() -> void:
	var data := _resolve_text(
		[_draw(), CatalogSamples.plain_effect(HandEffectSamples.look_effect())]
	)
	var text := EffectText.from_dict(data)
	assert_array(Array(text.find_errors())).is_empty()
	assert_int(text.timing).is_equal(EffectDefinition.EffectTiming.RESOLVE)
	assert_int(text.effects.size()).is_equal(2)
	assert_int(text.effects[0].kind).is_equal(EffectDefinition.EffectKind.DRAW_CARDS)
	assert_int(text.effects[1].kind).is_equal(EffectDefinition.EffectKind.LOOK_AT_TOP_CARD)


func test_decision_0064_a_text_needs_a_timing_and_effects() -> void:
	assert_bool(_mentions(_text_errors({"effects": [_draw()]}), "« timing » absent")).is_true()
	assert_bool(_mentions(_text_errors({"timing": "resolve"}), "« effects » absent")).is_true()
	var unknown := {"timing": "later", "effects": [_draw()]}
	assert_bool(_mentions(_text_errors(unknown), "« later » inconnu")).is_true()
	var stray := _resolve_text([_draw()])
	stray["colour"] = "red"
	assert_bool(_mentions(_text_errors(stray), "« colour » inconnu")).is_true()


func test_207_7_4_a_text_carries_at_least_one_effect() -> void:
	assert_bool(_mentions(_text_errors(_resolve_text([])), "207.7.4")).is_true()


func test_decision_0064_a_static_text_carries_a_single_effect() -> void:
	var one := TextSamples.text_of(
		[CatalogSamples.plain_effect(CatalogSamples.modify_force_static())], "static"
	)
	assert_array(Array(_text_errors(one))).is_empty()
	var statics := CatalogSamples.plain_effect(CatalogSamples.modify_force_static())
	var two := TextSamples.text_of([statics, statics.duplicate(true)], "static")
	assert_bool(_mentions(_text_errors(two), "0064")).is_true()


func test_decision_0064_a_spell_or_an_order_carries_at_most_one_text() -> void:
	var two_texts := [_resolve_text([_draw()]), _resolve_text([_draw()])]
	var spell := CatalogSamples.with_field(CatalogSamples.spell(), "texts", two_texts)
	assert_bool(_mentions(_card_errors(spell), "au plus un texte")).is_true()
	var order := HeroOrder.from_dict({"speed": "action", "texts": two_texts})
	assert_bool(_mentions(order.find_errors(), "au plus un texte")).is_true()
	var one_text := CatalogSamples.with_field(CatalogSamples.spell(), "texts", [two_texts[0]])
	assert_array(Array(_card_errors(one_text))).is_empty()


func test_207_7_6_if_you_do_depends_on_the_effect_before_it_and_is_never_first() -> void:
	var follower := _draw()
	follower["if_you_do"] = true
	assert_array(Array(_text_errors(_resolve_text([_draw(), follower])))).is_empty()
	assert_bool(_mentions(_text_errors(_resolve_text([follower])), "207.7.6")).is_true()
	var triggered := TextSamples.text_of(
		[_draw(), follower], "triggered", {"trigger": "end_of_turn"}
	)
	assert_array(Array(_text_errors(triggered))).is_empty()  # 207.7.6 vaut pour tout texte


func test_207_7_6_if_you_do_is_read_as_a_boolean() -> void:
	var follower := _draw()
	follower["if_you_do"] = "oui"
	var errors := _text_errors(_resolve_text([_draw(), follower]))
	assert_bool(_mentions(errors, "« if_you_do » doit être vrai ou faux")).is_true()
	(
		assert_bool(EffectText.from_dict(_resolve_text([_draw(), _draw()])).effects[1].if_you_do)
		. is_false()
	)


func test_decision_0064_if_you_do_does_not_combine_with_an_if_condition() -> void:
	var follower := _draw()
	follower["if_you_do"] = true
	follower["condition"] = CatalogSamples.hand_size_condition("at_most", 1)
	var errors := _text_errors(_resolve_text([_draw(), follower]))
	assert_bool(_mentions(errors, "207.7.6b")).is_true()


func test_207_7_6_a_static_effect_depends_on_no_other() -> void:
	var statics := CatalogSamples.plain_effect(CatalogSamples.modify_force_static())
	statics["if_you_do"] = true
	var errors := _text_errors(TextSamples.text_of([statics], "static"))
	assert_bool(_mentions(errors, "207.7.6")).is_true()


func test_207_7_1_if_condition_is_for_the_text_of_a_spell_or_an_order() -> void:
	var conditioned := _draw()
	conditioned["condition"] = CatalogSamples.hand_size_condition("at_most", 2)
	var spell := CatalogSamples.with_field(
		CatalogSamples.spell(), "texts", [_resolve_text([_draw(), conditioned])]
	)
	assert_array(Array(_card_errors(spell))).is_empty()
	var order := HeroOrder.from_dict({"speed": "action", "texts": [_resolve_text([conditioned])]})
	assert_array(Array(order.find_errors())).is_empty()


func test_decision_0064_if_condition_of_an_effect_of_a_triggered_text_is_refused() -> void:
	# Limite en attente d'une question du ruleset : 207.7.1 ne nomme que le Spell et l'Ordre ; la
	# condition d'un texte déclenché se lit à l'événement (207.3.13) et s'écrit sur le texte.
	var conditioned := _draw()
	conditioned["condition"] = CatalogSamples.hand_size_condition("at_most", 2)
	var triggered := TextSamples.text_of(
		[_draw(), conditioned], "triggered", {"trigger": "end_of_turn"}
	)
	assert_bool(_mentions(_text_errors(triggered), "207.7.1")).is_true()


func test_207_7_1_if_condition_is_read_as_a_closed_object() -> void:
	var conditioned := _draw()
	conditioned["condition"] = CatalogSamples.condition({"kind": "hand_empty"}, "at_most", 0)
	var errors := _text_errors(_resolve_text([conditioned]))
	assert_bool(_mentions(errors, "« hand_empty » inconnu")).is_true()


func test_207_3_13_event_condition_stays_on_the_triggered_text() -> void:
	var condition := CatalogSamples.hand_size_condition("at_most", 1)
	var triggered := TextSamples.text_of(
		[_draw()], "triggered", {"trigger": "start_of_own_turn", "condition": condition}
	)
	var text := EffectText.from_dict(triggered)
	assert_array(Array(text.find_errors())).is_empty()
	assert_int(text.condition.amount).is_equal(1)
	assert_object(text.effects[0].condition).is_null()


func test_decision_0064_a_triggered_text_targets_through_a_single_effect() -> void:
	var target := CatalogSamples.plain_effect(CatalogSamples.modify_force_resolve())
	var triggered := TextSamples.text_of(
		[target, target.duplicate(true)], "triggered", {"trigger": "end_of_turn"}
	)
	assert_bool(_mentions(_text_errors(triggered), "0064")).is_true()
	var spell := CatalogSamples.with_field(
		CatalogSamples.spell(), "texts", [_resolve_text([target, target.duplicate(true)])]
	)
	assert_array(Array(_card_errors(spell))).is_empty()  # un Spell juge chaque effet (207.5.1a)


func test_decision_0064_effect_errors_name_the_text_and_the_effect() -> void:
	var broken := CatalogSamples.without_field(CatalogSamples.destroy_effect(), "target")
	var spell := CatalogSamples.with_field(
		CatalogSamples.spell(),
		"texts",
		[_resolve_text([_draw(), CatalogSamples.plain_effect(broken)])]
	)
	assert_bool(_mentions(_card_errors(spell), "texte 1 : effet 2 : 207.5.1")).is_true()


func test_decision_0064_an_effect_no_longer_carries_timing_trigger_or_once_per_turn() -> void:
	for key: String in ["timing", "trigger", "once_per_turn"]:
		var effect := CatalogSamples.with_field(_draw(), key, "triggered")
		(
			assert_bool(_mentions(_text_errors(_resolve_text([effect])), "« %s » inconnu" % key))
			. is_true()
		)


func test_decision_0064_hero_and_order_texts_are_read() -> void:
	var hero := HeroDefinition.from_dict(TextSamples.hero_data())
	assert_array(Array(hero.find_errors())).is_empty()
	assert_int(hero.orders.size()).is_equal(1)
	assert_int(EffectText.resolution_of(hero.orders[0].texts).effects[0].kind).is_equal(
		EffectDefinition.EffectKind.DRAW_CARDS
	)
	var catalog := TextSamples.catalog()
	assert_array(Array(catalog.find_errors())).is_empty()
	assert_int(catalog.triggerable_texts(TextSamples.WORKSITE).size()).is_equal(1)
	assert_int(catalog.triggerable_texts(TextSamples.WORKSITE)[0].effects.size()).is_equal(2)


func test_decision_0064_text_samples_are_valid() -> void:
	for data: Dictionary in TextSamples.card_data():
		assert_array(Array(_card_errors(data))).is_empty()


func test_decision_0064_matching_pieces_is_the_last_subject() -> void:
	var names := EffectDefinition.EffectSubject.keys()
	assert_array(names).contains_exactly(
		["TARGETS", "OWNER_PLAYER", "SOURCE_PIECE", "MATCHING_PIECES"]
	)


func test_207_4_11_matching_pieces_names_its_set_in_affected() -> void:
	var affected := {"side": "enemy", "piece_kinds": ["unit"]}
	var effect := _matching("destroy", affected)
	var text := EffectText.from_dict(_resolve_text([effect]))
	assert_array(Array(text.find_errors())).is_empty()
	assert_int(text.effects[0].subject).is_equal(SUBJECT.MATCHING_PIECES)
	assert_int(text.effects[0].affected.side).is_equal(PieceFilter.SideFilter.ENEMY)
	var without := CatalogSamples.without_field(effect, "affected")
	assert_bool(_mentions(_text_errors(_resolve_text([without])), "207.4.11")).is_true()
	var stray := CatalogSamples.with_field(CatalogSamples.destroy_effect(), "affected", affected)
	assert_bool(_mentions(CatalogSamples.effect_errors(stray), "207.4.11")).is_true()


func test_207_4_11_matching_pieces_names_no_target() -> void:
	var effect := _matching("destroy", {"piece_kinds": ["unit"]})
	effect["target"] = CatalogSamples.ally_unit_target()
	assert_bool(_mentions(_text_errors(_resolve_text([effect])), "0057")).is_true()


func test_207_4_11_matching_pieces_is_for_the_kinds_that_touch_pieces() -> void:
	var affected := {"piece_kinds": ["unit"]}
	var force := {"amount": -1, "duration": "until_end_of_turn"}
	var grant := {"keyword": "assault", "amount": 1, "duration": "until_end_of_turn"}
	for effect: Dictionary in [
		_matching("modify_force", affected, force),
		_matching("grant_keyword", affected, grant),
		_matching("destroy", affected),
		_matching("sleep", affected),
		_matching("wake", affected),
	]:
		assert_array(Array(_text_errors(_resolve_text([effect])))).is_empty()
	for kind: String in ["draw_cards", "create_token", "swap_cells", "move_unit", "return_to_hand"]:
		var refused := _text_errors(_resolve_text([_matching(kind, affected)]))
		assert_bool(_mentions(refused, "n'admet pas le sujet matching_pieces")).is_true()


func test_207_4_11_a_static_effect_names_its_scope_not_an_affected_set() -> void:
	var effect := CatalogSamples.plain_effect(CatalogSamples.modify_force_static())
	effect["subject"] = "matching_pieces"
	effect["affected"] = {"piece_kinds": ["unit"]}
	var errors := _text_errors(TextSamples.text_of([effect], "static"))
	assert_bool(_mentions(errors, "0057")).is_true()


func test_q_097_a_set_never_includes_a_hero_for_force_or_destruction() -> void:
	var force := {"amount": -1, "duration": "until_end_of_turn"}
	for affected: Dictionary in [{"piece_kinds": ["unit", "hero"]}, {}]:
		for effect: Dictionary in [
			_matching("modify_force", affected, force), _matching("destroy", affected)
		]:
			var errors := _text_errors(_resolve_text([effect]))
			assert_bool(_mentions(errors, "202.3.9")).is_true()


func test_210_4_1c_a_granted_keyword_reaches_units_only() -> void:
	var grant := {"keyword": "assault", "amount": 1, "duration": "until_end_of_turn"}
	for kinds: Array in [["unit", "building"], ["hero"], []]:
		var effect := _matching("grant_keyword", {"piece_kinds": kinds}, grant)
		assert_bool(_mentions(_text_errors(_resolve_text([effect])), "210.4.1c")).is_true()


func test_205_5_6_a_set_that_wakes_names_units_or_heroes_never_buildings() -> void:
	for kinds: Array in [["building"], ["unit", "building"], []]:
		var effect := _matching("wake", {"piece_kinds": kinds})
		assert_bool(_mentions(_text_errors(_resolve_text([effect])), "205.5.6")).is_true()
	var hero := _matching("wake", {"piece_kinds": ["unit", "hero"]})
	assert_array(Array(_text_errors(_resolve_text([hero])))).is_empty()


func test_207_3_14_a_set_relative_to_the_source_piece_is_for_a_triggered_text() -> void:
	var affected := {"piece_kinds": ["unit"], "relation": "adjacent"}
	var force := {"amount": -1, "duration": "until_end_of_turn"}
	var effect := _matching("modify_force", affected, force)
	assert_bool(_mentions(_text_errors(_resolve_text([effect])), "207.3.14")).is_true()
	var triggered := TextSamples.text_of([effect], "triggered", {"trigger": "arrival"})
	assert_array(Array(_text_errors(triggered))).is_empty()
	var from_hero := {"piece_kinds": ["unit"], "relation": "adjacent", "relative_to": "own_hero"}
	var spell := _matching("modify_force", from_hero, force)
	assert_array(Array(_text_errors(_resolve_text([spell])))).is_empty()


func test_decision_0064_if_you_do_does_not_follow_a_wake_nor_a_set_without_target() -> void:
	# Le ruleset n'écrit pas « a eu lieu » pour réveiller une pièce éveillée ni pour un ensemble vide.
	var follower := _draw()
	follower["if_you_do"] = true
	var wake := CatalogSamples.plain_effect(HandEffectSamples.wake_effect())
	var set_effect := _matching("destroy", {"piece_kinds": ["unit"]})
	for preceding: Dictionary in [wake, set_effect]:
		var errors := _text_errors(_resolve_text([preceding, follower]))
		assert_bool(_mentions(errors, "en attente d'une question du ruleset")).is_true()
	var after_sleep := CatalogSamples.plain_effect(HandEffectSamples.sleep_effect())
	assert_array(Array(_text_errors(_resolve_text([after_sleep, follower])))).is_empty()
