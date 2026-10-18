extends Control
## Bac à sable du duel, outil de développement avant l'écran de l'étape 2.3 : un seul écran où
## l'on joue les deux joueurs à tour de rôle, sans relais ni animation, les deux mains visibles.
## DuelHost fait foi, DuelSelection traduit les clics, les composants affichent ; à chaque
## changement, tout l'écran se redessine depuis l'état.

## Boutons de commande, rangés dans cet ordre.
enum Command { CONFIRM, CANCEL, PASS, END_TURN, HERO_POWER }

const CELL_SCENE: PackedScene = preload("res://ui/components/cell_view.tscn")
const PIECE_SCENE: PackedScene = preload("res://ui/components/piece_view.tscn")
const CARD_SCENE: PackedScene = preload("res://ui/components/card_view.tscn")
const SOURCES_SCENE: PackedScene = preload("res://ui/components/sources_view.tscn")
const CLOCK_SCENE: PackedScene = preload("res://ui/components/clock_view.tscn")
const STACK_SCENE: PackedScene = preload("res://ui/components/stack_view.tscn")
const LOG_SCENE: PackedScene = preload("res://ui/components/log_view.tscn")
const PREVIEW_SCENE: PackedScene = preload("res://ui/components/hover_preview.tscn")
const HAND_HEIGHT: int = 180
const SIDE_PANEL_WIDTH: int = 560
const TOKEN_NAME: String = "Jeton"
const STACK_KIND_NAMES: Dictionary[StackEntry.StackEntryKind, String] = {
	StackEntry.StackEntryKind.DEPLOY: "déploiement",
	StackEntry.StackEntryKind.NORMAL_ACTION: "action normale",
	StackEntry.StackEntryKind.SPELL: "Spell",
	StackEntry.StackEntryKind.HERO_POWER: "pouvoir du Hero",
	StackEntry.StackEntryKind.ATTACH_GEAR: "Gear",
	StackEntry.StackEntryKind.TRIGGERED_EFFECT: "effet déclenché",
}
const DECISION_HINTS: Dictionary[PendingDecision.DecisionKind, String] = {
	PendingDecision.DecisionKind.MULLIGAN:
	"Mulligan : cliquez les cartes à écarter, puis Confirmer.",
	PendingDecision.DecisionKind.ORDER_TRIGGERS:
	"Cliquez les effets de la pile dans l'ordre d'ajout.",
	PendingDecision.DecisionKind.CHOOSE_TARGETS: "Cliquez la cible de l'effet.",
}

const COMMAND_LABELS: Dictionary[Command, String] = {
	Command.CONFIRM: "Confirmer",
	Command.CANCEL: "Annuler",
	Command.PASS: "Passer",
	Command.END_TURN: "Fin du tour",
	Command.HERO_POWER: "Pouvoir du Hero",
}

var _catalog: Catalog
var _engine: DuelEngine
var _host: DuelHost
var _selection: DuelSelection = DuelSelection.new()
var _board: GridContainer = GridContainer.new()
var _hands: Dictionary[DuelState.PlayerSide, HFlowContainer] = {}
var _sources: Dictionary[DuelState.PlayerSide, SourcesView] = {}
var _clocks: Dictionary[DuelState.PlayerSide, ClockView] = {}
var _stack_view: StackView
var _log_view: LogView
var _preview: HoverPreview
var _status: Label = Label.new()
var _buttons: Dictionary[Command, Button] = {}
## Textes affichés par les pendules, pour ne les redessiner que quand ils changent.
var _shown_clock_texts: PackedStringArray = PackedStringArray()


func _ready() -> void:
	_catalog = TrySamples.catalog()
	_engine = DuelEngine.new(_catalog)
	_host = DuelHost.new(_engine)
	_build_layout()
	_selection.setup(_engine, DuelState.PlayerSide.A)
	_selection.intent_chosen.connect(_on_intent_chosen)
	_selection.selection_changed.connect(_refresh)
	_host.host_state_changed.connect(_on_host_state_changed)
	_log_view.append_events(_host.start(_make_setup()))


# La pendule avance au temps réel (décision 0021) ; l'écran se recale si elle produit un fait.
func _process(_delta: float) -> void:
	var events := _host.tick()
	if not events.is_empty():
		_log_view.append_events(events)
	_refresh_clocks()


func _on_intent_chosen(intent: DuelIntent) -> void:
	_log_view.append_events(_host.submit_human(intent))


# Sans animation ni relais : l'affichage est confirmé aussitôt, l'appareil passe de lui-même.
func _on_host_state_changed(host_state: DuelHost.HostState) -> void:
	match host_state:
		DuelHost.HostState.PLAYING_EVENTS:
			_host.confirm_events_played.call_deferred()
		DuelHost.HostState.RELAY:
			_host.confirm_relay.call_deferred()
		DuelHost.HostState.AWAITING_HUMAN:
			_selection.set_player(_host.get_screen_player())
		DuelHost.HostState.ENDED:
			_refresh()


# Chaque carte des decks de test, une copie à la fois, jusqu'à 30 cartes (201.6.1, 201.6.2).
func _make_setup() -> DuelSetup:
	var setup := DuelSetup.new()
	var card_ids := _catalog.card_ids()
	for index: int in DuelConfig.new().deck_size:
		setup.deck_a.append(card_ids[index % card_ids.size()])
	setup.deck_b.assign(setup.deck_a)
	setup.hero_a = TrySamples.HERO_ID
	setup.hero_b = TrySamples.HERO_ID
	setup.rng_seed = randi()
	return setup


func _build_layout() -> void:
	var columns := HBoxContainer.new()
	TrySamples.frame(self, columns)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(left)
	left.add_child(_make_hand(DuelState.PlayerSide.B))
	var board_center := CenterContainer.new()
	board_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board.columns = BoardGeometry.COLUMN_COUNT
	board_center.add_child(_board)
	left.add_child(board_center)
	left.add_child(_make_hand(DuelState.PlayerSide.A))
	columns.add_child(_make_side_panel())
	_preview = PREVIEW_SCENE.instantiate()
	add_child(_preview)
	_preview.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)


func _make_hand(side: DuelState.PlayerSide) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, HAND_HEIGHT)
	var hand := HFlowContainer.new()
	hand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(hand)
	_hands[side] = hand
	return scroll


func _make_side_panel() -> VBoxContainer:
	var panel := VBoxContainer.new()
	panel.custom_minimum_size = Vector2(SIDE_PANEL_WIDTH, 0)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_status)
	var clock_row := HBoxContainer.new()
	panel.add_child(clock_row)
	for side: DuelState.PlayerSide in DuelState.SIDES:
		_clocks[side] = CLOCK_SCENE.instantiate()
		clock_row.add_child(_clocks[side])
		_clocks[side].setup(side)
		_sources[side] = SOURCES_SCENE.instantiate()
		panel.add_child(_sources[side])
		_sources[side].setup(side)
		_sources[side].source_pressed.connect(_selection.press_source)
	panel.add_child(_make_buttons())
	_stack_view = STACK_SCENE.instantiate()
	panel.add_child(_stack_view)
	_stack_view.stack_entry_pressed.connect(_selection.press_stack_entry)
	_log_view = LOG_SCENE.instantiate()
	_log_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(_log_view)
	return panel


func _make_buttons() -> HFlowContainer:
	var row := HFlowContainer.new()
	var actions: Dictionary[Command, Callable] = {
		Command.CONFIRM: _selection.press_confirm,
		Command.CANCEL: _selection.press_cancel,
		Command.PASS: _selection.press_pass,
		Command.END_TURN: _selection.press_end_turn,
		Command.HERO_POWER: _selection.press_hero_power,
	}
	for command: Command in actions:
		var button := Button.new()
		button.text = COMMAND_LABELS[command]
		button.pressed.connect(actions[command])
		row.add_child(button)
		_buttons[command] = button
	return row


func _refresh() -> void:
	if _engine.get_state() == null:
		return
	var shown := _selection.snapshot()
	_refresh_board(shown)
	for side: DuelState.PlayerSide in DuelState.SIDES:
		_refresh_hand(side, shown)
		_refresh_sources(side, shown)
	_refresh_stack(shown)
	_refresh_buttons(shown)
	_refresh_status()


func _refresh_board(shown: SelectionSnapshot) -> void:
	ViewNodes.free_children(_board)
	for cell: Vector2i in TrySamples.cells_in_display_order():
		var cell_view: CellView = CELL_SCENE.instantiate()
		_board.add_child(cell_view)
		cell_view.show_cell(cell)
		cell_view.set_highlighted(shown.legal_cells.has(cell))
		cell_view.cell_pressed.connect(_selection.press_cell)
		var piece := _engine.get_state().piece_at(cell)
		if piece != null:
			_put_piece(cell_view, piece, shown)


# La pièce est posée sur sa case avant d'être remplie : ses nœuds n'existent qu'une fois en scène.
func _put_piece(cell_view: CellView, piece: Piece, shown: SelectionSnapshot) -> void:
	var piece_view: PieceView = PIECE_SCENE.instantiate()
	cell_view.put_piece(piece_view)
	if piece.kind == Piece.PieceKind.HERO:
		var hero := _catalog.get_hero(piece.card.definition_id)
		piece_view.show_hero(piece.piece_id, hero.hero_name, piece.owner, piece.health)
	else:
		var piece_name := TOKEN_NAME if piece.card == null else _card_name(piece.card)
		var force := _engine.current_force(piece.piece_id)
		piece_view.show_unit(piece.piece_id, piece_name, piece.owner, force)
	if piece.attached_gear != null:
		piece_view.show_gear(_card_name(piece.attached_gear))
	var is_highlighted := shown.legal_piece_ids.has(piece.piece_id)
	piece_view.set_marks(is_highlighted, shown.chosen_piece_id == piece.piece_id)
	piece_view.piece_pressed.connect(_selection.press_piece)


func _refresh_hand(side: DuelState.PlayerSide, shown: SelectionSnapshot) -> void:
	var hand := _hands[side]
	ViewNodes.free_children(hand)
	var is_screen_player := side == _host.get_screen_player()
	for card: CardInstance in _engine.get_state().get_player(side).hand:
		var card_view: CardView = CARD_SCENE.instantiate()
		hand.add_child(card_view)
		var card_id := card.card_instance_id
		var definition := _catalog.get_card(card.definition_id)
		card_view.show_card(card_id, definition, side)
		var is_chosen := shown.chosen_card_id == card_id or shown.set_aside_card_ids.has(card_id)
		var is_playable := shown.playable_card_ids.has(card_id)
		card_view.set_marks(is_screen_player and is_playable, is_screen_player and is_chosen)
		card_view.card_pressed.connect(_selection.press_card)
		card_view.card_hovered.connect(
			func(_id: int) -> void: _preview.show_definition(definition, side)
		)
		card_view.card_unhovered.connect(func(_id: int) -> void: _preview.hide_preview())


func _refresh_sources(side: DuelState.PlayerSide, shown: SelectionSnapshot) -> void:
	var player := _engine.get_state().get_player(side)
	var is_screen_player := side == _host.get_screen_player()
	if is_screen_player:
		_sources[side].show_sources(shown.shown_upright_sources, shown.shown_tilted_sources)
	else:
		_sources[side].show_sources(player.sources_upright, player.sources_tilted)
	_sources[side].show_supply(
		player.sources_in_reserve, player.sources_in_fonte, player.essence_reserve
	)
	_sources[side].set_interactive(is_screen_player)


func _refresh_stack(shown: SelectionSnapshot) -> void:
	var entry_ids: Array[int] = []
	var labels := PackedStringArray()
	for entry: StackEntry in _engine.get_state().stack:
		entry_ids.append(entry.stack_entry_id)
		labels.append(_stack_label(entry))
	_stack_view.show_entries(entry_ids, labels, shown.legal_stack_entry_ids)


func _stack_label(entry: StackEntry) -> String:
	var owner := EventText.player_label(entry.owner)
	var subject := "" if entry.card == null else " " + _card_name(entry.card)
	return "%s : %s%s" % [owner, STACK_KIND_NAMES[entry.kind], subject]


func _refresh_buttons(shown: SelectionSnapshot) -> void:
	_buttons[Command.CONFIRM].disabled = not shown.can_confirm
	_buttons[Command.PASS].disabled = not shown.can_pass
	_buttons[Command.END_TURN].disabled = not shown.can_end_turn
	_buttons[Command.HERO_POWER].disabled = not shown.can_use_hero_power


func _refresh_status() -> void:
	var state := _engine.get_state()
	if state.is_ended():
		_status.text = "Duel terminé : %s." % DuelState.DuelResult.find_key(state.result)
		return
	var player := EventText.player_label(_host.get_screen_player())
	var hint := "Jouez une carte, une pièce ou une Source, ou passez la main."
	if state.pending_decision != null:
		hint = DECISION_HINTS[state.pending_decision.kind]
	_status.text = "Tour %d. Au joueur %s. %s" % [state.turn_number, player, hint]


# ui/CLAUDE.md : la pendule est la seule valeur relue à chaque image, le temps avançant sans
# événement (décision 0021) ; elle n'est redessinée que si son affichage change.
func _refresh_clocks() -> void:
	if _engine.get_state() == null:
		return
	var running := _engine.clock_owners()
	var texts := PackedStringArray()
	for side: DuelState.PlayerSide in DuelState.SIDES:
		var remaining_msec := _engine.get_state().get_player(side).clock_remaining_msec
		texts.append("%s %s" % [ClockView.format_time(remaining_msec), running.has(side)])
	if texts == _shown_clock_texts:
		return
	_shown_clock_texts = texts
	for side: DuelState.PlayerSide in DuelState.SIDES:
		var remaining_msec := _engine.get_state().get_player(side).clock_remaining_msec
		_clocks[side].show_clock(remaining_msec, running.has(side))


func _card_name(card: CardInstance) -> String:
	return _catalog.get_card(card.definition_id).card_name
