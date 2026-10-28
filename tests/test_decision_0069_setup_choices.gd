extends GdUnitTestSuite
## Sélecteurs de l'écran de préparation, sans scène (décision 0069) : entrées du sélecteur de
## partie et verrouillage des decks et du premier joueur par les fonctions statiques de
## `SetupScreen`.

const PLAN_GAME_NUMBER: int = 7
const PLAN_GAME_NUMBERS: Array[int] = [1, PLAN_GAME_NUMBER]
const PLAN_LABELS: Array[String] = ["Partie 1 — X contre Y", "Partie 7 — Y contre X"]
const CONTROLS_ENABLED: bool = true
const CONTROLS_DISABLED: bool = false


func test_decision_0069_game_option_lists_free_game_then_plan_games() -> void:
	var preparation := _preparation()
	var expected_numbers: Array[int] = [DuelSeries.NO_PLAN_GAME]
	expected_numbers.append_array(PLAN_GAME_NUMBERS)
	var expected_labels: Array[String] = [SetupScreen.FREE_GAME_TEXT]
	expected_labels.append_array(PLAN_LABELS)
	assert_array(Array(SetupScreen.game_numbers(preparation))).is_equal(expected_numbers)
	assert_array(Array(SetupScreen.game_labels(preparation))).is_equal(expected_labels)


func test_decision_0069_without_plan_only_the_free_game_is_listed() -> void:
	var preparation := SetupScreen.Preparation.new()
	assert_array(Array(SetupScreen.game_numbers(preparation))).is_equal([DuelSeries.NO_PLAN_GAME])
	assert_array(Array(SetupScreen.game_labels(preparation))).is_equal([SetupScreen.FREE_GAME_TEXT])


func test_decision_0069_free_game_leaves_decks_and_first_player_open() -> void:
	(
		assert_bool(SetupScreen.are_free_choices_enabled(DuelSeries.NO_PLAN_GAME, CONTROLS_ENABLED))
		. is_true()
	)


func test_decision_0069_plan_game_locks_decks_and_first_player() -> void:
	assert_bool(SetupScreen.are_free_choices_enabled(PLAN_GAME_NUMBER, CONTROLS_ENABLED)).is_false()


func test_decision_0069_free_choices_are_locked_while_connecting() -> void:
	(
		assert_bool(
			SetupScreen.are_free_choices_enabled(DuelSeries.NO_PLAN_GAME, CONTROLS_DISABLED)
		)
		. is_false()
	)


func _preparation() -> SetupScreen.Preparation:
	var preparation := SetupScreen.Preparation.new()
	preparation.plan_game_numbers = PackedInt32Array(PLAN_GAME_NUMBERS)
	preparation.plan_labels = PackedStringArray(PLAN_LABELS)
	return preparation
