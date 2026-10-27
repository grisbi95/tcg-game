extends GdUnitTestSuite
## Couverture du ruleset par les tests (ruleset 0.36, décision 0007 ; tests/CLAUDE.md).
##
## Chaque règle [ACTÉ] ou [PROVISOIRE] de docs/ruleset/20-regles-completes/ a un test à son nom
## (`test_206_3_6_…`), une entrée justifiée de RULES_WITHOUT_OWN_TEST ou, en attendant son étape du
## jalon J2c, une entrée de RULES_AWAITING_IMPLEMENTATION (décision 0054) ; chaque raison de refus
## hors NONE est citée par un test.

const RULES_DIRECTORY: String = "res://docs/ruleset/20-regles-completes"
const TESTS_DIRECTORY: String = "res://tests"
const RULE_PATTERN: String = "(?m)^\\*\\*(\\d{3}\\.\\d+\\.\\d+[a-z]?)\\*\\* \\[(ACTÉ|PROVISOIRE)\\]"
const TEST_PATTERN: String = "(?m)^func (test_\\w+)\\("

## 207.3.4a, 207.3.7a, 207.3.11, 207.3.11a : un jeton ne porte aucun effet déclenché.
const TOKEN_HAS_NO_TRIGGERED_EFFECT: String = (
	"Sans test possible : un jeton ne porte aucun effet à sa création (202.4.5) et n'en "
	+ "reçoit un que d'un Gear, d'un Spell ou d'une aura (202.4.5a) ; l'effet déclenché d'un "
	+ "Gear est celui du Gear, à son joueur (207.3.12b, "
	+ "test_207_3_12b_gear_effect_belongs_to_the_player_who_owns_the_gear), et aucun "
	+ "EffectKind ne donne d'effet déclenché à un jeton."
)

## Règle sans test à son nom, et pourquoi : règle de structure, ou vérifiée sous d'autres
## règles, tests nommés.
const RULES_WITHOUT_OWN_TEST: Dictionary[String, String] = {
	"200.1.1": "Règle d'arbitrage entre règles du ruleset : sans comportement propre du moteur.",
	"200.2.1a":
	(
		"Garantie par le vocabulaire fermé d'EffectKind (décision 0002) : aucun kind ne "
		+ "contredit un Invariant ; Invariants vérifiés sous 201.0.1 "
		+ "(test_201_0_1_place_piece_refuses_an_occupied_cell) et 201.0.2 "
		+ "(test_201_0_2_board_has_25_cells_in_5_columns_and_5_rows)."
	),
	"200.3.1":
	(
		"Sans test possible : aucun EffectKind ni mot-clé n'interdit encore quoi que ce soit, "
		+ "aucun conflit entre interdiction et permission à arbitrer."
	),
	"200.3.1a": "Précise la portée de 200.3.1, sans comportement propre.",
	"200.3.1b":
	(
		"Renvoie à 200.2.1 : vérifiée sous 200.2.1 "
		+ "(test_200_2_1_card_text_overrides_the_deploy_zone_rule)."
	),
	"201.0.4":
	(
		"Invariant garanti par le vocabulaire fermé d'EffectKind (décision 0002) : aucun kind "
		+ "ne touche à la fin de partie, que seul StateCheckRules décide (chapitre 209)."
	),
	"201.3.3":
	(
		"Vérifiée sous 201.3.6a, 201.5.3 et 202.2.12 (tests : "
		+ "test_201_3_6a_card_returning_to_a_full_hand_goes_to_its_owner_discard, "
		+ "test_201_5_3_destroyed_cards_stay_with_their_owner, "
		+ "test_202_2_12_replaced_gear_goes_to_discard)."
	),
	"201.4.10":
	(
		"Information publique : le moteur est omniscient (201.4) et la réserve d'Essence est "
		+ "un champ de l'état (test_203_6_3_inclining_a_source_adds_to_the_reserve) ; la vue "
		+ "l'affiche pour les deux joueurs (étape 2.3)."
	),
	"202.2.23":
	(
		"Vérifiée sous 202.2.14 et 202.2.24 (tests : test_202_2_14_gear_only_on_own_unit, "
		+ "test_202_2_24_gear_not_attached_when_unit_is_gone)."
	),
	"203.0.1":
	(
		"Invariant : tout coût se paie par EssencePayment, aucune autre ressource n'existe "
		+ "dans l'état ; vérifiée sous 203.3.1 "
		+ "(test_203_3_1_payment_must_produce_exactly_the_cost)."
	),
	"203.1.1":
	(
		"Vérifiée sous 203.3.1 (test_203_3_1_payment_must_produce_exactly_the_cost) : aucune "
		+ "autre ressource n'existe dans l'état."
	),
	"203.1.2":
	(
		"Vérifiée sous 203.2.1 et 203.2.2 (tests : "
		+ "test_203_2_1_incline_upright_sources_pays_cost, "
		+ "test_203_2_2_recycle_tilted_sources_pays_cost)."
	),
	"206.0.2":
	(
		"Vérifiée sous 206.2.1, 206.0.1 et 202.2.18 (tests : "
		+ "test_206_2_1_combat_compares_both_forces, "
		+ "test_206_0_1_no_damage_persists_after_combat, "
		+ "test_202_2_18_building_defends_its_cell_with_its_force)."
	),
	"206.4.6a":
	(
		"Vérifiée sous 209.2.6 et 201.1.3a (tests : test_209_2_6_conceding_player_loses, "
		+ "test_201_1_3a_opponent_of_conceding_player_wins)."
	),
	"205.6.16":
	(
		"Sans test possible : aucun effet du vocabulaire d'EffectKind ne fait sortir de la pile "
		+ "la carte d'un déploiement (Contrecarrer ne vise que les Spells, 207.6) ; le combat en "
		+ "attente la porte jusqu'à sa résolution "
		+ "(test_205_6_8_deploying_card_stays_on_the_stack_with_the_combat)."
	),
	"207.3.4a": TOKEN_HAS_NO_TRIGGERED_EFFECT,
	"207.3.7a": TOKEN_HAS_NO_TRIGGERED_EFFECT,
	"207.3.11": TOKEN_HAS_NO_TRIGGERED_EFFECT,
	"207.3.11a": TOKEN_HAS_NO_TRIGGERED_EFFECT,
	"207.4.7":
	(
		"Vérifiée sous 207.4.7a, 207.4.7b, 204.5.7, 202.2.21 et 210.3.2b (tests : "
		+ "test_207_4_7a_effect_ends_for_piece_leaving_the_board, "
		+ "test_207_4_7b_effect_continues_for_pieces_still_on_board, "
		+ "test_204_5_7_until_end_of_turn_effects_end, "
		+ "test_202_2_21_effect_with_duration_outlives_the_spell, "
		+ "test_210_3_2b_last_breath_happens_after_the_piece_left_the_board)."
	),
	"207.5.12":
	(
		"Sans test possible : aucun EffectKind n'atteint encore un joueur par son Hero ; le "
		+ "Hero est une cible légale, vérifiée sous 207.5.11a "
		+ "(test_207_5_11a_hero_can_be_targeted)."
	),
	"208.2.4a":
	(
		"Sans test possible : aucun déclencheur ne réagit à l'annonce de l'adversaire, "
		+ "OWN_SPELL_ANNOUNCED nomme son auteur (décision 0060, réexamen au premier déclencheur "
		+ "dont l'auteur est l'adversaire) ; le cas de l'auteur lui-même est vérifié sous 208.2.4 "
		+ "(test_208_2_4_opponent_answers_first_the_trigger_of_an_announcement)."
	),
	"210.1.2":
	(
		"Règle de rédaction du ruleset (texte écrit une fois avec X) ; le moteur lit X sur la "
		+ "carte (tests : test_210_1_3_the_card_fixes_the_value, "
		+ "test_210_4_1_assault_adds_force_when_attacking)."
	),
}

## Règles consignées par les éditions 0.45 à 0.55 du ruleset et pas encore codées, avec l'étape du
## jalon J2c qui les code (décision 0054) : chaque étape retire ses lignes en écrivant leurs tests,
## la liste est vide à la sortie de c.8.
const RULES_AWAITING_IMPLEMENTATION: Dictionary[String, String] = {
	"201.4.1a": "c.7",
	"207.3.15": "c.5e",
	"207.5.18": "c.6",
	"217.1.5": "c.7",
	"217.1.8": "c.5e",
}

var _rule_ids: PackedStringArray
var _test_names: PackedStringArray
var _tests_text: String


func before() -> void:
	_rule_ids = _read_rule_ids()
	_tests_text = _read_tests_text()
	_test_names = _matches(TEST_PATTERN, _tests_text)


func test_decision_0007_ruleset_rules_are_read() -> void:
	assert_int(_rule_ids.size()).is_greater(0)


func test_decision_0007_every_rule_has_a_test_or_a_reason() -> void:
	var missing := PackedStringArray()
	for rule_id: String in _rule_ids:
		if _has_own_test(rule_id) or RULES_WITHOUT_OWN_TEST.has(rule_id):
			continue
		if not RULES_AWAITING_IMPLEMENTATION.has(rule_id):
			missing.append(rule_id)
	(
		assert_array(Array(missing))
		. override_failure_message("Règles sans test ni justification : " + ", ".join(missing))
		. is_empty()
	)


func test_decision_0007_justified_rules_exist_and_lack_own_test() -> void:
	var stale := PackedStringArray()
	for rule_id: String in RULES_WITHOUT_OWN_TEST:
		if not _rule_ids.has(rule_id) or _has_own_test(rule_id):
			stale.append(rule_id)
	(
		assert_array(Array(stale))
		. override_failure_message(
			"Entrées à retirer de RULES_WITHOUT_OWN_TEST : " + ", ".join(stale)
		)
		. is_empty()
	)


func test_decision_0054_awaiting_rules_exist_and_lack_own_test() -> void:
	var stale := PackedStringArray()
	for rule_id: String in RULES_AWAITING_IMPLEMENTATION:
		var settled := _has_own_test(rule_id) or RULES_WITHOUT_OWN_TEST.has(rule_id)
		if not _rule_ids.has(rule_id) or settled:
			stale.append(rule_id)
	(
		assert_array(Array(stale))
		. override_failure_message(
			"Entrées à retirer de RULES_AWAITING_IMPLEMENTATION : " + ", ".join(stale)
		)
		. is_empty()
	)


func test_decision_0007_tests_cited_by_justifications_exist() -> void:
	var unknown := PackedStringArray()
	for reason: String in RULES_WITHOUT_OWN_TEST.values():
		for test_name: String in _matches("(test_[0-9a-z_]+)", reason):
			if not _test_names.has(test_name):
				unknown.append(test_name)
	(
		assert_array(Array(unknown))
		. override_failure_message("Tests cités introuvables : " + ", ".join(unknown))
		. is_empty()
	)


func test_decision_0007_every_reject_reason_is_cited_by_a_test() -> void:
	var uncited := PackedStringArray()
	for reason_name: String in IntentRejected.RejectReason.keys():
		if reason_name == "NONE":
			continue
		var cited := RegEx.create_from_string("\\b%s\\b" % reason_name).search(_tests_text)
		if cited == null:
			uncited.append(reason_name)
	(
		assert_array(Array(uncited))
		. override_failure_message("Raisons de refus jamais citées : " + ", ".join(uncited))
		. is_empty()
	)


func _has_own_test(rule_id: String) -> bool:
	var prefix := "test_%s_" % rule_id.replace(".", "_")
	for test_name: String in _test_names:
		if test_name.begins_with(prefix):
			return true
	return false


func _read_rule_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	for file_name: String in DirAccess.get_files_at(RULES_DIRECTORY):
		if file_name.get_extension() == "md":
			var text := FileAccess.get_file_as_string(RULES_DIRECTORY.path_join(file_name))
			ids.append_array(_matches(RULE_PATTERN, text))
	return ids


# Sans ce fichier : ses justifications ne comptent pas comme des tests.
func _read_tests_text() -> String:
	var own_script: Script = get_script()
	var own_name := own_script.resource_path.get_file()
	var text := ""
	for file_name: String in DirAccess.get_files_at(TESTS_DIRECTORY):
		if file_name.get_extension() == "gd" and file_name != own_name:
			text += FileAccess.get_file_as_string(TESTS_DIRECTORY.path_join(file_name))
	return text


func _matches(pattern: String, text: String) -> PackedStringArray:
	var found := PackedStringArray()
	for result: RegExMatch in RegEx.create_from_string(pattern).search_all(text):
		found.append(result.get_string(1))
	return found
