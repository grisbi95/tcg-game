# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## Réserve d'Essence : production pendant son tour, paiement depuis la réserve, paiement à
## l'annonce pendant le tour adverse, perte en fin de tour (ruleset 0.35, sections 203.6,
## 203.2.4, 203.2.5a, 203.3.2a, 203.3.2b, 204.5.7a ; décisions 0003 et 0026).

const UNIT: StringName = &"reserve_unit"
const UNIT_FORCE: int = 3
const UNIT_COST: int = 2  # CatalogSamples.unit()
const SPELL: StringName = &"reserve_spell"
const DEPLOY_CELL: String = "B1"
const DECK_SIZE: int = 4
const GEAR: StringName = &"sample_gear"  # CatalogSamples.gear(), coût 1
const GEAR_COST: int = 1
const HERO: StringName = &"sample_hero"  # CatalogSamples.hero(), pouvoir de coût 2
const POWER_COST: int = 2
const UNIT_CELL: String = "B2"

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const REASON := IntentRejected.RejectReason

var _builder: DuelStateBuilder
var _engine: DuelEngine


func before_test() -> void:
	var catalog := Catalog.new()
	SetupSamples.add_unit(catalog, UNIT, UNIT_FORCE)
	var spell := CatalogSamples.with_field(CatalogSamples.spell(), "id", String(SPELL))
	catalog.add_card(CardDefinition.from_dict(CatalogSamples.with_field(spell, "effects", [])))
	catalog.add_card(CardDefinition.from_dict(CatalogSamples.gear()))
	catalog.add_hero(HeroDefinition.from_dict(CatalogSamples.hero()))
	_builder = DuelStateBuilder.new(DuelConfig.new(), catalog)
	_engine = DuelEngine.new(catalog)
	for side: DuelState.PlayerSide in [A, B]:
		for index: int in DECK_SIZE:
			_builder.add_to_deck(side, UNIT)


func test_203_6_3_inclining_a_source_adds_to_the_reserve() -> void:
	_start()
	var events := _engine.submit(_produce(A, 1, 0))
	assert_array(EventLog.describe(events)).contains_exactly(
		["SourceInclined:A", "EssenceProduced:A"]
	)
	var player := _player(A)
	assert_int(player.essence_reserve).is_equal(1)
	assert_int(player.sources_tilted).is_equal(1)


func test_203_6_4_recycling_a_source_adds_to_the_reserve() -> void:
	_builder.with_sources_in_play(A, 0, 2)
	_start()
	var events := _engine.submit(_produce(A, 0, 1))
	assert_array(EventLog.describe(events)).contains_exactly(
		["SourceRecycled:A", "EssenceProduced:A"]
	)
	assert_int(_player(A).essence_reserve).is_equal(1)
	assert_int(_player(A).sources_in_fonte).is_equal(1)


func test_203_6_1_reserve_keeps_unspent_essence_during_the_turn() -> void:
	_start()
	_engine.submit(_produce(A, 1, 0))
	_engine.submit(_produce(A, 1, 0))
	assert_int(_player(A).essence_reserve).is_equal(2)


func test_203_3_2a_cost_paid_from_the_reserve() -> void:
	var card_id := _builder.add_to_hand(A, UNIT)
	_builder.with_essence_reserve(A, UNIT_COST + 1)
	_start()
	_engine.submit(_deploy(card_id, EssencePayment.new()))
	assert_int(_player(A).essence_reserve).is_equal(1)
	assert_int(_player(A).sources_tilted).is_equal(0)


func test_203_3_2a_gear_cost_paid_from_the_reserve() -> void:
	var unit_id := _builder.place_piece(A, Piece.PieceKind.UNIT, _cell(UNIT_CELL), UNIT)
	var gear_id := _builder.add_to_hand(A, GEAR)
	_builder.with_essence_reserve(A, GEAR_COST)
	_start()
	var events := _engine.submit(AttachGear.new(A, gear_id, unit_id, EssencePayment.new()))
	assert_int(EventLog.rejection_reason(events)).is_equal(EventLog.NOT_A_SINGLE_REJECTION)
	assert_int(_player(A).essence_reserve).is_equal(0)


func test_203_3_2a_hero_power_cost_paid_from_the_reserve() -> void:
	var unit_id := _builder.place_piece(A, Piece.PieceKind.UNIT, _cell(UNIT_CELL), UNIT)
	_builder.with_hero_definition(A, HERO).with_essence_reserve(A, POWER_COST)
	_start()
	var power := UseHeroPower.new(A, EssencePayment.new())
	power.target_piece_ids.append(unit_id)
	assert_int(EventLog.rejection_reason(_engine.submit(power))).is_equal(
		EventLog.NOT_A_SINGLE_REJECTION
	)
	assert_int(_player(A).essence_reserve).is_equal(0)


func test_203_6_5_announcement_completes_the_reserve() -> void:
	var card_id := _builder.add_to_hand(A, UNIT)
	_builder.with_essence_reserve(A, UNIT_COST - 1)
	_start()
	_engine.submit(_deploy(card_id, EssencePayment.new(1, 0)))
	assert_int(_player(A).essence_reserve).is_equal(0)
	assert_int(_player(A).sources_tilted).is_equal(1)


func test_203_6_5_announcement_does_not_overfill_the_reserve() -> void:
	var card_id := _builder.add_to_hand(A, UNIT)
	_builder.with_essence_reserve(A, UNIT_COST)
	_start()
	_assert_rejected(_deploy(card_id, EssencePayment.new(1, 0)), REASON.PAYMENT_DOES_NOT_MATCH_COST)


func test_203_2_4_opponent_produces_no_essence_outside_a_payment() -> void:
	_respond_to_a_spell_of(A)
	_assert_rejected(_produce(B, 1, 0), REASON.NOT_YOUR_TURN)


func test_203_3_2b_opponent_pays_at_announcement() -> void:
	var card_id := _builder.add_to_hand(B, SPELL)
	_respond_to_a_spell_of(A)
	var events := _engine.submit(CastSpell.new(B, card_id, EssencePayment.new(1, 0)))
	assert_int(EventLog.rejection_reason(events)).is_equal(EventLog.NOT_A_SINGLE_REJECTION)
	assert_int(_player(B).sources_tilted).is_equal(1)


func test_203_6_2_opponent_has_no_reserve() -> void:
	var card_id := _builder.add_to_hand(B, SPELL)
	_respond_to_a_spell_of(A)
	_engine.submit(CastSpell.new(B, card_id, EssencePayment.new(1, 0)))
	assert_int(_player(B).essence_reserve).is_equal(0)


func test_203_2_5a_opponent_recycles_a_source_tilted_in_his_own_turn() -> void:
	var card_id := _builder.add_to_hand(B, SPELL)
	_builder.with_sources_in_play(B, 0, 1)
	_respond_to_a_spell_of(A)
	var events := _engine.submit(CastSpell.new(B, card_id, EssencePayment.new(0, 1)))
	assert_array(EventLog.describe(events)).contains(["SourceRecycled:B"])


func test_203_6_6_active_player_acts_in_main_phase_with_empty_stack() -> void:
	_start()
	assert_int(_engine.validate(_produce(A, 1, 0))).is_equal(REASON.NONE)


func test_203_6_6_not_outside_the_main_phase_with_empty_stack() -> void:
	_builder.with_phase(DuelState.DuelPhase.TURN_START)
	_start()
	_assert_rejected(_produce(A, 1, 0), REASON.WRONG_PHASE)


func test_203_6_7_active_player_acts_when_he_can_answer() -> void:
	_builder.push_spell(_builder.make_card_instance(B, SPELL))
	_builder.with_priority_player(A)
	_start()
	assert_int(_engine.validate(_produce(A, 1, 0))).is_equal(REASON.NONE)


func test_203_6_7_active_player_acts_when_he_can_answer_during_the_end_of_turn() -> void:
	_builder.push_spell(_builder.make_card_instance(B, SPELL))
	_builder.with_phase(DuelState.DuelPhase.TURN_END).with_priority_player(A)
	_start()
	assert_int(_engine.validate(_produce(A, 1, 0))).is_equal(REASON.NONE)


func test_203_6_8_not_while_the_opponent_can_answer() -> void:
	_respond_to_a_spell_of(A)
	_assert_rejected(_produce(A, 1, 0), REASON.NOT_YOUR_PRIORITY)


func test_203_6_9_not_while_a_choice_is_awaited_from_him() -> void:
	var decision := PendingDecision.new()
	decision.kind = PendingDecision.DecisionKind.ORDER_TRIGGERS
	decision.awaited_players.append(A)
	_builder.with_pending_decision(decision)
	_start()
	_assert_rejected(_produce(A, 1, 0), REASON.DECISION_PENDING)


func test_203_6_11_producing_essence_is_not_an_announcement() -> void:
	_start()
	var labels := EventLog.describe(_engine.submit(_produce(A, 1, 0)))
	assert_bool(labels.has("StackEntryAdded:A")).is_false()
	assert_array(_engine.get_state().stack).is_empty()


func test_203_6_12_essence_is_added_at_once_without_the_stack() -> void:
	_builder.push_spell(_builder.make_card_instance(B, SPELL))
	_builder.with_priority_player(A)
	_start()
	_engine.submit(_produce(A, 1, 0))
	assert_int(_player(A).essence_reserve).is_equal(1)
	assert_int(_engine.get_state().stack.size()).is_equal(1)


func test_203_6_13_producing_essence_keeps_who_can_act() -> void:
	_builder.push_spell(_builder.make_card_instance(B, SPELL))
	_builder.with_priority_player(A)
	_start()
	_engine.submit(_produce(A, 1, 0))
	assert_int(_engine.get_state().priority_player).is_equal(A)
	assert_int(_engine.get_state().stack.size()).is_equal(1)


func test_204_5_7a_unspent_essence_is_lost_at_the_end_of_the_turn() -> void:
	_builder.with_essence_reserve(A, 2)
	_start()
	var labels := EventLog.describe(_engine.submit(EndTurn.new(A)))
	assert_array(labels).contains(["EssenceLost:A"])
	assert_int(labels.find("EssenceLost:A")).is_less(labels.find("TurnStarted:B"))
	assert_int(_player(A).essence_reserve).is_equal(0)


func test_203_1_3_essence_is_not_kept_beyond_its_turn() -> void:
	_start()
	_engine.submit(_produce(A, 1, 0))
	_engine.submit(EndTurn.new(A))
	assert_int(_player(A).essence_reserve).is_equal(0)


func test_decision_0026_production_must_produce_essence() -> void:
	_start()
	assert_int(_engine.validate(_produce(A, 0, 0))).is_equal(REASON.NO_ESSENCE_PRODUCED)
	assert_int(_engine.validate(_produce(A, -1, 2))).is_equal(REASON.NEGATIVE_PAYMENT)
	assert_int(_engine.validate(_produce(A, 3, 0))).is_equal(REASON.NOT_ENOUGH_UPRIGHT_SOURCES)


# A a annoncé un Spell ; B peut répondre ou passer.
func _respond_to_a_spell_of(side: DuelState.PlayerSide) -> void:
	_builder.push_spell(_builder.make_card_instance(side, SPELL))
	_builder.with_priority_player(DuelState.opponent_of(side))
	_start()


func _start() -> void:
	_engine.start_from_state(_builder.build())


func _produce(side: DuelState.PlayerSide, inclined: int, recycled: int) -> ProduceEssence:
	return ProduceEssence.new(side, EssencePayment.new(inclined, recycled))


func _deploy(card_id: int, payment: EssencePayment) -> DeployCard:
	return DeployCard.new(A, card_id, _cell(DEPLOY_CELL), payment)


func _cell(cell_name: String) -> Vector2i:
	return DuelStateBuilder.cell(cell_name)


func _player(side: DuelState.PlayerSide) -> PlayerState:
	return _engine.get_state().get_player(side)


# Le moteur est démarré : vérifie le refus et l'état inchangé.
func _assert_rejected(intent: DuelIntent, expected: IntentRejected.RejectReason) -> void:
	var snapshot := _engine.get_state().clone()
	assert_int(EventLog.rejection_reason(_engine.submit(intent))).is_equal(expected)
	assert_array(DeepCompare.find_clone_defects(snapshot, _engine.get_state())).is_empty()
