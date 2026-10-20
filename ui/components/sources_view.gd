class_name SourcesView
extends VBoxContainer
## Sources d'un joueur (203 ; décisions 0023 et 0028) : dix emplacements en deux rangées de cinq,
## vides en pointillé ; une Source inclinée est estompée, sans pivoter. Un clic sur une Source
## redressée la presse ; au survol d'une Source inclinée, un bouton « Recycler +1 » la presse.
## Compteurs lisibles : Essence (la réserve du joueur, publique, 203.6 ; ou son paiement préparé
## pendant le tour adverse, décision 0032), Réserve et Fonte (203.5). Aucun « Annuler » : un coup
## joué est définitif.

signal source_pressed(is_tilted: bool)

## Ajouter à la fin, sans réordonner.
enum SlotState {
	UPRIGHT,
	TILTED,
	EMPTY,
}

## Place des compteurs : au-dessus pour le bloc du bas, en dessous pour celui du haut (0030).
## Ajouter à la fin, sans réordonner.
enum CounterPlacement {
	ABOVE,
	BELOW,
}

const SLOT_SIZE := Vector2(74, 106)
const SOURCE_ICON_SIZE: float = 30.0
const SLOT_RADIUS: int = 7
const SLOT_BORDER_WIDTH: int = 2
const RECYCLE_TEXT: String = "Recycler +1"
const RECYCLE_MARGIN: float = 4.0
const RECYCLE_HEIGHT: float = 26.0
const CHIP_PADDING: float = 6.0

var _player: DuelState.PlayerSide = DuelState.PlayerSide.A
var _is_interactive: bool = true
var _slots: Array[SourceSlot] = []

@onready var _counters: HBoxContainer = %Counters
@onready var _essence_chip: PanelContainer = %EssenceChip
@onready var _essence_icon: Control = %EssenceIcon
@onready var _essence_label: Label = %EssenceLabel
@onready var _essence_value: Label = %EssenceValue
@onready var _reserve_chip: PanelContainer = %ReserveChip
@onready var _reserve_value: Label = %ReserveValue
@onready var _fonte_chip: PanelContainer = %FonteChip
@onready var _fonte_value: Label = %FonteValue
@onready var _slot_grid: GridContainer = %SlotGrid


## Un emplacement : son état et les nœuds qui l'affichent.
class SourceSlot:
	extends RefCounted
	var state: SlotState = SlotState.EMPTY
	var panel: PanelContainer
	var icon: Control
	var recycle_button: Button


func _ready() -> void:
	var counter := DuelPalette.framed_style(
		DuelPalette.COUNTER_COLOR,
		DuelPalette.COUNTER_LINE_COLOR,
		DuelPalette.LINE_WIDTH,
		CHIP_PADDING
	)
	DuelIcons.bind(
		_essence_icon,
		func() -> DuelIcons.Icon: return DuelIcons.Icon.SOURCE,
		func() -> Color: return DuelPalette.ESSENCE_COLOR
	)
	_reserve_chip.add_theme_stylebox_override("panel", counter)
	_fonte_chip.add_theme_stylebox_override("panel", counter)
	_essence_chip.add_theme_stylebox_override(
		"panel",
		DuelPalette.framed_style(
			DuelPalette.ESSENCE_BACKGROUND, DuelPalette.ESSENCE_COLOR, 1, CHIP_PADDING
		)
	)
	for label: Label in [_essence_label, _essence_value]:
		label.add_theme_color_override("font_color", DuelPalette.ESSENCE_COLOR)


## Sources du joueur `player`, compteurs à `counter_placement` du bloc ; `slot_count` : Sources
## d'un joueur (203.5.7). Le compteur Essence est montré, à 0, jusqu'à `hide_essence`.
func setup(
	player: DuelState.PlayerSide, counter_placement: CounterPlacement, slot_count: int
) -> void:
	_player = player
	_essence_chip.visible = true
	move_child(_counters, 0 if counter_placement == CounterPlacement.ABOVE else 1)
	ViewNodes.free_children(_slot_grid)
	_slots.clear()
	for index: int in slot_count:
		var slot := _make_slot(index)
		_slots.append(slot)
		_slot_grid.add_child(slot.panel)
	show_essence(0)
	show_sources(0, 0)


## Sources en jeu, `upright` redressées puis `tilted` inclinées ; les autres emplacements vides.
func show_sources(upright: int, tilted: int) -> void:
	for index: int in _slots.size():
		var state := SlotState.EMPTY
		if index < upright:
			state = SlotState.UPRIGHT
		elif index < upright + tilted:
			state = SlotState.TILTED
		_slots[index].state = state
		_refresh_slot(index, false)


## 203.5 : Sources pas encore en jeu (Réserve) et Sources recyclées (Fonte).
func show_supply(sources_in_reserve: int, sources_in_fonte: int) -> void:
	_reserve_value.text = str(sources_in_reserve)
	_fonte_value.text = str(sources_in_fonte)


## `essence` montrée dans le bloc : la réserve du joueur (203.6), ou, pendant le tour adverse, le
## paiement préparé de celui qui a l'appareil (décision 0032).
func show_essence(essence: int) -> void:
	_essence_value.text = str(essence)
	_essence_chip.visible = true


## Cache le compteur Essence quand le bloc n'a rien à y montrer.
func hide_essence() -> void:
	_essence_chip.visible = false


## Sources pressables seulement quand le joueur devant l'écran peut s'en servir.
func set_interactive(is_interactive: bool) -> void:
	_is_interactive = is_interactive
	for index: int in _slots.size():
		_refresh_slot(index, false)


func _make_slot(index: int) -> SourceSlot:
	var slot := SourceSlot.new()
	slot.panel = PanelContainer.new()
	slot.panel.custom_minimum_size = SLOT_SIZE
	var overlay := Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.panel.add_child(overlay)
	slot.icon = _make_source_icon()
	overlay.add_child(slot.icon)
	slot.recycle_button = _make_recycle_button()
	overlay.add_child(slot.recycle_button)
	var panel := slot.panel
	panel.mouse_entered.connect(func() -> void: _refresh_slot(index, true))
	panel.mouse_exited.connect(func() -> void: _refresh_slot(index, _is_pointer_inside(panel)))
	panel.gui_input.connect(func(event: InputEvent) -> void: _on_slot_input(index, event))
	panel.draw.connect(func() -> void: _draw_empty_outline(index))
	return slot


func _make_source_icon() -> Control:
	var icon := Control.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_preset(Control.PRESET_CENTER)
	var half := SOURCE_ICON_SIZE / 2.0
	icon.offset_left = -half
	icon.offset_top = -half
	icon.offset_right = half
	icon.offset_bottom = half
	DuelIcons.bind(
		icon,
		func() -> DuelIcons.Icon: return DuelIcons.Icon.SOURCE,
		func() -> Color: return DuelPalette.player_ink(_player)
	)
	return icon


func _make_recycle_button() -> Button:
	var button := Button.new()
	button.text = RECYCLE_TEXT
	button.theme_type_variation = &"SmallButton"
	button.anchor_left = 0.0
	button.anchor_right = 1.0
	button.anchor_top = 1.0
	button.anchor_bottom = 1.0
	button.offset_left = RECYCLE_MARGIN
	button.offset_right = -RECYCLE_MARGIN
	button.offset_top = -RECYCLE_MARGIN - RECYCLE_HEIGHT
	button.offset_bottom = -RECYCLE_MARGIN
	for state: String in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(
			state, DuelPalette.fill_style(DuelPalette.INK_COLOR, SLOT_RADIUS, 0.0)
		)
	for color: String in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(color, DuelPalette.CARD_TEXT_COLOR)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func() -> void: source_pressed.emit(true))
	return button


# Décision 0028 : seule une Source redressée se presse par un clic ; une Source inclinée se recycle
# par son bouton.
func _on_slot_input(index: int, event: InputEvent) -> void:
	if not ViewInput.is_left_click(event) or not _is_interactive:
		return
	if _slots[index].state == SlotState.UPRIGHT:
		source_pressed.emit(false)
		_slots[index].panel.accept_event()


func _refresh_slot(index: int, is_hovered: bool) -> void:
	var slot := _slots[index]
	var is_lit := is_hovered and _is_interactive
	slot.icon.visible = slot.state != SlotState.EMPTY
	slot.recycle_button.visible = slot.state == SlotState.TILTED and is_lit
	_apply_slot_style(slot.panel, slot.state, is_lit)
	slot.panel.queue_redraw()


func _apply_slot_style(slot: PanelContainer, state: SlotState, is_lit: bool) -> void:
	slot.modulate.a = 1.0
	match state:
		SlotState.UPRIGHT:
			var background := DuelPalette.SOURCE_HOVER_COLOR if is_lit else DuelPalette.SOURCE_COLOR
			slot.add_theme_stylebox_override("panel", _slot_style(background, _player_border()))
		SlotState.TILTED:
			if not is_lit:
				slot.modulate.a = DuelPalette.DIMMED_ALPHA
			slot.add_theme_stylebox_override(
				"panel", _slot_style(DuelPalette.PANEL_COLOR, DuelPalette.SOURCE_TILTED_LINE_COLOR)
			)
		SlotState.EMPTY:
			slot.add_theme_stylebox_override("panel", StyleBoxEmpty.new())


func _slot_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := DuelPalette.framed_style(background, border, SLOT_BORDER_WIDTH, 0.0)
	style.set_corner_radius_all(SLOT_RADIUS)
	return style


func _draw_empty_outline(index: int) -> void:
	var slot := _slots[index]
	if slot.state == SlotState.EMPTY:
		DashedOutline.draw(slot.panel, slot.panel.size)


func _player_border() -> Color:
	return DuelPalette.player_color(_player)


# Godot signale la sortie quand le pointeur passe sur le bouton enfant : rester survolé tant qu'il
# est dans l'emplacement.
func _is_pointer_inside(slot: Control) -> bool:
	return Rect2(Vector2.ZERO, slot.size).has_point(slot.get_local_mouse_position())
