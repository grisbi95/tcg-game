extends Control
## Essai de EndPanelView (décision 0036) : le panneau de fin sur un décor factice ; les trois
## boutons écrivent dans la sortie.

const PANEL_SCENE: PackedScene = preload("res://ui/components/end_panel_view.tscn")
const BACKDROP_TEXT: String = "Jeu figé (décor factice)"
const TITLE_TEXT: String = "Victoire du joueur A"
const REASON_TEXT: String = "Le joueur B abandonne"
const DETAILS_TEXT: String = "Tour 7 · 12 min 4 s"
const SHEET_STATUS_TEXT: String = "Fiche enregistrée : ~/playtest/fiche-partie-1-graine-42.csv"


func _ready() -> void:
	var backdrop := VBoxContainer.new()
	TrySamples.frame(self, backdrop)
	var backdrop_label := Label.new()
	backdrop_label.text = BACKDROP_TEXT
	backdrop.add_child(backdrop_label)
	var panel: EndPanelView = PANEL_SCENE.instantiate()
	add_child(panel)
	panel.show_end(DuelState.DuelResult.PLAYER_A_WINS, TITLE_TEXT, REASON_TEXT, DETAILS_TEXT)
	panel.rematch_pressed.connect(func() -> void: print("Rejouer pressé"))
	panel.setup_pressed.connect(func() -> void: print("Préparation pressée"))
	panel.sheet_pressed.connect(func() -> void: panel.show_sheet_status(SHEET_STATUS_TEXT))
	panel.show_sheet_status(SHEET_STATUS_TEXT)
