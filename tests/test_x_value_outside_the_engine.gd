extends GdUnitTestSuite
## Valeur X hors du moteur (ruleset 0.53, chapitre 213 ; décisions 0022 et 0058) : le journal des
## intentions écrit `x_value` et relit un journal ancien sans ce champ avec 0 ; l'agent aléatoire
## propose des valeurs de X pour un Spell à coût X.

const SOURCES: int = 4
const FORCE: int = ValueSamples.UNIT_FORCE

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const REASON := IntentRejected.RejectReason

var _builder: DuelStateBuilder
var _engine: DuelEngine


func before_test() -> void:
	var catalog := ValueSamples.catalog()
	_builder = DuelStateBuilder.new(DuelConfig.new(), catalog)
	_builder.with_sources_in_play(A, SOURCES, 0)
	_engine = DuelEngine.new(catalog)


func test_decision_0058_codec_round_trips_the_value_of_x() -> void:
	var intent := ValueSamples.cast(A, 12, 3, [5])
	var parsed: Variant = JSON.parse_string(JSON.stringify(IntentCodec.encode(intent)))
	var through_json: Dictionary = parsed if parsed is Dictionary else {}
	var decoded := IntentCodec.decode(through_json) as CastSpell
	assert_object(decoded).is_not_null()
	assert_int(decoded.x_value).is_equal(3)
	assert_array(Array(DeepCompare.find_clone_defects(intent, decoded))).is_empty()


func test_decision_0058_an_old_journal_without_x_reads_with_zero() -> void:
	var data := IntentCodec.encode(ValueSamples.cast_fixed(A, 12, 2, [5]))
	data.erase("x_value")
	var decoded := IntentCodec.decode(data) as CastSpell
	assert_object(decoded).is_not_null()
	assert_int(decoded.x_value).is_equal(0)
	data.erase("card_instance_id")
	assert_object(IntentCodec.decode(data)).is_null()


func test_decision_0058_the_random_agent_proposes_each_x_the_essence_pays() -> void:
	var card_id := _builder.add_to_hand(A, ValueSamples.EXECUTION)
	var state := _builder.build()
	var proposed: Array[int] = []
	for intent: DuelIntent in RandomLegalAgent.candidates(state, A):
		if intent is CastSpell and not proposed.has((intent as CastSpell).x_value):
			proposed.append((intent as CastSpell).x_value)
			assert_int((intent as CastSpell).card_instance_id).is_equal(card_id)
	proposed.sort()
	assert_array(proposed).contains_exactly([1, 2, 3, 4])


func test_decision_0058_the_random_agent_bounds_x() -> void:
	_builder.with_sources_in_play(A, RandomLegalAgent.MAX_X_CANDIDATES + 2, 0)
	_builder.add_to_hand(A, ValueSamples.EXECUTION)
	var largest := 0
	for intent: DuelIntent in RandomLegalAgent.candidates(_builder.build(), A):
		if intent is CastSpell:
			largest = maxi(largest, (intent as CastSpell).x_value)
	assert_int(largest).is_equal(RandomLegalAgent.MAX_X_CANDIDATES)


func test_decision_0058_a_proposed_x_is_paid_and_legal() -> void:
	_builder.add_to_hand(A, ValueSamples.EXECUTION)
	var enemy_id := _builder.place_piece(
		B, Piece.PieceKind.UNIT, DuelStateBuilder.cell("C4"), ValueSamples.SOLDIER
	)
	_engine.start_from_state(_builder.build())
	var legal: Array[int] = []
	for intent: DuelIntent in RandomLegalAgent.candidates(_engine.get_state(), A):
		var cast := intent as CastSpell
		if cast == null or _engine.validate(cast) != REASON.NONE:
			continue
		legal.append(cast.x_value)
		assert_array(cast.target_piece_ids).contains_exactly([enemy_id])
		assert_int(cast.payment.essence_produced()).is_equal(cast.x_value)
	legal.sort()
	assert_int(legal[0]).is_equal(FORCE)
	assert_int(legal[-1]).is_equal(SOURCES)
