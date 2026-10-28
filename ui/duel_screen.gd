class_name DuelScreen
extends Control
## Écran de duel de l'étape 2.3 (décisions 0020, 0028 à 0032, 0052) : assemble les composants de
## `ui/components/` en quatre couches et en conteneurs (fiche `docs/fiches/ecran-de-duel.md`,
## repère 1920×1080, marges de 16 px, joueur A en bas), sans placer aucune zone par code, les
## câble à `DuelSelection` et à une `DuelSession` (décision 0050 : même appareil, hôte ou second
## écran d'un duel à distance), et les recale sur `get_state()` après chaque lot
## d'événements joué par `EventPlayer`. Aucune règle ici : seul `DuelSelection` fait d'un geste une
## intention, et `DuelViewModel` filtre ce que voit le joueur de l'appareil (201.4).
##
## Flux : geste → `DuelSelection` → `intent_chosen` → `DuelSession.submit` → événements →
## `EventPlayer` → `batch_played` → `confirm_events_played` → recalage. `InputShield` bloque les
## commandes pendant la lecture et quand le joueur de l'écran n'est pas attendu. `OverlayLayer`,
## dans `ModalLayer` au-dessus du bouclier, porte la confirmation d'abandon et le panneau de fin
## (décision 0036). Entre deux humains sur le même écran, le relais est confirmé aussitôt, sans
## rideau (décision 0048). Le camp du joueur de l'écran est en bas : A, sauf pour le second écran
## d'un duel à distance (décision 0050).

## Le panneau de fin demande une nouvelle partie : l'autre joueur commence, nouvelle graine.
signal rematch_requested
## Le panneau de fin demande de revenir à la préparation.
signal setup_requested
## Le panneau de fin demande la fiche de relevé de la partie.
signal sheet_requested
## Duel à distance : la connexion est perdue ou les navigateurs sont incompatibles (`reason`).
signal connection_lost(reason: String)

var _catalog: Catalog
var _engine: DuelEngine
var _session: DuelSession
var _selection: DuelSelection = DuelSelection.new()
var _previewer: DuelPreviewer = DuelPreviewer.new()
var _model: DuelViewModel
var _zones: DuelZonesPresenter = DuelZonesPresenter.new()
var _center: DuelCenterPresenter = DuelCenterPresenter.new()
var _scripted: ScriptedIntentsPlayer = ScriptedIntentsPlayer.new()
## Événements du lot qui a terminé le duel : la raison du panneau de fin s'en déduit.
var _final_events: Array[DuelEvent] = []

@onready var _table: ColorRect = %Table
@onready var _board: BoardView = %Board
@onready var _hand: HandView = %Hand
@onready var _opponent_hand: OpponentHandView = %OpponentHand
@onready var _column: DuelColumnView = %Column
@onready var _column_letters: ColumnLettersView = %ColumnLetters
@onready var _preview: HoverPreview = %Preview
@onready var _tooltips: InfoTooltips = %Tooltips
@onready var _input_shield: Control = %InputShield
@onready var _event_player: EventPlayer = %EventPlayer
@onready var _overlays: DuelOverlays = %OverlayLayer
@onready var _sources: Dictionary[DuelState.PlayerSide, SourcesView] = {
	DuelState.PlayerSide.A: %SourcesBottom,
	DuelState.PlayerSide.B: %SourcesTop,
}
@onready var _timer_bars: Dictionary[DuelState.PlayerSide, TurnTimerBar] = {
	DuelState.PlayerSide.A: %TimerBarBottom,
	DuelState.PlayerSide.B: %TimerBarTop,
}
@onready var _deck_corners: Dictionary[DuelState.PlayerSide, DeckCornerView] = {
	DuelState.PlayerSide.A: %DeckCornerBottom,
	DuelState.PlayerSide.B: %DeckCornerTop,
}


func _ready() -> void:
	_table.color = DuelPalette.TABLE_COLOR
	_selection.intent_chosen.connect(_on_intent_chosen)
	_selection.response_started.connect(_on_response_started)
	_scripted.intent_chosen.connect(_on_intent_chosen)
	_event_player.batch_played.connect(_on_batch_played)
	_connect_gestures()
	_connect_overlays()


# Décision 0021 : le temps réel avance sans événement ; les temps se relisent.
func _process(_delta: float) -> void:
	if _session == null or _engine.get_state() == null:
		return
	_event_player.play(_session.tick())
	_center.refresh_clocks()


## Démarre sur cet appareil le duel de `duel_setup`, une seule fois, après l'entrée de l'écran
## dans l'arbre.
func start_duel(duel_setup: DuelSetup, config: DuelConfig, catalog: Catalog) -> void:
	var host := DuelHost.new(DuelEngine.new(catalog, config))
	start_session(HostedDuelSession.new(host, duel_setup), catalog)


## Démarre le duel de `session`, une seule fois, après l'entrée de l'écran dans l'arbre.
func start_session(session: DuelSession, catalog: Catalog) -> void:
	if _session != null:
		push_error("DuelScreen : le duel est déjà démarré")
		return
	_catalog = catalog
	_session = session
	_engine = session.get_engine()
	_previewer.setup(_preview, _engine, _tooltips)
	_zones.setup(_board, _engine, _previewer.show_piece, _previewer.hide_preview)
	_scripted.setup(_session)
	_center.setup(_column, _timer_bars, _session)
	_session.session_state_changed.connect(_on_session_state_changed)
	var first_events := _session.start()
	if _engine.get_state() == null:
		push_error("DuelScreen : le duel n'a pas démarré")
		return
	_setup_views()
	_selection.setup(_engine, _session.get_viewer())
	_selection.selection_changed.connect(_refresh_marks)
	_refresh_zones()
	_event_player.play(first_events)


## Outil de développement, juste après `start_duel` : `intents` sont soumis un par un, chacun quand
## l'hôte attend son joueur ; un refus de `DuelEngine.validate()` arrête la suite.
func play_scripted_intents(intents: Array[DuelIntent]) -> void:
	_scripted.add_intents(intents)


## Journal de la partie, d'où se lit la fiche de relevé (décision 0042).
func get_journal() -> DuelJournal:
	return _session.get_journal()


## Vrai pour un duel à distance (décision 0050).
func is_remote() -> bool:
	return _session.is_remote()


## Ferme la connexion d'un duel à distance, avant de quitter l'écran.
func close_session() -> void:
	_session.close()


## Dit au joueur, sous les boutons du panneau de fin, ce qu'est devenue sa demande de fiche.
func show_sheet_status(text: String) -> void:
	_overlays.show_sheet_status(text)


func _setup_views() -> void:
	var config := _engine.get_state().config
	var bottom_side := _session.get_bottom_side()
	if bottom_side != DuelState.PlayerSide.A:
		_board.show_from_side(bottom_side)
		_column_letters.show_from_side(bottom_side)
		for zones: Dictionary in [_sources, _deck_corners, _timer_bars]:
			ScreenSides.swap(zones)
	for side: DuelState.PlayerSide in DuelState.SIDES:
		_timer_bars[side].setup(side, config.turn_time_msec, config.response_time_msec)
		_setup_player_zones(side, side == bottom_side)
	_connect_previews()


# Décision 0030 : le camp du bas a compteurs et libellé au-dessus ; celui du haut, en dessous.
func _setup_player_zones(side: DuelState.PlayerSide, is_bottom: bool) -> void:
	var source_count := _engine.get_state().config.total_sources_per_player
	var counter_placement := (
		SourcesView.CounterPlacement.ABOVE if is_bottom else SourcesView.CounterPlacement.BELOW
	)
	var label_placement := (
		DeckCornerView.LabelPlacement.ABOVE if is_bottom else DeckCornerView.LabelPlacement.BELOW
	)
	_sources[side].setup(side, counter_placement, source_count)
	_deck_corners[side].setup(side, label_placement)
	_zones.add_player_zones(side, _sources[side], _deck_corners[side])


func _connect_gestures() -> void:
	_board.cell_pressed.connect(_selection.press_cell)
	_hand.card_pressed.connect(_selection.press_card)
	_column.end_turn_pressed.connect(_selection.press_end_turn)
	_column.pass_pressed.connect(_selection.press_pass)
	_column.confirm_pressed.connect(_selection.press_confirm)
	_column.stack_entry_pressed.connect(_selection.press_stack_entry)
	_column.x_decrease_pressed.connect(_selection.press_x_decrease)
	_column.x_increase_pressed.connect(_selection.press_x_increase)
	_column.x_confirm_pressed.connect(_selection.press_x_confirm)
	_column.choice_pressed.connect(_selection.press_choice)
	_column.cancel_pressed.connect(_selection.press_cancel)
	for side: DuelState.PlayerSide in DuelState.SIDES:
		_sources[side].source_pressed.connect(_selection.press_source)


func _connect_previews() -> void:
	_hand.card_hovered.connect(_previewer.show_card)
	_hand.card_unhovered.connect(_previewer.hide_preview)
	_column.stack_entry_hovered.connect(_previewer.show_stack_entry)
	_column.stack_entry_unhovered.connect(_previewer.hide_preview)
	for side: DuelState.PlayerSide in DuelState.SIDES:
		_deck_corners[side].discard_hovered.connect(_previewer.show_card)
		_deck_corners[side].discard_unhovered.connect(_previewer.hide_preview)


func _connect_overlays() -> void:
	_column.concede_pressed.connect(_on_concede_pressed)
	_overlays.concede_confirmed.connect(_on_concede_confirmed)
	_overlays.rematch_pressed.connect(rematch_requested.emit)
	_overlays.setup_pressed.connect(setup_requested.emit)
	_overlays.sheet_pressed.connect(sheet_requested.emit)


func _on_intent_chosen(intent: DuelIntent) -> void:
	_event_player.play(_session.submit(intent))


# Décision 0036 : les commandes ne passent que quand le joueur de l'écran est attendu ; le relais
# entre deux humains est confirmé par la session (décision 0048). Le coup d'un autre joueur
# (agent, joueur distant) recale aussi l'écran.
func _on_session_state_changed(session_state: DuelSession.SessionState) -> void:
	_input_shield.visible = session_state != DuelSession.SessionState.AWAITING_VIEWER
	_refresh_overlays(session_state)
	_center.refresh_response_window()
	match session_state:
		DuelSession.SessionState.AWAITING_VIEWER:
			_selection.set_player(_session.get_viewer())
			_refresh_zones()
			_scripted.submit_next.call_deferred()
		DuelSession.SessionState.AWAITING_OTHER:
			_refresh_zones()
		DuelSession.SessionState.ENDED:
			_refresh_zones()
			_show_end_panel()
		DuelSession.SessionState.DISCONNECTED:
			connection_lost.emit(_session.get_disconnection())


# La confirmation d'abandon ne vit que dans l'état qui l'appelle.
func _refresh_overlays(session_state: DuelSession.SessionState) -> void:
	if session_state != DuelSession.SessionState.AWAITING_VIEWER:
		_overlays.hide_concede_confirm()
	_refresh_concede_button()


# Décision 0042 : la réponse commencée est notée au journal pour le relevé ; la fenêtre reste
# ouverte (208.6.2).
func _on_response_started() -> void:
	_session.begin_response()


# Décision 0036 : « Abandonner » est pour le joueur de l'écran quand il est attendu, fenêtre
# de réponse ouverte ou non (208.6.2) : aucune passe automatique ne ferme la confirmation.
func _refresh_concede_button() -> void:
	if _session.get_session_state() == DuelSession.SessionState.AWAITING_VIEWER:
		_column.show_concede()
	else:
		_column.hide_concede()


func _on_concede_pressed() -> void:
	_overlays.show_concede_confirm(_session.get_viewer())


# 209.2.5 : le joueur de l'écran abandonne.
func _on_concede_confirmed() -> void:
	_overlays.hide_concede_confirm()
	_event_player.play(_session.concede())


func _show_end_panel() -> void:
	var state := _engine.get_state()
	var elapsed_msec := _session.get_journal().total_elapsed_msec()
	_overlays.show_end(
		state.result,
		DuelViewModel.result_text(state.result),
		EndSummary.reason_text(_final_events),
		EndSummary.details_text(state.turn_number, elapsed_msec)
	)


# La session attend la confirmation de chaque lot ; c'est son changement d'état qui recale l'écran.
func _on_batch_played(events: Array[DuelEvent]) -> void:
	if events.any(func(event: DuelEvent) -> bool: return event is DuelEnded):
		_final_events = events
	_session.confirm_events_played()


# Recalage sur l'état, zone par zone, après des événements ou un changement d'appareil.
func _refresh_zones() -> void:
	_use_viewer_model()
	_selection.resync()
	_refresh_zones_around(_model.hand_cards())


func _use_viewer_model() -> void:
	_previewer.hide_preview()
	_model = DuelViewModel.new(_engine.get_state(), _catalog, _session.get_viewer())
	_previewer.use_model(_model)


func _refresh_zones_around(hand_cards: Array[HandView.HandCard]) -> void:
	_zones.refresh_pieces(_model)
	_hand.show_cards(hand_cards)
	_opponent_hand.show_hand(_model.get_opponent(), _model.opponent_hand_size())
	_zones.refresh_piles(_model)
	_refresh_marks()


# Ce que la sélection change : marques, Sources et centre de la colonne.
func _refresh_marks() -> void:
	var shown := _selection.snapshot()
	_board.show_highlighted_cells(shown.legal_cells)
	_zones.show_piece_marks(shown)
	_hand.show_marks(shown.playable_card_ids, _chosen_card_ids(shown))
	_zones.refresh_sources(_model, shown)
	_center.show_center(_model, shown)
	_show_looked_card(shown)


# 201.4.1a, 217.1.5 : la carte regardée n'est montrée qu'à son joueur (`DuelViewModel`).
func _show_looked_card(shown: SelectionSnapshot) -> void:
	if shown.looked_card_id != DuelState.NO_ID:
		_previewer.show_card(shown.looked_card_id)


func _chosen_card_ids(shown: SelectionSnapshot) -> Array[int]:
	var chosen_ids := shown.picked_card_ids.duplicate()
	if shown.chosen_card_id != DuelState.NO_ID:
		chosen_ids.append(shown.chosen_card_id)
	return chosen_ids
