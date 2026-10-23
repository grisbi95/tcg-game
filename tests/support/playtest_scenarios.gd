class_name PlaytestScenarios
extends RefCounted
## Duels de deux humains, joués par `HumanDuelDriver` sur le catalogue d'essai, dont les tests du
## relevé de playtest lisent la fiche. Chaque scénario laisse le duel en cours.

const UNIT_COST: int = 2  # CatalogSamples.unit()
const REACTION_COST: int = 1  # CatalogSamples.spell()
const BEACON_COST: int = 3  # CatalogSamples.building()
const DEPLOY_BOTH_SOURCES: int = UNIT_COST + BEACON_COST  # 204.1.2 levée : deux déploiements
const CATEGORY_COPIES: int = 10  # trois catégories : 30 cartes (201.6.1)
const LARGE_COPIES: int = 30  # 201.6.2 levée : un deck d'un seul exemplaire répété
const REACTION_ID: StringName = &"scenario_reaction"
const MARTYR_SEED: int = 1
const LARGE_HAND_SIZE: int = 20  # 201.3.4 levée : les pioches ne sont plus bloquées
const TURN_TIME_MSEC: int = 90_000  # 209.4.3
const RESPONSE_TIME_MSEC: int = 30_000  # 209.4.6

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const A1 := Vector2i(0, 0)
const A2 := Vector2i(0, 1)
const A3 := Vector2i(0, 2)
const A4 := Vector2i(0, 3)
const A5 := Vector2i(0, 4)


## Mulligans passés, A au début de son premier tour.
static func fresh() -> HumanDuelDriver:
	var driver := HumanDuelDriver.new(SetupSamples.catalog())
	driver.start(SetupSamples.setup())
	return driver


## Chaque joueur termine son tour `round_count` fois, sans rien faire ; le tour suivant de A
## a commencé à la fin.
static func idle_rounds(round_count: int) -> HumanDuelDriver:
	var driver := fresh()
	for round_index: int in round_count:
		driver.end_turn(A)
		driver.end_turn(B)
	return driver


## A laisse expirer son premier tour (209.4.9) ; B, dont le deck n'est que la Réaction d'essai,
## l'annonce (208.7.1) et A, qui peut répondre, laisse expirer son temps de réponse (209.4.10) :
## il passe et le Spell se résout.
static func expiring() -> HumanDuelDriver:
	var config := _large_copies_config()
	var setup := SetupSamples.setup()
	setup.deck_b = _repeated(REACTION_ID, config.deck_size)
	var driver := HumanDuelDriver.new(
		ResponseWindowSamples.catalog_with_reaction(REACTION_ID), config
	)
	driver.start(setup)
	driver.wait(TURN_TIME_MSEC)
	driver.host.confirm_relay()
	_cast_reaction(driver, B, EssencePayment.new(REACTION_COST))
	driver.wait(RESPONSE_TIME_MSEC)
	return driver


## A déploie (sans réponse), puis chacun termine son tour et A termine son deuxième tour.
static func deploying() -> HumanDuelDriver:
	var driver := fresh()
	driver.deploy(A, A1)
	driver.end_turn(A)
	driver.end_turn(B)
	driver.end_turn(A)
	return driver


## Comme `deploying()`, avec en plus un recyclage, pendant le premier tour de A, d'une Source
## que le paiement du déploiement a inclinée (203.2.6).
static func economy() -> HumanDuelDriver:
	var driver := fresh()
	driver.deploy(A, A1)
	driver.play(ProduceEssence.new(A, EssencePayment.new(0, 1)))
	driver.end_turn(A)
	driver.end_turn(B)
	driver.end_turn(A)
	return driver


## A annonce la Réaction d'essai, dont les deux decks se composent (208.7.1) ; B y répond
## (208.2.4) ; les tours s'enchaînent ensuite jusqu'à la fin du deuxième tour de B.
static func answering() -> HumanDuelDriver:
	var config := _large_copies_config()
	var setup := SetupSamples.setup()
	setup.deck_a = _repeated(REACTION_ID, config.deck_size)
	setup.deck_b = _repeated(REACTION_ID, config.deck_size)
	var driver := HumanDuelDriver.new(
		ResponseWindowSamples.catalog_with_reaction(REACTION_ID), config
	)
	driver.start(setup)
	_cast_reaction(driver, A, EssencePayment.new(REACTION_COST))
	_cast_reaction(driver, B, EssencePayment.new(REACTION_COST))
	driver.pass_priority(A)
	for round_index: int in 2:
		driver.end_turn(A)
		driver.end_turn(B)
	return driver


## Le tour 2 de A comporte un échange de réponses. Au tour 1, A déploie une Unit, cible du Beacon
## (207.5.1a), puis le Beacon : à chaque fin de tour, de A ou de B, l'effet du Beacon se résout
## aussitôt (204.5.3, 208.7.16). Le scénario s'arrête au tour 2 de A, avant toute action de ce
## tour.
static func before_own_end_of_turn() -> HumanDuelDriver:
	var config := _large_copies_config()
	config.max_hand_size = LARGE_HAND_SIZE
	config.starting_sources = DEPLOY_BOTH_SOURCES
	config.setup_sources_in_play = DEPLOY_BOTH_SOURCES
	config.setup_sources_in_reserve = config.total_sources_per_player - DEPLOY_BOTH_SOURCES
	var setup := SetupSamples.setup()
	setup.deck_a = _own_end_of_turn_deck()
	setup.deck_b = _repeated(REACTION_ID, config.deck_size)
	var driver := HumanDuelDriver.new(_catalog_with_beacon_and_reaction(), config)
	driver.start(setup)
	_deploy_from_hand(driver, SetupSamples.deck()[0], A1, UNIT_COST)
	_deploy_from_hand(driver, TriggerSamples.BEACON, A2, BEACON_COST)
	driver.end_turn(A)
	driver.end_turn(B)
	return driver


## Suite de `before_own_end_of_turn()` : A produit l'Essence en recyclant une Source (203.2.2) et
## l'utilise pour annoncer sa Réaction ; B y répond (208.2.4) ; A passe et la pile se résout. A
## termine ensuite son tour 2, B son tour 2 et A son tour 3.
static func answer_then_end_own_turn(driver: HumanDuelDriver) -> HumanDuelDriver:
	driver.play(ProduceEssence.new(A, EssencePayment.new(REACTION_COST, REACTION_COST)))
	_cast_reaction(driver, A, EssencePayment.new())
	_cast_reaction(driver, B, EssencePayment.new(REACTION_COST))
	driver.pass_priority(A)
	driver.end_turn(A)
	driver.end_turn(B)
	driver.end_turn(A)
	return driver


static func answering_in_own_turn() -> HumanDuelDriver:
	return answer_then_end_own_turn(before_own_end_of_turn())


## A avance sa Unit d'une rangée par tour jusqu'à la case A5 de la Unit de B, qu'elle attaque à
## son cinquième tour (205.2.6, 206.1.1) ; le scénario s'arrête avant la fin de ce tour.
static func walk_to_attack(driver: HumanDuelDriver) -> HumanDuelDriver:
	driver.deploy(A, A1)
	driver.end_turn(A)
	driver.deploy(B, A5)
	driver.end_turn(B)
	var from := A1
	for to: Vector2i in [A2, A3, A4]:
		driver.move(A, from, to)
		driver.end_turn(A)
		driver.end_turn(B)
		from = to
	driver.move(A, A4, A5)
	return driver


## Les deux decks ne contiennent que le Martyr de `TriggerSamples` (Dernier souffle).
static func martyr_duel() -> HumanDuelDriver:
	var config := _large_copies_config()
	var catalog := SetupSamples.catalog()
	for data: Dictionary in TriggerSamples.card_data():
		if data["id"] == String(TriggerSamples.MARTYR):
			catalog.add_card(CardDefinition.from_dict(data))
	var deck_ids := _repeated(TriggerSamples.MARTYR, config.deck_size)
	var setup := SetupSamples.mirror_setup(deck_ids, SetupSamples.HERO_ID, MARTYR_SEED)
	var driver := HumanDuelDriver.new(catalog, config)
	driver.start(setup)
	return driver


## Deck réduit à `deck_size` cartes et main non bornée, pour que la fatigue arrive vite (201.3.4,
## 201.6.1, 209.5.2).
static func small_deck_duel(deck_size: int) -> HumanDuelDriver:
	var config := DuelConfig.new()
	config.deck_size = deck_size
	config.max_hand_size = LARGE_HAND_SIZE
	var deck_ids: Array[StringName] = SetupSamples.deck().slice(0, deck_size)
	var setup := SetupSamples.mirror_setup(
		deck_ids, SetupSamples.HERO_ID, SetupSamples.DEFAULT_SEED
	)
	var driver := HumanDuelDriver.new(SetupSamples.catalog(), config)
	driver.start(setup)
	return driver


## Préparation de deux mulligans sans carte écartée, A commençant ; à compléter d'entrées.
static func journal_after_mulligans() -> DuelJournal:
	var setup := SetupSamples.setup()
	setup.impose_first_player(A)
	var journal := DuelJournal.new(setup)
	journal.record_intent(ChooseMulligan.new(A))
	journal.record_intent(ChooseMulligan.new(B))
	return journal


static func _large_copies_config() -> DuelConfig:
	var config := DuelConfig.new()
	config.max_copies_per_card = LARGE_COPIES
	return config


static func _repeated(card_id: StringName, count: int) -> Array[StringName]:
	var card_ids: Array[StringName] = []
	card_ids.resize(count)
	card_ids.fill(card_id)
	return card_ids


# Dix exemplaires de chaque catégorie (201.6.1, 201.6.2 levée) : une Unit, un Beacon, une Réaction.
static func _own_end_of_turn_deck() -> Array[StringName]:
	var deck_ids := _repeated(SetupSamples.deck()[0], CATEGORY_COPIES)
	deck_ids.append_array(_repeated(TriggerSamples.BEACON, CATEGORY_COPIES))
	deck_ids.append_array(_repeated(REACTION_ID, CATEGORY_COPIES))
	return deck_ids


static func _catalog_with_beacon_and_reaction() -> Catalog:
	var catalog := ResponseWindowSamples.catalog_with_reaction(REACTION_ID)
	for data: Dictionary in TriggerSamples.card_data():
		if data["id"] == String(TriggerSamples.BEACON):
			catalog.add_card(CardDefinition.from_dict(data))
	return catalog


# 208.7.3 : A déploie la carte `definition_id` de sa main ; le déploiement se résout aussitôt.
static func _deploy_from_hand(
	driver: HumanDuelDriver, definition_id: StringName, cell: Vector2i, cost: int
) -> void:
	var card := _hand_card(driver, A, definition_id)
	driver.play(DeployCard.new(A, card.card_instance_id, cell, EssencePayment.new(cost, 0)))


static func _cast_reaction(
	driver: HumanDuelDriver, side: DuelState.PlayerSide, payment: EssencePayment
) -> void:
	var card := _hand_card(driver, side, REACTION_ID)
	driver.play(CastSpell.new(side, card.card_instance_id, payment))


static func _hand_card(
	driver: HumanDuelDriver, side: DuelState.PlayerSide, definition_id: StringName
) -> CardInstance:
	for card: CardInstance in driver.engine.get_state().get_player(side).hand:
		if card.definition_id == definition_id:
			return card
	return null
