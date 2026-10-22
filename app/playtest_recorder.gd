class_name PlaytestRecorder
extends RefCounted
## Relevé de playtest (décision 0042) : rejoue un journal dans un moteur neuf et en tire la fiche
## du protocole (`PlaytestSheet`), mesure par mesure, d'après les événements de chaque entrée et
## l'état lu avant et après elle. Ne lit ni l'hôte ni l'écran : la fiche d'une partie se produit
## depuis son journal, après coup, et deux fois la même (déterminisme, décision 0001).


## Ce que le relevé lit dans l'état, avant qu'une entrée le change ou après.
class Snapshot:
	extends RefCounted
	## Indexés par `DuelState.PlayerSide`.
	var sources_upright: Array[int] = [0, 0]
	var hand_counts: Array[int] = [0, 0]
	var sources_in_play: Array[int] = [0, 0]
	var sources_recycled: Array[int] = [0, 0]
	var piece_definition_ids: Dictionary[int, StringName] = {}
	var piece_owners: Dictionary[int, DuelState.PlayerSide] = {}

	static func of(state: DuelState) -> Snapshot:
		var snapshot := Snapshot.new()
		for side: DuelState.PlayerSide in DuelState.SIDES:
			var player := state.get_player(side)
			snapshot.sources_upright[side] = player.sources_upright
			snapshot.hand_counts[side] = player.hand.size()
			snapshot.sources_in_play[side] = player.sources_upright + player.sources_tilted
			snapshot.sources_recycled[side] = player.sources_recycled_this_turn
		for piece: Piece in state.pieces:
			snapshot.piece_owners[piece.piece_id] = piece.owner
			if not piece.is_token():
				snapshot.piece_definition_ids[piece.piece_id] = piece.card.definition_id
		return snapshot


var _catalog: Catalog
var _config: DuelConfig
var _engine: DuelEngine
var _sheet: PlaytestSheet
var _before: Snapshot
## Indexés par `DuelState.PlayerSide`.
var _turn_counts: Array[int] = [0, 0]
var _fought: Array[bool] = [false, false]
var _card_played: Array[bool] = [false, false]
var _mulligan_taken: Array[bool] = [false, false]
## Vrai entre `TurnStarted` et le relevé de fin de ce tour.
var _is_row_open: bool = false


func _init(catalog: Catalog, config: DuelConfig = DuelConfig.new()) -> void:
	_catalog = catalog
	_config = config


## Fiche de `journal`, rejoué entièrement ; `game_number` et `date_text` viennent de l'appelant,
## qui tient la série et l'horloge.
func record(journal: DuelJournal, game_number: int, date_text: String) -> PlaytestSheet:
	_reset(journal, game_number, date_text)
	_engine = DuelEngine.new(_catalog, _config)
	_before = Snapshot.new()
	_observe(_engine.start_new_duel(journal.setup))
	for entry: DuelJournal.Entry in journal.entries:
		_before = Snapshot.of(_engine.get_state())
		_observe(DuelJournal.replay_entry(_engine, entry))
	_record_end(journal)
	return _sheet


func _reset(journal: DuelJournal, game_number: int, date_text: String) -> void:
	_sheet = PlaytestSheet.new()
	_sheet.game_number = game_number
	_sheet.date_text = date_text
	_sheet.rng_seed = journal.setup.rng_seed
	_turn_counts = [0, 0]
	_fought = [false, false]
	_card_played = [false, false]
	_mulligan_taken = [false, false]
	_is_row_open = false


func _observe(events: Array[DuelEvent]) -> void:
	for index: int in events.size():
		var event := events[index]
		if event is TurnStarted:
			_close_row_at_turn_start(events, index)
			_start_row(event as TurnStarted)
		elif event is EssenceLost:
			_note_essence_lost(event as EssenceLost)
		elif event is TimeExpired:
			_note_expiry(events, index)
		_observe_play(event)
		_observe_end(event)


func _observe_play(event: DuelEvent) -> void:
	if event is DeployAnnounced or event is SpellAnnounced or event is GearAnnounced:
		_card_played[(event as PlayerEvent).player] = true
	elif event is HeroAttacked:
		_fought[DuelState.opponent_of((event as HeroAttacked).player)] = true
	elif event is PieceEnteredAttacking:
		_fought[(event as PieceEnteredAttacking).player] = true
	elif event is CombatResolved:
		_note_combat(event as CombatResolved)
	elif event is EffectTriggered:
		_note_trigger(event as EffectTriggered)


func _observe_end(event: DuelEvent) -> void:
	if event is FirstPlayerChosen:
		_sheet.end_fields.first_player = (event as FirstPlayerChosen).player
	elif event is CardSetAside:
		_mulligan_taken[(event as CardSetAside).player] = true
	elif event is FatigueIncreased:
		_note_fatigue()
	elif event is DuelEnded:
		var ended := event as DuelEnded
		_sheet.end_fields.result = ended.result
		_sheet.end_fields.reason = ended.reason
		_close_last_row_at_end()


# Décision 0160 du ruleset : l'Essence inutilisée est lue juste avant le redressement (204.3.2),
# dans l'état d'avant l'entrée qui commence le tour.
func _start_row(started: TurnStarted) -> void:
	var side := started.player
	_turn_counts[side] += 1
	var row := PlaytestSheet.TurnRow.new()
	row.turn_rank = _turn_counts[side]
	row.active_player = side
	row.cells[side].essence_unused = _before.sources_upright[side]
	row.cells[side].essence_lost = 0
	_sheet.turn_rows.append(row)
	_fought = [false, false]
	_is_row_open = true


# La fin du tour (204.5) dure jusqu'à 204.5.7a, déclencheurs et réponses compris : la ligne se
# clôt au `TurnStarted` suivant, dans l'état d'après l'entrée, moins ce que le début du tour
# suivant a déjà changé (204.3.8 : Sources reçues, cartes piochées, compteurs du tour remis à zéro).
func _close_row_at_turn_start(events: Array[DuelEvent], turn_start_index: int) -> void:
	var row := _current_row()
	if row == null or not _is_row_open:
		return
	var started := events[turn_start_index] as TurnStarted
	var snapshot := Snapshot.of(_engine.get_state())
	snapshot.sources_recycled = _before.sources_recycled.duplicate()
	for index: int in range(turn_start_index + 1, events.size()):
		var event := events[index]
		if event is CardDrawn and (event as CardDrawn).player == started.player:
			snapshot.hand_counts[started.player] -= 1
		elif event is SourceReceived and (event as SourceReceived).player == started.player:
			snapshot.sources_in_play[started.player] -= 1
	_close_row_with(snapshot, row.active_player)


# Un tour interrompu par la fin de la partie se relève dans l'état final.
func _close_last_row_at_end() -> void:
	var row := _current_row()
	if row != null and _is_row_open:
		_close_row_with(Snapshot.of(_engine.get_state()), row.active_player)


# « Carte jouée » repart de non jusqu'au tour suivant du joueur (décisions 0168 et 0173 du ruleset).
func _close_row_with(snapshot: Snapshot, active_player: DuelState.PlayerSide) -> void:
	var row := _current_row()
	if row == null:
		return
	for side: DuelState.PlayerSide in DuelState.SIDES:
		var cells := row.cells[side]
		cells.hand_count = snapshot.hand_counts[side]
		cells.sources_in_play = snapshot.sources_in_play[side]
		cells.sources_recycled = snapshot.sources_recycled[side]
		cells.fought = _mark_of(_fought[side])
	row.cells[active_player].card_played = _mark_of(_card_played[active_player])
	_card_played[active_player] = false
	_is_row_open = false


# Décision 0195 du ruleset : l'Essence perdue (204.5.7a) va sur la ligne du tour qui se termine.
func _note_essence_lost(lost: EssenceLost) -> void:
	var row := _current_row()
	if row != null and row.active_player == lost.player:
		row.cells[lost.player].essence_lost = lost.amount


func _note_combat(combat: CombatResolved) -> void:
	var attacker_id := combat.attacker_piece_id
	if _before.piece_owners.has(attacker_id):
		_fought[_before.piece_owners[attacker_id]] = true
		return
	var attacker := _engine.get_state().find_piece(attacker_id)
	if attacker != null:
		_fought[attacker.owner] = true


# 210.3.2, décision 0175 du ruleset : une note par déclenchement de Dernier souffle.
func _note_trigger(triggered: EffectTriggered) -> void:
	var row := _current_row()
	if row == null or not _is_last_breath(triggered):
		return
	var note := PlaytestSheet.LastBreathNote.new()
	note.turn_rank = row.turn_rank
	note.active_player = row.active_player
	_sheet.last_breath_notes.append(note)


# L'effet en attente dit son déclencheur (207.3.3) ; s'il a déjà quitté les files du moteur, le
# mot-clé de la carte de la pièce, lue dans l'état d'avant, tranche (210.3.2).
func _is_last_breath(triggered: EffectTriggered) -> bool:
	var entry := _find_trigger_entry(triggered.stack_entry_id)
	if entry != null:
		var definition := _catalog.get_card(entry.source_definition_id)
		return definition != null and _is_destroyed_trigger(definition, entry.effect_index)
	var definition_id: StringName = _before.piece_definition_ids.get(triggered.source_piece_id, &"")
	var card := _catalog.get_card(definition_id)
	return card != null and card.has_keyword(CardDefinition.Keyword.LAST_BREATH)


func _find_trigger_entry(stack_entry_id: int) -> StackEntry:
	var state := _engine.get_state()
	for entries: Array[StackEntry] in [state.waiting_triggers, state.triggers_to_add, state.stack]:
		for entry: StackEntry in entries:
			if entry.stack_entry_id == stack_entry_id:
				return entry
	return null


static func _is_destroyed_trigger(definition: CardDefinition, effect_index: int) -> bool:
	if effect_index < 0 or effect_index >= definition.effects.size():
		return false
	return definition.effects[effect_index].trigger == EffectDefinition.TriggerEvent.DESTROYED


# 209.4.9, 209.4.10, décision 0205 du ruleset : l'événement qui suit l'expiration dit si elle a
# terminé le tour ou fait passer le joueur ; un choix abandonné ou ordonné ne compte pas.
func _note_expiry(events: Array[DuelEvent], expiry_index: int) -> void:
	if expiry_index + 1 >= events.size():
		return
	var side := (events[expiry_index] as TimeExpired).player
	var consequence := events[expiry_index + 1]
	if consequence is TurnEnded:
		_sheet.end_fields.turn_expiry_count[side] += 1
	elif consequence is PriorityPassed:
		_sheet.end_fields.response_expiry_count[side] += 1


# 209.5.2 : rang du tour en cours au premier compteur de fatigue qui augmente.
func _note_fatigue() -> void:
	var row := _current_row()
	if row == null or _sheet.end_fields.first_fatigue_turn_rank != PlaytestSheet.NO_VALUE:
		return
	_sheet.end_fields.first_fatigue_turn_rank = row.turn_rank


func _record_end(journal: DuelJournal) -> void:
	var fields := _sheet.end_fields
	fields.duration_msec = journal.total_elapsed_msec()
	for side: DuelState.PlayerSide in DuelState.SIDES:
		if _mulligan_taken[side]:
			fields.mulligan_count += 1


func _current_row() -> PlaytestSheet.TurnRow:
	return null if _sheet.turn_rows.is_empty() else _sheet.turn_rows.back()


static func _mark_of(value: bool) -> PlaytestSheet.Mark:
	return PlaytestSheet.Mark.YES if value else PlaytestSheet.Mark.NO
