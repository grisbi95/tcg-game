class_name HumanDuelDriver
extends RefCounted
## Deux humains jouent un `DuelHost` sans scène, avec une horloge manuelle (décisions 0020 et
## 0021) : chaque intention est suivie de la confirmation de l'affichage et du relais, comme le
## ferait la scène. Sert aux tests du relevé de playtest, dont le journal vient de l'hôte.

const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B

var engine: DuelEngine
var clock: ManualClock = ManualClock.new()
var host: DuelHost
## Intentions refusées par le moteur depuis le début ; un scénario correct en compte zéro.
var rejected_intent_count: int = 0


func _init(catalog: Catalog, config: DuelConfig = DuelConfig.new()) -> void:
	engine = DuelEngine.new(catalog, config)
	host = DuelHost.new(engine, clock)


## Démarre `setup` avec A pour premier joueur (décision 0012), puis les mulligans de A et de B
## (décisions 0013 et 0015) : les joueurs de `redrawing_sides` écartent leur première carte, les
## autres aucune. A est alors au début de son premier tour.
func start(setup: DuelSetup, redrawing_sides: Array[DuelState.PlayerSide] = []) -> void:
	setup.impose_first_player(A)
	host.start(setup)
	host.confirm_events_played()
	host.confirm_relay()
	for side: DuelState.PlayerSide in DuelState.SIDES:
		var set_aside: Array[int] = []
		if redrawing_sides.has(side):
			set_aside.append(engine.get_state().get_player(side).hand[0].card_instance_id)
		play(ChooseMulligan.new(side, set_aside))


## Intention de l'humain devant l'écran, affichage et relais confirmés.
func play(intent: DuelIntent) -> Array[DuelEvent]:
	var events := host.submit_human(intent)
	if events.is_empty() or EventLog.rejection_reason(events) != EventLog.NOT_A_SINGLE_REJECTION:
		rejected_intent_count += 1
	host.confirm_events_played()
	host.confirm_relay()
	return events


## Du temps réel passe, décompté par l'hôte.
func wait(elapsed_msec: int) -> void:
	clock.advance(elapsed_msec)
	host.tick()
	host.confirm_events_played()


func end_turn(side: DuelState.PlayerSide) -> void:
	play(EndTurn.new(side))


## 208.7.3 : `side` déploie la première carte de sa main payée en inclinant des Sources ; le
## déploiement est sans réponse et se résout aussitôt.
func deploy(side: DuelState.PlayerSide, cell: Vector2i) -> void:
	var card: CardInstance = engine.get_state().get_player(side).hand[0]
	var cost := engine.get_state().catalog.get_card(card.definition_id).cost
	var payment := EssencePayment.new(cost, 0)
	play(DeployCard.new(side, card.card_instance_id, cell, payment))


## L'action normale de la pièce de `side` en `from` vers `to` : vers une case libre, elle se
## résout aussitôt (208.7.4) ; vers une pièce ennemie, c'est une attaque (208.7.2) que
## l'adversaire laisse résoudre en passant.
func move(side: DuelState.PlayerSide, from: Vector2i, to: Vector2i) -> void:
	var piece := engine.get_state().piece_at(from)
	play(TakeNormalAction.new(side, piece.piece_id, to))
	if not engine.get_state().stack.is_empty():
		pass_priority(engine.get_state().priority_player)


func pass_priority(side: DuelState.PlayerSide) -> void:
	play(PassPriority.new(side))


## Fiche de relevé du journal de l'hôte, rejoué avec le catalogue et la configuration du duel ;
## `deck_names` par joueur (décision 0069).
func record_sheet(
	game_number: int, date_text: String, deck_names: Dictionary[DuelState.PlayerSide, String]
) -> PlaytestSheet:
	var state := engine.get_state()
	var recorder := PlaytestRecorder.new(state.catalog, state.config)
	return recorder.record(host.get_journal(), game_number, date_text, deck_names)
