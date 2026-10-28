extends Control
## Essai de HomeScreen (décision 0075) : l'accueil seul. Les signals écrivent dans la sortie ;
## « Rejoindre » passe à l'attente, « Annuler » rend l'accueil libre.

const HOME_SCENE: PackedScene = preload("res://ui/home_screen.tscn")
const WAITING_TEXT: String = "Partie rejointe ; en attente de l'hôte…"


func _ready() -> void:
	var home: HomeScreen = HOME_SCENE.instantiate()
	add_child(home)
	home.new_game_pressed.connect(func() -> void: print("Nouvelle partie"))
	home.join_pressed.connect(
		func(code: String) -> void:
			print("Rejoindre ", code)
			home.show_connecting(WAITING_TEXT)
	)
	home.cancel_pressed.connect(
		func() -> void:
			print("Annuler")
			home.show_idle()
	)
