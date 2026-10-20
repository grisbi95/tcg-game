class_name DuelScreen
extends Control
## Écran de duel de l'étape 2.3 (décisions 0020, 0028 à 0032) : assemble les composants de
## `ui/components/` aux cotes de 0030 (repère 1920×1080, marges de 16 px, joueur A toujours en
## bas), les câble à `DuelSelection` et à `DuelHost`, et les recale sur `get_state()` après chaque
## lot d'événements joué par `EventPlayer`. Aucune règle ici : un geste de vue devient une
## intention par `DuelSelection` seul, et `DuelViewModel` filtre ce que le joueur qui a l'appareil
## voit (201.4).
##
## Flux : geste → `DuelSelection` → `intent_chosen` → `DuelHost.submit_human` → événements →
## `EventPlayer` → `batch_played` → `confirm_events_played` → recalage. Pendant la lecture et hors
## du tour d'un humain, `InputShield` bloque les commandes. `OverlayLayer` reste vide : l'étape 2.4
## y mettra les écrans de relais et de fin. Pour l'instant le relais entre deux humains est
## automatique et la fin tient en une ligne au centre de la colonne (décision 0032, point 8).

const PIECE_SCENE: PackedScene = preload("res://ui/components/piece_view.tscn")

var _catalog: Catalog
var _engine: DuelEngine
var _host: DuelHost
var _selection: DuelSelection = DuelSelection.new()
var _model: DuelViewModel
var _piece_views: Dictionary[int, PieceView] = {}
var _center_state: DuelColumnView.CenterState = DuelColumnView.CenterState.TURN

@onready var _table: ColorRect = %Table
@onready var _board: BoardView = %Board
@onready var _hand: HandView = %Hand
@onready var _opponent_hand: OpponentHandView = %OpponentHand
@onready var _column: DuelColumnView = %Column
@onready var _preview: HoverPreview = %Preview
@onready var _input_shield: Control = %InputShield
@onready var _event_player: EventPlayer = %EventPlayer
@onready var _right_column_a: VBoxContainer = %RightColumnA
@onready var _right_column_b: VBoxContainer = %RightColumnB
@onready var _sources: Dictionary[DuelState.PlayerSide, SourcesView] = {
	DuelState.PlayerSide.A: %SourcesA,
	DuelState.PlayerSide.B: %SourcesB,
}
@onready var _deck_corners: Dictionary[DuelState.PlayerSide, DeckCornerView] = {
	DuelState.PlayerSide.A: %DeckCornerA,
	DuelState.PlayerSide.B: %DeckCornerB,
}
@onready var _hero_cards: Dictionary[DuelState.PlayerSide, HeroCardView] = {
	DuelState.PlayerSide.A: %HeroCardA,
	DuelState.PlayerSide.B: %HeroCardB,
}


func _ready() -> void:
	_table.color = DuelPalette.TABLE_COLOR
	_place_zones()
	_catalog = TestDuelLaunch.load_catalog()
	_engine = DuelEngine.new(_catalog)
	_host = DuelHost.new(_engine)
	_selection.intent_chosen.connect(_on_intent_chosen)
	_selection.response_started.connect(_host.begin_response)
	_host.host_state_changed.connect(_on_host_state_changed)
	_event_player.batch_played.connect(_on_batch_played)
	var duel_setup := TestDuelLaunch.make_setup(_catalog)
	var first_events := _host.start(duel_setup)
	if _engine.get_state() == null:
		push_error("DuelScreen : le duel n'a pas démarré")
		return
	_setup_views(duel_setup)
	_selection.setup(_engine, DuelState.PlayerSide.A)
	_selection.selection_changed.connect(_refresh_marks)
	_connect_gestures()
	_connect_previews()
	_refresh_zones()
	_event_player.play(first_events)


# Le temps réel avance sans événement (décisions 0021 et 0029) : l'hôte le décompte, et seuls la
# pendule et le décompte de la fenêtre de réponse sont relus à chaque image.
func _process(_delta: float) -> void:
	if _engine.get_state() == null:
		return
	_event_player.play(_host.tick())
	_refresh_clocks()
	_refresh_response_countdown()


# Décision 0030 : chaque zone est ancrée au coin ou au bord le plus proche, pour suivre un écran
# d'une autre proportion.
func _place_zones() -> void:
	DuelScreenLayout.pin(_board, Control.PRESET_CENTER_TOP, DuelScreenLayout.BOARD_POSITION)
	DuelScreenLayout.pin(_column, Control.PRESET_CENTER_TOP, DuelScreenLayout.COLUMN_POSITION)
	DuelScreenLayout.pin(_hand, Control.PRESET_CENTER_BOTTOM, DuelScreenLayout.HAND_BOTTOM_LEFT)
	var hand_position := DuelScreenLayout.OPPONENT_HAND_POSITION
	DuelScreenLayout.pin(_opponent_hand, Control.PRESET_CENTER_TOP, hand_position)
	_opponent_hand.grow_horizontal = Control.GROW_DIRECTION_BOTH
	var sources_b := _sources[DuelState.PlayerSide.B]
	DuelScreenLayout.pin(sources_b, Control.PRESET_TOP_LEFT, DuelScreenLayout.TOP_LEFT_CORNER)
	var sources_a := _sources[DuelState.PlayerSide.A]
	DuelScreenLayout.pin(sources_a, Control.PRESET_BOTTOM_LEFT, DuelScreenLayout.BOTTOM_LEFT_CORNER)
	DuelScreenLayout.pin(
		_right_column_b, Control.PRESET_TOP_RIGHT, DuelScreenLayout.TOP_RIGHT_CORNER
	)
	DuelScreenLayout.pin(
		_right_column_a, Control.PRESET_BOTTOM_RIGHT, DuelScreenLayout.BOTTOM_RIGHT_CORNER
	)
	DuelScreenLayout.pin(_preview, Control.PRESET_CENTER, DuelScreenLayout.PREVIEW_CENTER)
	_preview.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_preview.grow_vertical = Control.GROW_DIRECTION_BOTH


func _setup_views(duel_setup: DuelSetup) -> void:
	_column.setup(_engine.get_state().config.clock_duration_msec)
	for side: DuelState.PlayerSide in DuelState.SIDES:
		_setup_player_zones(side, duel_setup)


# Décision 0030 : A en bas, compteurs et libellé au-dessus ; B en haut, en dessous.
func _setup_player_zones(side: DuelState.PlayerSide, duel_setup: DuelSetup) -> void:
	var is_bottom := side == DuelState.PlayerSide.A
	var source_count := _engine.get_state().config.total_sources_per_player
	var counter_placement := (
		SourcesView.CounterPlacement.ABOVE if is_bottom else SourcesView.CounterPlacement.BELOW
	)
	var label_placement := (
		DeckCornerView.LabelPlacement.ABOVE if is_bottom else DeckCornerView.LabelPlacement.BELOW
	)
	_sources[side].setup(side, counter_placement, source_count)
	_deck_corners[side].setup(side, label_placement)
	_hero_cards[side].setup(side, _catalog.get_hero(duel_setup.hero_of(side)))


func _connect_gestures() -> void:
	_board.cell_pressed.connect(_selection.press_cell)
	_hand.card_pressed.connect(_selection.press_card)
	_column.end_turn_pressed.connect(_selection.press_end_turn)
	_column.pass_pressed.connect(_selection.press_pass)
	_column.confirm_pressed.connect(_selection.press_confirm)
	_column.stack_entry_pressed.connect(_selection.press_stack_entry)
	for side: DuelState.PlayerSide in DuelState.SIDES:
		_sources[side].source_pressed.connect(_selection.press_source)
		_hero_cards[side].hero_card_pressed.connect(_selection.press_hero_power)


func _connect_previews() -> void:
	_hand.card_hovered.connect(_preview_card)
	_hand.card_unhovered.connect(_hide_preview)
	_column.stack_entry_hovered.connect(_preview_stack_entry)
	_column.stack_entry_unhovered.connect(_hide_preview)
	for side: DuelState.PlayerSide in DuelState.SIDES:
		_deck_corners[side].discard_hovered.connect(_preview_card)
		_deck_corners[side].discard_unhovered.connect(_hide_preview)
		_hero_cards[side].hero_card_hovered.connect(_preview_hero.bind(side))
		_hero_cards[side].hero_card_unhovered.connect(_hide_preview)


func _on_intent_chosen(intent: DuelIntent) -> void:
	_event_player.play(_host.submit_human(intent))


# Le relais entre deux humains est automatique (l'étape 2.4 fera son écran) ; les commandes ne
# passent que pendant le tour d'un humain.
func _on_host_state_changed(host_state: DuelHost.HostState) -> void:
	_input_shield.visible = host_state != DuelHost.HostState.AWAITING_HUMAN
	match host_state:
		DuelHost.HostState.RELAY:
			_host.confirm_relay.call_deferred()
		DuelHost.HostState.AWAITING_HUMAN:
			_selection.set_player(_host.get_screen_player())
			_refresh_zones()
		DuelHost.HostState.ENDED:
			_refresh_zones()


# L'hôte attend la confirmation de chaque lot ; c'est son changement d'état qui recale l'écran.
func _on_batch_played(_events: Array[DuelEvent]) -> void:
	_host.confirm_events_played()


# Recalage sur l'état, zone par zone, après des événements ou un changement d'appareil.
func _refresh_zones() -> void:
	_hide_preview()
	_model = DuelViewModel.new(_engine.get_state(), _catalog, _host.get_screen_player())
	_refresh_pieces()
	_hand.show_cards(_model.hand_cards())
	_opponent_hand.show_hand(_model.get_opponent(), _model.opponent_hand_size())
	_refresh_piles()
	_refresh_marks()


# Ce que la sélection change : marques, Sources, pouvoir du Hero et centre de la colonne.
func _refresh_marks() -> void:
	var shown := _selection.snapshot()
	_board.show_highlighted_cells(shown.legal_cells)
	for piece_id: int in _piece_views:
		_piece_views[piece_id].set_marks(
			shown.legal_piece_ids.has(piece_id), shown.chosen_piece_id == piece_id
		)
	_hand.show_marks(shown.playable_card_ids, _chosen_card_ids(shown))
	_refresh_sources(shown)
	_refresh_hero_cards(shown)
	_refresh_center(shown)


func _chosen_card_ids(shown: SelectionSnapshot) -> Array[int]:
	var chosen_ids := shown.set_aside_card_ids.duplicate()
	if shown.chosen_card_id != DuelState.NO_ID:
		chosen_ids.append(shown.chosen_card_id)
	return chosen_ids


func _refresh_pieces() -> void:
	_board.clear_pieces()
	_piece_views.clear()
	for piece: Piece in _engine.get_state().pieces:
		var piece_view: PieceView = PIECE_SCENE.instantiate()
		_board.put_piece(piece.cell, piece_view)
		_fill_piece(piece_view, piece)
		piece_view.piece_hovered.connect(_preview_piece)
		piece_view.piece_unhovered.connect(_hide_preview)
		_piece_views[piece.piece_id] = piece_view


# La pièce est posée sur sa case avant d'être remplie : ses nœuds n'existent qu'une fois en scène.
func _fill_piece(piece_view: PieceView, piece: Piece) -> void:
	var gear := _model.gear_definition(piece)
	piece_view.show_gear("" if gear == null else gear.card_name)
	var force := _engine.current_force(piece.piece_id)
	match DuelViewModel.piece_form_of(piece):
		DuelViewModel.PieceForm.HERO:
			var hero := _model.hero_definition(piece.owner)
			piece_view.show_hero(piece.piece_id, hero, piece.owner)
			piece_view.show_health(piece.health)
		DuelViewModel.PieceForm.TOKEN:
			var card_type := _model.token_card_type(piece)
			piece_view.show_token(piece.piece_id, card_type, piece.owner)
			piece_view.show_force(force, piece.token_force)
		DuelViewModel.PieceForm.CARD:
			var definition := _model.piece_definition(piece)
			piece_view.show_card_piece(piece.piece_id, definition, piece.owner)
			piece_view.show_force(force, definition.force)


func _refresh_piles() -> void:
	for side: DuelState.PlayerSide in DuelState.SIDES:
		var corner := _deck_corners[side]
		corner.show_deck(_model.deck_size(side))
		corner.show_fatigue(_model.fatigue(side))
		var top := _model.discard_top(side)
		if top == null:
			corner.show_empty_discard()
		else:
			corner.show_discard(top.card_instance_id, top.definition)


func _refresh_sources(shown: SelectionSnapshot) -> void:
	for side: DuelState.PlayerSide in DuelState.SIDES:
		var view := _sources[side]
		var player := _engine.get_state().get_player(side)
		view.show_sources(_model.upright_sources(side, shown), _model.tilted_sources(side, shown))
		view.show_supply(player.sources_in_reserve, player.sources_in_fonte)
		view.show_essence(_model.essence_shown(side, shown.draft_payment))
		view.set_interactive(side == _model.get_viewer())


# Décision 0032, point 3 : seul le joueur qui a l'appareil clique sa carte Hero.
func _refresh_hero_cards(shown: SelectionSnapshot) -> void:
	for side: DuelState.PlayerSide in DuelState.SIDES:
		var is_viewer := side == _model.get_viewer()
		_hero_cards[side].set_clickable(is_viewer)
		_hero_cards[side].set_power_usable(is_viewer and shown.can_use_hero_power)


func _refresh_center(shown: SelectionSnapshot) -> void:
	var state := _engine.get_state()
	_center_state = DuelViewModel.center_state_of(state)
	match _center_state:
		DuelColumnView.CenterState.TURN:
			_column.show_turn(state.turn_number, state.active_player, shown.can_end_turn)
		DuelColumnView.CenterState.STACK:
			var lines := _model.stack_lines()
			_column.show_stack(
				lines, shown.legal_stack_entry_ids, state.priority_player, shown.can_pass
			)
			_refresh_response_countdown()
		DuelColumnView.CenterState.MULLIGAN:
			_column.show_mulligan(_model.get_viewer(), shown.can_confirm)
		DuelColumnView.CenterState.CHOICE:
			_show_choice(shown)
		DuelColumnView.CenterState.ENDED:
			_column.show_ended(DuelViewModel.result_text(state.result))


# Décision 0032, point 6 : l'ordre des effets déclenchés se choisit dans la pile, leurs rangs
# numérotés au fil des clics.
func _show_choice(shown: SelectionSnapshot) -> void:
	var decision := _engine.get_state().pending_decision
	var ordered_candidate_ids: Array[int] = []
	if decision.kind == PendingDecision.DecisionKind.ORDER_TRIGGERS:
		ordered_candidate_ids.assign(decision.candidate_ids)
	var lines := _model.stack_lines(ordered_candidate_ids, shown.ordered_entry_ids)
	var instruction := DuelViewModel.choice_instruction(decision.kind)
	_column.show_choice(instruction, lines, shown.legal_stack_entry_ids)


# La pendule est relue à chaque image sans événement (décision 0021) ; la colonne ne redessine
# une pendule que si ses secondes changent.
func _refresh_clocks() -> void:
	var state := _engine.get_state()
	_column.show_clocks(
		state.get_player(DuelState.PlayerSide.A).clock_remaining_msec,
		state.get_player(DuelState.PlayerSide.B).clock_remaining_msec,
		_engine.clock_owners()
	)


# Décision 0029 : le décompte de la fenêtre de réponse se lit auprès de l'hôte à chaque image,
# tant que le joueur peut répondre ; la colonne ne se redessine que si l'affichage change.
func _refresh_response_countdown() -> void:
	if _center_state != DuelColumnView.CenterState.STACK:
		return
	if _host.get_host_state() != DuelHost.HostState.AWAITING_HUMAN:
		return
	if _host.is_response_window_running():
		var window_msec := _engine.get_state().config.response_window_msec
		_column.show_response_time(_host.get_response_time_left_msec(), window_msec)
	else:
		_column.show_response_stopped()


func _preview_card(card_instance_id: int) -> void:
	var definition := _model.visible_definition(card_instance_id)
	if definition != null:
		_preview.show_card(definition)


func _preview_hero(side: DuelState.PlayerSide) -> void:
	_preview.show_hero(_model.hero_definition(side))


func _preview_piece(piece_id: int) -> void:
	var piece := _engine.get_state().find_piece(piece_id)
	if piece == null:
		return
	var gear := _model.gear_definition(piece)
	match DuelViewModel.piece_form_of(piece):
		DuelViewModel.PieceForm.HERO:
			_preview.show_hero(_model.hero_definition(piece.owner), gear)
		DuelViewModel.PieceForm.TOKEN:
			var force := _engine.current_force(piece_id)
			_preview.show_token(_model.token_card_type(piece), force, gear)
		DuelViewModel.PieceForm.CARD:
			_preview.show_card(_model.piece_definition(piece), gear)


func _preview_stack_entry(stack_entry_id: int) -> void:
	var entry := _model.find_entry(stack_entry_id)
	if entry == null:
		return
	if entry.kind == StackEntry.StackEntryKind.HERO_POWER:
		_preview.show_hero(_model.hero_definition(entry.owner))
		return
	var definition := _model.entry_definition(entry)
	if definition != null:
		_preview.show_card(definition)


func _hide_preview(_ignored_id: int = DuelState.NO_ID) -> void:
	_preview.hide_preview()
