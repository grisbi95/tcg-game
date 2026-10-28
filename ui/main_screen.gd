class_name MainScreen
extends Control
## Scène racine (décision 0036, point 6) : enchaîne la préparation, le duel et sa fin, puis la
## partie suivante ou la préparation. Décisions 0043 et 0050 : mène aussi la connexion au relais
## d'un duel à distance, de « Créer » ou « Rejoindre » jusqu'au duel ; en duel à distance, la fin
## ramène à la préparation. Tient la suite des parties (`DuelSeries`) et n'affiche qu'un
## écran enfant à la fois ; aucun état global, aucune règle. Une erreur de lecture des cartes ou du
## deck s'affiche au lieu de planter.

## Étape de la connexion au relais, de la préparation au duel.
enum LobbyStep {
	NONE,
	CREATING,
	JOINING,
	AWAITING_SETUP,
}

const SETUP_SCENE: PackedScene = preload("res://ui/setup_screen.tscn")
const DUEL_SCENE: PackedScene = preload("res://ui/duel_screen.tscn")
const LOAD_ERROR_TEXT: String = "Impossible de charger le jeu : cartes ou deck de test en erreur."
const PLAN_UNREADABLE_TEXT: String = "Plan de série illisible : parties libres seulement"
const PLAN_LABEL_FORMAT: String = "Partie %d — %s contre %s (%s commence)"
const DECK_LABEL_FORMAT: String = "%s — %s"
const BACK_TEXT: String = "Retour"
const SETUP_ERROR_FORMAT: String = "Partie impossible : %s"
const SHEET_SAVED_FORMAT: String = "Fiche enregistrée : %s"
const SHEET_FAILED_TEXT: String = "Fiche impossible à enregistrer"
const CONNECTING_TEXT: String = "Connexion au relais…"
const ROOM_CODE_FORMAT: String = "Code de la partie : %s\nDonne-le à l'autre joueur ; en attente…"
const AWAITING_HOST_TEXT: String = "Partie rejointe ; en attente de l'hôte…"
const DISCONNECTED_FORMAT: String = "Duel à distance interrompu : %s"

var _catalog: Catalog
var _config: DuelConfig = DuelConfig.new()
var _series: DuelSeries
## Decks proposés à la préparation, dans l'ordre de `GameLibrary.load_decks`.
var _decks: Array[DeckList] = []
var _screen: Control
var _lobby_step: LobbyStep = LobbyStep.NONE
var _connection: RelayConnection
## Graine choisie par le créateur d'une partie à distance, jusqu'à l'arrivée de l'autre joueur.
var _remote_seed: int = 0
var _guest_session: RemoteGuestSession
## Statut de la préparation quand rien d'autre n'est à dire : plan de série illisible (0069).
var _setup_default_status: String = ""

@onready var _table: ColorRect = %Table
@onready var _error_box: Control = %ErrorBox
@onready var _error_label: Label = %ErrorLabel
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_table.color = DuelPalette.TABLE_COLOR
	_error_label.add_theme_color_override("font_color", DuelPalette.INK_COLOR)
	_back_button.text = BACK_TEXT
	_back_button.pressed.connect(_show_setup)
	_catalog = GameLibrary.load_catalog()
	if _catalog == null:
		_show_load_error()
		return
	_decks = GameLibrary.load_decks(_catalog)
	var test_deck_index := _find_deck_index(GameLibrary.TEST_DECK_ID)
	if test_deck_index < 0:
		_show_load_error()
		return
	_series = DuelSeries.new(_decks[test_deck_index], _decks[test_deck_index])
	var plan := GameLibrary.load_series_plan(_catalog, _decks)
	if plan == null:
		_setup_default_status = PLAN_UNREADABLE_TEXT
	else:
		_series.set_plan(plan, _decks)
	_show_setup()


# Contournement Web : sans thread, la connexion au relais avance à chaque image.
func _process(_delta: float) -> void:
	match _lobby_step:
		LobbyStep.CREATING, LobbyStep.JOINING:
			_advance_connection()
		LobbyStep.AWAITING_SETUP:
			_advance_guest_session()


func _show_setup(status: String = "") -> void:
	var setup_screen: SetupScreen = SETUP_SCENE.instantiate()
	_replace_screen(setup_screen)
	setup_screen.start_pressed.connect(_start_duel)
	setup_screen.create_pressed.connect(_on_create_pressed)
	setup_screen.join_pressed.connect(_on_join_pressed)
	setup_screen.cancel_pressed.connect(_on_cancel_pressed)
	setup_screen.deck_chosen.connect(_on_deck_chosen)
	setup_screen.game_chosen.connect(_on_game_chosen)
	setup_screen.first_player_chosen.connect(_series.set_first_player_choice)
	setup_screen.show_preparation(_make_preparation())
	setup_screen.show_idle(_setup_default_status if status.is_empty() else status)


func _make_preparation() -> SetupScreen.Preparation:
	var preparation := SetupScreen.Preparation.new()
	preparation.game_number = _series.get_game_number()
	for game: SeriesPlanGame in _series.get_plan_games():
		preparation.plan_game_numbers.append(game.game_number)
		preparation.plan_labels.append(_plan_label(game))
	for deck: DeckList in _decks:
		preparation.deck_labels.append(DECK_LABEL_FORMAT % [deck.deck_name, _hero_name(deck)])
	for side: DuelState.PlayerSide in DuelState.SIDES:
		preparation.deck_indexes[side] = _decks.find(_series.get_deck(side))
	preparation.first_player_choice = _series.get_chosen_first_player_choice()
	preparation.rng_seed = DuelSeries.draw_seed()
	return preparation


func _plan_label(game: SeriesPlanGame) -> String:
	return (
		PLAN_LABEL_FORMAT
		% [
			game.game_number,
			_deck_name(game.deck_id_a),
			_deck_name(game.deck_id_b),
			PlayerNames.letter(game.first_player),
		]
	)


func _deck_name(deck_id: StringName) -> String:
	var deck_index := _find_deck_index(deck_id)
	return String(deck_id) if deck_index < 0 else _decks[deck_index].deck_name


func _hero_name(deck: DeckList) -> String:
	var hero := _catalog.get_hero(deck.hero_id)
	return String(deck.hero_id) if hero == null else hero.hero_name


func _find_deck_index(deck_id: StringName) -> int:
	for deck_index: int in _decks.size():
		if _decks[deck_index].deck_id == deck_id:
			return deck_index
	return -1


func _on_game_chosen(game_number: int) -> void:
	if game_number == DuelSeries.NO_PLAN_GAME:
		_series.choose_free_game()
	else:
		_series.choose_plan_game(game_number)
	_setup_screen().show_game(_make_preparation())


func _on_deck_chosen(side: DuelState.PlayerSide, deck_index: int) -> void:
	_series.set_deck(side, _decks[deck_index])


func _start_duel(rng_seed: int) -> void:
	var duel_setup := _checked_setup(rng_seed)
	if duel_setup != null:
		_open_duel_screen().start_duel(duel_setup, _config, _catalog)


# Préparation de la partie, ou null après l'affichage de ses erreurs.
func _checked_setup(rng_seed: int) -> DuelSetup:
	var duel_setup := _series.make_setup(rng_seed)
	var errors := duel_setup.find_errors(_catalog, _config)
	if not errors.is_empty():
		_show_error(SETUP_ERROR_FORMAT % "\n".join(errors), true)
		return null
	return duel_setup


func _open_duel_screen() -> DuelScreen:
	var duel_screen: DuelScreen = DUEL_SCENE.instantiate()
	_replace_screen(duel_screen)
	duel_screen.rematch_requested.connect(_on_rematch_requested)
	duel_screen.setup_requested.connect(_on_setup_requested)
	duel_screen.sheet_requested.connect(_on_sheet_requested)
	duel_screen.connection_lost.connect(_on_connection_lost)
	return duel_screen


func _on_create_pressed(rng_seed: int) -> void:
	_remote_seed = rng_seed
	_connection = RelayConnection.new()
	_connection.create_room(RelayAddress.url())
	_enter_lobby(LobbyStep.CREATING, CONNECTING_TEXT)


func _on_join_pressed(code: String) -> void:
	_connection = RelayConnection.new()
	_connection.join_room(RelayAddress.url(), code)
	_enter_lobby(LobbyStep.JOINING, CONNECTING_TEXT)


func _on_cancel_pressed() -> void:
	_leave_lobby()
	_setup_screen().show_idle()


func _enter_lobby(step: LobbyStep, status: String) -> void:
	_lobby_step = step
	_setup_screen().show_connecting(status)


func _leave_lobby() -> void:
	if _connection != null:
		_connection.close()
	_connection = null
	_guest_session = null
	_lobby_step = LobbyStep.NONE


func _setup_screen() -> SetupScreen:
	return _screen as SetupScreen


func _advance_connection() -> void:
	_connection.poll()
	match _connection.get_status():
		RelayConnection.Status.WAITING_FOR_PEER:
			if _lobby_step == LobbyStep.CREATING and not _connection.get_room_code().is_empty():
				_setup_screen().show_connecting(ROOM_CODE_FORMAT % _connection.get_room_code())
		RelayConnection.Status.PAIRED:
			_on_paired()
		RelayConnection.Status.CLOSED:
			var reason := _connection.get_error()
			_leave_lobby()
			_setup_screen().show_idle(DISCONNECTED_FORMAT % reason)


# Décision 0050 : le créateur joue A et démarre le duel ; celui qui rejoint attend sa préparation.
func _on_paired() -> void:
	if _lobby_step == LobbyStep.JOINING:
		var engine := DuelEngine.new(_catalog, _config)
		_guest_session = RemoteGuestSession.new(engine, _connection, _catalog.edition)
		_enter_lobby(LobbyStep.AWAITING_SETUP, AWAITING_HOST_TEXT)
		return
	var connection := _connection
	_connection = null
	_lobby_step = LobbyStep.NONE
	var duel_setup := _checked_setup(_remote_seed)
	if duel_setup == null:
		connection.close()
		return
	var host := DuelHost.new(DuelEngine.new(_catalog, _config))
	var session := RemoteHostSession.new(host, duel_setup, connection, _catalog.edition)
	_open_duel_screen().start_session(session, _catalog)


# Une incompatibilité arrive avec la préparation : elle passe avant le démarrage.
func _advance_guest_session() -> void:
	var is_ready := _guest_session.poll_until_ready()
	if _guest_session.get_session_state() == DuelSession.SessionState.DISCONNECTED:
		var reason := _guest_session.get_disconnection()
		_leave_lobby()
		_setup_screen().show_idle(DISCONNECTED_FORMAT % reason)
	elif is_ready:
		var session := _guest_session
		_guest_session = null
		_connection = null
		_lobby_step = LobbyStep.NONE
		_open_duel_screen().start_session(session, _catalog)


func _on_connection_lost(reason: String) -> void:
	_show_setup(DISCONNECTED_FORMAT % reason)


# Décisions 0036, 0050, 0066 et 0069 : `DuelSeries.rematch_returns_to_setup` ; sinon, decks et
# premier joueur de la partie libre restent ceux de l'hôte, la graine est tirée de nouveau.
func _on_rematch_requested() -> void:
	var duel_screen := _screen as DuelScreen
	var is_remote := duel_screen != null and duel_screen.is_remote()
	if _series.rematch_returns_to_setup(is_remote):
		_on_setup_requested()
		return
	_start_duel(DuelSeries.draw_seed())


func _on_setup_requested() -> void:
	_show_setup()


# Décision 0042 : la fiche se relit dans le journal de la partie, puis se remet au joueur.
func _on_sheet_requested() -> void:
	var duel_screen := _screen as DuelScreen
	if duel_screen == null:
		return
	var recorder := PlaytestRecorder.new(_catalog, _config)
	var date_text := Time.get_date_string_from_system()
	var sheet := recorder.record(
		duel_screen.get_journal(), _series.get_game_number(), date_text, _series.get_deck_names()
	)
	var saved_path := FileDownload.save_text(
		sheet.file_name(), sheet.to_csv(), PlaytestSheet.MIME_TYPE
	)
	if saved_path.is_empty():
		duel_screen.show_sheet_status(SHEET_FAILED_TEXT)
	else:
		duel_screen.show_sheet_status(SHEET_SAVED_FORMAT % saved_path)


func _show_load_error() -> void:
	_show_error(LOAD_ERROR_TEXT, false)


# `can_go_back` : un bouton « Retour » ramène à la préparation (préparation refusée).
func _show_error(message: String, can_go_back: bool) -> void:
	_replace_screen(null)
	_error_label.text = message
	_back_button.visible = can_go_back
	_error_box.visible = true


# Un seul écran enfant à la fois : l'ancien est retiré avant l'arrivée du nouveau ; un duel à
# distance quitté ferme sa connexion.
func _replace_screen(new_screen: Control) -> void:
	if _screen is DuelScreen:
		var duel_screen: DuelScreen = _screen
		duel_screen.close_session()
	if _screen != null:
		remove_child(_screen)
		_screen.queue_free()
	_error_box.visible = false
	_screen = new_screen
	if new_screen != null:
		add_child(new_screen)
