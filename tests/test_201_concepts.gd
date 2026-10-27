# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## Concepts du chapitre 201 par le moteur : joueurs, fin de partie, pile commune, appartenance et
## contrôle, construction du deck (ruleset 0.33, sections 201.1, 201.3, 201.5, 201.6).

const SOLDIER: StringName = &"concept_soldier"
const WEAK: StringName = &"concept_weak"
const MAKER: StringName = &"concept_token_maker"
const BOOST_SPELL: StringName = &"sample_spell"
const TOKEN_SPELL: StringName = &"concept_token_spell"
const GEAR: StringName = &"sample_gear"
const OTHER_HERO: StringName = &"concept_other_hero"
const OTHER_HERO_HEALTH: int = 20
const PLAYER_COUNT: int = 2  # 201.1.1
const STRONG_FORCE: int = 5
const WEAK_FORCE: int = 2
const BOOST_COST: int = 1  # CatalogSamples.spell()
const TOKEN_SPELL_COST: int = 2
const SOLDIER_COST: int = 2  # CatalogSamples.unit()

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const REASON := IntentRejected.RejectReason

var _catalog: Catalog
var _builder: DuelStateBuilder
var _engine: DuelEngine


func before_test() -> void:
	_catalog = SetupSamples.catalog()
	SetupSamples.add_unit(_catalog, SOLDIER, STRONG_FORCE)
	SetupSamples.add_unit(_catalog, WEAK, WEAK_FORCE)
	_catalog.add_card(CardDefinition.from_dict(CatalogSamples.spell()))
	_catalog.add_card(CardDefinition.from_dict(CatalogSamples.gear()))
	_catalog.add_card(CatalogSamples.token_spell(TOKEN_SPELL, TOKEN_SPELL_COST))
	_catalog.add_card(_token_maker())
	_builder = DuelStateBuilder.new(DuelConfig.new(), _catalog)
	_engine = DuelEngine.new(_catalog)


func test_201_1_1_a_duel_has_two_players() -> void:
	var state := DuelState.create(DuelConfig.new())
	assert_int(state.players.size()).is_equal(PLAYER_COUNT)
	assert_int(DuelState.opponent_of(A)).is_equal(B)
	assert_int(DuelState.opponent_of(B)).is_equal(A)


func test_201_1_1_started_duel_places_one_hero_per_player() -> void:
	var events := _engine.start_new_duel(SetupSamples.setup())
	assert_array(EventLog.describe(events).filter(DuelChecks.is_hero_placed)).contains_exactly(
		["HeroPlaced:A", "HeroPlaced:B"]
	)
	assert_int(_engine.get_state().players.size()).is_equal(PLAYER_COUNT)


func test_201_1_3_no_other_condition_makes_a_player_win() -> void:
	# B n'a plus que son Hero, ni carte, ni Source : aucune de ces situations ne termine la partie.
	_builder.with_sources_in_play(B, 0, 0).with_sources_in_reserve(B, 0)
	_builder.with_sources_in_fonte(B, 10)
	_place(A, SOLDIER, "B2")
	_engine.start_from_state(_builder.build())
	_engine.submit(EndTurn.new(A))
	var state := _engine.get_state()
	assert_int(state.phase).is_equal(DuelState.DuelPhase.MAIN)
	assert_int(state.result).is_equal(DuelState.DuelResult.NONE)
	assert_int(state.active_player).is_equal(B)
	assert_int(_engine.validate(EndTurn.new(B))).is_equal(REASON.NONE)
	_engine.submit(EndTurn.new(B))
	assert_int(_engine.get_state().result).is_equal(DuelState.DuelResult.NONE)


func test_201_3_7_the_stack_is_one_zone_for_both_players() -> void:
	var own_unit_id := _place(B, SOLDIER, "B4")
	_builder.with_sources_in_play(B, BOOST_COST, 0)
	var card_id := _builder.add_to_hand(B, BOOST_SPELL)
	_builder.push_spell(_builder.make_card_instance(A, BOOST_SPELL))
	_builder.with_priority_player(B)
	_engine.start_from_state(_builder.build())
	var intent := CastSpell.new(B, card_id, EssencePayment.new(BOOST_COST))
	intent.target_piece_ids.append(own_unit_id)
	_engine.submit(intent)
	var owners: Array[DuelState.PlayerSide] = []
	for entry: StackEntry in _engine.get_state().stack:
		owners.append(entry.owner)
	assert_array(owners).is_equal([A, B])


func test_201_5_2_deployed_piece_is_controlled_by_the_owner_of_its_card() -> void:
	_builder.with_active_player(B).with_priority_player(B)
	var card_id := _builder.add_to_hand(B, SOLDIER)
	_engine.start_from_state(_builder.build())
	var deploy := DeployCard.new(
		B, card_id, DuelStateBuilder.cell("B5"), EssencePayment.new(SOLDIER_COST)
	)
	_engine.submit(deploy)
	_engine.submit(PassPriority.new(A))
	var piece := _engine.get_state().piece_at(DuelStateBuilder.cell("B5"))
	assert_int(piece.card.owner).is_equal(B)
	assert_int(piece.owner).is_equal(B)


func test_201_5_2_player_acts_only_with_the_pieces_he_controls() -> void:
	var own_reason := _normal_action_reason(A, A, false)
	var foreign_reason := _normal_action_reason(A, B, false)
	assert_int(own_reason).is_equal(REASON.NONE)
	assert_int(foreign_reason).is_equal(REASON.PIECE_NOT_YOURS)


func test_201_5_2_player_plays_only_cards_he_controls() -> void:
	var card_id := _builder.add_to_hand(B, SOLDIER)
	_engine.start_from_state(_builder.build())
	var snapshot := _engine.get_state().clone()
	var deploy := DeployCard.new(
		A, card_id, DuelStateBuilder.cell("B1"), EssencePayment.new(SOLDIER_COST)
	)
	assert_int(EventLog.rejection_reason(_engine.submit(deploy))).is_equal(REASON.CARD_NOT_IN_HAND)
	assert_array(DeepCompare.find_clone_defects(snapshot, _engine.get_state())).is_empty()


func test_201_5_2a_player_acts_only_with_the_tokens_he_controls() -> void:
	var own_reason := _normal_action_reason(A, A, true)
	var foreign_reason := _normal_action_reason(A, B, true)
	assert_int(own_reason).is_equal(REASON.NONE)
	assert_int(foreign_reason).is_equal(REASON.PIECE_NOT_YOURS)


func test_201_5_3_destroyed_cards_stay_with_their_owner() -> void:
	var attacker_id := _place(B, SOLDIER, "B3")
	var defender_id := _place(A, WEAK, "B2")
	var gear_id := _builder.attach_gear(defender_id, GEAR)
	var state := _builder.build()
	var events: Array[DuelEvent] = []
	CombatRules.resolve_attack(
		state, state.find_piece(attacker_id), state.find_piece(defender_id), events
	)
	var discard := state.get_player(A).discard
	assert_int(discard.size()).is_equal(2)
	for card: CardInstance in discard:
		assert_int(card.owner).is_equal(A)
	assert_array(DuelChecks.card_ids(discard)).contains([gear_id])
	assert_array(state.get_player(B).discard).is_empty()


func test_201_5_4a_token_created_by_a_spell_belongs_to_the_spell_owner() -> void:
	_builder.with_active_player(B).with_priority_player(B)
	_builder.with_sources_in_play(B, TOKEN_SPELL_COST, 0)
	var card_id := _builder.add_to_hand(B, TOKEN_SPELL)
	_engine.start_from_state(_builder.build())
	var intent := CastSpell.new(B, card_id, EssencePayment.new(TOKEN_SPELL_COST))
	intent.target_cells.append(DuelStateBuilder.cell("B5"))
	_engine.submit(intent)
	_engine.submit(PassPriority.new(A))
	var token := _engine.get_state().piece_at(DuelStateBuilder.cell("B5"))
	assert_bool(token.is_token()).is_true()
	assert_int(token.owner).is_equal(B)


func test_201_5_4b_token_created_by_a_triggered_effect_belongs_to_its_owner() -> void:
	var maker_id := _place(B, MAKER, "C3")
	var state := _builder.build()
	_engine.start_from_state(state)
	var events: Array[DuelEvent] = []
	TriggerRules.trigger(
		state, state.find_piece(maker_id), EffectDefinition.TriggerEvent.ARRIVAL, events
	)
	TriggerRules.add_waiting_triggers(state, events)
	assert_int(state.active_player).is_equal(A)
	var choice := ChooseTargets.new(B)
	choice.target_cells.append(DuelStateBuilder.cell("B5"))
	_engine.submit(choice)
	_engine.submit(PassPriority.new(A))
	var token := state.piece_at(DuelStateBuilder.cell("B5"))
	assert_bool(token.is_token()).is_true()
	assert_int(token.owner).is_equal(B)


func test_201_6_3_hero_does_not_limit_the_deck() -> void:
	var other_hero := CatalogSamples.with_field(CatalogSamples.hero(), "id", String(OTHER_HERO))
	other_hero = CatalogSamples.with_field(other_hero, "health", OTHER_HERO_HEALTH)
	_catalog.add_hero(HeroDefinition.from_dict(other_hero))
	var setup := SetupSamples.setup()
	setup.hero_b = OTHER_HERO
	var config := DuelConfig.new()
	assert_array(Array(setup.find_errors(_catalog, config))).is_empty()
	assert_array(Array(_catalog.find_deck_errors(setup.deck_a, config))).is_empty()
	assert_array(setup.deck_a).is_equal(setup.deck_b)


func _normal_action_reason(
	active: DuelState.PlayerSide, piece_owner: DuelState.PlayerSide, as_token: bool
) -> IntentRejected.RejectReason:
	var builder := DuelStateBuilder.new(DuelConfig.new(), _catalog)
	var cell := DuelStateBuilder.cell("C3")
	var piece_id := DuelState.NO_ID
	if as_token:
		piece_id = builder.place_token(piece_owner, Piece.PieceKind.UNIT, cell, STRONG_FORCE)
	else:
		piece_id = builder.place_piece(piece_owner, Piece.PieceKind.UNIT, cell, SOLDIER)
	builder.with_active_player(active).with_priority_player(active)
	var engine := DuelEngine.new(_catalog)
	engine.start_from_state(builder.build())
	return engine.validate(TakeNormalAction.new(active, piece_id, DuelStateBuilder.cell("B3")))


func _place(side: DuelState.PlayerSide, definition_id: StringName, cell_name: String) -> int:
	return _builder.place_piece(
		side, Piece.PieceKind.UNIT, DuelStateBuilder.cell(cell_name), definition_id
	)


func _token_maker() -> CardDefinition:
	var effect := CatalogSamples.create_token_effect()
	effect["timing"] = "triggered"
	effect["trigger"] = "arrival"
	var data := CatalogSamples.with_field(CatalogSamples.unit(), "id", String(MAKER))
	data = CatalogSamples.with_effects(data, [effect])
	data = CatalogSamples.with_field(data, "keywords", [{"keyword": "arrival"}])
	var definition := CardDefinition.from_dict(data)
	assert_array(Array(definition.find_errors())).is_empty()
	return definition
