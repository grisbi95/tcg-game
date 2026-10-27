extends PlaytestSuite
## Catalogue de playtest chargé depuis data/cards/ et data/decks/ (ruleset 0.55,
## docs/ruleset/50-cartes/ ; étape c.6, décisions 0002, 0010, 0037 et 0061) : le catalogue entier,
## les Heroes, les decks et la pratique de rédaction 207.5.18. Les cartes sont dans
## test_playtest_red.gd, _green, _violet, _blue et _neutral.

const DECK_SIZE: int = 30  # 201.6.1
const CATALOG_DISTINCT_CARDS: int = 48  # 50-cartes/README.md : 9 par couleur et 12 neutres
const TEST_DECK_HERO: StringName = &"capitaine"
const CARD_IDS: Array[StringName] = [
	&"eclaireur",
	&"pillard",
	&"maraudeur",
	&"furieux",
	&"charge",
	&"furie",
	&"forge",
	&"tambour_de_guerre",
	&"hache_de_guerre",
	&"semeuse",
	&"porte_enseigne",
	&"compagnon_tenace",
	&"ancien_du_bosquet",
	&"rassemblement",
	&"seve",
	&"garnison",
	&"chantier",
	&"banniere",
	&"ombre",
	&"sentinelle",
	&"passeur",
	&"manipulateur",
	&"glissement",
	&"reflux",
	&"obelisque",
	&"poudriere",
	&"cape_d_ombre",
	&"apprenti",
	&"spectre_des_archives",
	&"lettre",
	&"lame_sort",
	&"etude",
	&"contre",
	&"bibliotheque",
	&"observatoire",
	&"grimoire",
	&"recrue",
	&"soldat",
	&"gardien",
	&"veteran",
	&"champion",
	&"colosse",
	&"inspiration",
	&"renfort",
	&"choc",
	&"execution",
	&"campement",
	&"trophee"
]

## Heroes du catalogue de playtest écrits en JSON.
const HEROES: Array[StringName] = [&"chef_de_guerre", &"recruteuse", &"stratege", &"pilleuse"]
## Hero, puis Units, Buildings, Spells et Gear de chaque deck (decks.md).
const DECK_TYPE_COUNTS: Dictionary[StringName, Array] = {
	&"percee": [&"chef_de_guerre", 17, 2, 9, 2],
	&"phalange": [&"recruteuse", 18, 4, 6, 2],
	&"echiquier": [&"stratege", 20, 2, 7, 1],
	&"grimoire": [&"pilleuse", 14, 1, 13, 2],
}


func test_decision_0002_playtest_catalog_has_no_error() -> void:
	assert_array(Array(_loader.find_errors())).is_empty()


func test_decision_0002_playtest_catalog_holds_the_forty_eight_cards() -> void:
	var missing: Array[StringName] = []
	for card_id: StringName in CARD_IDS:
		if _catalog.get_card(card_id) == null:
			missing.append(card_id)
	assert_array(missing).is_empty()
	assert_int(CARD_IDS.size()).is_equal(CATALOG_DISTINCT_CARDS)


func test_207_5_18_text_says_targeted_only_when_an_effect_targets() -> void:
	var wrong: Array[String] = []
	for card_id: StringName in _catalog.card_ids():
		var card := _catalog.get_card(card_id)
		if _says_targeted(card.text) != _has_target(EffectText.all_effects(card.texts)):
			wrong.append(String(card_id))
	var hero_ids: Array[StringName] = HEROES.duplicate()
	hero_ids.append(TEST_DECK_HERO)
	for hero_id: StringName in hero_ids:
		var hero := _catalog.get_hero(hero_id)
		if _says_targeted(hero.text) != _has_target(_hero_effects(hero)):
			wrong.append(String(hero_id))
	assert_array(wrong).is_empty()


func test_202_3_7_chef_de_guerre_wakes_an_adjacent_ally_by_order() -> void:
	var hero := _catalog.get_hero(&"chef_de_guerre")
	assert_int(hero.health).is_equal(13)
	assert_int(hero.orders.size()).is_equal(1)
	var order := hero.orders[0]
	assert_int(order.speed).is_equal(SPEED.ACTION)
	assert_int(order.cost).is_equal(0)
	var effects := EffectText.all_effects(order.texts)
	assert_int(effects.size()).is_equal(1)
	assert_int(effects[0].kind).is_equal(KIND.WAKE)
	var filter := effects[0].target.piece_filter
	assert_int(filter.side).is_equal(SIDE.ALLY)
	assert_int(filter.relation).is_equal(RELATION.ADJACENT)
	assert_int(filter.relative_to).is_equal(PieceFilter.RelativeTo.OWN_HERO)


func test_205_2_5_recruteuse_creates_a_token_next_to_its_hero_by_order() -> void:
	var hero := _catalog.get_hero(&"recruteuse")
	assert_int(hero.health).is_equal(16)
	assert_int(hero.orders.size()).is_equal(1)
	var order := hero.orders[0]
	assert_int(order.speed).is_equal(SPEED.ACTION)
	assert_int(order.cost).is_equal(2)
	var effects := EffectText.all_effects(order.texts)
	assert_int(effects.size()).is_equal(1)
	assert_int(effects[0].kind).is_equal(KIND.CREATE_TOKEN)
	assert_int(effects[0].token_piece_kind).is_equal(Piece.PieceKind.UNIT)
	assert_int(effects[0].token_force).is_equal(1)
	assert_int(effects[0].target.what).is_equal(TargetSpec.TargetWhat.CELL)
	assert_int(effects[0].target.adjacent_to).is_equal(TargetSpec.AdjacentTo.OWN_HERO)


func test_211_1_stratege_swaps_two_distinct_allies_by_reaction_order() -> void:
	var hero := _catalog.get_hero(&"stratege")
	assert_int(hero.health).is_equal(15)
	assert_int(hero.orders.size()).is_equal(1)
	var order := hero.orders[0]
	assert_int(order.speed).is_equal(SPEED.REACTION)
	assert_int(order.cost).is_equal(0)
	var effects := EffectText.all_effects(order.texts)
	assert_int(effects.size()).is_equal(1)
	assert_int(effects[0].kind).is_equal(KIND.SWAP_CELLS)
	var target := effects[0].target
	assert_bool(target.distinct).is_true()
	assert_int(target.piece_filter.relation).is_equal(RELATION.ADJACENT)
	assert_int(target.piece_filter.relative_to).is_equal(PieceFilter.RelativeTo.OWN_HERO)


func test_207_3_13_pilleuse_draws_two_when_the_hand_is_nearly_empty() -> void:
	var hero := _catalog.get_hero(&"pilleuse")
	assert_int(hero.health).is_equal(15)
	assert_array(hero.orders).is_empty()
	assert_int(hero.triggered.size()).is_equal(1)
	var text := hero.triggered[0]
	assert_int(text.trigger).is_equal(TRIGGER.START_OF_OWN_TURN)
	assert_int(text.condition.value.kind).is_equal(GameValue.Kind.HAND_SIZE)
	assert_int(text.condition.comparison).is_equal(EffectCondition.Comparison.AT_MOST)
	assert_int(text.condition.amount).is_equal(1)
	assert_int(text.effects.size()).is_equal(1)
	assert_int(text.effects[0].kind).is_equal(KIND.DRAW_CARDS)
	assert_int(text.effects[0].amount).is_equal(2)


func test_201_6_1_playtest_decks_have_thirty_cards_and_their_types() -> void:
	var decks := _decks()
	for deck_id: StringName in DECK_TYPE_COUNTS:
		var deck := decks.find_deck(deck_id)
		assert_object(deck).override_failure_message(String(deck_id)).is_not_null()
		assert_int(deck.card_ids().size()).is_equal(DECK_SIZE)
		var actual: Array = [deck.hero_id] + _type_counts(deck)
		assert_array(actual).override_failure_message(String(deck_id)).is_equal(
			DECK_TYPE_COUNTS[deck_id]
		)


func test_201_6_2_playtest_decks_are_valid() -> void:
	var decks := _decks()
	for deck_id: StringName in DECK_TYPE_COUNTS:
		var deck := decks.find_deck(deck_id)
		var errors := _catalog.find_deck_errors(deck.card_ids(), DuelConfig.new())
		assert_array(Array(errors)).override_failure_message(String(deck_id)).is_empty()


func test_202_3_5_playtest_decks_have_their_hero() -> void:
	var decks := _decks()
	for deck_id: StringName in DECK_TYPE_COUNTS:
		var hero_id := decks.find_deck(deck_id).hero_id
		var hero := _catalog.get_hero(hero_id)
		assert_object(hero).override_failure_message(String(hero_id)).is_not_null()


func test_decision_0037_playtest_decks_load_without_error() -> void:
	assert_array(Array(_decks().find_errors())).is_empty()


func _decks() -> DeckLoader:
	var loader := DeckLoader.new(EDITION)
	loader.load_directory(GameLibrary.DECKS_DIRECTORY)
	return loader


## Units, Buildings, Spells et Gear du deck.
func _type_counts(deck: DeckList) -> Array:
	var counts: Dictionary[CardDefinition.CardType, int] = {
		TYPE.UNIT: 0, TYPE.BUILDING: 0, TYPE.SPELL: 0, TYPE.GEAR: 0
	}
	for card_id: StringName in deck.card_ids():
		counts[_catalog.get_card(card_id).card_type] += 1
	return [counts[TYPE.UNIT], counts[TYPE.BUILDING], counts[TYPE.SPELL], counts[TYPE.GEAR]]


func _says_targeted(text: String) -> bool:
	return text.contains("ciblé")


func _has_target(effects: Array[EffectDefinition]) -> bool:
	return effects.any(
		func(effect: EffectDefinition) -> bool:
			return effect.target != null or effect.destination != null
	)


func _hero_effects(hero: HeroDefinition) -> Array[EffectDefinition]:
	var effects := EffectText.all_effects(hero.passive)
	effects.append_array(EffectText.all_effects(hero.triggered))
	for order: HeroOrder in hero.orders:
		effects.append_array(EffectText.all_effects(order.texts))
	return effects
