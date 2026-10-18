extends Control
## Essai de SourcesView (décisions 0023 et 0028) : les Sources de A, pressables, compteurs
## au-dessus avec l'Essence et « Annuler » ; celles de B, non pressables, compteurs dessous. Les
## nombres sont factices : un clic ne fait qu'écrire dans la sortie.

const SOURCES_SCENE: PackedScene = preload("res://ui/components/sources_view.tscn")
const SLOT_COUNT: int = 10  # 203.5.7


func _ready() -> void:
	var column := VBoxContainer.new()
	TrySamples.frame(self, column)
	var other := _add_sources(column, DuelState.PlayerSide.B, false)
	other.show_sources(5, 0)
	other.show_supply(5, 0)
	other.set_interactive(false)
	var own := _add_sources(column, DuelState.PlayerSide.A, true)
	own.show_sources(4, 2)
	own.show_supply(3, 1)
	own.show_essence(2, true)


func _add_sources(column: VBoxContainer, owner: DuelState.PlayerSide, is_own: bool) -> SourcesView:
	var sources: SourcesView = SOURCES_SCENE.instantiate()
	column.add_child(sources)
	sources.setup(owner, is_own, SLOT_COUNT)
	sources.source_pressed.connect(
		func(is_tilted: bool) -> void: print("Source pressée, inclinée : ", is_tilted)
	)
	sources.cancel_pressed.connect(func() -> void: print("Annuler"))
	return sources
