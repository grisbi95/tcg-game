extends GdUnitTestSuite
## Écrans d'entrée (décision 0075), sans relais : l'accueil (`HomeScreen`) et la préparation
## (`SetupScreen`) instanciés seuls, leurs commandes lues par nom unique. Exception assumée à
## « aucune suite n'instancie de scène » (`tests/CLAUDE.md`) : la décision porte sur des commandes.

const HOME_SCENE: PackedScene = preload("res://ui/home_screen.tscn")
const SETUP_SCENE: PackedScene = preload("res://ui/setup_screen.tscn")
const LOWER_CODE: String = "ab3z"
const UPPER_CODE: String = "AB3Z"
const SHORT_CODE: String = "AB3"
const STATUS_TEXT: String = "Connexion au relais…"

var _home: HomeScreen
var _setup: SetupScreen


func before_test() -> void:
	_home = HOME_SCENE.instantiate()
	add_child(_home)
	_setup = SETUP_SCENE.instantiate()
	add_child(_setup)


func after_test() -> void:
	_home.free()
	_setup.free()


func test_decision_0075_home_join_is_disabled_without_a_full_code() -> void:
	assert_bool(_button(_home, "JoinButton").disabled).is_true()
	_type_code(SHORT_CODE)
	assert_bool(_button(_home, "JoinButton").disabled).is_true()
	_type_code(UPPER_CODE)
	assert_bool(_button(_home, "JoinButton").disabled).is_false()


func test_decision_0075_home_code_is_uppercased() -> void:
	_type_code(LOWER_CODE)
	assert_str(_line_edit(_home, "CodeEdit").text).is_equal(UPPER_CODE)


func test_decision_0075_home_join_emits_the_code() -> void:
	var codes: Array[String] = []
	_home.join_pressed.connect(func(code: String) -> void: codes.append(code))
	_type_code(LOWER_CODE)
	_button(_home, "JoinButton").pressed.emit()
	assert_array(codes).is_equal([UPPER_CODE])


func test_decision_0075_home_enter_in_the_code_field_joins_only_with_a_full_code() -> void:
	var codes: Array[String] = []
	_home.join_pressed.connect(func(code: String) -> void: codes.append(code))
	_type_code(SHORT_CODE)
	_line_edit(_home, "CodeEdit").text_submitted.emit(SHORT_CODE)
	assert_array(codes).is_empty()
	_type_code(UPPER_CODE)
	_line_edit(_home, "CodeEdit").text_submitted.emit(UPPER_CODE)
	assert_array(codes).is_equal([UPPER_CODE])


func test_decision_0075_home_new_game_emits_its_signal() -> void:
	var counts: Array[int] = [0]
	_home.new_game_pressed.connect(func() -> void: counts[0] += 1)
	_button(_home, "NewGameButton").pressed.emit()
	assert_int(counts[0]).is_equal(1)


func test_decision_0075_home_connecting_greys_the_controls_and_shows_cancel() -> void:
	_type_code(UPPER_CODE)
	_home.show_connecting(STATUS_TEXT)
	assert_bool(_button(_home, "NewGameButton").disabled).is_true()
	assert_bool(_button(_home, "JoinButton").disabled).is_true()
	assert_bool(_line_edit(_home, "CodeEdit").editable).is_false()
	assert_bool(_button(_home, "CancelButton").visible).is_true()
	assert_str(_label(_home, "StatusLabel").text).is_equal(STATUS_TEXT)
	assert_bool(_label(_home, "StatusLabel").visible).is_true()


func test_decision_0075_home_idle_reopens_the_controls_and_hides_cancel() -> void:
	_type_code(UPPER_CODE)
	_home.show_connecting(STATUS_TEXT)
	_home.show_idle()
	assert_bool(_button(_home, "NewGameButton").disabled).is_false()
	assert_bool(_button(_home, "JoinButton").disabled).is_false()
	assert_bool(_line_edit(_home, "CodeEdit").editable).is_true()
	assert_bool(_button(_home, "CancelButton").visible).is_false()
	assert_bool(_label(_home, "StatusLabel").visible).is_false()


func test_decision_0075_home_cancel_emits_its_signal() -> void:
	var counts: Array[int] = [0]
	_home.cancel_pressed.connect(func() -> void: counts[0] += 1)
	_home.show_connecting(STATUS_TEXT)
	_button(_home, "CancelButton").pressed.emit()
	assert_int(counts[0]).is_equal(1)


func test_decision_0075_setup_has_no_code_field_nor_join_button() -> void:
	assert_object(_setup.find_child("CodeEdit", true, false)).is_null()
	assert_object(_setup.find_child("JoinButton", true, false)).is_null()
	assert_object(_setup.find_child("RemoteTitleLabel", true, false)).is_null()
	assert_bool(_setup.has_signal("join_pressed")).is_false()


func test_decision_0075_setup_back_emits_its_signal() -> void:
	var counts: Array[int] = [0]
	_setup.back_pressed.connect(func() -> void: counts[0] += 1)
	_button(_setup, "BackButton").pressed.emit()
	assert_int(counts[0]).is_equal(1)


func test_decision_0075_setup_hides_back_while_connecting_and_shows_cancel() -> void:
	_setup.show_idle()
	assert_bool(_button(_setup, "BackButton").visible).is_true()
	assert_bool(_button(_setup, "CancelButton").visible).is_false()
	_setup.show_connecting(STATUS_TEXT)
	assert_bool(_button(_setup, "BackButton").visible).is_false()
	assert_bool(_button(_setup, "CancelButton").visible).is_true()
	assert_str(_label(_setup, "StatusLabel").text).is_equal(STATUS_TEXT)
	_setup.show_idle()
	assert_bool(_button(_setup, "BackButton").visible).is_true()
	assert_bool(_button(_setup, "CancelButton").visible).is_false()


func test_decision_0075_both_entry_screens_answer_to_entry_screen() -> void:
	assert_bool(_home is EntryScreen).is_true()
	assert_bool(_setup is EntryScreen).is_true()


func _type_code(code: String) -> void:
	var code_edit := _line_edit(_home, "CodeEdit")
	code_edit.text = code
	code_edit.text_changed.emit(code)


func _button(screen: Control, node_name: String) -> Button:
	return screen.find_child(node_name, true, false) as Button


func _line_edit(screen: Control, node_name: String) -> LineEdit:
	return screen.find_child(node_name, true, false) as LineEdit


func _label(screen: Control, node_name: String) -> Label:
	return screen.find_child(node_name, true, false) as Label
