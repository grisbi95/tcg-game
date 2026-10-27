# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## Catalogue : définitions de cartes et de Heroes (ruleset 0.52, décisions 0002, 0010 et 0055 ;
## décision de design 0211 du ruleset pour l'Ordre). Un test nommé par identifiant vérifie une
## règle de 202.1, 202.2, 202.3, 207.1 ou 211 ; les autres vérifient le contrat du format JSON.


func _card_errors(data: Dictionary) -> PackedStringArray:
	return CardDefinition.from_dict(data).find_errors()


func _hero_errors(data: Dictionary) -> PackedStringArray:
	return HeroDefinition.from_dict(data).find_errors()


func _mentions(errors: PackedStringArray, fragment: String) -> bool:
	return CatalogSamples.mentions(errors, fragment)


func test_valid_samples_have_no_errors() -> void:
	assert_array(Array(_card_errors(CatalogSamples.unit()))).is_empty()
	assert_array(Array(_card_errors(CatalogSamples.building()))).is_empty()
	assert_array(Array(_card_errors(CatalogSamples.spell()))).is_empty()
	assert_array(Array(_card_errors(CatalogSamples.gear()))).is_empty()
	assert_array(Array(_hero_errors(CatalogSamples.hero()))).is_empty()


func test_202_1_1_name_is_required() -> void:
	var errors := _card_errors(CatalogSamples.without_field(CatalogSamples.unit(), "name"))
	assert_bool(_mentions(errors, "202.1.1")).is_true()


func test_202_1_2_cost_is_required() -> void:
	var errors := _card_errors(CatalogSamples.without_field(CatalogSamples.unit(), "cost"))
	assert_bool(_mentions(errors, "202.1.2")).is_true()


func test_202_1_2_cost_is_a_whole_number_of_at_least_zero() -> void:
	var negative := _card_errors(CatalogSamples.with_field(CatalogSamples.unit(), "cost", -1))
	var fractional := _card_errors(CatalogSamples.with_field(CatalogSamples.unit(), "cost", 1.5))
	var text := _card_errors(CatalogSamples.with_field(CatalogSamples.unit(), "cost", "deux"))
	assert_bool(negative.is_empty()).is_false()
	assert_bool(fractional.is_empty()).is_false()
	assert_bool(text.is_empty()).is_false()


func test_202_1_2_cost_zero_is_accepted() -> void:
	var errors := _card_errors(CatalogSamples.with_field(CatalogSamples.unit(), "cost", 0))
	assert_array(Array(errors)).is_empty()


func test_202_1_3_type_is_required() -> void:
	var errors := _card_errors(CatalogSamples.without_field(CatalogSamples.unit(), "type"))
	assert_bool(_mentions(errors, "202.1.3")).is_true()


func test_202_1_4_text_is_required_but_may_be_empty() -> void:
	var missing := _card_errors(CatalogSamples.without_field(CatalogSamples.unit(), "text"))
	var empty := _card_errors(CatalogSamples.with_field(CatalogSamples.unit(), "text", ""))
	assert_bool(_mentions(missing, "202.1.4")).is_true()
	assert_array(Array(empty)).is_empty()


func test_202_1_5_unit_requires_force() -> void:
	var errors := _card_errors(CatalogSamples.without_field(CatalogSamples.unit(), "force"))
	assert_bool(_mentions(errors, "202.1.5")).is_true()


func test_202_1_6_building_requires_force() -> void:
	var errors := _card_errors(CatalogSamples.without_field(CatalogSamples.building(), "force"))
	assert_bool(_mentions(errors, "202.1.6")).is_true()


func test_202_1_7_spell_has_no_force() -> void:
	var errors := _card_errors(CatalogSamples.with_field(CatalogSamples.spell(), "force", 1))
	assert_bool(_mentions(errors, "202.1.7")).is_true()


func test_202_1_8_gear_has_no_force() -> void:
	var errors := _card_errors(CatalogSamples.with_field(CatalogSamples.gear(), "force", 1))
	assert_bool(_mentions(errors, "202.1.8")).is_true()


func test_202_1_5_force_zero_is_a_force() -> void:
	var card := CardDefinition.from_dict(
		CatalogSamples.with_field(CatalogSamples.unit(), "force", 0)
	)
	assert_array(Array(card.find_errors())).is_empty()
	assert_int(card.force).is_equal(0)


func test_202_2_1_four_card_types() -> void:
	assert_int(CardDefinition.CardType.size()).is_equal(4)
	var types: Array[CardDefinition.CardType] = [
		CardDefinition.from_dict(CatalogSamples.unit()).card_type,
		CardDefinition.from_dict(CatalogSamples.building()).card_type,
		CardDefinition.from_dict(CatalogSamples.spell()).card_type,
		CardDefinition.from_dict(CatalogSamples.gear()).card_type,
	]
	(
		assert_array(types)
		. contains_exactly(
			[
				CardDefinition.CardType.UNIT,
				CardDefinition.CardType.BUILDING,
				CardDefinition.CardType.SPELL,
				CardDefinition.CardType.GEAR,
			]
		)
	)


func test_202_2_1_unknown_type_is_refused() -> void:
	var errors := _card_errors(CatalogSamples.with_field(CatalogSamples.unit(), "type", "hero"))
	assert_bool(_mentions(errors, "« type » : « hero » inconnu")).is_true()


func test_202_2_20_spell_effect_resolves() -> void:
	var data := CatalogSamples.with_effects(
		CatalogSamples.spell(), [CatalogSamples.modify_force_static()]
	)
	assert_bool(_mentions(_card_errors(data), "timing refusé pour spell")).is_true()


func test_207_2_8_gear_effect_is_static() -> void:
	var data := CatalogSamples.with_effects(
		CatalogSamples.gear(), [CatalogSamples.modify_force_resolve()]
	)
	assert_bool(_mentions(_card_errors(data), "timing refusé pour gear")).is_true()


func test_207_2_2_unit_effect_is_static_or_triggered() -> void:
	var resolve := CatalogSamples.with_effects(
		CatalogSamples.unit(), [CatalogSamples.modify_force_resolve()]
	)
	var static_effect := CatalogSamples.with_effects(
		CatalogSamples.unit(), [CatalogSamples.modify_force_static()]
	)
	assert_bool(_mentions(_card_errors(resolve), "timing refusé pour unit")).is_true()
	assert_array(Array(_card_errors(static_effect))).is_empty()


func test_207_1_1_spell_requires_speed() -> void:
	var errors := _card_errors(CatalogSamples.without_field(CatalogSamples.spell(), "speed"))
	assert_bool(_mentions(errors, "207.1.1")).is_true()


func test_207_1_2_speed_is_action_or_reaction() -> void:
	var action := CardDefinition.from_dict(
		CatalogSamples.with_field(CatalogSamples.spell(), "speed", "action")
	)
	var unknown := _card_errors(CatalogSamples.with_field(CatalogSamples.spell(), "speed", "slow"))
	assert_int(action.speed).is_equal(CardDefinition.SpellSpeed.ACTION)
	assert_array(Array(action.find_errors())).is_empty()
	assert_bool(_mentions(unknown, "« speed » : « slow » inconnu")).is_true()


func test_207_1_1_only_a_spell_has_a_speed() -> void:
	var errors := _card_errors(CatalogSamples.with_field(CatalogSamples.unit(), "speed", "action"))
	assert_bool(_mentions(errors, "207.1.1")).is_true()


func test_202_3_6_hero_requires_a_name() -> void:
	var errors := _hero_errors(CatalogSamples.without_field(CatalogSamples.hero(), "name"))
	assert_bool(_mentions(errors, "202.3.6")).is_true()


func test_202_3_7_hero_has_health() -> void:
	var missing := _hero_errors(CatalogSamples.without_field(CatalogSamples.hero(), "health"))
	var zero := _hero_errors(CatalogSamples.with_field(CatalogSamples.hero(), "health", 0))
	assert_bool(_mentions(missing, "202.3.7")).is_true()
	assert_bool(_mentions(zero, "202.3.7")).is_true()


func test_202_3_8_hero_text_is_required() -> void:
	var errors := _hero_errors(CatalogSamples.without_field(CatalogSamples.hero(), "text"))
	assert_bool(_mentions(errors, "202.3.8")).is_true()


func test_202_3_9_hero_has_no_force() -> void:
	var errors := _hero_errors(CatalogSamples.with_field(CatalogSamples.hero(), "force", 3))
	assert_bool(_mentions(errors, "202.3.9")).is_true()


func test_202_3_11_hero_passive_is_optional() -> void:
	var passive_only := HeroDefinition.from_dict(CatalogSamples.hero())
	assert_array(passive_only.passive).has_size(1)
	var without_passive := OrderSamples.hero_data(OrderSamples.HERO, false)
	assert_array(Array(_hero_errors(without_passive))).is_empty()
	assert_array(HeroDefinition.from_dict(without_passive).passive).is_empty()


func test_202_3_19_hero_text_may_carry_orders() -> void:
	var hero := HeroDefinition.from_dict(OrderSamples.hero_data(OrderSamples.HERO, false))
	assert_array(Array(hero.find_errors())).is_empty()
	assert_array(hero.orders).has_size(OrderSamples.ORDER_COUNT)
	assert_array(HeroDefinition.from_dict(CatalogSamples.hero()).orders).is_empty()


func test_202_3_20_hero_text_may_carry_a_triggered_effect() -> void:
	var data := OrderSamples.hero_data(OrderSamples.HERO, false)
	var hero := HeroDefinition.from_dict(data)
	assert_array(hero.triggered).has_size(1)
	var untimed := CatalogSamples.with_flats(
		data, "triggered", [CatalogSamples.modify_force_resolve()]
	)
	assert_bool(_mentions(_hero_errors(untimed), "triggered 1 : timing refusé")).is_true()
	var no_event := CatalogSamples.triggered("end_of_turn")
	no_event.erase("trigger")
	var unnamed := CatalogSamples.with_flats(data, "triggered", [no_event])
	assert_bool(_mentions(_hero_errors(unnamed), "207.3.1")).is_true()


func test_202_3_21_hero_text_fixes_the_number_of_orders_and_triggered_effects() -> void:
	var data := OrderSamples.hero_data(OrderSamples.HERO, false)
	var orders: Array = data["orders"]
	var hero := HeroDefinition.from_dict(data)
	assert_int(hero.orders.size()).is_equal(orders.size())
	assert_int(hero.triggered.size()).is_equal(1)
	data["orders"] = [orders[0]]
	assert_int(HeroDefinition.from_dict(data).orders.size()).is_equal(1)


func test_202_3_22_hero_text_carries_at_least_one_ability() -> void:
	var data := OrderSamples.hero_data(OrderSamples.HERO, false)
	data["orders"] = []
	data["triggered"] = []
	assert_bool(_mentions(_hero_errors(data), "202.3.22")).is_true()
	assert_bool(_mentions(_hero_errors(CatalogSamples.hero()), "202.3.22")).is_false()
	data["triggered"] = CatalogSamples.texts_of([CatalogSamples.triggered("end_of_turn")])
	assert_array(Array(_hero_errors(data))).is_empty()


func test_211_1_2_order_carries_a_speed() -> void:
	var data := OrderSamples.hero_data(OrderSamples.HERO, false)
	var orders: Array = data["orders"]
	var order: Dictionary = orders[0]
	order.erase("speed")
	assert_bool(_mentions(_hero_errors(data), "211.1.2")).is_true()
	order["speed"] = "none"
	assert_bool(_mentions(_hero_errors(data), "211.1.2")).is_true()
	order["speed"] = "reaction"
	assert_array(Array(_hero_errors(data))).is_empty()


func test_211_1_3_order_cost_is_nil_by_default() -> void:
	var order := HeroOrder.from_dict({"speed": "action", "texts": []})
	assert_int(order.cost).is_equal(0)
	assert_array(Array(order.find_errors())).is_empty()
	var negative := HeroOrder.from_dict({"speed": "action", "cost": -1})
	assert_bool(_mentions(negative.find_errors(), "« cost »")).is_true()


func test_decision_0055_order_effects_resolve_like_a_spell() -> void:
	var data := OrderSamples.hero_data(OrderSamples.HERO, false)
	var orders: Array = data["orders"]
	var order: Dictionary = orders[0]
	order["texts"] = CatalogSamples.texts_of([CatalogSamples.modify_force_static()])
	assert_bool(_mentions(_hero_errors(data), "timing refusé pour un Ordre")).is_true()
	order["texts"] = CatalogSamples.texts_of([CatalogSamples.modify_force_resolve({"amount": 0})])
	assert_bool(_mentions(_hero_errors(data), "order 1 : texte 1 : effet 1")).is_true()


func test_202_3_18_hero_passive_is_static() -> void:
	var data := CatalogSamples.with_flats(
		CatalogSamples.hero(), "passive", [CatalogSamples.modify_force_resolve()]
	)
	assert_bool(_mentions(_hero_errors(data), "passive 1 : timing refusé")).is_true()


func test_id_is_ascii_snake_case() -> void:
	for bad_id: String in ["", "Soldat", "vétéran", "deux mots", "1er"]:
		var errors := _card_errors(CatalogSamples.with_field(CatalogSamples.unit(), "id", bad_id))
		assert_bool(_mentions(errors, "snake_case")).is_true()


func test_unknown_field_is_refused() -> void:
	var errors := _card_errors(CatalogSamples.with_field(CatalogSamples.unit(), "forcce", 3))
	assert_bool(_mentions(errors, "« forcce » inconnu")).is_true()


func test_wrong_json_type_is_refused() -> void:
	var errors := _card_errors(CatalogSamples.with_field(CatalogSamples.unit(), "name", 12))
	assert_bool(_mentions(errors, "« name » doit être un texte")).is_true()


func test_parsed_fields_reach_the_definition() -> void:
	var card := CardDefinition.from_dict(CatalogSamples.unit())
	assert_str(card.id).is_equal("sample_unit")
	assert_str(card.card_name).is_equal("Unit d'essai")
	assert_int(card.cost).is_equal(2)
	assert_int(card.force).is_equal(3)
	assert_int(card.card_type).is_equal(CardDefinition.CardType.UNIT)
