extends GdUnitTestSuite
## « A eu lieu » d'un effet qui endort (ruleset 0.55 ; 207.7.6a, 205.5.7a, 205.5.7b, 200.4.1) : « si
## vous le faites » ne suit « endormez » que si une pièce s'est endormie. Carte : TextSamples.

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const SOLDIER: StringName = TriggerSamples.SOLDIER
const DECK_SIZE: int = 4

var _builder: DuelStateBuilder
var _engine: DuelEngine


func before_test() -> void:
	var catalog := TextSamples.catalog()
	_builder = HandEffectSamples.builder(catalog)
	_engine = DuelEngine.new(catalog)
	for index: int in DECK_SIZE:
		_builder.add_to_deck(A, SOLDIER)


func test_207_7_6a_if_you_do_follows_a_sleep_that_put_an_awake_piece_to_sleep() -> void:
	var events := _sleep_then_draw(true, Piece.PieceKind.UNIT)
	(
		assert_array(EventLog.describe(events))
		. contains_exactly(
			[
				"PriorityPassed:B",
				"PieceFellAsleep:A",
				"CardDrawn:A",
				"CardDiscarded:A",
				"StackEntryResolved:A",
			]
		)
	)


func test_207_7_6a_if_you_do_does_not_follow_a_sleep_on_an_already_sleeping_piece() -> void:
	var events := _sleep_then_draw(false, Piece.PieceKind.UNIT)  # 205.5.7a
	assert_array(EventLog.describe(events)).contains_exactly(
		["PriorityPassed:B", "CardDiscarded:A", "StackEntryResolved:A"]
	)


func test_207_7_6a_if_you_do_does_not_follow_a_sleep_on_a_building() -> void:
	var events := _sleep_then_draw(true, Piece.PieceKind.BUILDING)  # 205.5.7b
	assert_array(EventLog.describe(events)).contains_exactly(
		["PriorityPassed:B", "CardDiscarded:A", "StackEntryResolved:A"]
	)


# Endormir la pièce `kind` (éveillée ou non) de A, puis piocher si l'on l'a fait.
func _sleep_then_draw(awake: bool, kind: Piece.PieceKind) -> Array[DuelEvent]:
	var piece_id := _builder.place_piece(A, kind, DuelStateBuilder.cell("B2"), SOLDIER)
	_builder.with_piece_awake(piece_id, awake)
	var spell_id := _builder.add_to_hand(A, TextSamples.SLEEP_THEN_DRAW)
	_engine.start_from_state(_builder.build())
	_engine.submit(HandEffectSamples.cast(A, spell_id, [piece_id]))
	return HandEffectSamples.resolve(_engine)
