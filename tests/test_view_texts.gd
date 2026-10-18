extends GdUnitTestSuite
## Textes de la vue sans scène : phrases du journal, lignes des cartes (ruleset 0.35 ; décision
## 0025 ; ui/CLAUDE.md, fonctions statiques des vues).

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B


func test_decision_0025_every_event_class_has_a_sentence() -> void:
	for global_class: Dictionary in ProjectSettings.get_global_class_list():
		var base: StringName = global_class["base"]
		var name: StringName = global_class["class"]
		if name == &"PlayerEvent" or not (base == &"DuelEvent" or base == &"PlayerEvent"):
			continue
		(
			assert_bool(EventText.SENTENCES.has(name))
			. override_failure_message("%s sans phrase dans EventText.SENTENCES" % name)
			. is_true()
		)


func test_decision_0025_player_event_names_its_player() -> void:
	assert_str(EventText.describe(TurnStarted.new(B, 3))).is_equal("Début du tour du joueur B.")
	assert_str(EventText.describe(CardDrawn.new(A))).is_equal("Le joueur A pioche une carte.")


func test_decision_0025_other_event_has_a_plain_sentence() -> void:
	assert_str(EventText.describe(DuelEnded.new())).is_equal("Le duel est terminé.")


func test_decision_0025_card_lines() -> void:
	var unit := CardDefinition.from_dict(CatalogSamples.unit())
	assert_str(CardText.cost_line(unit)).is_equal("Coût 2")
	assert_str(CardText.type_line(unit)).is_equal("Unit · Force 3")
	var spell := CardDefinition.from_dict(CatalogSamples.spell())
	assert_str(CardText.type_line(spell)).is_equal("Spell · Réaction")
	assert_str(CardText.keywords_line(spell)).is_empty()


func test_decision_0025_keywords_line_names_each_keyword_with_its_value() -> void:
	var unit := CardDefinition.from_dict(CatalogSamples.unit())
	unit.keywords[CardDefinition.Keyword.ASSAULT] = 2
	unit.keywords[CardDefinition.Keyword.OUTPOST] = CardDefinition.NO_KEYWORD_VALUE
	assert_str(CardText.keywords_line(unit)).is_equal("Assaut 2 · Avant-poste")


func test_decision_0025_clock_shows_minutes_and_started_seconds() -> void:
	assert_str(ClockView.format_time(545_000)).is_equal("09:05")
	assert_str(ClockView.format_time(600_000)).is_equal("10:00")
	assert_str(ClockView.format_time(1)).is_equal("00:01")
	assert_str(ClockView.format_time(-5)).is_equal("00:00")
