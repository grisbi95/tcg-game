extends PlaytestSuite
## Cartes rouges du catalogue de playtest (docs/ruleset/50-cartes/rouge.md, ruleset 0.55), chargées
## depuis data/cards/ : type, coût, Force, vitesse, mots-clés, nombre et forme des effets.


func test_210_3_1_scout_wakes_itself() -> void:
	_assert_card(&"eclaireur", [TYPE.UNIT, 1, 1, SPEED.NONE], {KEYWORD.ARRIVAL: 0}, [KIND.WAKE])
	_assert_trigger(&"eclaireur", TRIGGER.ARRIVAL)
	_assert_source_subject(&"eclaireur")


func test_210_4_1_raider_has_assault_one() -> void:
	_assert_card(&"pillard", [TYPE.UNIT, 2, 2, SPEED.NONE], {KEYWORD.ASSAULT: 1}, [])


func test_210_4_1_marauder_has_assault_two() -> void:
	_assert_card(&"maraudeur", [TYPE.UNIT, 3, 3, SPEED.NONE], {KEYWORD.ASSAULT: 2}, [])


func test_210_3_1_furious_has_assault_and_wakes_itself() -> void:
	_assert_card(
		&"furieux",
		[TYPE.UNIT, 4, 4, SPEED.NONE],
		{KEYWORD.ASSAULT: 1, KEYWORD.ARRIVAL: 0},
		[KIND.WAKE]
	)
	_assert_trigger(&"furieux", TRIGGER.ARRIVAL)
	_assert_source_subject(&"furieux")


func test_205_5_1_charge_wakes_an_allied_unit() -> void:
	_assert_card(&"charge", [TYPE.SPELL, 1, CardDefinition.NO_FORCE, SPEED.ACTION], {}, [KIND.WAKE])
	_assert_target(&"charge", SIDE.ALLY)


func test_213_2_3_fury_grants_assault_of_target_force() -> void:
	_assert_card(
		&"furie", [TYPE.SPELL, 3, CardDefinition.NO_FORCE, SPEED.ACTION], {}, [KIND.GRANT_KEYWORD]
	)
	_assert_force_keyword(&"furie", KEYWORD.ASSAULT)


func test_204_3_12_forge_boosts_at_start_of_turn() -> void:
	_assert_card(&"forge", [TYPE.BUILDING, 2, 2, SPEED.NONE], {}, [KIND.MODIFY_FORCE])
	_assert_trigger(&"forge", TRIGGER.START_OF_OWN_TURN)
	_assert_amount(&"forge", 2)
	_assert_target(&"forge", SIDE.ALLY)


func test_207_2_2_war_drum_grants_assault_to_adjacent_allies() -> void:
	_assert_card(&"tambour_de_guerre", [TYPE.BUILDING, 3, 3, SPEED.NONE], {}, [KIND.GRANT_KEYWORD])
	_assert_static_scope(&"tambour_de_guerre", SIDE.ALLY, RELATION.ADJACENT)
	_assert_amount(&"tambour_de_guerre", 1)


func test_207_2_8_war_axe_gives_assault_two_to_its_bearer() -> void:
	_assert_card(
		&"hache_de_guerre",
		[TYPE.GEAR, 1, CardDefinition.NO_FORCE, SPEED.NONE],
		{},
		[KIND.GRANT_KEYWORD]
	)
	_assert_static_scope(&"hache_de_guerre", SIDE.ANY, RELATION.SELF)
	_assert_amount(&"hache_de_guerre", 2)
