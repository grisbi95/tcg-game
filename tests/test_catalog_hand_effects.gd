extends GdUnitTestSuite
## Catalogue : sujet d'un effet et effets de main (ruleset 0.53, décisions 0010 et 0057) :
## `subject`, accord avec le `kind`, paramètres de piocher, défausser, regarder et réveiller.
## Ne résout aucun effet : la résolution est dans test_212_discard.gd, test_217_look_at_top.gd et
## test_draw_and_wake_effects.gd.

const FIRST_HAND_KIND_VALUE: int = 7  # le premier kind de la décision 0057, après RETURN_TO_HAND
const KIND := EffectDefinition.EffectKind
const SUBJECT := EffectDefinition.EffectSubject


func _errors(data: Dictionary) -> PackedStringArray:
	return CatalogSamples.effect_errors(data)


func _mentions(errors: PackedStringArray, fragment: String) -> bool:
	return CatalogSamples.mentions(errors, fragment)


func test_decision_0057_hand_effect_samples_are_valid() -> void:
	for data: Dictionary in HandEffectSamples.card_data():
		assert_array(CardDefinition.from_dict(data).find_errors()).is_empty()
	for data: Dictionary in HandEffectSamples.effect_samples():
		assert_array(Array(_errors(data))).is_empty()


func test_decision_0057_new_kinds_come_last_and_keep_their_values() -> void:
	assert_int(KIND.RETURN_TO_HAND).is_equal(FIRST_HAND_KIND_VALUE - 1)
	assert_int(KIND.DRAW_CARDS).is_equal(FIRST_HAND_KIND_VALUE)
	assert_int(KIND.DISCARD_CARDS).is_equal(FIRST_HAND_KIND_VALUE + 1)
	assert_int(KIND.LOOK_AT_TOP_CARD).is_equal(FIRST_HAND_KIND_VALUE + 2)
	assert_int(KIND.WAKE).is_equal(FIRST_HAND_KIND_VALUE + 3)
	assert_int(SUBJECT.TARGETS).is_equal(0)
	assert_int(SUBJECT.OWNER_PLAYER).is_equal(1)
	assert_int(SUBJECT.SOURCE_PIECE).is_equal(2)


func test_decision_0057_subject_defaults_to_the_targets() -> void:
	var effect := CatalogSamples.effect_from(CatalogSamples.modify_force_resolve())
	assert_int(effect.subject).is_equal(SUBJECT.TARGETS)
	(
		assert_array(Array(CatalogSamples.effect_errors(CatalogSamples.modify_force_resolve())))
		. is_empty()
	)
	for data: Dictionary in [
		CatalogSamples.destroy_effect(),
		CatalogSamples.swap_cells_effect(),
		CatalogSamples.move_unit_effect(),
		CatalogSamples.return_to_hand_effect(),
		CatalogSamples.counter_spell_effect(),
		CatalogSamples.create_token_effect(),
	]:
		assert_int(CatalogSamples.effect_from(data).subject).is_equal(SUBJECT.TARGETS)


func test_decision_0057_subject_is_read_and_closed() -> void:
	assert_int(CatalogSamples.effect_from(HandEffectSamples.draw_effect(1)).subject).is_equal(
		SUBJECT.OWNER_PLAYER
	)
	var source := CatalogSamples.effect_from(HandEffectSamples.wake_source_effect())
	assert_int(source.subject).is_equal(SUBJECT.SOURCE_PIECE)
	var unknown := CatalogSamples.with_field(
		HandEffectSamples.draw_effect(1), "subject", "adversaire"
	)
	assert_array(Array(_errors(unknown))).is_not_empty()


func test_decision_0057_an_effect_without_target_is_admitted_unless_it_targets() -> void:
	assert_array(Array(_errors(HandEffectSamples.draw_effect(1)))).is_empty()
	var no_target := CatalogSamples.without_field(CatalogSamples.destroy_effect(), "target")
	assert_bool(_mentions(_errors(no_target), "207.5.1")).is_true()
	var wake_without_target := CatalogSamples.without_field(
		HandEffectSamples.wake_effect(), "target"
	)
	assert_bool(_mentions(_errors(wake_without_target), "207.5.1")).is_true()


func test_decision_0057_an_effect_that_does_not_target_names_no_target() -> void:
	var with_target := CatalogSamples.with_field(
		HandEffectSamples.draw_effect(1), "target", CatalogSamples.ally_unit_target()
	)
	assert_bool(_mentions(_errors(with_target), "0057")).is_true()


func test_decision_0057_subject_matches_the_kind() -> void:
	for data: Dictionary in [
		HandEffectSamples.draw_effect(1),
		HandEffectSamples.discard_effect(1),
		HandEffectSamples.look_effect(),
	]:
		var on_targets := CatalogSamples.with_field(data, "subject", "targets")
		assert_bool(_mentions(_errors(on_targets), "n'admet pas le sujet")).is_true()
		var on_source := CatalogSamples.with_field(data, "subject", "source_piece")
		assert_bool(_mentions(_errors(on_source), "n'admet pas le sujet")).is_true()
	var destroy := CatalogSamples.with_field(
		CatalogSamples.destroy_effect(), "subject", "owner_player"
	)
	assert_bool(_mentions(_errors(destroy), "n'admet pas le sujet")).is_true()
	var wake_on_player := CatalogSamples.with_field(
		CatalogSamples.without_field(HandEffectSamples.wake_effect(), "target"),
		"subject",
		"owner_player"
	)
	assert_bool(_mentions(_errors(wake_on_player), "n'admet pas le sujet")).is_true()


func test_decision_0057_the_source_piece_is_for_a_triggered_effect_only() -> void:
	var at_resolution := CatalogSamples.with_field(
		HandEffectSamples.wake_source_effect(), "timing", "resolve"
	)
	at_resolution = CatalogSamples.without_field(at_resolution, "trigger")
	assert_bool(_mentions(_errors(at_resolution), "source_piece")).is_true()
	assert_array(Array(_errors(HandEffectSamples.wake_source_effect()))).is_empty()


func test_decision_0057_a_static_effect_names_no_subject() -> void:
	var static_effect := CatalogSamples.with_field(
		CatalogSamples.modify_force_static(), "subject", "owner_player"
	)
	assert_bool(_mentions(_errors(static_effect), "statique")).is_true()


func test_decision_0057_draw_and_discard_count_at_least_one_card() -> void:
	for data: Dictionary in [HandEffectSamples.draw_effect(1), HandEffectSamples.discard_effect(1)]:
		for amount: int in [0, -1]:
			var refused := CatalogSamples.with_field(data, "amount", amount)
			assert_bool(_mentions(_errors(refused), "amount")).is_true()
		assert_array(Array(_errors(CatalogSamples.with_field(data, "amount", 2)))).is_empty()


func test_decision_0057_look_and_wake_take_no_amount() -> void:
	for data: Dictionary in [HandEffectSamples.look_effect(), HandEffectSamples.wake_effect()]:
		var refused := CatalogSamples.with_field(data, "amount", 1)
		assert_bool(_mentions(_errors(refused), "amount")).is_true()


func test_decision_0057_wake_effect_targets_units_or_heroes_never_buildings() -> void:
	assert_array(Array(_errors(HandEffectSamples.wake_unit_or_hero_effect()))).is_empty()
	for kinds: Array in [["building"], ["unit", "building"], []]:
		var target := {"what": "piece", "filter": {"piece_kinds": kinds}}
		var refused := CatalogSamples.with_field(HandEffectSamples.wake_effect(), "target", target)
		assert_bool(_mentions(_errors(refused), "205.5.6")).is_true()


func test_decision_0057_a_building_does_not_carry_a_source_wake_effect() -> void:
	var building := CatalogSamples.with_effects(
		CatalogSamples.building(), [HandEffectSamples.wake_source_effect()]
	)
	building = CatalogSamples.with_field(building, "keywords", [{"keyword": "arrival"}])
	assert_bool(_mentions(CardDefinition.from_dict(building).find_errors(), "205.5.6")).is_true()
	var unit := CatalogSamples.with_effects(
		CatalogSamples.unit(), [HandEffectSamples.wake_source_effect()]
	)
	unit = CatalogSamples.with_field(unit, "keywords", [{"keyword": "arrival"}])
	assert_array(Array(CardDefinition.from_dict(unit).find_errors())).is_empty()


func test_decision_0057_hand_effects_are_actions_not_static() -> void:
	for data: Dictionary in HandEffectSamples.effect_samples():
		var static_effect := CatalogSamples.with_field(data, "timing", "static")
		assert_array(Array(_errors(static_effect))).is_not_empty()
