extends GdUnitTestSuite
## Condition « si » d'un Spell lue sur une valeur du jeu (ruleset 0.55, 207.7.1 à 207.7.3, 207.7.7,
## 207.7.8 ; décision 0065) : comparaison « au moins » ou « au plus », lue à la résolution quand
## l'effet vient dans l'ordre du texte. Cartes : GameValueSamples (Appel, Rassemblement, Grand X).

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const SOLDIER: StringName = TriggerSamples.SOLDIER
const ROLLCALL: StringName = GameValueSamples.ROLLCALL  # au plus 2 Units alliées
const GATHER: StringName = GameValueSamples.GATHER  # au moins 2 Units alliées
const BIG_X: StringName = GameValueSamples.BIG_X  # X au moins 2
const LIMIT: int = GameValueSamples.ROLLCALL_LIMIT

var _catalog: Catalog
var _builder: DuelStateBuilder
var _engine: DuelEngine


func before_test() -> void:
	_catalog = GameValueSamples.catalog()
	_builder = HandEffectSamples.builder(_catalog)
	for index: int in 3:
		_builder.add_to_deck(A, SOLDIER)


func test_207_7_1_at_most_reads_the_pieces_when_the_spell_resolves() -> void:
	var piece_ids := _place_allies(LIMIT + 1)
	var spell_id := _builder.add_to_hand(A, ROLLCALL)
	_start()
	_engine.submit(HandEffectSamples.cast(A, spell_id))
	_engine.get_state().pieces.erase(_engine.get_state().find_piece(piece_ids[0]))
	var labels := EventLog.describe(HandEffectSamples.resolve(_engine))
	assert_array(labels).contains_exactly(
		["PriorityPassed:B", "CardDrawn:A", "CardDiscarded:A", "StackEntryResolved:A"]
	)


func test_207_7_2_at_most_false_the_effect_does_not_happen() -> void:
	_place_allies(LIMIT + 1)
	var spell_id := _builder.add_to_hand(A, ROLLCALL)
	_start()
	_engine.submit(HandEffectSamples.cast(A, spell_id))
	var labels := EventLog.describe(HandEffectSamples.resolve(_engine))
	assert_array(labels).contains_exactly(
		["PriorityPassed:B", "CardDiscarded:A", "StackEntryResolved:A"]
	)
	var state := _engine.get_state()
	assert_int(state.get_player(A).sources_tilted).is_equal(HandEffectSamples.SPELL_COST)  # 207.7.7


func test_207_7_1_at_least_reads_the_pieces_when_the_spell_resolves() -> void:
	_place_allies(LIMIT)
	var spell_id := _builder.add_to_hand(A, GATHER)
	_start()
	_engine.submit(HandEffectSamples.cast(A, spell_id))
	var labels := EventLog.describe(HandEffectSamples.resolve(_engine))
	assert_array(labels).contains_exactly(
		["PriorityPassed:B", "CardDrawn:A", "CardDiscarded:A", "StackEntryResolved:A"]
	)


func test_207_7_3_at_least_false_the_card_still_goes_to_the_discard() -> void:
	_place_allies(LIMIT - 1)
	var spell_id := _builder.add_to_hand(A, GATHER)
	_start()
	_engine.submit(HandEffectSamples.cast(A, spell_id))
	var labels := EventLog.describe(HandEffectSamples.resolve(_engine))
	assert_array(labels).contains_exactly(
		["PriorityPassed:B", "CardDiscarded:A", "StackEntryResolved:A"]  # 207.7.8
	)


func test_207_7_1_the_condition_compares_with_the_x_chosen_at_the_announcement() -> void:
	var small_id := _builder.add_to_hand(A, BIG_X)
	var big_id := _builder.add_to_hand(A, BIG_X)
	_start()
	_engine.submit(ValueSamples.cast(A, small_id, LIMIT - 1))
	var small := EventLog.describe(HandEffectSamples.resolve(_engine))
	assert_array(small).not_contains("CardDrawn:A")
	_engine.submit(ValueSamples.cast(A, big_id, LIMIT))
	var big := EventLog.describe(HandEffectSamples.resolve(_engine))
	assert_array(big).contains("CardDrawn:A")


func test_207_7_1_the_condition_of_an_order_is_read_from_the_json_as_a_game_value() -> void:
	var order := HeroOrder.from_dict(
		{
			"speed": "action",
			"texts":
			[
				TextSamples.text_of(
					[
						GameValueSamples.conditioned(
							GameValueSamples.draw(),
							GameValueSamples.condition(
								GameValueSamples.enemy_units(), "at_least", 1
							)
						)
					]
				)
			]
		}
	)
	assert_array(Array(order.find_errors())).is_empty()
	var condition := order.texts[0].effects[0].condition
	assert_int(condition.value.kind).is_equal(GameValue.Kind.PIECE_COUNT)
	assert_int(condition.comparison).is_equal(EffectCondition.Comparison.AT_LEAST)


func _place_allies(count: int) -> Array[int]:
	var cells: Array[String] = ["B2", "C2", "D2", "B3"]
	var piece_ids: Array[int] = []
	for index: int in count:
		piece_ids.append(
			_builder.place_piece(
				A, Piece.PieceKind.UNIT, DuelStateBuilder.cell(cells[index]), SOLDIER
			)
		)
	return piece_ids


func _start() -> void:
	_engine = DuelEngine.new(_catalog)
	_engine.start_from_state(_builder.build())
