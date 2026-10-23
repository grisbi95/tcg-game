extends Control
## Essai de l'écran de duel dans les situations rares (outil de développement) : les touches 1 à 7
## relancent l'écran sur un scénario de `DuelScenarios`, joué par des intentions validées par le
## moteur. `scenario` choisit celui du lancement.

const SCREEN_SCENE: PackedScene = preload("res://ui/duel_screen.tscn")
const SCENARIO_KEYS: Array[Key] = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7]

@export var scenario: DuelScenarios.Scenario = DuelScenarios.Scenario.CHOICE_TARGET

var _screen: DuelScreen


func _ready() -> void:
	_launch(scenario)


func _unhandled_key_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	var index := SCENARIO_KEYS.find(key_event.keycode)
	if index >= 0 and index < DuelScenarios.Scenario.size():
		_launch(index as DuelScenarios.Scenario)


func _launch(chosen: DuelScenarios.Scenario) -> void:
	if _screen != null:
		remove_child(_screen)
		_screen.queue_free()
	var data := DuelScenarios.build(chosen)
	if not data.is_reached:
		return
	print("Scénario %d : %s" % [chosen + 1, DuelScenarios.name_of(chosen)])
	_screen = SCREEN_SCENE.instantiate()
	add_child(_screen)
	_screen.start_duel(data.setup, data.config, data.catalog)
	_screen.play_scripted_intents(data.intents)
