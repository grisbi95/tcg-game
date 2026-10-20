class_name SetupScreen
extends Control
## Écran de préparation (décision 0036, point 3) : « Nouvelle partie », le numéro de la partie et
## le joueur qui commence, le deck et le Hero de chaque joueur, la graine (affichée, modifiable,
## entier positif) et « Commencer ». Le parent donne les textes et reçoit la graine choisie ; aucune
## règle ici.

## « Commencer » est pressé, avec la graine du champ.
signal start_pressed(rng_seed: int)

const MAX_SEED_DIGITS: int = 18
const TITLE_TEXT: String = "Nouvelle partie"
const GAME_FORMAT: String = "Partie %d ·"
const FIRST_PLAYER_FORMAT: String = "%s commence"
const PLAYER_LINE_FORMAT: String = "%s : %s · %s"
const SEED_TEXT: String = "Graine"
const START_TEXT: String = "Commencer"

@onready var _table: ColorRect = %Table
@onready var _panel: PanelContainer = %Panel
@onready var _title_label: Label = %TitleLabel
@onready var _game_label: Label = %GameLabel
@onready var _first_player_label: Label = %FirstPlayerLabel
@onready var _seed_title_label: Label = %SeedTitleLabel
@onready var _seed_edit: LineEdit = %SeedEdit
@onready var _start_button: Button = %StartButton
@onready var _player_labels: Dictionary[DuelState.PlayerSide, Label] = {
	DuelState.PlayerSide.A: %PlayerLabelA,
	DuelState.PlayerSide.B: %PlayerLabelB,
}


## Ce que la préparation dit d'un joueur : son deck et son Hero.
class PlayerLine:
	extends RefCounted
	var side: DuelState.PlayerSide = DuelState.PlayerSide.A
	var deck_name: String = ""
	var hero_name: String = ""

	func _init(player_side: DuelState.PlayerSide, deck: String, hero: String) -> void:
		side = player_side
		deck_name = deck
		hero_name = hero


func _ready() -> void:
	_table.color = DuelPalette.TABLE_COLOR
	_panel.add_theme_stylebox_override(
		"panel", DuelPalette.modal_style(DuelPalette.CELL_LINE_COLOR)
	)
	_title_label.text = TITLE_TEXT
	_title_label.add_theme_color_override("font_color", DuelPalette.INK_COLOR)
	_game_label.add_theme_color_override("font_color", DuelPalette.MUTED_COLOR)
	_seed_title_label.text = SEED_TEXT
	_seed_title_label.add_theme_color_override("font_color", DuelPalette.MUTED_COLOR)
	_start_button.text = START_TEXT
	_seed_edit.max_length = MAX_SEED_DIGITS
	_seed_edit.text_changed.connect(_on_seed_text_changed)
	_seed_edit.text_submitted.connect(_on_seed_submitted)
	_start_button.pressed.connect(_on_start_pressed)


## Montre la partie numéro `game_number`, que commence `first_player`, avec les `lines` de chaque
## joueur et la graine `rng_seed` proposée.
func show_preparation(
	game_number: int, first_player: DuelState.PlayerSide, lines: Array[PlayerLine], rng_seed: int
) -> void:
	_game_label.text = GAME_FORMAT % game_number
	_first_player_label.text = FIRST_PLAYER_FORMAT % PlayerNames.display_name(first_player)
	_first_player_label.add_theme_color_override("font_color", DuelPalette.player_ink(first_player))
	for line: PlayerLine in lines:
		var label := _player_labels[line.side]
		label.text = (
			PLAYER_LINE_FORMAT
			% [PlayerNames.display_name(line.side), line.deck_name, line.hero_name]
		)
		label.add_theme_color_override("font_color", DuelPalette.player_ink(line.side))
	_seed_edit.text = str(rng_seed)
	_start_button.disabled = false


static func _digits_only(text: String) -> String:
	var digits := ""
	for character: String in text:
		if character >= "0" and character <= "9":
			digits += character
	return digits


func _on_seed_text_changed(new_text: String) -> void:
	var digits := _digits_only(new_text)
	if digits != new_text:
		var caret := _seed_edit.caret_column - (new_text.length() - digits.length())
		_seed_edit.text = digits
		_seed_edit.caret_column = maxi(caret, 0)
	_start_button.disabled = digits.is_empty()


func _on_seed_submitted(_text: String) -> void:
	_on_start_pressed()


func _on_start_pressed() -> void:
	if _start_button.disabled:
		return
	start_pressed.emit(_seed_edit.text.to_int())
