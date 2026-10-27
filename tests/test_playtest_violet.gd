extends PlaytestSuite
## Cartes violettes du catalogue de playtest (50-cartes/violet.md, ruleset 0.55), chargées
## depuis data/cards/ : type, coût, Force, vitesse, mots-clés, nombre et forme des effets.


func test_214_1_3_shade_swaps_two_distinct_allies() -> void:
	_assert_card(&"ombre", [TYPE.UNIT, 2, 2, SPEED.NONE], {KEYWORD.ARRIVAL: 0}, [KIND.SWAP_CELLS])
	_assert_trigger(&"ombre", TRIGGER.ARRIVAL)
	_assert_two_distinct_targets(&"ombre")


func test_210_4_2_sentinel_has_rampart_two() -> void:
	_assert_card(&"sentinelle", [TYPE.UNIT, 3, 3, SPEED.NONE], {KEYWORD.RAMPART: 2}, [])


func test_216_1_1_ferryman_returns_a_weak_enemy_on_arrival() -> void:
	_assert_card(
		&"passeur", [TYPE.UNIT, 3, 2, SPEED.NONE], {KEYWORD.ARRIVAL: 0}, [KIND.RETURN_TO_HAND]
	)
	_assert_trigger(&"passeur", TRIGGER.ARRIVAL)
	_assert_target(&"passeur", SIDE.ENEMY, 2)


func test_215_1_1_manipulator_moves_an_enemy_on_arrival() -> void:
	_assert_card(
		&"manipulateur", [TYPE.UNIT, 4, 3, SPEED.NONE], {KEYWORD.ARRIVAL: 0}, [KIND.MOVE_UNIT]
	)
	_assert_trigger(&"manipulateur", TRIGGER.ARRIVAL)
	_assert_target(&"manipulateur", SIDE.ENEMY)
	_assert_destination(&"manipulateur")


func test_215_1_1_slide_moves_an_enemy() -> void:
	_assert_card(
		&"glissement", [TYPE.SPELL, 1, CardDefinition.NO_FORCE, SPEED.ACTION], {}, [KIND.MOVE_UNIT]
	)
	_assert_target(&"glissement", SIDE.ENEMY)
	_assert_destination(&"glissement")


func test_216_1_1_backflow_returns_an_enemy_of_force_three_or_less() -> void:
	_assert_card(
		&"reflux", [TYPE.SPELL, 2, CardDefinition.NO_FORCE, SPEED.ACTION], {}, [KIND.RETURN_TO_HAND]
	)
	_assert_target(&"reflux", SIDE.ENEMY, 3)


func test_206_5_5_obelisk_weakens_adjacent_enemies() -> void:
	_assert_card(&"obelisque", [TYPE.BUILDING, 3, 4, SPEED.NONE], {}, [KIND.MODIFY_FORCE])
	_assert_static_scope(&"obelisque", SIDE.ENEMY, RELATION.ADJACENT)
	_assert_amount(&"obelisque", -1)


func test_207_3_14_powder_works_destroys_a_weak_adjacent_enemy_when_destroyed() -> void:
	_assert_card(
		&"poudriere", [TYPE.BUILDING, 2, 3, SPEED.NONE], {KEYWORD.LAST_BREATH: 0}, [KIND.DESTROY]
	)
	_assert_trigger(&"poudriere", TRIGGER.DESTROYED)
	_assert_target(&"poudriere", SIDE.ENEMY, 4)
	_assert_adjacent_to_source(&"poudriere")


func test_207_2_8_shadow_cloak_gives_rampart_two_to_its_bearer() -> void:
	_assert_card(
		&"cape_d_ombre",
		[TYPE.GEAR, 1, CardDefinition.NO_FORCE, SPEED.NONE],
		{},
		[KIND.GRANT_KEYWORD]
	)
	_assert_static_scope(&"cape_d_ombre", SIDE.ANY, RELATION.SELF)
	_assert_amount(&"cape_d_ombre", 2)
