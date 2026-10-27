class_name SetupScreen
extends Control
## Écran de préparation (décision 0036, point 3) : « Nouvelle partie », le numéro de la partie, le
## deck de chaque joueur et le premier joueur, choisis par l'hôte (décision 0066), la graine
## (affichée, modifiable, entier positif) et « Commencer ». Décisions 0043 et 0050 : « Créer une
## partie à distance » (le créateur joue A) ou « Rejoindre » par le code de la partie (B) ; le
## parent mène la connexion et dit où elle en est. Le parent donne les textes et reçoit la graine
## choisie ; aucune règle ici.

## L'hôte donne au joueur `side` le deck `deck_index` de `Preparation.deck_labels`.
signal deck_chosen(side: DuelState.PlayerSide, deck_index: int)
## L'hôte choisit qui commence.
signal first_player_chosen(choice: DuelSeries.FirstPlayerChoice)
## « Commencer » est pressé, avec la graine du champ.
signal start_pressed(rng_seed: int)
## « Créer une partie à distance » est pressé, avec la graine du champ.
signal create_pressed(rng_seed: int)
## « Rejoindre » est pressé, avec le code saisi.
signal join_pressed(code: String)
## « Annuler » est pressé pendant la connexion au relais.
signal cancel_pressed

const MAX_SEED_DIGITS: int = 18
const TITLE_TEXT: String = "Nouvelle partie"
const GAME_FORMAT: String = "Partie %d ·"
const FIRST_PLAYER_TEXT: String = "Commence"
const DRAWN_TEXT: String = "Tiré au sort"
const SEED_TEXT: String = "Graine"
const START_TEXT: String = "Commencer sur cet appareil"
const REMOTE_TITLE_TEXT: String = "À distance"
const CREATE_TEXT: String = "Créer une partie à distance"
const JOIN_TEXT: String = "Rejoindre"
const CODE_PLACEHOLDER: String = "Code"
const CANCEL_TEXT: String = "Annuler"
## Longueur d'un code de partie du relais (`tools/relay/server.js`).
const CODE_LENGTH: int = 4

@onready var _table: ColorRect = %Table
@onready var _panel: PanelContainer = %Panel
@onready var _title_label: Label = %TitleLabel
@onready var _game_label: Label = %GameLabel
@onready var _first_player_label: Label = %FirstPlayerLabel
@onready var _first_player_option: OptionButton = %FirstPlayerOption
@onready var _seed_title_label: Label = %SeedTitleLabel
@onready var _seed_edit: LineEdit = %SeedEdit
@onready var _start_button: Button = %StartButton
@onready var _remote_title_label: Label = %RemoteTitleLabel
@onready var _create_button: Button = %CreateButton
@onready var _code_edit: LineEdit = %CodeEdit
@onready var _join_button: Button = %JoinButton
@onready var _status_label: Label = %StatusLabel
@onready var _cancel_button: Button = %CancelButton
@onready var _player_labels: Dictionary[DuelState.PlayerSide, Label] = {
	DuelState.PlayerSide.A: %PlayerLabelA,
	DuelState.PlayerSide.B: %PlayerLabelB,
}
@onready var _deck_options: Dictionary[DuelState.PlayerSide, OptionButton] = {
	DuelState.PlayerSide.A: %DeckOptionA,
	DuelState.PlayerSide.B: %DeckOptionB,
}


## Ce que la préparation montre : le numéro de la partie, les decks proposés (textes déjà formés),
## le deck choisi de chaque joueur (index dans `deck_labels`), le premier joueur et la graine.
class Preparation:
	extends RefCounted
	var game_number: int = 1
	var deck_labels: PackedStringArray = PackedStringArray()
	var deck_indexes: Dictionary[DuelState.PlayerSide, int] = {}
	var first_player_choice: DuelSeries.FirstPlayerChoice = DuelSeries.FirstPlayerChoice.PLAYER_A
	var rng_seed: int = 0


func _ready() -> void:
	_table.color = DuelPalette.TABLE_COLOR
	_panel.add_theme_stylebox_override(
		"panel", DuelPalette.modal_style(DuelPalette.CELL_LINE_COLOR)
	)
	_title_label.text = TITLE_TEXT
	_title_label.add_theme_color_override("font_color", DuelPalette.INK_COLOR)
	_game_label.add_theme_color_override("font_color", DuelPalette.MUTED_COLOR)
	_setup_choice_controls()
	_seed_title_label.text = SEED_TEXT
	_seed_title_label.add_theme_color_override("font_color", DuelPalette.MUTED_COLOR)
	_start_button.text = START_TEXT
	_seed_edit.max_length = MAX_SEED_DIGITS
	_seed_edit.text_changed.connect(_on_seed_text_changed)
	_seed_edit.text_submitted.connect(_on_seed_submitted)
	_start_button.pressed.connect(_on_start_pressed)
	_setup_remote_controls()


## Montre la `preparation` : choix de l'hôte et graine proposée.
func show_preparation(preparation: Preparation) -> void:
	_game_label.text = GAME_FORMAT % preparation.game_number
	for side: DuelState.PlayerSide in DuelState.SIDES:
		_fill_deck_option(side, preparation)
	_first_player_option.select(
		_first_player_option.get_item_index(preparation.first_player_choice)
	)
	_seed_edit.text = str(preparation.rng_seed)
	show_idle()


## Rien en cours : les choix sont ouverts ; `status` dit, s'il n'est pas vide, ce qui s'est passé
## (connexion perdue, code inconnu).
func show_idle(status: String = "") -> void:
	_set_controls_enabled(true)
	_cancel_button.visible = false
	_show_status(status)


## Connexion au relais en cours, ou attente de l'autre joueur : `status` le dit, « Annuler » arrête.
func show_connecting(status: String) -> void:
	_set_controls_enabled(false)
	_cancel_button.visible = true
	_show_status(status)


static func _digits_only(text: String) -> String:
	var digits := ""
	for character: String in text:
		if character >= "0" and character <= "9":
			digits += character
	return digits


func _setup_choice_controls() -> void:
	for side: DuelState.PlayerSide in DuelState.SIDES:
		var label := _player_labels[side]
		label.text = PlayerNames.display_name(side)
		label.add_theme_color_override("font_color", DuelPalette.player_ink(side))
		_deck_options[side].item_selected.connect(_on_deck_selected.bind(side))
	_first_player_label.text = FIRST_PLAYER_TEXT
	_first_player_label.add_theme_color_override("font_color", DuelPalette.MUTED_COLOR)
	_first_player_option.add_item(
		PlayerNames.display_name(DuelState.PlayerSide.A), DuelSeries.FirstPlayerChoice.PLAYER_A
	)
	_first_player_option.add_item(
		PlayerNames.display_name(DuelState.PlayerSide.B), DuelSeries.FirstPlayerChoice.PLAYER_B
	)
	_first_player_option.add_item(DRAWN_TEXT, DuelSeries.FirstPlayerChoice.DRAWN)
	_first_player_option.item_selected.connect(_on_first_player_selected)


func _fill_deck_option(side: DuelState.PlayerSide, preparation: Preparation) -> void:
	var option := _deck_options[side]
	option.clear()
	for deck_label: String in preparation.deck_labels:
		option.add_item(deck_label)
	option.select(preparation.deck_indexes[side])


func _setup_remote_controls() -> void:
	_remote_title_label.text = REMOTE_TITLE_TEXT
	_remote_title_label.add_theme_color_override("font_color", DuelPalette.MUTED_COLOR)
	_create_button.text = CREATE_TEXT
	_join_button.text = JOIN_TEXT
	_cancel_button.text = CANCEL_TEXT
	_code_edit.placeholder_text = CODE_PLACEHOLDER
	_code_edit.max_length = CODE_LENGTH
	_status_label.add_theme_color_override("font_color", DuelPalette.INK_COLOR)
	_create_button.pressed.connect(_on_create_pressed)
	_join_button.pressed.connect(_on_join_pressed)
	_code_edit.text_changed.connect(_on_code_text_changed)
	_code_edit.text_submitted.connect(_on_code_submitted)
	_cancel_button.pressed.connect(cancel_pressed.emit)


func _set_controls_enabled(is_enabled: bool) -> void:
	var has_seed := not _seed_edit.text.is_empty()
	_start_button.disabled = not (is_enabled and has_seed)
	_create_button.disabled = not (is_enabled and has_seed)
	_join_button.disabled = not (is_enabled and _code_edit.text.length() == CODE_LENGTH)
	_seed_edit.editable = is_enabled
	_first_player_option.disabled = not is_enabled
	for option: OptionButton in _deck_options.values():
		option.disabled = not is_enabled
	_code_edit.editable = is_enabled


func _show_status(status: String) -> void:
	_status_label.text = status
	_status_label.visible = not status.is_empty()


func _on_deck_selected(deck_index: int, side: DuelState.PlayerSide) -> void:
	deck_chosen.emit(side, deck_index)


func _on_first_player_selected(item_index: int) -> void:
	var choice: DuelSeries.FirstPlayerChoice = _first_player_option.get_item_id(item_index)
	first_player_chosen.emit(choice)


func _on_seed_text_changed(new_text: String) -> void:
	var digits := _digits_only(new_text)
	if digits != new_text:
		var caret := _seed_edit.caret_column - (new_text.length() - digits.length())
		_seed_edit.text = digits
		_seed_edit.caret_column = maxi(caret, 0)
	_start_button.disabled = digits.is_empty()
	_create_button.disabled = digits.is_empty()


func _on_seed_submitted(_text: String) -> void:
	_on_start_pressed()


func _on_start_pressed() -> void:
	if _start_button.disabled:
		return
	start_pressed.emit(_seed_edit.text.to_int())


func _on_create_pressed() -> void:
	if not _create_button.disabled:
		create_pressed.emit(_seed_edit.text.to_int())


# Le code se dicte en majuscules (relais) ; les minuscules saisies y sont ramenées.
func _on_code_text_changed(new_text: String) -> void:
	var upper := new_text.to_upper()
	if upper != new_text:
		var caret := _code_edit.caret_column
		_code_edit.text = upper
		_code_edit.caret_column = caret
	_join_button.disabled = upper.length() != CODE_LENGTH


func _on_code_submitted(_text: String) -> void:
	_on_join_pressed()


func _on_join_pressed() -> void:
	if not _join_button.disabled:
		join_pressed.emit(_code_edit.text)
