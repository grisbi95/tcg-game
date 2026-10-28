class_name SetupScreen
extends EntryScreen
## Écran de préparation (décision 0036, point 3) : « Nouvelle partie », la partie (du plan de série
## ou libre, décision 0069), le deck de chaque joueur et le premier joueur (imposés par une partie
## du plan, choisis par l'hôte en partie libre, décision 0066), la graine
## (affichée, modifiable, entier positif) et « Commencer ». Décisions 0043, 0050 et 0075 : « Créer
## une partie à distance » (le créateur joue A) ; « Rejoindre » est à l'accueil, d'où « Retour »
## revient. Le parent mène la connexion et dit où elle en est. Le parent donne les textes et reçoit
## la graine choisie ; aucune règle ici.

## L'hôte choisit une partie : son numéro dans le plan, `DuelSeries.NO_PLAN_GAME` pour la libre.
signal game_chosen(game_number: int)
## L'hôte donne au joueur `side` le deck `deck_index` de `Preparation.deck_labels`.
signal deck_chosen(side: DuelState.PlayerSide, deck_index: int)
## L'hôte choisit qui commence.
signal first_player_chosen(choice: DuelSeries.FirstPlayerChoice)
## « Commencer » est pressé, avec la graine du champ.
signal start_pressed(rng_seed: int)
## « Créer une partie à distance » est pressé, avec la graine du champ.
signal create_pressed(rng_seed: int)
## « Retour » est pressé : retour à l'accueil.
signal back_pressed

const MAX_SEED_DIGITS: int = 18
const TITLE_TEXT: String = "Nouvelle partie"
const GAME_TEXT: String = "Partie"
const FREE_GAME_TEXT: String = "Partie libre"
const FIRST_PLAYER_TEXT: String = "Commence"
const DRAWN_TEXT: String = "Tiré au sort"
const SEED_TEXT: String = "Graine"
const START_TEXT: String = "Commencer sur cet appareil"
const CREATE_TEXT: String = "Créer une partie à distance"
const BACK_TEXT: String = "Retour"

var _game_number: int = DuelSeries.NO_PLAN_GAME

@onready var _table: ColorRect = %Table
@onready var _title_label: Label = %TitleLabel
@onready var _game_label: Label = %GameLabel
@onready var _game_option: OptionButton = %GameOption
@onready var _first_player_label: Label = %FirstPlayerLabel
@onready var _first_player_option: OptionButton = %FirstPlayerOption
@onready var _seed_title_label: Label = %SeedTitleLabel
@onready var _seed_edit: LineEdit = %SeedEdit
@onready var _start_button: Button = %StartButton
@onready var _create_button: Button = %CreateButton
@onready var _back_button: Button = %BackButton
@onready var _player_labels: Dictionary[DuelState.PlayerSide, Label] = {
	DuelState.PlayerSide.A: %PlayerLabelA,
	DuelState.PlayerSide.B: %PlayerLabelB,
}
@onready var _deck_options: Dictionary[DuelState.PlayerSide, OptionButton] = {
	DuelState.PlayerSide.A: %DeckOptionA,
	DuelState.PlayerSide.B: %DeckOptionB,
}


## Ce que la préparation montre : les parties du plan (`plan_game_numbers` et leurs `plan_labels`,
## textes déjà formés), la partie choisie (`game_number`, `NO_PLAN_GAME` pour la libre), les decks
## proposés, le deck choisi de chaque joueur (index dans `deck_labels`), le premier joueur et la
## graine.
class Preparation:
	extends RefCounted
	var game_number: int = DuelSeries.NO_PLAN_GAME
	var plan_game_numbers: PackedInt32Array = PackedInt32Array()
	var plan_labels: PackedStringArray = PackedStringArray()
	var deck_labels: PackedStringArray = PackedStringArray()
	var deck_indexes: Dictionary[DuelState.PlayerSide, int] = {}
	var first_player_choice: DuelSeries.FirstPlayerChoice = DuelSeries.FirstPlayerChoice.PLAYER_A
	var rng_seed: int = 0


func _ready() -> void:
	_table.color = DuelPalette.TABLE_COLOR
	_title_label.text = TITLE_TEXT
	_game_label.text = GAME_TEXT
	_game_option.item_selected.connect(_on_game_selected)
	_setup_choice_controls()
	_seed_title_label.text = SEED_TEXT
	_start_button.text = START_TEXT
	_seed_edit.max_length = MAX_SEED_DIGITS
	_seed_edit.text_changed.connect(_on_seed_text_changed)
	_seed_edit.text_submitted.connect(_on_seed_submitted)
	_start_button.pressed.connect(_on_start_pressed)
	_setup_remote_controls()


## Montre la `preparation` : choix de l'hôte et graine proposée.
func show_preparation(preparation: Preparation) -> void:
	_fill_game_option(preparation)
	_seed_edit.text = str(preparation.rng_seed)
	show_game(preparation)


## Montre la partie choisie de la `preparation` : decks et premier joueur, libres ou imposés par le
## plan (décision 0069) ; la graine ne change pas.
func show_game(preparation: Preparation) -> void:
	_game_number = preparation.game_number
	_game_option.select(_game_option.get_item_index(preparation.game_number))
	for side: DuelState.PlayerSide in DuelState.SIDES:
		_fill_deck_option(side, preparation)
	_first_player_option.select(
		_first_player_option.get_item_index(preparation.first_player_choice)
	)
	show_idle()


## Décision 0069 : numéros des entrées du sélecteur de partie, la partie libre puis les parties du
## plan, dans l'ordre de `game_labels`.
static func game_numbers(preparation: Preparation) -> PackedInt32Array:
	var numbers := PackedInt32Array([DuelSeries.NO_PLAN_GAME])
	numbers.append_array(preparation.plan_game_numbers)
	return numbers


## Décision 0069 : libellés des entrées du sélecteur de partie, dans l'ordre de `game_numbers`.
static func game_labels(preparation: Preparation) -> PackedStringArray:
	var labels := PackedStringArray([FREE_GAME_TEXT])
	labels.append_array(preparation.plan_labels)
	return labels


## Décision 0069 : decks et premier joueur ne se choisissent qu'en partie libre (`game_number`),
## et seulement quand les choix sont ouverts (`are_controls_enabled`, rien en cours) ; une partie
## du plan les impose.
static func are_free_choices_enabled(game_number: int, are_controls_enabled: bool) -> bool:
	return are_controls_enabled and game_number == DuelSeries.NO_PLAN_GAME


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
	_first_player_option.add_item(
		PlayerNames.display_name(DuelState.PlayerSide.A), DuelSeries.FirstPlayerChoice.PLAYER_A
	)
	_first_player_option.add_item(
		PlayerNames.display_name(DuelState.PlayerSide.B), DuelSeries.FirstPlayerChoice.PLAYER_B
	)
	_first_player_option.add_item(DRAWN_TEXT, DuelSeries.FirstPlayerChoice.DRAWN)
	_first_player_option.item_selected.connect(_on_first_player_selected)


func _fill_game_option(preparation: Preparation) -> void:
	_game_option.clear()
	var numbers := game_numbers(preparation)
	var labels := game_labels(preparation)
	for index: int in numbers.size():
		_game_option.add_item(labels[index], numbers[index])


func _fill_deck_option(side: DuelState.PlayerSide, preparation: Preparation) -> void:
	var option := _deck_options[side]
	option.clear()
	for deck_label: String in preparation.deck_labels:
		option.add_item(deck_label)
	option.select(preparation.deck_indexes[side])


func _setup_remote_controls() -> void:
	_create_button.text = CREATE_TEXT
	_back_button.text = BACK_TEXT
	_create_button.pressed.connect(_on_create_pressed)
	_bind_entry_controls(%StatusLabel as Label, %CancelButton as Button)
	_back_button.pressed.connect(back_pressed.emit)


func _set_controls_enabled(is_enabled: bool) -> void:
	_back_button.visible = is_enabled
	var has_seed := not _seed_edit.text.is_empty()
	_start_button.disabled = not (is_enabled and has_seed)
	_create_button.disabled = not (is_enabled and has_seed)
	_seed_edit.editable = is_enabled
	_game_option.disabled = not is_enabled
	var is_free := are_free_choices_enabled(_game_number, is_enabled)
	_first_player_option.disabled = not is_free
	for option: OptionButton in _deck_options.values():
		option.disabled = not is_free


func _on_game_selected(item_index: int) -> void:
	game_chosen.emit(_game_option.get_item_id(item_index))


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
