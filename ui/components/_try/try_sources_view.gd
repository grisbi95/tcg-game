extends Control
## Essai de SourcesView : les Sources de A (3 redressées, 2 inclinées), pressables, et celles de
## B, non pressables. Les nombres sont factices : un clic ne fait qu'écrire dans la sortie.

const SOURCES_SCENE: PackedScene = preload("res://ui/components/sources_view.tscn")


func _ready() -> void:
	var column := VBoxContainer.new()
	TrySamples.frame(self, column)
	var own := _add_sources(column, DuelState.PlayerSide.A)
	own.show_sources(3, 2)
	own.show_supply(5, 0, 2)
	var other := _add_sources(column, DuelState.PlayerSide.B)
	other.show_sources(1, 1)
	other.show_supply(7, 1, 0)
	other.set_interactive(false)


func _add_sources(column: VBoxContainer, owner: DuelState.PlayerSide) -> SourcesView:
	var sources: SourcesView = SOURCES_SCENE.instantiate()
	column.add_child(sources)
	sources.setup(owner)
	sources.source_pressed.connect(
		func(is_tilted: bool) -> void: print("Source pressée, inclinée : ", is_tilted)
	)
	return sources
