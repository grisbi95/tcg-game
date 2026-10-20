class_name MainScreen
extends Control
## Scène racine (décision 0036, point 6) : enchaîne la préparation, le duel et sa fin, puis la
## partie suivante ou la préparation. Tient la suite des parties (`DuelSeries`) et n'affiche qu'un
## écran enfant à la fois ; aucun état global, aucune règle. Une erreur de lecture des cartes ou du
## deck s'affiche au lieu de planter.

const SETUP_SCENE: PackedScene = preload("res://ui/setup_screen.tscn")
const DUEL_SCENE: PackedScene = preload("res://ui/duel_screen.tscn")
const LOAD_ERROR_TEXT: String = "Impossible de charger le jeu : cartes ou deck de test en erreur."
const BACK_TEXT: String = "Retour"
const SETUP_ERROR_FORMAT: String = "Partie impossible : %s"

var _catalog: Catalog
var _series: DuelSeries
var _screen: Control

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
	var deck := GameLibrary.load_deck(_catalog)
	if deck == null:
		_show_load_error()
		return
	_series = DuelSeries.new(deck, deck)
	_show_setup()


func _show_setup() -> void:
	var setup_screen: SetupScreen = SETUP_SCENE.instantiate()
	_replace_screen(setup_screen)
	setup_screen.start_pressed.connect(_start_duel)
	setup_screen.show_preparation(
		_series.get_game_number(),
		_series.get_first_player(),
		_setup_lines(),
		DuelSeries.draw_seed()
	)


func _setup_lines() -> Array[SetupScreen.PlayerLine]:
	var lines: Array[SetupScreen.PlayerLine] = []
	for side: DuelState.PlayerSide in DuelState.SIDES:
		var deck := _series.get_deck(side)
		var hero := _catalog.get_hero(deck.hero_id)
		var hero_name := String(deck.hero_id) if hero == null else hero.hero_name
		lines.append(SetupScreen.PlayerLine.new(side, deck.deck_name, hero_name))
	return lines


func _start_duel(rng_seed: int) -> void:
	var duel_setup := _series.make_setup(rng_seed)
	var config := DuelConfig.new()
	var errors := duel_setup.find_errors(_catalog, config)
	if not errors.is_empty():
		_show_error(SETUP_ERROR_FORMAT % "\n".join(errors), true)
		return
	var duel_screen: DuelScreen = DUEL_SCENE.instantiate()
	_replace_screen(duel_screen)
	duel_screen.rematch_requested.connect(_on_rematch_requested)
	duel_screen.setup_requested.connect(_on_setup_requested)
	duel_screen.start_duel(duel_setup, config, _catalog)


# Décision 0036 : l'autre joueur commence, la graine est tirée de nouveau.
func _on_rematch_requested() -> void:
	_series.advance_to_next_game()
	_start_duel(DuelSeries.draw_seed())


func _on_setup_requested() -> void:
	_series.advance_to_next_game()
	_show_setup()


func _show_load_error() -> void:
	_show_error(LOAD_ERROR_TEXT, false)


# `can_go_back` : un bouton « Retour » ramène à la préparation (préparation refusée).
func _show_error(message: String, can_go_back: bool) -> void:
	_replace_screen(null)
	_error_label.text = message
	_back_button.visible = can_go_back
	_error_box.visible = true


# Un seul écran enfant à la fois : l'ancien est retiré avant l'arrivée du nouveau.
func _replace_screen(new_screen: Control) -> void:
	if _screen != null:
		remove_child(_screen)
		_screen.queue_free()
	_error_box.visible = false
	_screen = new_screen
	if new_screen != null:
		add_child(new_screen)
