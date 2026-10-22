class_name DuelScreen
extends Control
## Écran de duel de l'étape 2.3 (décisions 0020, 0028 à 0032) : assemble les composants de
## `ui/components/` aux cotes de 0030 (repère 1920×1080, marges de 16 px, joueur A en bas), les
## câble à `DuelSelection` et à `DuelHost`, et les recale sur `get_state()` après chaque lot
## d'événements joué par `EventPlayer`. Aucune règle ici : seul `DuelSelection` fait d'un geste une
## intention, et `DuelViewModel` filtre ce que voit le joueur de l'appareil (201.4).
##
## Flux : geste → `DuelSelection` → `intent_chosen` → `DuelHost.submit_human` → événements →
## `EventPlayer` → `batch_played` → `confirm_events_played` → recalage. `InputShield` bloque les
## commandes pendant la lecture et hors du tour d'un humain. `OverlayLayer`, au-dessus du bouclier,
## porte le rideau de relais, la confirmation d'abandon et le panneau de fin (décision 0036).

## Le panneau de fin demande une nouvelle partie : l'autre joueur commence, nouvelle graine.
signal rematch_requested
## Le panneau de fin demande de revenir à la préparation.
signal setup_requested
## Le panneau de fin demande la fiche de relevé de la partie.
signal sheet_requested

var _catalog: Catalog
var _engine: DuelEngine
var _host: DuelHost
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
@onready var _preview: HoverPreview = %Preview
@onready var _input_shield: Control = %InputShield
@onready var _event_player: EventPlayer = %EventPlayer
@onready var _overlays: DuelOverlays = %OverlayLayer
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
	_selection.intent_chosen.connect(_on_intent_chosen)
	_selection.response_started.connect(_on_response_started)
	_scripted.intent_chosen.connect(_on_intent_chosen)
	_event_player.batch_played.connect(_on_batch_played)
	_connect_gestures()
	_connect_previews()
	_connect_overlays()


# Décision 0021 : le temps réel avance sans événement ; la pendule se relit.
func _process(_delta: float) -> void:
	if _host == null or _engine.get_state() == null:
		return
	_event_player.play(_host.tick())
	_center.refresh_clocks()


## Démarre le duel de `duel_setup`, une seule fois, après l'entrée de l'écran dans l'arbre.
func start_duel(duel_setup: DuelSetup, config: DuelConfig, catalog: Catalog) -> void:
	if _host != null:
		push_error("DuelScreen : le duel est déjà démarré")
		return
	_catalog = catalog
	_engine = DuelEngine.new(_catalog, config)
	_previewer.setup(_preview, _engine)
	_zones.setup(_board, _engine, _previewer.show_piece, _previewer.hide_preview)
	_host = DuelHost.new(_engine)
	_scripted.setup(_engine, _host)
	_center.setup(_column, _engine, _host)
	_host.host_state_changed.connect(_on_host_state_changed)
	var first_events := _host.start(duel_setup)
	if _engine.get_state() == null:
		push_error("DuelScreen : le duel n'a pas démarré")
		return
	_setup_views(duel_setup)
	_selection.setup(_engine, DuelState.PlayerSide.A)
	_selection.selection_changed.connect(_refresh_marks)
	_refresh_zones_hiding_hand()
	_event_player.play(first_events)


## Outil de développement, juste après `start_duel` : `intents` sont soumis un par un, chacun quand
## l'hôte attend son joueur ; un refus de `DuelEngine.validate()` arrête la suite.
func play_scripted_intents(intents: Array[DuelIntent]) -> void:
	_scripted.add_intents(intents)


## Journal de la partie, d'où se lit la fiche de relevé (décision 0042).
func get_journal() -> DuelJournal:
	return _host.get_journal()


## Dit au joueur, sous les boutons du panneau de fin, ce qu'est devenue sa demande de fiche.
func show_sheet_status(text: String) -> void:
	_overlays.show_sheet_status(text)


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
	_zones.add_player_zones(side, _sources[side], _deck_corners[side], _hero_cards[side])


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
	_hand.card_hovered.connect(_previewer.show_card)
	_hand.card_unhovered.connect(_previewer.hide_preview)
	_column.stack_entry_hovered.connect(_previewer.show_stack_entry)
	_column.stack_entry_unhovered.connect(_previewer.hide_preview)
	for side: DuelState.PlayerSide in DuelState.SIDES:
		_deck_corners[side].discard_hovered.connect(_previewer.show_card)
		_deck_corners[side].discard_unhovered.connect(_previewer.hide_preview)
		_hero_cards[side].hero_card_hovered.connect(_previewer.show_hero.bind(side))
		_hero_cards[side].hero_card_unhovered.connect(_previewer.hide_preview)


func _connect_overlays() -> void:
	_column.concede_pressed.connect(_on_concede_pressed)
	_overlays.relay_confirmed.connect(_on_relay_confirmed)
	_overlays.concede_confirmed.connect(_on_concede_confirmed)
	_overlays.rematch_pressed.connect(rematch_requested.emit)
	_overlays.setup_pressed.connect(setup_requested.emit)
	_overlays.sheet_pressed.connect(sheet_requested.emit)


func _on_intent_chosen(intent: DuelIntent) -> void:
	_event_player.play(_host.submit_human(intent))


# Décision 0036 : les commandes ne passent que pendant le tour d'un humain ; le relais attend le
# clic du joueur attendu sur le rideau, sauf tant que des intentions scriptées restent.
func _on_host_state_changed(host_state: DuelHost.HostState) -> void:
	_input_shield.visible = host_state != DuelHost.HostState.AWAITING_HUMAN
	_refresh_overlays(host_state)
	_center.refresh_response_window()
	match host_state:
		DuelHost.HostState.RELAY:
			_start_relay()
		DuelHost.HostState.AWAITING_HUMAN:
			_selection.set_player(_host.get_screen_player())
			_refresh_zones()
			_scripted.submit_next.call_deferred()
		DuelHost.HostState.ENDED:
			_refresh_zones()
			_show_end_panel()


# Rideau et confirmation ne vivent que dans l'état qui les appelle.
func _refresh_overlays(host_state: DuelHost.HostState) -> void:
	if host_state != DuelHost.HostState.RELAY:
		_overlays.hide_relay()
	if host_state != DuelHost.HostState.AWAITING_HUMAN:
		_overlays.hide_concede_confirm()
	_refresh_concede_button()


# Décision 0042 : la réponse commencée est notée au journal pour le relevé ; la fenêtre reste
# ouverte (208.6.2).
func _on_response_started() -> void:
	_host.begin_response()


# Décision 0036 : « Abandonner » est pour le joueur qui a l'appareil, en AWAITING_HUMAN, fenêtre
# de réponse ouverte ou non (208.6.2) : aucune passe automatique ne ferme la confirmation.
func _refresh_concede_button() -> void:
	if _host.get_host_state() == DuelHost.HostState.AWAITING_HUMAN:
		_column.show_concede(_host.get_screen_player())
	else:
		_column.hide_concede()


func _start_relay() -> void:
	if _scripted.has_pending():
		_host.confirm_relay.call_deferred()
		return
	_refresh_zones_hiding_hand()
	_overlays.show_relay(_host.get_awaited_player())


func _on_relay_confirmed() -> void:
	_overlays.hide_relay()
	_host.confirm_relay()


func _on_concede_pressed() -> void:
	_overlays.show_concede_confirm(_host.get_screen_player())


# 209.2.5 : le joueur qui a l'appareil abandonne.
func _on_concede_confirmed() -> void:
	_overlays.hide_concede_confirm()
	_event_player.play(_host.concede(_host.get_screen_player()))


func _show_end_panel() -> void:
	var state := _engine.get_state()
	var elapsed_msec := _host.get_journal().total_elapsed_msec()
	_overlays.show_end(
		state.result,
		DuelViewModel.result_text(state.result),
		EndSummary.reason_text(_final_events),
		EndSummary.details_text(state.turn_number, elapsed_msec)
	)


# L'hôte attend la confirmation de chaque lot ; c'est son changement d'état qui recale l'écran.
func _on_batch_played(events: Array[DuelEvent]) -> void:
	if events.any(func(event: DuelEvent) -> bool: return event is DuelEnded):
		_final_events = events
	_host.confirm_events_played()


# Recalage sur l'état, zone par zone, après des événements ou un changement d'appareil.
func _refresh_zones() -> void:
	_use_viewer_model()
	_refresh_zones_around(_model.hand_cards())


# Pendant le relais, l'appareil montre encore le joueur d'avant : sa main ne reste pas affichée sous
# le rideau (201.4.2).
func _refresh_zones_hiding_hand() -> void:
	_use_viewer_model()
	_refresh_zones_around([])


func _use_viewer_model() -> void:
	_previewer.hide_preview()
	_model = DuelViewModel.new(_engine.get_state(), _catalog, _host.get_screen_player())
	_previewer.use_model(_model)


func _refresh_zones_around(hand_cards: Array[HandView.HandCard]) -> void:
	_zones.refresh_pieces(_model)
	_hand.show_cards(hand_cards)
	_opponent_hand.show_hand(_model.get_opponent(), _model.opponent_hand_size())
	_zones.refresh_piles(_model)
	_refresh_marks()


# Ce que la sélection change : marques, Sources, pouvoir du Hero et centre de la colonne.
func _refresh_marks() -> void:
	var shown := _selection.snapshot()
	_board.show_highlighted_cells(shown.legal_cells)
	_zones.show_piece_marks(shown)
	_hand.show_marks(shown.playable_card_ids, _chosen_card_ids(shown))
	_zones.refresh_sources(_model, shown)
	_zones.refresh_hero_cards(_model, shown)
	_center.show_center(_model, shown)


func _chosen_card_ids(shown: SelectionSnapshot) -> Array[int]:
	var chosen_ids := shown.set_aside_card_ids.duplicate()
	if shown.chosen_card_id != DuelState.NO_ID:
		chosen_ids.append(shown.chosen_card_id)
	return chosen_ids
