class_name TimeScenarios
extends RefCounted
## Montages des suites du temps de tour et du temps de réponse (209.4, 209.2.10) : catalogue
## d'essai, état construit à la main, attentes de choix.

const CARD: StringName = &"clock_card"
const CARD_FORCE: int = 3
## Réaction sans effet.
const SPELL: StringName = &"clock_spell"
const DECK_CARDS: int = 4

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B


static func catalog() -> Catalog:
	var result := TriggerSamples.catalog()
	SetupSamples.add_unit(result, CARD, CARD_FORCE)
	var spell := CatalogSamples.with_field(CatalogSamples.spell(), "id", String(SPELL))
	result.add_card(CardDefinition.from_dict(CatalogSamples.with_effects(spell, [])))
	return result


## Un état en phase principale, un deck de `DECK_CARDS` cartes par joueur.
static func builder(with_catalog: Catalog) -> DuelStateBuilder:
	var result := DuelStateBuilder.new(DuelConfig.new(), with_catalog)
	for side: DuelState.PlayerSide in [A, B]:
		for index: int in DECK_CARDS:
			result.add_to_deck(side, CARD)
	return result


## Un duel démarré par la préparation, mulligans en attente (204.2.2).
static func start_sample_duel() -> DuelEngine:
	var engine := DuelEngine.new(SetupSamples.catalog())
	engine.start_new_duel(SetupSamples.setup())
	return engine


## Moteur démarré sur un état neuf dont A a `turn_time_msec` de temps de tour.
static func engine_with_turn_time(with_catalog: Catalog, turn_time_msec: int) -> DuelEngine:
	var engine := DuelEngine.new(with_catalog)
	var state_builder := builder(with_catalog).with_turn_time_remaining(A, turn_time_msec)
	engine.start_from_state(state_builder.build())
	return engine


## Démarre `engine` sur une attente `kind` des joueurs `sides`, au sujet de `subject_id`.
static func await_decision(
	state_builder: DuelStateBuilder,
	engine: DuelEngine,
	kind: PendingDecision.DecisionKind,
	sides: Array[DuelState.PlayerSide],
	subject_id: int
) -> void:
	var decision := PendingDecision.new()
	decision.kind = kind
	decision.awaited_players.assign(sides)
	decision.subject_stack_entry_id = subject_id
	engine.start_from_state(state_builder.with_pending_decision(decision).build())


static func push_spell(state_builder: DuelStateBuilder, side: DuelState.PlayerSide) -> int:
	return state_builder.push_spell(state_builder.make_card_instance(side, SPELL))


## Le Héraut de A arrive face à deux Units ennemies : A choisit ses cibles, la pile est vide.
static func ask_herald_targets(state_builder: DuelStateBuilder, engine: DuelEngine) -> void:
	for cell_name: String in ["B4", "D4"]:
		state_builder.place_piece(
			B, Piece.PieceKind.UNIT, DuelStateBuilder.cell(cell_name), TriggerSamples.SOLDIER
		)
	var card := state_builder.make_card_instance(A, TriggerSamples.HERALD)
	state_builder.push_deploy(card, DuelStateBuilder.cell("B1"))
	engine.start_from_state(state_builder.with_priority_player(B).build())
	engine.submit(PassPriority.new(B))


## Deux Beacons de A : à la fin du tour, A ordonne leurs effets. Renvoie l'identifiant du
## premier effet déclenché.
static func end_turn_with_two_beacons(state_builder: DuelStateBuilder, engine: DuelEngine) -> int:
	state_builder.place_piece(
		A, Piece.PieceKind.UNIT, DuelStateBuilder.cell("D1"), TriggerSamples.SOLDIER
	)
	for cell_name: String in ["B2", "E2"]:
		state_builder.place_piece(
			A, Piece.PieceKind.BUILDING, DuelStateBuilder.cell(cell_name), TriggerSamples.BEACON
		)
	engine.start_from_state(state_builder.build())
	for event: DuelEvent in engine.submit(EndTurn.new(A)):
		if event is EffectTriggered:
			return (event as EffectTriggered).stack_entry_id
	return DuelState.NO_ID


## Règle le temps de tour de `side` sur un état déjà démarré.
static func set_turn_time(
	engine: DuelEngine, side: DuelState.PlayerSide, remaining_msec: int
) -> void:
	engine.get_state().get_player(side).turn_time_remaining_msec = remaining_msec


static func turn_time(engine: DuelEngine, side: DuelState.PlayerSide) -> int:
	return engine.get_state().get_player(side).turn_time_remaining_msec


static func response_time(engine: DuelEngine, side: DuelState.PlayerSide) -> int:
	return engine.get_state().get_player(side).response_time_remaining_msec
