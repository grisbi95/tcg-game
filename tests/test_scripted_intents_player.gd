extends GdUnitTestSuite
## ScriptedIntentsPlayer sans scène (outil de développement de `ui/support/`) : une suite
## d'intentions soumise une à une, abandonnée à la première intention d'un autre joueur que celui
## de l'écran ou refusée par `DuelEngine.validate()`. Vrai `DuelHost`, `ManualClock`, deux humains.
##
## Le duel est au mulligan de A (204.2), A devant l'écran : ChooseMulligan(A) est valide,
## EndTurn(A) est refusé tant que le choix est attendu.

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const ERROR_PREFIX: String = "ScriptedIntentsPlayer : "
const OTHER_PLAYER_ERROR: String = ERROR_PREFIX + "intention d'un autre joueur que celui de l'écran"
const REFUSED_ERROR: String = ERROR_PREFIX + "intention refusée, la suite est abandonnée"

var _engine: DuelEngine
var _host: DuelHost
var _player: ScriptedIntentsPlayer
var _chosen: Array[DuelIntent] = []


func before_test() -> void:
	_engine = DuelEngine.new(SetupSamples.catalog())
	_host = DuelHost.new(_engine, ManualClock.new())
	var setup := SetupSamples.setup()
	setup.impose_first_player(A)
	_host.start(setup)
	_host.confirm_events_played()
	_host.confirm_relay()
	_player = ScriptedIntentsPlayer.new()
	_player.setup(HostedDuelSession.new(_host, setup))
	_chosen = []
	_player.intent_chosen.connect(func(intent: DuelIntent) -> void: _chosen.append(intent))


func test_decision_0036_nothing_is_pending_without_intents() -> void:
	assert_bool(_player.has_pending()).is_false()
	_player.submit_next()
	assert_array(_chosen).is_empty()


func test_decision_0036_pending_until_every_intent_is_played() -> void:
	_player.add_intents([ChooseMulligan.new(A), ChooseMulligan.new(A)])
	assert_bool(_player.has_pending()).is_true()
	_player.submit_next()
	assert_bool(_player.has_pending()).is_true()
	_player.submit_next()
	assert_bool(_player.has_pending()).is_false()


func test_decision_0036_valid_intents_are_emitted_in_order_one_per_call() -> void:
	var first := ChooseMulligan.new(A)
	var second := ChooseMulligan.new(A)
	_player.add_intents([first, second])
	_player.submit_next()
	assert_array(_chosen).has_size(1)
	assert_object(_chosen[0]).is_same(first)
	_player.submit_next()
	assert_object(_chosen[1]).is_same(second)


func test_decision_0036_intents_added_later_follow_the_earlier_ones() -> void:
	var first := ChooseMulligan.new(A)
	var later := ChooseMulligan.new(A)
	_player.add_intents([first])
	_player.add_intents([later])
	_player.submit_next()
	_player.submit_next()
	assert_object(_chosen[0]).is_same(first)
	assert_object(_chosen[1]).is_same(later)


func test_decision_0036_refused_intent_stops_the_whole_suite() -> void:
	_player.add_intents([EndTurn.new(A), ChooseMulligan.new(A)])
	var snapshot := _engine.get_state().clone()
	await assert_error(func() -> void: _player.submit_next()).is_push_error(REFUSED_ERROR)
	assert_array(_chosen).is_empty()
	assert_bool(_player.has_pending()).is_false()
	_player.submit_next()
	assert_array(_chosen).is_empty()
	assert_array(DeepCompare.find_clone_defects(snapshot, _engine.get_state())).is_empty()


func test_decision_0036_intent_of_the_other_player_stops_the_whole_suite() -> void:
	_player.add_intents([ChooseMulligan.new(B), ChooseMulligan.new(A)])
	await assert_error(func() -> void: _player.submit_next()).is_push_error(OTHER_PLAYER_ERROR)
	assert_array(_chosen).is_empty()
	assert_bool(_player.has_pending()).is_false()


func test_decision_0036_valid_intents_before_a_refused_one_are_still_emitted() -> void:
	var valid := ChooseMulligan.new(A)
	_player.add_intents([valid, EndTurn.new(A)])
	_player.submit_next()
	assert_array(_chosen).has_size(1)
	assert_bool(_player.has_pending()).is_true()
	await assert_error(func() -> void: _player.submit_next()).is_push_error(REFUSED_ERROR)
	assert_array(_chosen).has_size(1)
	assert_bool(_player.has_pending()).is_false()


func test_decision_0036_emitting_does_not_submit_the_intent() -> void:
	_player.add_intents([ChooseMulligan.new(A)])
	var snapshot := _engine.get_state().clone()
	_player.submit_next()
	assert_array(DeepCompare.find_clone_defects(snapshot, _engine.get_state())).is_empty()
