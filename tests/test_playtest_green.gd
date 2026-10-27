extends PlaytestSuite
## Cartes vertes du catalogue de playtest (docs/ruleset/50-cartes/vert.md, ruleset 0.55), chargées
## depuis data/cards/ : type, coût, Force, vitesse, mots-clés, nombre et forme des effets.


func test_202_4_12_sower_creates_a_token_next_to_itself() -> void:
	_assert_card(
		&"semeuse", [TYPE.UNIT, 2, 1, SPEED.NONE], {KEYWORD.ARRIVAL: 0}, [KIND.CREATE_TOKEN]
	)
	_assert_trigger(&"semeuse", TRIGGER.ARRIVAL)
	_assert_token(&"semeuse", 1)


func test_206_5_5_standard_bearer_boosts_other_adjacent_allies() -> void:
	_assert_card(&"porte_enseigne", [TYPE.UNIT, 3, 2, SPEED.NONE], {}, [KIND.MODIFY_FORCE])
	_assert_static_scope(&"porte_enseigne", SIDE.ALLY, RELATION.ADJACENT)
	_assert_others_only(&"porte_enseigne")
	_assert_amount(&"porte_enseigne", 1)


func test_210_3_2_stubborn_companion_creates_a_token_when_destroyed() -> void:
	_assert_card(
		&"compagnon_tenace",
		[TYPE.UNIT, 3, 3, SPEED.NONE],
		{KEYWORD.LAST_BREATH: 0},
		[KIND.CREATE_TOKEN]
	)
	_assert_trigger(&"compagnon_tenace", TRIGGER.DESTROYED)
	_assert_token(&"compagnon_tenace", 1)


func test_206_5_5_elder_boosts_other_allies_in_its_row() -> void:
	_assert_card(&"ancien_du_bosquet", [TYPE.UNIT, 5, 4, SPEED.NONE], {}, [KIND.MODIFY_FORCE])
	_assert_static_scope(&"ancien_du_bosquet", SIDE.ALLY, RELATION.SAME_ROW)
	_assert_others_only(&"ancien_du_bosquet")
	_assert_amount(&"ancien_du_bosquet", 1)


func test_207_5_10_rally_targets_two_distinct_cells() -> void:
	_assert_card(
		&"rassemblement",
		[TYPE.SPELL, 3, CardDefinition.NO_FORCE, SPEED.ACTION],
		{},
		[KIND.CREATE_TOKEN]
	)
	_assert_token(&"rassemblement", 1)
	_assert_two_distinct_targets(&"rassemblement")


func test_213_2_3_sap_grants_rampart_of_target_force() -> void:
	_assert_card(
		&"seve", [TYPE.SPELL, 2, CardDefinition.NO_FORCE, SPEED.REACTION], {}, [KIND.GRANT_KEYWORD]
	)
	_assert_force_keyword(&"seve", KEYWORD.RAMPART)


func test_204_3_12_garrison_creates_a_token_at_start_of_turn() -> void:
	_assert_card(&"garnison", [TYPE.BUILDING, 4, 3, SPEED.NONE], {}, [KIND.CREATE_TOKEN])
	_assert_trigger(&"garnison", TRIGGER.START_OF_OWN_TURN)
	_assert_token(&"garnison", 1)


func test_207_7_4_worksite_creates_a_token_then_destroys_itself() -> void:
	_assert_card(
		&"chantier", [TYPE.BUILDING, 3, 2, SPEED.NONE], {}, [KIND.CREATE_TOKEN, KIND.DESTROY]
	)
	_assert_trigger(&"chantier", TRIGGER.START_OF_OWN_TURN)
	_assert_token(&"chantier", 4)
	_assert_source_destroy_last(&"chantier")


func test_207_2_8_banner_boosts_allies_adjacent_to_its_bearer() -> void:
	_assert_card(
		&"banniere", [TYPE.GEAR, 2, CardDefinition.NO_FORCE, SPEED.NONE], {}, [KIND.MODIFY_FORCE]
	)
	_assert_static_scope(&"banniere", SIDE.ALLY, RELATION.ADJACENT)
	_assert_amount(&"banniere", 1)
