extends Control
## Essai de SourcesView (décisions 0023, 0030 et 0032) : le bloc de B, non pressable, compteurs
## dessous ; le bloc de A, pressable, compteurs au-dessus. L'Essence est montrée dans les deux.
## Les nombres sont factices : un clic ne fait qu'écrire dans la sortie.

const SOURCES_SCENE: PackedScene = preload("res://ui/components/sources_view.tscn")
const SLOT_COUNT: int = 10  # 203.5.7
const B_ESSENCE: int = 3
const A_ESSENCE: int = 2


func _ready() -> void:
	var column := VBoxContainer.new()
	TrySamples.frame(self, column)
	var other := _add_sources(column, DuelState.PlayerSide.B, SourcesView.CounterPlacement.BELOW)
	other.show_sources(5, 0)
	other.show_supply(5, 0)
	other.show_essence(B_ESSENCE)
	other.set_interactive(false)
	var own := _add_sources(column, DuelState.PlayerSide.A, SourcesView.CounterPlacement.ABOVE)
	own.show_sources(4, 2)
	own.show_supply(3, 1)
	own.show_essence(A_ESSENCE)


func _add_sources(
	column: VBoxContainer,
	player: DuelState.PlayerSide,
	counter_placement: SourcesView.CounterPlacement
) -> SourcesView:
	var sources: SourcesView = SOURCES_SCENE.instantiate()
	column.add_child(sources)
	sources.setup(player, counter_placement, SLOT_COUNT)
	sources.source_pressed.connect(
		func(is_tilted: bool) -> void: print("Source pressée, inclinée : ", is_tilted)
	)
	return sources
