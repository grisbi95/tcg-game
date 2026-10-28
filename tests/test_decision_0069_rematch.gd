extends GdUnitTestSuite
## « Revanche » et premier joueur montré à la préparation, sans scène (décision 0069 ; décisions
## 0036, 0050 et 0066) : `DuelSeries.rematch_returns_to_setup` et
## `DuelSeries.get_chosen_first_player_choice`, que `MainScreen` appelle.

const PLAN_GAME_NUMBER: int = 1
const PLAN_DECK_ID: StringName = &"plan_deck"
const IS_REMOTE: bool = true
const IS_LOCAL: bool = false


func test_decision_0069_rematch_in_free_game_replays_the_duel() -> void:
	assert_bool(_free_series().rematch_returns_to_setup(IS_LOCAL)).is_false()


func test_decision_0069_rematch_after_a_plan_game_returns_to_setup() -> void:
	assert_bool(_plan_series(DuelState.PlayerSide.A).rematch_returns_to_setup(IS_LOCAL)).is_true()


func test_decision_0069_remote_rematch_returns_to_setup_as_in_decision_0050() -> void:
	assert_bool(_free_series().rematch_returns_to_setup(IS_REMOTE)).is_true()
	assert_bool(_plan_series(DuelState.PlayerSide.A).rematch_returns_to_setup(IS_REMOTE)).is_true()


func test_decision_0069_free_game_shows_the_host_first_player_choice() -> void:
	var series := _free_series()
	series.set_first_player_choice(DuelSeries.FirstPlayerChoice.DRAWN)
	assert_int(series.get_chosen_first_player_choice()).is_equal(DuelSeries.FirstPlayerChoice.DRAWN)


func test_decision_0069_plan_game_shows_its_imposed_first_player() -> void:
	var series := _plan_series(DuelState.PlayerSide.B)
	series.set_first_player_choice(DuelSeries.FirstPlayerChoice.DRAWN)
	assert_int(series.get_chosen_first_player_choice()).is_equal(
		DuelSeries.FirstPlayerChoice.PLAYER_B
	)
	assert_int(_plan_series(DuelState.PlayerSide.A).get_chosen_first_player_choice()).is_equal(
		DuelSeries.FirstPlayerChoice.PLAYER_A
	)


func _free_series() -> DuelSeries:
	return DuelSeries.new(DeckList.new(), DeckList.new())


# Série dont la partie choisie est l'unique partie d'un plan en mémoire.
func _plan_series(first_player: DuelState.PlayerSide) -> DuelSeries:
	var deck := DeckList.new()
	deck.deck_id = PLAN_DECK_ID
	var game := SeriesPlanGame.new()
	game.game_number = PLAN_GAME_NUMBER
	game.deck_id_a = PLAN_DECK_ID
	game.deck_id_b = PLAN_DECK_ID
	game.first_player = first_player
	var plan := SeriesPlan.new()
	plan.games.append(game)
	var series := _free_series()
	var decks: Array[DeckList] = [deck]
	series.set_plan(plan, decks)
	series.choose_plan_game(PLAN_GAME_NUMBER)
	return series
