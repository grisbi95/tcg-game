extends PlaytestSuite
## Cartes neutres du catalogue de playtest (docs/ruleset/50-cartes/neutres.md, ruleset 0.55),
## chargées depuis data/cards/ : type, coût, Force, vitesse, mots-clés, effets.


func test_202_1_5_recruit_is_a_plain_unit() -> void:
	_assert_card(&"recrue", [TYPE.UNIT, 1, 2, SPEED.NONE], {}, [])


func test_202_1_5_soldier_is_a_plain_unit() -> void:
	_assert_card(&"soldat", [TYPE.UNIT, 2, 3, SPEED.NONE], {}, [])


func test_210_4_2_guardian_has_rampart_one() -> void:
	_assert_card(&"gardien", [TYPE.UNIT, 2, 2, SPEED.NONE], {KEYWORD.RAMPART: 1}, [])


func test_202_1_5_veteran_is_a_plain_unit() -> void:
	_assert_card(&"veteran", [TYPE.UNIT, 3, 4, SPEED.NONE], {}, [])


func test_202_1_5_champion_is_a_plain_unit() -> void:
	_assert_card(&"champion", [TYPE.UNIT, 4, 5, SPEED.NONE], {}, [])


func test_202_1_5_colossus_is_a_plain_unit() -> void:
	_assert_card(&"colosse", [TYPE.UNIT, 5, 6, SPEED.NONE], {}, [])


func test_201_3_5_inspiration_draws_a_card() -> void:
	_assert_card(
		&"inspiration",
		[TYPE.SPELL, 1, CardDefinition.NO_FORCE, SPEED.REACTION],
		{},
		[KIND.DRAW_CARDS]
	)
	_assert_amount(&"inspiration", 1)


func test_207_4_2_reinforcement_boosts_an_ally_until_end_of_turn() -> void:
	_assert_card(
		&"renfort",
		[TYPE.SPELL, 1, CardDefinition.NO_FORCE, SPEED.REACTION],
		{},
		[KIND.MODIFY_FORCE]
	)
	_assert_target(&"renfort", SIDE.ALLY)
	_assert_amount(&"renfort", 2)


func test_207_4_2_shock_weakens_an_enemy_until_end_of_turn() -> void:
	_assert_card(
		&"choc", [TYPE.SPELL, 2, CardDefinition.NO_FORCE, SPEED.REACTION], {}, [KIND.MODIFY_FORCE]
	)
	_assert_target(&"choc", SIDE.ENEMY)
	_assert_amount(&"choc", -2)


func test_213_1_10_execution_destroys_an_enemy_of_force_x_or_less() -> void:
	_assert_card(
		&"execution", [TYPE.SPELL, 0, CardDefinition.NO_FORCE, SPEED.ACTION], {}, [KIND.DESTROY]
	)
	_assert_execution(&"execution")


func test_210_2_1_camp_has_outpost() -> void:
	_assert_card(&"campement", [TYPE.BUILDING, 3, 4, SPEED.NONE], {KEYWORD.OUTPOST: 0}, [])


func test_206_3_7_trophy_boosts_its_bearer_for_as_long_as_the_piece_is_in_play() -> void:
	_assert_card(
		&"trophee", [TYPE.GEAR, 2, CardDefinition.NO_FORCE, SPEED.NONE], {}, [KIND.MODIFY_FORCE]
	)
	_assert_trigger(&"trophee", TRIGGER.DESTROYS_DEFENDER)
	_assert_source_subject(&"trophee")
	_assert_amount(&"trophee", 1)


func test_213_1_1_execution_has_an_x_cost() -> void:
	assert_bool(_catalog.get_card(&"execution").has_x_cost).is_true()
