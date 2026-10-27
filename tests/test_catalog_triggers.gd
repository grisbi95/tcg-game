extends GdUnitTestSuite
## Catalogue : événements déclencheurs nommés avec leur auteur, Gear à effet déclenché et condition
## (ruleset 0.54, décisions 0010 et 0060). Ne résout aucun effet.

const NEW_EVENTS: Array[String] = [
	"start_of_own_turn", "own_spell_announced", "own_card_discarded", "destroys_defender"
]


func _card_errors(data: Dictionary) -> PackedStringArray:
	return CardDefinition.from_dict(data).find_errors()


func _with_trigger(card: Dictionary, trigger: String) -> Dictionary:
	var effect := HandEffectSamples.draw_effect(1)
	effect["timing"] = "triggered"
	effect["trigger"] = trigger
	return CatalogSamples.with_effects(card, [effect])


func test_decision_0060_new_trigger_events_are_appended_after_the_existing_ones() -> void:
	var names := EffectDefinition.TriggerEvent.keys()
	assert_array(names.slice(0, 4)).contains_exactly(
		["NONE", "ARRIVAL", "DESTROYED", "END_OF_TURN"]
	)
	assert_array(names.slice(4)).contains_exactly(
		["START_OF_OWN_TURN", "OWN_SPELL_ANNOUNCED", "OWN_CARD_DISCARDED", "DESTROYS_DEFENDER"]
	)


func test_decision_0060_new_trigger_events_are_valid_for_a_unit() -> void:
	for trigger: String in NEW_EVENTS:
		var data := _with_trigger(CatalogSamples.unit(), trigger)
		assert_array(Array(_card_errors(data))).is_empty()


func test_decision_0060_building_refuses_only_the_event_of_an_attacking_piece() -> void:
	for trigger: String in NEW_EVENTS:
		var errors := _card_errors(_with_trigger(CatalogSamples.building(), trigger))
		var expected_refused := trigger == "destroys_defender"
		assert_bool(CatalogSamples.mentions(errors, "206.3.7")).is_equal(expected_refused)


func test_decision_0060_gear_admits_the_events_that_make_sense_for_it() -> void:
	for trigger: String in NEW_EVENTS + ["end_of_turn"]:
		var data := _with_trigger(CatalogSamples.gear(), trigger)
		assert_array(Array(_card_errors(data))).is_empty()


func test_decision_0060_gear_refuses_the_keyword_events_of_a_piece() -> void:
	for trigger: String in ["arrival", "destroyed"]:
		var errors := _card_errors(_with_trigger(CatalogSamples.gear(), trigger))
		assert_bool(CatalogSamples.mentions(errors, "210.3")).is_true()


func test_decision_0060_hero_effect_cannot_destroy_a_defender() -> void:
	var effect := HandEffectSamples.draw_effect(1)
	effect["timing"] = "triggered"
	effect["trigger"] = "destroys_defender"
	var data := CatalogSamples.with_flats(
		NamedTriggerSamples.hero_data(&"x_hero", false), "triggered", [effect]
	)
	var errors := HeroDefinition.from_dict(data).find_errors()
	assert_bool(CatalogSamples.mentions(errors, "206.3.7")).is_true()


func test_decision_0060_named_trigger_samples_are_valid() -> void:
	for data: Dictionary in NamedTriggerSamples.card_data():
		assert_array(Array(_card_errors(data))).is_empty()
	var catalog := NamedTriggerSamples.catalog()
	assert_array(Array(catalog.find_errors())).is_empty()


func test_decision_0060_condition_is_read_from_the_json_effect() -> void:
	var effect := HandEffectSamples.draw_effect(1)
	effect["timing"] = "triggered"
	effect["trigger"] = "start_of_own_turn"
	effect["condition"] = {"kind": "hand_size_at_most", "amount": 1}
	var text := CatalogSamples.text_from(effect)
	assert_array(Array(text.find_errors())).is_empty()
	assert_int(text.condition.amount).is_equal(1)
	assert_object(CatalogSamples.text_from(HandEffectSamples.draw_effect(1)).condition).is_null()


func test_decision_0060_condition_must_be_an_object() -> void:
	var effect := HandEffectSamples.draw_effect(1)
	effect["timing"] = "triggered"
	effect["trigger"] = "start_of_own_turn"
	effect["condition"] = "hand_size_at_most"
	(
		assert_bool(
			CatalogSamples.mentions(
				CatalogSamples.effect_errors(effect), "« condition » doit être un objet"
			)
		)
		. is_true()
	)
