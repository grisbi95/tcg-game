# gdlint: disable=max-public-methods

extends GdUnitTestSuite
## Renvoyer dans la main (ruleset 0.52, chapitre 216 ; 201.3.4 à 201.3.6a, 201.5.1, 207.4.7a ;
## décision de design 0234 du ruleset ; décision 0056). Le Spell et l'Unit à Arrivée viennent de
## MovementSamples.

const HAND_LIMIT: int = 7  # 201.3.4
const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const REASON := IntentRejected.RejectReason
const SOURCES_IN_PLAY: int = 4

var _builder: DuelStateBuilder
var _engine: DuelEngine


func before_test() -> void:
	var catalog := MovementSamples.catalog()
	_builder = DuelStateBuilder.new(DuelConfig.new(), catalog)
	for side: DuelState.PlayerSide in [A, B]:
		_builder.with_sources_in_play(side, SOURCES_IN_PLAY, 0)
	_engine = DuelEngine.new(catalog)


func test_216_1_1_returned_unit_leaves_the_board() -> void:
	var enemy_id := _place(B, TriggerSamples.SOLDIER, "B4")
	var card_id := _builder.add_to_hand(A, MovementSamples.RETURN_SPELL)
	MovementSamples.start(_engine, _builder)
	var announced := _engine.submit(MovementSamples.cast(A, card_id, [enemy_id]))
	assert_array(EventLog.describe(announced)).contains_exactly(
		["SourceInclined:A", "SpellAnnounced:A", "StackEntryAdded:A"]
	)
	assert_array(MovementSamples.resolve(_engine)).contains_exactly(
		[
			"PriorityPassed:B",
			"PieceReturnedToHand:B",
			"CardReturnedToHand:B",
			"CardDiscarded:A",
			"StackEntryResolved:A"
		]
	)
	assert_object(_engine.get_state().find_piece(enemy_id)).is_null()
	assert_object(_engine.get_state().piece_at(DuelStateBuilder.cell("B4"))).is_null()


func test_216_1_1_effect_targets_one_unit() -> void:
	var enemy_id := _place(B, TriggerSamples.SOLDIER, "B4")
	var ally_id := _place(A, TriggerSamples.SOLDIER, "B2")
	var building_id := _builder.place_piece(
		B, Piece.PieceKind.BUILDING, DuelStateBuilder.cell("D4"), TriggerSamples.BEACON
	)
	var card_id := _builder.add_to_hand(A, MovementSamples.RETURN_SPELL)
	MovementSamples.start(_engine, _builder)
	var hero_id := _engine.get_state().find_hero(B).piece_id
	for refused_id: int in [ally_id, building_id, hero_id]:
		_assert_rejected(MovementSamples.cast(A, card_id, [refused_id]), REASON.ILLEGAL_TARGET)
	_assert_rejected(
		MovementSamples.cast(A, card_id, [enemy_id, enemy_id]), REASON.WRONG_TARGET_COUNT
	)
	_assert_rejected(MovementSamples.cast(A, card_id, []), REASON.WRONG_TARGET_COUNT)


func test_216_1_1_effects_while_the_piece_is_in_play_end_with_the_return() -> void:
	var enemy_id := _place(B, TriggerSamples.SOLDIER, "B4")
	var effect := ActiveEffect.new()
	effect.affected_piece_id = enemy_id
	effect.duration = ActiveEffect.EffectDuration.WHILE_PIECE_IN_PLAY
	effect.effect_kind = EffectDefinition.kind_id(EffectDefinition.EffectKind.MODIFY_FORCE)
	effect.amount = 1
	var effect_id := _builder.add_active_effect(effect)
	var events := _cast_and_resolve(enemy_id)
	var found := events.filter(func(event: DuelEvent) -> bool: return event is ActiveEffectEnded)
	var ended: ActiveEffectEnded = found[0]
	assert_int(ended.effect_id).is_equal(effect_id)
	assert_array(_engine.get_state().active_effects).is_empty()


func test_216_1_2_card_returns_to_the_hand_of_its_owner() -> void:
	var enemy_id := _place(B, TriggerSamples.SOLDIER, "B4")
	var card_id := _builder.build().find_piece(enemy_id).card.card_instance_id
	_cast_and_resolve(enemy_id)
	var state := _engine.get_state()
	assert_array(DuelChecks.card_ids(state.get_player(B).hand)).contains_exactly([card_id])
	assert_array(state.get_player(B).discard).is_empty()


func test_216_1_2_card_goes_to_its_owner_even_if_another_player_controls_the_unit() -> void:
	var enemy_id := _place(B, TriggerSamples.SOLDIER, "B4")
	var card := _builder.build().find_piece(enemy_id).card
	card.owner = A
	_cast_and_resolve(enemy_id)
	var state := _engine.get_state()
	assert_array(DuelChecks.card_ids(state.get_player(A).hand)).contains_exactly(
		[card.card_instance_id]
	)
	assert_array(state.get_player(B).hand).is_empty()


func test_216_1_2_last_free_place_in_hand_is_taken() -> void:
	var enemy_id := _place(B, TriggerSamples.SOLDIER, "B4")
	for index: int in HAND_LIMIT - 1:
		_builder.add_to_hand(B, TriggerSamples.SOLDIER)
	var events := _cast_and_resolve(enemy_id)
	assert_bool(EventLog.describe(events).has("CardReturnedToHand:B")).is_true()
	assert_int(_engine.get_state().get_player(B).hand.size()).is_equal(HAND_LIMIT)


func test_216_1_2a_returned_card_goes_to_discard_when_the_hand_is_full() -> void:
	var enemy_id := _place(B, TriggerSamples.SOLDIER, "B4")
	var card_id := _builder.build().find_piece(enemy_id).card.card_instance_id
	for index: int in HAND_LIMIT:
		_builder.add_to_hand(B, TriggerSamples.SOLDIER)
	var labels := EventLog.describe(_cast_and_resolve(enemy_id))
	assert_array(labels).contains_exactly(
		[
			"PriorityPassed:B",
			"PieceReturnedToHand:B",
			"CardDiscarded:B",
			"CardDiscarded:A",
			"StackEntryResolved:A"
		]
	)
	var state := _engine.get_state()
	assert_int(state.get_player(B).hand.size()).is_equal(HAND_LIMIT)
	assert_array(DuelChecks.card_ids(state.get_player(B).discard)).contains_exactly([card_id])


func test_216_1_3_returned_token_ceases_to_exist() -> void:
	var token_id := _builder.place_token(B, Piece.PieceKind.UNIT, DuelStateBuilder.cell("B4"), 2)
	var labels := EventLog.describe(_cast_and_resolve(token_id))
	assert_array(labels).contains_exactly(
		["PriorityPassed:B", "PieceReturnedToHand:B", "CardDiscarded:A", "StackEntryResolved:A"]
	)
	var state := _engine.get_state()
	assert_object(state.find_piece(token_id)).is_null()
	assert_array(state.get_player(B).hand).is_empty()
	assert_array(state.get_player(B).discard).is_empty()


func test_216_1_4_gear_of_the_returned_unit_goes_to_its_discard() -> void:
	var enemy_id := _place(B, TriggerSamples.SOLDIER, "B4")
	var gear_id := _builder.attach_gear(enemy_id, &"sample_gear")
	var labels := EventLog.describe(_cast_and_resolve(enemy_id))
	assert_array(labels).contains_exactly(
		[
			"PriorityPassed:B",
			"PieceReturnedToHand:B",
			"CardReturnedToHand:B",
			"CardDiscarded:B",
			"CardDiscarded:A",
			"StackEntryResolved:A"
		]
	)
	var discard := _engine.get_state().get_player(B).discard
	assert_array(DuelChecks.card_ids(discard)).contains_exactly([gear_id])


func test_216_1_4_gear_goes_to_discard_even_when_the_card_returns_to_a_full_hand() -> void:
	var enemy_id := _place(B, TriggerSamples.SOLDIER, "B4")
	var gear_id := _builder.attach_gear(enemy_id, &"sample_gear")
	for index: int in HAND_LIMIT:
		_builder.add_to_hand(B, TriggerSamples.SOLDIER)
	_cast_and_resolve(enemy_id)
	var discard := _engine.get_state().get_player(B).discard
	assert_int(discard.size()).is_equal(2)
	assert_bool(DuelChecks.card_ids(discard).has(gear_id)).is_true()


func test_216_2_1_return_is_not_a_destruction() -> void:
	var enemy_id := _place(B, TriggerSamples.SOLDIER, "B4")
	var labels := EventLog.describe(_cast_and_resolve(enemy_id))
	assert_bool(labels.has("PieceDestroyed:B")).is_false()
	assert_array(_engine.get_state().get_player(B).discard).is_empty()


func test_216_2_2_last_breath_of_a_returned_piece_does_not_trigger() -> void:
	var martyr_id := _place(B, TriggerSamples.MARTYR, "B4")
	_place(B, TriggerSamples.SOLDIER, "D4")
	var labels := EventLog.describe(_cast_and_resolve(martyr_id))
	assert_bool(labels.has("EffectTriggered:B")).is_false()
	var state := _engine.get_state()
	assert_array(state.stack).is_empty()
	assert_array(state.waiting_triggers).is_empty()
	assert_array(state.active_effects).is_empty()


func test_decision_0008_returned_card_redeployed_is_a_new_piece() -> void:
	var enemy_id := _place(B, TriggerSamples.SOLDIER, "B4")
	var card_id := _builder.build().find_piece(enemy_id).card.card_instance_id
	_cast_and_resolve(enemy_id)
	_engine.submit(EndTurn.new(A))
	var deploy := DeployCard.new(B, card_id, DuelStateBuilder.cell("B5"), EssencePayment.new(2))
	assert_int(_engine.validate(deploy)).is_equal(REASON.NONE)
	_engine.submit(deploy)
	DuelChecks.pass_until_stack_empty(_engine)
	var redeployed := _engine.get_state().piece_at(DuelStateBuilder.cell("B5"))
	assert_int(redeployed.card.card_instance_id).is_equal(card_id)
	assert_int(redeployed.piece_id).is_not_equal(enemy_id)
	assert_object(_engine.get_state().find_piece(enemy_id)).is_null()


func test_decision_0056_return_arrival_targets_the_only_enemy_unit() -> void:
	var enemy_id := _place(B, TriggerSamples.SOLDIER, "B4")
	var card := _builder.make_card_instance(A, MovementSamples.RETURNER)
	_builder.push_deploy(card, DuelStateBuilder.cell("B1"))
	_builder.with_priority_player(B)
	MovementSamples.start(_engine, _builder)
	var labels := EventLog.describe(DuelChecks.pass_once(_engine, B))
	assert_bool(labels.has("DecisionResolvedAutomatically:A")).is_true()
	assert_array(_engine.get_state().stack[0].target_piece_ids).contains_exactly([enemy_id])
	var resolved := EventLog.describe(DuelChecks.pass_once(_engine, B))
	assert_bool(resolved.has("PieceReturnedToHand:B")).is_true()
	assert_object(_engine.get_state().find_piece(enemy_id)).is_null()


func test_216_1_1_return_targets_a_unit() -> void:
	var return_effect := CatalogSamples.return_to_hand_effect()
	assert_array(Array(MovementSamples.effect_errors(return_effect))).is_empty()
	for kinds: Array in [["hero"], ["building"], ["unit", "building"]]:
		var wrong := CatalogSamples.return_to_hand_effect()
		wrong["target"]["filter"]["piece_kinds"] = kinds
		(
			assert_bool(CatalogSamples.mentions(MovementSamples.effect_errors(wrong), "216.1.1"))
			. is_true()
		)
	var on_cell := CatalogSamples.with_field(return_effect, "target", {"what": "cell"})
	(
		assert_bool(
			CatalogSamples.mentions(
				MovementSamples.effect_errors(on_cell), "216.1.1 : return_to_hand cible piece"
			)
		)
		. is_true()
	)


func _place(side: DuelState.PlayerSide, definition_id: StringName, cell_name: String) -> int:
	return _builder.place_piece(
		side, Piece.PieceKind.UNIT, DuelStateBuilder.cell(cell_name), definition_id
	)


# A annonce le renvoi de `piece_id`, B passe : la pile se résout. Renvoie les événements.
func _cast_and_resolve(piece_id: int) -> Array[DuelEvent]:
	var card_id := _builder.add_to_hand(A, MovementSamples.RETURN_SPELL)
	MovementSamples.start(_engine, _builder)
	_engine.submit(MovementSamples.cast(A, card_id, [piece_id]))
	return DuelChecks.pass_once(_engine, B)


func _assert_rejected(intent: DuelIntent, expected: IntentRejected.RejectReason) -> void:
	assert_array(DuelChecks.rejection_defects(_engine, intent, expected)).is_empty()
