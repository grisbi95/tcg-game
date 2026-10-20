extends Control
## Essai de RelayCurtainView (décision 0036) : le rideau de chaque joueur, à la taille de la main du
## bas. Un clic sur « Voir ma main » cache le rideau et l'écrit dans la sortie.

const CURTAIN_SCENE: PackedScene = preload("res://ui/components/relay_curtain_view.tscn")
const SPACING: int = 16


func _ready() -> void:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", SPACING)
	TrySamples.frame(self, column)
	for side: DuelState.PlayerSide in DuelState.SIDES:
		_add_curtain(column, side)


func _add_curtain(column: VBoxContainer, side: DuelState.PlayerSide) -> void:
	var curtain: RelayCurtainView = CURTAIN_SCENE.instantiate()
	column.add_child(curtain)
	curtain.setup(HandView.AREA_SIZE)
	curtain.show_relay(side)
	curtain.relay_confirmed.connect(
		func() -> void:
			print("Relais confirmé : ", PlayerNames.display_name(side))
			curtain.hide_relay()
	)
