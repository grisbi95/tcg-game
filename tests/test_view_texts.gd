extends GdUnitTestSuite
## Textes de la vue sans scène : phrases du journal, textes des cartes (ruleset 0.36 ; décisions
## 0025 et 0027 ; ui/CLAUDE.md, fonctions statiques des vues).

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B


func test_decision_0025_every_event_class_has_a_sentence() -> void:
	for global_class: Dictionary in ProjectSettings.get_global_class_list():
		var base: StringName = global_class["base"]
		var event_class: StringName = global_class["class"]
		if event_class == &"PlayerEvent" or not (base == &"DuelEvent" or base == &"PlayerEvent"):
			continue
		(
			assert_bool(EventText.SENTENCES.has(event_class))
			. override_failure_message("%s sans phrase dans EventText.SENTENCES" % event_class)
			. is_true()
		)


func test_decision_0025_player_event_names_its_player() -> void:
	assert_str(EventText.describe(TurnStarted.new(B, 3))).is_equal("Début du tour du joueur B.")
	assert_str(EventText.describe(CardDrawn.new(A))).is_equal("Le joueur A pioche une carte.")


func test_decision_0025_other_event_has_a_plain_sentence() -> void:
	assert_str(EventText.describe(DuelEnded.new())).is_equal("Le duel est terminé.")


func test_decision_0027_type_and_speed_names() -> void:
	var unit := CardDefinition.from_dict(CatalogSamples.unit())
	assert_str(CardText.type_name(unit.card_type)).is_equal("Unit")
	assert_str(CardText.speed_name(unit)).is_empty()
	var spell := CardDefinition.from_dict(CatalogSamples.spell())
	assert_str(CardText.speed_name(spell)).is_equal("Réaction")


func test_decision_0027_keyword_tag_replaces_its_written_name() -> void:
	var unit := CardDefinition.from_dict(CatalogSamples.unit())
	unit.keywords[CardDefinition.Keyword.ARRIVAL] = CardDefinition.NO_KEYWORD_VALUE
	unit.text = "Arrivée : une Unit ennemie ciblée a −1 Force."
	assert_str(CardText.body_bbcode(unit)).is_equal("une Unit ennemie ciblée a −1 Force.")
	unit.text = "Arrivée"
	assert_str(CardText.body_bbcode(unit)).is_empty()


func test_decision_0027_hero_text_is_shown_as_is_without_chip() -> void:
	var hero := HeroDefinition.from_dict(CatalogSamples.hero())
	hero.text = "Passif : effet [rare]."
	assert_str(CardText.hero_body_bbcode(hero)).is_equal("Passif : effet [lb]rare].")


func test_decision_0027_chips_list_the_spell_speed_then_each_keyword_in_capitals() -> void:
	var unit := CardDefinition.from_dict(CatalogSamples.unit())
	unit.keywords[CardDefinition.Keyword.ASSAULT] = 2
	unit.keywords[CardDefinition.Keyword.OUTPOST] = CardDefinition.NO_KEYWORD_VALUE
	var chips := CardText.chips(unit)
	assert_int(chips.size()).is_equal(2)
	assert_str(chips[0].label).is_equal("ASSAUT 2")
	assert_bool(chips[0].has_icon).is_true()
	assert_int(chips[0].icon).is_equal(DuelIcons.Icon.ASSAULT)
	assert_str(chips[1].label).is_equal("AVANT-POSTE")
	var spell := CardDefinition.from_dict(CatalogSamples.spell())
	var spell_chips := CardText.chips(spell)
	assert_str(spell_chips[0].label).is_equal("RÉACTION")
	assert_bool(spell_chips[0].has_icon).is_false()
	assert_int(CardText.chips(CardDefinition.from_dict(CatalogSamples.building())).size()).is_equal(
		0
	)


func test_decision_0045_clock_alerts_under_ten_seconds() -> void:
	assert_bool(TurnTimerBar.is_alert(9_000)).is_true()
	assert_bool(TurnTimerBar.is_alert(9_001)).is_false()
	assert_bool(TurnTimerBar.is_alert(0)).is_true()
	assert_bool(TurnTimerBar.is_alert(30_000)).is_false()


func test_decision_0045_clock_reading_key_changes_with_the_displayed_seconds() -> void:
	var turn := DuelState.ClockKind.TURN
	var first := ClockReading.new(turn, 12_300, true)
	assert_str(ClockReading.new(turn, 12_900, true).display_key()).is_equal(first.display_key())
	assert_str(ClockReading.new(turn, 11_900, true).display_key()).is_not_equal(first.display_key())
	assert_str(ClockReading.new(turn, 12_300, false).display_key()).is_not_equal(
		first.display_key()
	)
	var response := DuelState.ClockKind.RESPONSE
	assert_str(ClockReading.new(response, 12_300, true).display_key()).is_not_equal(
		first.display_key()
	)


func test_205_6_combat_put_on_hold_names_the_player() -> void:
	var text := EventText.describe(CombatPutOnHold.new(A))
	assert_str(text).is_equal("Un combat du joueur A est mis en attente.")


func test_decision_0053_header_speaks_to_the_viewer_on_their_turn() -> void:
	assert_str(DuelColumnView.turn_actor_text(A, A)).is_equal("À toi de jouer")
	assert_str(DuelColumnView.responder_text(B, B)).is_equal("À toi de répondre")


func test_decision_0053_header_names_the_other_player() -> void:
	assert_str(DuelColumnView.turn_actor_text(B, A)).is_equal("B joue")
	assert_str(DuelColumnView.responder_text(B, A)).is_equal("B peut répondre")
