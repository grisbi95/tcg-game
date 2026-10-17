extends GdUnitTestSuite
## Règles d'or (ruleset 0.33, chapitre 200). Texte de carte contre règle (200.2.1) et
## instruction possible en partie seulement (200.4.2).

const SOLDIER: StringName = &"golden_soldier"
const CAMP: StringName = &"golden_camp"
const CARD: StringName = &"golden_card"
const SOLDIER_FORCE: int = 2
const STARTING_SOURCES: int = 2  # 204.1.2
const SOLDIER_COST: int = 2  # CatalogSamples.unit()
const SOURCES_RECEIVED_PER_TURN: int = 2  # valeur d'essai : 204.3.1 vaut 1 (PROVISOIRE)
const CARDS_DRAWN_PER_TURN: int = 2  # 204.3.6
const OVERKILL_FORCE: int = 40
const HERO_HEALTH: int = DuelStateBuilder.DEFAULT_HERO_HEALTH

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const REASON := IntentRejected.RejectReason

var _catalog: Catalog


func before_test() -> void:
	_catalog = Catalog.new()
	SetupSamples.add_unit(_catalog, SOLDIER, SOLDIER_FORCE)
	SetupSamples.add_unit(_catalog, CARD, SOLDIER_FORCE)
	var camp := CatalogSamples.with_field(CatalogSamples.building(), "id", String(CAMP))
	camp = CatalogSamples.with_field(camp, "keywords", [{"keyword": "outpost"}])
	_catalog.add_card(CardDefinition.from_dict(camp))


func test_200_2_1_card_text_overrides_the_deploy_zone_rule() -> void:
	var rule_alone := _validate_deploy_on_second_row(false)
	var with_card_text := _validate_deploy_on_second_row(true)
	assert_int(rule_alone).is_equal(REASON.CELL_NOT_IN_DEPLOY_ZONE)
	assert_int(with_card_text).is_equal(REASON.NONE)


func test_200_4_2_hero_loses_only_the_health_it_has() -> void:
	var builder := DuelStateBuilder.new(DuelConfig.new(), _catalog)
	builder.with_hero_health(B, 2)
	var state := builder.build()
	var events: Array[DuelEvent] = []
	StateCheckRules.lose_health(state, B, OVERKILL_FORCE, events)
	assert_int(state.find_hero(B).health).is_equal(0)
	assert_array(EventLog.describe(events)).contains_exactly(["HeroLostHealth:B", "DuelEnded"])
	assert_int((events[0] as HeroLostHealth).amount).is_equal(2)


func test_200_4_2_hero_with_more_health_loses_the_whole_amount() -> void:
	var builder := DuelStateBuilder.new(DuelConfig.new(), _catalog)
	var state := builder.build()
	var events: Array[DuelEvent] = []
	StateCheckRules.lose_health(state, B, 2, events)
	assert_int(state.find_hero(B).health).is_equal(HERO_HEALTH - 2)
	assert_int((events[0] as HeroLostHealth).amount).is_equal(2)


func test_200_4_2_reserve_gives_the_sources_it_has() -> void:
	var config := DuelConfig.new()
	config.sources_received_per_turn = SOURCES_RECEIVED_PER_TURN
	var builder := DuelStateBuilder.new(config, _catalog)
	builder.with_sources_in_reserve(B, 1)
	for index: int in CARDS_DRAWN_PER_TURN:
		builder.add_to_deck(B, CARD)
	var engine := DuelEngine.new(_catalog, config)
	engine.start_from_state(builder.build())
	var labels := EventLog.describe(engine.submit(EndTurn.new(A)))
	assert_int(labels.count("SourceReceived:B")).is_equal(1)
	var player := engine.get_state().get_player(B)
	assert_int(player.sources_in_reserve).is_equal(0)
	assert_int(player.sources_upright).is_equal(STARTING_SOURCES + 1)


func _validate_deploy_on_second_row(has_outpost_building: bool) -> IntentRejected.RejectReason:
	var builder := DuelStateBuilder.new(DuelConfig.new(), _catalog)
	if has_outpost_building:
		builder.place_piece(A, Piece.PieceKind.BUILDING, DuelStateBuilder.cell("B2"), CAMP)
	var card_id := builder.add_to_hand(A, SOLDIER)
	var engine := DuelEngine.new(_catalog)
	engine.start_from_state(builder.build())
	var intent := DeployCard.new(
		A, card_id, DuelStateBuilder.cell("A2"), EssencePayment.new(SOLDIER_COST)
	)
	return engine.validate(intent)
