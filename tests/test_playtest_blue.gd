extends PlaytestSuite
## Cartes bleues du catalogue de playtest (docs/ruleset/50-cartes/bleu.md, ruleset 0.55), chargées
## depuis data/cards/ : type, coût, Force, vitesse, mots-clés, nombre et forme des effets.


func test_207_3_1_apprentice_grows_when_its_player_announces_a_spell() -> void:
	_assert_card(&"apprenti", [TYPE.UNIT, 2, 2, SPEED.NONE], {}, [KIND.MODIFY_FORCE])
	_assert_trigger(&"apprenti", TRIGGER.OWN_SPELL_ANNOUNCED)
	_assert_source_subject(&"apprenti")
	_assert_amount(&"apprenti", 1)
	_assert_not_once_per_turn(&"apprenti")


func test_207_3_5_archive_specter_grows_once_per_turn_on_discard() -> void:
	_assert_card(&"spectre_des_archives", [TYPE.UNIT, 2, 2, SPEED.NONE], {}, [KIND.MODIFY_FORCE])
	_assert_trigger(&"spectre_des_archives", TRIGGER.OWN_CARD_DISCARDED)
	_assert_source_subject(&"spectre_des_archives")
	_assert_amount(&"spectre_des_archives", 2)
	_assert_once_per_turn(&"spectre_des_archives")


func test_210_3_1_scholar_draws_a_card_on_arrival() -> void:
	_assert_card(&"lettre", [TYPE.UNIT, 3, 2, SPEED.NONE], {KEYWORD.ARRIVAL: 0}, [KIND.DRAW_CARDS])
	_assert_trigger(&"lettre", TRIGGER.ARRIVAL)
	_assert_amount(&"lettre", 1)


func test_207_3_5_spellblade_boosts_an_ally_once_per_turn() -> void:
	_assert_card(&"lame_sort", [TYPE.UNIT, 3, 3, SPEED.NONE], {}, [KIND.MODIFY_FORCE])
	_assert_trigger(&"lame_sort", TRIGGER.OWN_SPELL_ANNOUNCED)
	_assert_target(&"lame_sort", SIDE.ALLY)
	_assert_amount(&"lame_sort", 1)
	_assert_once_per_turn(&"lame_sort")


func test_207_7_5_study_draws_two_then_discards_one() -> void:
	_assert_card(
		&"etude",
		[TYPE.SPELL, 1, CardDefinition.NO_FORCE, SPEED.ACTION],
		{},
		[KIND.DRAW_CARDS, KIND.DISCARD_CARDS]
	)
	_assert_study_order(&"etude")


func test_207_6_2_counter_counters_a_spell() -> void:
	_assert_card(
		&"contre",
		[TYPE.SPELL, 2, CardDefinition.NO_FORCE, SPEED.REACTION],
		{},
		[KIND.COUNTER_SPELL]
	)


func test_204_3_12_library_draws_at_start_of_turn() -> void:
	_assert_card(&"bibliotheque", [TYPE.BUILDING, 3, 2, SPEED.NONE], {}, [KIND.DRAW_CARDS])
	_assert_trigger(&"bibliotheque", TRIGGER.START_OF_OWN_TURN)
	_assert_amount(&"bibliotheque", 1)


func test_217_1_1_observatory_looks_at_the_top_card_at_start_of_turn() -> void:
	_assert_card(&"observatoire", [TYPE.BUILDING, 2, 3, SPEED.NONE], {}, [KIND.LOOK_AT_TOP_CARD])
	_assert_trigger(&"observatoire", TRIGGER.START_OF_OWN_TURN)


func test_207_3_12_grimoire_draws_then_discards_when_its_bearer_destroys_a_defender() -> void:
	_assert_card(
		&"grimoire",
		[TYPE.GEAR, 1, CardDefinition.NO_FORCE, SPEED.NONE],
		{},
		[KIND.DRAW_CARDS, KIND.DISCARD_CARDS]
	)
	_assert_trigger(&"grimoire", TRIGGER.DESTROYS_DEFENDER)
	_assert_study_order(&"grimoire", 1)
