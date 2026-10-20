extends Control
## Essai de ConcedeConfirmView (décision 0036) : la confirmation du joueur B sur un décor factice ;
## « Oui » et « Non » écrivent dans la sortie.

const CONFIRM_SCENE: PackedScene = preload("res://ui/components/concede_confirm_view.tscn")
const BACKDROP_TEXT: String = "Jeu en cours (décor factice)"


func _ready() -> void:
	var backdrop := VBoxContainer.new()
	TrySamples.frame(self, backdrop)
	var backdrop_label := Label.new()
	backdrop_label.text = BACKDROP_TEXT
	backdrop.add_child(backdrop_label)
	var confirm: ConcedeConfirmView = CONFIRM_SCENE.instantiate()
	add_child(confirm)
	confirm.show_confirm(DuelState.PlayerSide.B)
	confirm.concede_confirmed.connect(func() -> void: print("Abandon confirmé"))
	confirm.concede_cancelled.connect(func() -> void: print("Abandon annulé"))
