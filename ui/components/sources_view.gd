class_name SourcesView
extends PanelContainer
## Sources d'un joueur (203, décision 0023) : une Source redressée est verticale, une Source
## inclinée horizontale ; chacune se presse. Dessous, sa réserve de Sources, sa Fonte et sa
## réserve d'Essence, visible des deux joueurs (201.4.10).

signal source_pressed(is_tilted: bool)

const UPRIGHT_SIZE := Vector2(28, 52)
const TILTED_SIZE := Vector2(52, 28)

var _is_interactive: bool = true
var _owner_color: Color = DuelPalette.NEUTRAL_COLOR

@onready var _source_row: HBoxContainer = %SourceRow
@onready var _supply_label: Label = %SupplyLabel


## Couleur du cadre : celle du joueur `owner`.
func setup(owner: DuelState.PlayerSide) -> void:
	_owner_color = DuelPalette.player_color(owner)
	add_theme_stylebox_override("panel", DuelPalette.panel_style(_owner_color, false))


## Sources en jeu à montrer, `upright` redressées puis `tilted` inclinées.
func show_sources(upright: int, tilted: int) -> void:
	ViewNodes.free_children(_source_row)
	for index: int in upright:
		_source_row.add_child(_make_source(false))
	for index: int in tilted:
		_source_row.add_child(_make_source(true))


## 203.5, 203.6.1 : Sources pas encore en jeu, Sources en Fonte, Essence de la réserve d'Essence.
func show_supply(sources_in_reserve: int, sources_in_fonte: int, essence_reserve: int) -> void:
	_supply_label.text = (
		"Réserve %d · Fonte %d · Essence %d"
		% [sources_in_reserve, sources_in_fonte, essence_reserve]
	)


## Sources pressables seulement quand le joueur devant l'écran peut s'en servir.
func set_interactive(is_interactive: bool) -> void:
	_is_interactive = is_interactive
	for child: Node in _source_row.get_children():
		(child as Button).disabled = not is_interactive


func _make_source(is_tilted: bool) -> Button:
	var source := Button.new()
	source.custom_minimum_size = TILTED_SIZE if is_tilted else UPRIGHT_SIZE
	source.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	source.tooltip_text = "Source inclinée" if is_tilted else "Source redressée"
	source.disabled = not _is_interactive
	var style := DuelPalette.source_style(_owner_color, is_tilted)
	for state: String in ["normal", "pressed", "disabled", "focus"]:
		source.add_theme_stylebox_override(state, style)
	var hover := DuelPalette.source_style(
		_owner_color.lightened(DuelPalette.HOVER_LIGHTENING), is_tilted
	)
	source.add_theme_stylebox_override("hover", hover)
	source.pressed.connect(func() -> void: source_pressed.emit(is_tilted))
	return source
