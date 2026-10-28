class_name HomeScreen
extends EntryScreen
## Écran d'accueil (décision 0075, fiche `docs/fiches/ecrans-d-entree.md`) : le titre du jeu,
## « Nouvelle partie » qui ouvre la préparation, et « Rejoindre » une partie à distance par son code
## (décisions 0043 et 0050). Le parent mène la connexion et dit où elle en est ; aucune règle ici.

## « Nouvelle partie » est pressé.
signal new_game_pressed
## « Rejoindre » est pressé, avec le code saisi.
signal join_pressed(code: String)

## Titre provisoire : le jeu n'a pas encore de nom.
const TITLE_TEXT: String = "TOURNOI"
const SUBTITLE_TEXT: String = "DUEL SUR UN SOL DE 5 × 5"
const NEW_GAME_TEXT: String = "Nouvelle partie"
const JOIN_TITLE_TEXT: String = "REJOINDRE UNE PARTIE"
const JOIN_TEXT: String = "Rejoindre"
const CODE_PLACEHOLDER: String = "Code"
## Longueur d'un code de partie du relais (`tools/relay/server.js`).
const CODE_LENGTH: int = 4

@onready var _table: ColorRect = %Table
@onready var _title_label: Label = %TitleLabel
@onready var _subtitle_label: Label = %SubtitleLabel
@onready var _new_game_button: Button = %NewGameButton
@onready var _join_title_label: Label = %JoinTitleLabel
@onready var _code_edit: LineEdit = %CodeEdit
@onready var _join_button: Button = %JoinButton


func _ready() -> void:
	_table.color = DuelPalette.TABLE_COLOR
	_title_label.text = TITLE_TEXT
	_subtitle_label.text = SUBTITLE_TEXT
	_new_game_button.text = NEW_GAME_TEXT
	_join_title_label.text = JOIN_TITLE_TEXT
	_join_button.text = JOIN_TEXT
	_code_edit.placeholder_text = CODE_PLACEHOLDER
	_code_edit.max_length = CODE_LENGTH
	_new_game_button.pressed.connect(new_game_pressed.emit)
	_join_button.pressed.connect(_on_join_pressed)
	_code_edit.text_changed.connect(_on_code_text_changed)
	_code_edit.text_submitted.connect(_on_code_submitted)
	_bind_entry_controls(%StatusLabel as Label, %CancelButton as Button)
	show_idle()


func _set_controls_enabled(is_enabled: bool) -> void:
	_new_game_button.disabled = not is_enabled
	_code_edit.editable = is_enabled
	_join_button.disabled = not (is_enabled and _code_edit.text.length() == CODE_LENGTH)


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
