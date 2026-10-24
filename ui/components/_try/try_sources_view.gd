extends Control
## Essai de SourcesView (décisions 0023, 0030, 0032 et 0053) : le bloc de B, non pressable, compteur
## dessous ; le bloc de A, pressable, compteur au-dessus. Le bloc de A montre les quatre états des
## emplacements (4 redressées, 2 inclinées, 3 en réserve, 1 en Fonte), celui de B 5 redressées et
## 5 en réserve. L'Essence est montrée dans les deux.
## Les nombres sont factices : un clic ne fait qu'écrire dans la sortie.

const SOURCES_SCENE: PackedScene = preload("res://ui/components/sources_view.tscn")
const B_ESSENCE: int = 3
const A_ESSENCE: int = 2


func _ready() -> void:
	var column := VBoxContainer.new()
	TrySamples.frame(self, column)
	var other := _add_sources(column, DuelState.PlayerSide.B, SourcesView.CounterPlacement.BELOW)
	other.show_sources(5, 0, 5, 0)
	other.show_essence(B_ESSENCE)
	other.set_interactive(false)
	var own := _add_sources(column, DuelState.PlayerSide.A, SourcesView.CounterPlacement.ABOVE)
	own.show_sources(4, 2, 3, 1)
	own.show_essence(A_ESSENCE)


func _add_sources(
	column: VBoxContainer,
	player: DuelState.PlayerSide,
	counter_placement: SourcesView.CounterPlacement
) -> SourcesView:
	var sources: SourcesView = SOURCES_SCENE.instantiate()
	column.add_child(sources)
	sources.setup(player, counter_placement, DuelConfig.new().total_sources_per_player)
	sources.source_pressed.connect(
		func(is_tilted: bool) -> void: print("Source pressée, inclinée : ", is_tilted)
	)
	return sources
