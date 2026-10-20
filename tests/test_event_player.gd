extends GdUnitTestSuite
## EventPlayer sans scène : un lot joué émet `event_played` dans l'ordre puis `batch_played` une
## fois, les lots s'enchaînent dans l'ordre, `is_playing()` bloque les commandes pendant la
## lecture (décision 0006 ; ui/CLAUDE.md). Le nœud est ajouté à l'arbre de la suite, qui lui
## fournit `get_tree().process_frame`.

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const FIRST_TURN: int = 1
const SECOND_TURN: int = 2

var _player: EventPlayer
var _journal: Array[String] = []


func before_test() -> void:
	_player = EventPlayer.new()
	add_child(_player)
	_journal = []
	_player.event_played.connect(
		func(event: DuelEvent) -> void: _journal.append("event:%s" % EventText.describe(event))
	)
	_player.batch_played.connect(
		func(events: Array[DuelEvent]) -> void: _journal.append("batch:%d" % events.size())
	)


func after_test() -> void:
	_player.free()


func test_decision_0006_new_player_is_idle() -> void:
	assert_bool(_player.is_playing()).is_false()


func test_decision_0006_batch_emits_its_events_in_order_then_ends_once() -> void:
	_player.play(_batch_of_two())
	await _wait_frames()
	(
		assert_array(_journal)
		. contains_exactly(
			[
				"event:%s" % EventText.describe(CardDrawn.new(A)),
				"event:%s" % EventText.describe(TurnStarted.new(B, SECOND_TURN)),
				"batch:2",
			]
		)
	)


func test_decision_0006_batch_end_comes_after_a_frame_not_during_play() -> void:
	_player.play(_batch_of_two())
	assert_array(_journal).has_size(2)
	assert_bool(_player.is_playing()).is_true()
	await _wait_frames()
	assert_array(_journal).has_size(3)


func test_decision_0006_commands_are_blocked_while_playing_then_released() -> void:
	_player.play(_batch_of_two())
	assert_bool(_player.is_playing()).is_true()
	await _wait_frames()
	assert_bool(_player.is_playing()).is_false()


func test_decision_0006_batch_played_carries_the_events_of_the_batch() -> void:
	var received: Array[int] = []
	_player.batch_played.connect(
		func(events: Array[DuelEvent]) -> void: received.append(events.size())
	)
	_player.play(_batch_of_two())
	await _wait_frames()
	assert_array(received).contains_exactly([2])


func test_decision_0006_empty_batch_is_ignored() -> void:
	var no_events: Array[DuelEvent] = []
	_player.play(no_events)
	assert_bool(_player.is_playing()).is_false()
	await _wait_frames()
	assert_array(_journal).is_empty()


func test_decision_0006_batch_sent_during_playback_is_played_after_the_first() -> void:
	var second: Array[DuelEvent] = [TurnStarted.new(A, FIRST_TURN)]
	_player.play(_batch_of_two())
	_player.play(second)
	await _wait_frames()
	(
		assert_array(_journal)
		. contains_exactly(
			[
				"event:%s" % EventText.describe(CardDrawn.new(A)),
				"event:%s" % EventText.describe(TurnStarted.new(B, SECOND_TURN)),
				"batch:2",
				"event:%s" % EventText.describe(TurnStarted.new(A, FIRST_TURN)),
				"batch:1",
			]
		)
	)
	assert_bool(_player.is_playing()).is_false()


func test_decision_0006_player_can_play_again_once_idle() -> void:
	_player.play(_batch_of_two())
	await _wait_frames()
	_journal.clear()
	var again: Array[DuelEvent] = [CardDrawn.new(B)]
	_player.play(again)
	assert_bool(_player.is_playing()).is_true()
	await _wait_frames()
	assert_array(_journal).has_size(2)
	assert_str(_journal[1]).is_equal("batch:1")


func _batch_of_two() -> Array[DuelEvent]:
	var events: Array[DuelEvent] = [CardDrawn.new(A), TurnStarted.new(B, SECOND_TURN)]
	return events


# Les lots attendent une image chacun ; trois images couvrent les essais à deux lots.
func _wait_frames() -> void:
	for frame: int in 3:
		await get_tree().process_frame
