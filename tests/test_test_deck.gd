extends GdUnitTestSuite
## Hero et deck de test chargés depuis data/cards/ (ruleset 0.33, 70-playtest/decks-de-test.md ;
## 201.6, 202.1, 202.3, 210 ; décisions 0002, 0010 et 0012). Le chargement sans erreur dans
## l'édition courante est vérifié par test_catalog_loader.gd.
##
## Les valeurs des tables sont recopiées de decks-de-test.md. Le deck est lu dans
## data/decks/deck_de_test.json (ruleset 0.36, décisions 0037 et 0171 du ruleset).

const DECK_SIZE: int = 30  # 201.6.1
const CAPTAIN_HEALTH: int = 15  # 202.3.7
const SEED: int = 11
const TYPE := CardDefinition.CardType
const SPEED := CardDefinition.SpellSpeed
const KEYWORD := CardDefinition.Keyword
const KIND := EffectDefinition.EffectKind
const DURATION := ActiveEffect.EffectDuration

## Type, coût, Force (NO_FORCE pour un Spell ou un Gear) et vitesse de chaque carte.
const CARDS: Dictionary[StringName, Array] = {
	&"recrue": [TYPE.UNIT, 1, 2, SPEED.NONE],
	&"soldat": [TYPE.UNIT, 2, 3, SPEED.NONE],
	&"veteran": [TYPE.UNIT, 3, 4, SPEED.NONE],
	&"champion": [TYPE.UNIT, 4, 5, SPEED.NONE],
	&"colosse": [TYPE.UNIT, 5, 6, SPEED.NONE],
	&"pillard": [TYPE.UNIT, 2, 2, SPEED.NONE],
	&"gardien": [TYPE.UNIT, 2, 2, SPEED.NONE],
	&"heraut": [TYPE.UNIT, 3, 3, SPEED.NONE],
	&"martyr": [TYPE.UNIT, 3, 3, SPEED.NONE],
	&"palissade": [TYPE.BUILDING, 2, 4, SPEED.NONE],
	&"bastion": [TYPE.BUILDING, 3, 5, SPEED.NONE],
	&"campement": [TYPE.BUILDING, 3, 4, SPEED.NONE],
	&"renfort": [TYPE.SPELL, 1, CardDefinition.NO_FORCE, SPEED.REACTION],
	&"frappe": [TYPE.SPELL, 3, CardDefinition.NO_FORCE, SPEED.ACTION],
	&"contre": [TYPE.SPELL, 2, CardDefinition.NO_FORCE, SPEED.REACTION],
	&"levee": [TYPE.SPELL, 2, CardDefinition.NO_FORCE, SPEED.ACTION],
	&"lame": [TYPE.GEAR, 1, CardDefinition.NO_FORCE, SPEED.NONE],
}
## 210.1.3 : mots-clés et valeur X ; une carte absente n'en porte aucun.
const KEYWORDS: Dictionary[StringName, Dictionary] = {
	&"pillard": {KEYWORD.ASSAULT: 1},
	&"gardien": {KEYWORD.RAMPART: 1},
	&"heraut": {KEYWORD.ARRIVAL: 0},
	&"martyr": {KEYWORD.LAST_BREATH: 0},
	&"campement": {KEYWORD.OUTPOST: 0},
}
## Genre et valeur de l'effet unique de chaque carte à effet ; une carte absente n'en a aucun.
const EFFECTS: Dictionary[StringName, Array] = {
	&"heraut": [KIND.MODIFY_FORCE, -1],
	&"martyr": [KIND.MODIFY_FORCE, 1],
	&"renfort": [KIND.MODIFY_FORCE, 2],
	&"frappe": [KIND.DESTROY, 0],
	&"contre": [KIND.COUNTER_SPELL, 0],
	&"levee": [KIND.CREATE_TOKEN, 0],
	&"lame": [KIND.MODIFY_FORCE, 1],
}
## Exemplaires de chaque carte, colonne Nombre de « Liste des cartes » (décision 0171 du ruleset).
const DECK_COPIES: Dictionary[StringName, int] = {
	&"recrue": 2,
	&"soldat": 3,
	&"veteran": 3,
	&"champion": 2,
	&"colosse": 2,
	&"pillard": 2,
	&"gardien": 2,
	&"heraut": 1,
	&"martyr": 1,
	&"palissade": 1,
	&"bastion": 1,
	&"campement": 2,
	&"renfort": 2,
	&"frappe": 2,
	&"contre": 1,
	&"levee": 1,
	&"lame": 2,
}
const STRIKE_MAX_FORCE: int = 3  # Frappe
const LEVY_TOKEN_FORCE: int = 2  # Levée

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B

var _catalog: Catalog


func before() -> void:
	_catalog = TestCatalog.catalog()


func test_decision_0010_catalog_holds_every_test_card() -> void:
	assert_array(_catalog.card_ids()).contains_exactly_in_any_order(CARDS.keys())


func test_202_1_test_cards_match_the_playtest_list() -> void:
	for card_id: StringName in CARDS:
		var expected := CARDS[card_id]
		var card := _catalog.get_card(card_id)
		var actual := [card.card_type, card.cost, card.force, card.speed]
		assert_array(actual).override_failure_message(String(card_id)).is_equal(expected)


func test_210_1_3_test_cards_carry_their_keywords() -> void:
	for card_id: StringName in CARDS:
		var expected: Dictionary = KEYWORDS.get(card_id, {})
		var keywords := _catalog.get_card(card_id).keywords
		assert_dict(keywords).override_failure_message(String(card_id)).is_equal(expected)


func test_207_test_cards_carry_their_effects() -> void:
	for card_id: StringName in CARDS:
		var effects := EffectText.all_effects(_catalog.get_card(card_id).texts)
		if not EFFECTS.has(card_id):
			assert_array(effects).override_failure_message(String(card_id)).is_empty()
			continue
		assert_int(effects.size()).is_equal(1)
		var actual := [effects[0].kind, effects[0].amount]
		assert_array(actual).override_failure_message(String(card_id)).is_equal(EFFECTS[card_id])


func test_207_4_2_test_effects_have_their_durations() -> void:
	var expected: Dictionary[StringName, DURATION] = {
		&"heraut": DURATION.UNTIL_END_OF_TURN,
		&"martyr": DURATION.WHILE_PIECE_IN_PLAY,
		&"renfort": DURATION.UNTIL_END_OF_TURN,
	}
	for card_id: StringName in expected:
		var effect := _catalog.get_card(card_id).texts[0].effects[0]
		assert_int(effect.duration).is_equal(expected[card_id])


func test_207_5_6_strike_and_levy_keep_their_values() -> void:
	assert_int(_catalog.get_card(&"frappe").texts[0].effects[0].target.max_force).is_equal(
		STRIKE_MAX_FORCE
	)
	assert_int(_catalog.get_card(&"levee").texts[0].effects[0].token_force).is_equal(
		LEVY_TOKEN_FORCE
	)


func test_201_6_1_test_deck_has_thirty_cards() -> void:
	assert_int(TestCatalog.deck().size()).is_equal(DECK_SIZE)


func test_201_6_2_test_deck_is_valid() -> void:
	var errors := _catalog.find_deck_errors(TestCatalog.deck(), DuelConfig.new())
	assert_array(Array(errors)).is_empty()


func test_decision_0037_test_deck_file_matches_the_playtest_table() -> void:
	var loader := DeckLoader.new()
	loader.load_directory(TestCatalog.DECKS_DIRECTORY)
	var deck := loader.find_deck(TestCatalog.DECK_ID)
	assert_object(deck).is_not_null()
	assert_dict(deck.copies).is_equal(DECK_COPIES)
	assert_str(String(deck.hero_id)).is_equal("capitaine")
	assert_array(deck.card_ids()).is_equal(TestCatalog.deck())


func test_202_3_7_captain_has_fifteen_health() -> void:
	assert_int(_captain().health).is_equal(CAPTAIN_HEALTH)


func test_decision_0012_duel_starts_with_the_test_decks() -> void:
	var engine := DuelEngine.new(_catalog)
	var labels := EventLog.describe(engine.start_new_duel(TestCatalog.setup(SEED)))
	assert_array(labels.slice(0, 2)).contains_exactly(["HeroPlaced:A", "HeroPlaced:B"])
	var state := engine.get_state()
	assert_int(state.pending_decision.kind).is_equal(PendingDecision.DecisionKind.MULLIGAN)
	for side: DuelState.PlayerSide in [A, B]:
		assert_int(state.find_hero(side).health).is_equal(CAPTAIN_HEALTH)


func _captain() -> HeroDefinition:
	return _catalog.get_hero(TestCatalog.HERO_ID)
