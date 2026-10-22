class_name DuelScenarios
extends RefCounted
## Outil de développement : prépare les situations de l'écran de duel qu'on ne rencontre pas au
## début d'une partie (choix du moteur, fin de partie, aperçus, pouvoir du Hero, fatigue, paiement
## préparé). Un scénario fixe un catalogue, une configuration de développement (decks courts de
## cartes identiques ou presque, fenêtre de réponse longue), un premier joueur et un plan de
## gestes que `ScenarioRecorder` joue à blanc ; les intentions acceptées sont rejouées par l'écran.
## Aucune règle ici : le plan tente des gestes, le moteur dit ce qui passe. La graine est cherchée
## jusqu'à ce que le plan réussisse avec les mains tirées.

## Ajouter à la fin, sans réordonner.
enum Scenario {
	CHOICE_TARGET,
	CHOICE_ORDER,
	ENDED,
	PREVIEW_GEAR,
	PREVIEW_PILES,
	HERO_POWER,
	FATIGUE,
	PAYMENT_PREPARED,
}

const A := DuelState.PlayerSide.A
const B := DuelState.PlayerSide.B
## Le Hero des deux joueurs dans tous les scénarios.
const HERO_ID: StringName = &"capitaine"
const DEV_DECK_SIZE: int = 12
## Deck court et main de départ réduite : les pioches vident le deck sans remplir la main (201.3.5),
## puis la fatigue commence (209.5).
const FATIGUE_DECK_SIZE: int = 6
const FATIGUE_OPENING_HAND_SIZE: int = 2
const SEED_LIMIT: int = 60
const MAX_TURNS_TO_FATIGUE: int = 8
## CARTE D'ESSAI, pour l'outil de développement seulement : un Building dont la fin du tour
## déclenche un effet, pour obtenir deux effets déclenchés d'un même joueur (208.4.6), ce que les
## cartes de `data/cards/` ne font pas. Elle n'existe que dans ce catalogue d'essai : absente de
## `data/cards/` et des decks de test du ruleset, elle ne doit jamais y entrer.
const BEACON_ID: StringName = &"essai_balise"
const BEACON_JSON: String = """{
	"edition": "0.39",
	"cards": [{
		"id": "essai_balise", "name": "Balise (essai)", "cost": 1, "type": "building", "force": 4,
		"text": "Fin du tour : une pièce alliée ciblée a +1 Force jusqu'à la fin du tour.",
		"effects": [{
			"kind": "modify_force", "timing": "triggered", "amount": 1,
			"trigger": "end_of_turn", "duration": "until_end_of_turn",
			"target": {"what": "piece", "side": "ally", "piece_kinds": ["unit", "building"]}
		}]
	}]
}"""
const SCENARIO_NAMES: Dictionary[Scenario, String] = {
	Scenario.CHOICE_TARGET: "choix de la cible d'un effet déclenché",
	Scenario.CHOICE_ORDER: "ordre de deux effets déclenchés",
	Scenario.ENDED: "fin de partie par abandon",
	Scenario.PREVIEW_GEAR: "aperçu d'une Unit avec son Gear",
	Scenario.PREVIEW_PILES: "aperçu depuis la défausse et la pile",
	Scenario.HERO_POWER: "pouvoir du Hero",
	Scenario.FATIGUE: "fatigue",
	Scenario.PAYMENT_PREPARED: "paiement préparé au tour adverse",
}


## Ce qu'il faut pour lancer un scénario sur l'écran.
class ScenarioData:
	extends RefCounted
	var catalog: Catalog
	var config: DuelConfig
	var setup: DuelSetup
	var intents: Array[DuelIntent] = []
	var is_reached: bool = false


## Un scénario : ses decks (identifiant de carte → exemplaires), son premier joueur et son plan.
class ScenarioSpec:
	extends RefCounted
	var copies_a: Dictionary[StringName, int] = {}
	var copies_b: Dictionary[StringName, int] = {}
	var first_player: DuelState.PlayerSide = DuelState.PlayerSide.A
	var deck_size: int = DEV_DECK_SIZE
	var opening_hand_size: int = DuelConfig.new().opening_hand_size
	var plan: Callable = Callable()


static func name_of(scenario: Scenario) -> String:
	return SCENARIO_NAMES[scenario]


## Catalogue de `data/cards/` et carte de développement.
static func load_catalog() -> Catalog:
	var loader := CatalogLoader.new()
	loader.load_directory(GameLibrary.CARDS_DIRECTORY)
	loader.load_text(BEACON_JSON, "DuelScenarios")
	for error: String in loader.find_errors():
		push_error("DuelScenarios : " + error)
	return loader.get_catalog()


## Cherche une graine pour laquelle le plan de `scenario` réussit, et rend de quoi lancer l'écran.
static func build(scenario: Scenario) -> ScenarioData:
	var spec := _spec_of(scenario)
	var data := ScenarioData.new()
	data.catalog = load_catalog()
	data.config = _make_config(spec)
	for rng_seed: int in range(1, SEED_LIMIT):
		data.setup = _make_setup(spec, rng_seed)
		var recorder := _record(spec, data)
		if recorder != null:
			data.intents = recorder.get_intents()
			data.is_reached = true
			return data
	push_error("DuelScenarios : « %s » n'est atteint avec aucune graine" % name_of(scenario))
	return data


# Le plan joué à blanc sur un moteur neuf ; null s'il échoue.
static func _record(spec: ScenarioSpec, data: ScenarioData) -> ScenarioRecorder:
	var engine := DuelEngine.new(data.catalog, data.config)
	engine.start_new_duel(data.setup)
	if engine.get_state() == null:
		return null
	var recorder := ScenarioRecorder.new(engine)
	if recorder.confirm_mulligans() and spec.plan.call(recorder):
		return recorder
	return null


static func _make_config(spec: ScenarioSpec) -> DuelConfig:
	var config := DuelConfig.new()
	config.deck_size = spec.deck_size
	config.max_copies_per_card = spec.deck_size
	config.opening_hand_size = spec.opening_hand_size
	return config


static func _make_setup(spec: ScenarioSpec, rng_seed: int) -> DuelSetup:
	var duel_setup := DuelSetup.new()
	duel_setup.deck_a = _deck_of(spec.copies_a, spec.deck_size)
	duel_setup.deck_b = _deck_of(spec.copies_b, spec.deck_size)
	duel_setup.hero_a = HERO_ID
	duel_setup.hero_b = HERO_ID
	duel_setup.rng_seed = rng_seed
	duel_setup.impose_first_player(spec.first_player)
	return duel_setup


static func _deck_of(copies: Dictionary[StringName, int], deck_size: int) -> Array[StringName]:
	var deck: Array[StringName] = []
	for card_id: StringName in copies:
		for _index: int in copies[card_id]:
			deck.append(card_id)
	assert(deck.size() == deck_size, "DuelScenarios : un deck compte %d cartes" % deck_size)
	return deck


static func _spec_of(scenario: Scenario) -> ScenarioSpec:
	var spec := ScenarioSpec.new()
	match scenario:
		Scenario.CHOICE_TARGET:
			_fill(spec, {&"heraut": DEV_DECK_SIZE}, {&"soldat": DEV_DECK_SIZE}, B)
			spec.plan = _plan_choice_target
		Scenario.CHOICE_ORDER:
			_fill(spec, {BEACON_ID: DEV_DECK_SIZE}, {&"soldat": DEV_DECK_SIZE}, A)
			spec.plan = _plan_choice_order
		Scenario.ENDED:
			_fill(spec, {&"recrue": DEV_DECK_SIZE}, {&"soldat": DEV_DECK_SIZE}, A)
			spec.plan = _plan_ended
		Scenario.PREVIEW_GEAR:
			var half := floori(DEV_DECK_SIZE / 2.0)
			_fill(spec, {&"recrue": half, &"lame": half}, {&"soldat": DEV_DECK_SIZE}, A)
			spec.plan = _plan_preview_gear
		Scenario.PREVIEW_PILES:
			_fill(spec, {&"frappe": DEV_DECK_SIZE}, {&"soldat": DEV_DECK_SIZE}, B)
			spec.plan = _plan_preview_piles
		Scenario.HERO_POWER:
			_fill(spec, {&"recrue": DEV_DECK_SIZE}, {&"soldat": DEV_DECK_SIZE}, A)
			spec.plan = _plan_hero_power
		Scenario.FATIGUE:
			spec.deck_size = FATIGUE_DECK_SIZE
			spec.opening_hand_size = FATIGUE_OPENING_HAND_SIZE
			_fill(spec, {&"recrue": FATIGUE_DECK_SIZE}, {&"soldat": FATIGUE_DECK_SIZE}, A)
			spec.plan = _plan_fatigue
		Scenario.PAYMENT_PREPARED:
			_fill(spec, {&"recrue": DEV_DECK_SIZE}, {&"contre": DEV_DECK_SIZE}, A)
			spec.plan = _plan_payment_prepared
	return spec


static func _fill(
	spec: ScenarioSpec,
	copies_a: Dictionary[StringName, int],
	copies_b: Dictionary[StringName, int],
	first_player: DuelState.PlayerSide
) -> void:
	spec.copies_a = copies_a
	spec.copies_b = copies_b
	spec.first_player = first_player


# Plans : chacun s'arrête sur la situation à voir. `and` coupe à la première étape manquée.
# B déploie deux Soldats avant que A déploie le Héraut : la cible n'est plus unique (0004).
static func _plan_choice_target(recorder: ScenarioRecorder) -> bool:
	return (
		recorder.deploy(B, &"soldat")
		and recorder.resolve_stack()
		and recorder.end_turn(B)
		and recorder.end_turn(A)
		and recorder.deploy(B, &"soldat")
		and recorder.resolve_stack()
		and recorder.end_turn(B)
		and recorder.deploy(A, &"heraut")
		and recorder.resolve_stack()
		and recorder.state().pending_decision != null
	)


# Deux Balises de A, puis la fin de son tour : leurs deux effets attendent leur ordre (208.4.6).
static func _plan_choice_order(recorder: ScenarioRecorder) -> bool:
	return (
		recorder.deploy(A, BEACON_ID)
		and recorder.resolve_stack()
		and recorder.deploy(A, BEACON_ID)
		and recorder.resolve_stack()
		and recorder.end_turn(A)
		and recorder.state().pending_decision != null
	)


static func _plan_ended(recorder: ScenarioRecorder) -> bool:
	return (
		recorder.deploy(A, &"recrue")
		and recorder.resolve_stack()
		and recorder.concede(A)
		and recorder.state().is_ended()
	)


static func _plan_preview_gear(recorder: ScenarioRecorder) -> bool:
	return (
		recorder.deploy(A, &"recrue")
		and recorder.resolve_stack()
		and recorder.announce(A, &"lame")
		and recorder.resolve_stack()
	)


# Une défausse garnie de chaque côté, puis un second Frappe laissé sur la pile.
static func _plan_preview_piles(recorder: ScenarioRecorder) -> bool:
	return (
		recorder.deploy(B, &"soldat")
		and recorder.resolve_stack()
		and recorder.end_turn(B)
		and recorder.announce(A, &"frappe")
		and recorder.resolve_stack()
		and recorder.end_turn(A)
		and recorder.deploy(B, &"soldat")
		and recorder.resolve_stack()
		and recorder.end_turn(B)
		and recorder.announce(A, &"frappe")
	)


# Au second tour de A : une Unit alliée et de quoi payer le pouvoir, qui est utilisable.
static func _plan_hero_power(recorder: ScenarioRecorder) -> bool:
	var hero := recorder.state().catalog.get_hero(HERO_ID)
	return (
		recorder.deploy(A, &"recrue")
		and recorder.resolve_stack()
		and recorder.end_turn(A)
		and recorder.end_turn(B)
		and recorder.produce_essence(A, hero.power_cost)
	)


static func _plan_fatigue(recorder: ScenarioRecorder) -> bool:
	for _turn: int in MAX_TURNS_TO_FATIGUE:
		if _has_fatigue(recorder.state()):
			return true
		if not recorder.end_turn(recorder.state().active_player):
			return false
	return _has_fatigue(recorder.state())


# A déploie, B peut répondre : sa fenêtre est ouverte quand l'écran lui passe l'appareil.
static func _plan_payment_prepared(recorder: ScenarioRecorder) -> bool:
	return recorder.deploy(A, &"recrue")


static func _has_fatigue(state: DuelState) -> bool:
	return DuelState.SIDES.any(
		func(side: DuelState.PlayerSide) -> bool: return state.get_player(side).fatigue_counter > 0
	)
