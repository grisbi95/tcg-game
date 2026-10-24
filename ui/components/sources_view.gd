class_name SourcesView
extends VBoxContainer
## Sources d'un joueur (203 ; décisions 0023, 0028 et 0053, fiche E13 à E15) : un emplacement par
## Source du joueur (203.5.7), en rangées de cinq, chacun dans l'un de quatre états, remplis dans
## cet ordre : en jeu redressée, en jeu inclinée (estompée, sans pivoter, 201.4.4), en réserve
## (contour pointillé, 201.4.5) et dans la Fonte (barrée d'une croix, estompée, 201.4.6). Un clic
## sur une Source redressée la presse ; au survol d'une Source inclinée, un bouton « Recycler +1 »
## la presse. Un seul compteur : l'Essence (la réserve du joueur, publique, 203.6 ; ou son paiement
## préparé pendant le tour adverse, décision 0032). Aucun « Annuler » : un coup joué est définitif.

signal source_pressed(is_tilted: bool)

## Ajouter à la fin, sans réordonner.
enum SlotState {
	UPRIGHT,
	TILTED,
	RESERVE,
	FONTE,
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
const CROSS_MARGIN: float = 22.0
const CHIP_PADDING: float = 6.0

var _player: DuelState.PlayerSide = DuelState.PlayerSide.A
var _is_interactive: bool = true
var _slots: Array[SourceSlot] = []

@onready var _counters: HBoxContainer = %Counters
@onready var _essence_chip: PanelContainer = %EssenceChip
@onready var _essence_icon: Control = %EssenceIcon
@onready var _essence_label: Label = %EssenceLabel
@onready var _essence_value: Label = %EssenceValue
@onready var _slot_grid: GridContainer = %SlotGrid


## Un emplacement : son état et les nœuds qui l'affichent.
class SourceSlot:
	extends RefCounted
	var state: SlotState = SlotState.RESERVE
	var panel: PanelContainer
	var icon: Control
	var recycle_button: Button


## Bornes des états le long des emplacements : redressées, inclinées, réserve, puis Fonte.
class SlotLimits:
	extends RefCounted
	var upright_end: int
	var tilted_end: int
	var fonte_start: int
	var fonte_end: int

	func _init(upright: int, tilted: int, in_reserve: int, in_fonte: int) -> void:
		upright_end = upright
		tilted_end = upright + tilted
		fonte_start = tilted_end + in_reserve
		fonte_end = fonte_start + in_fonte


func _ready() -> void:
	DuelIcons.bind(
		_essence_icon,
		func() -> DuelIcons.Icon: return DuelIcons.Icon.ESSENCE,
		func() -> Color: return DuelPalette.ESSENCE_COLOR
	)
	_essence_chip.add_theme_stylebox_override(
		"panel",
		DuelPalette.framed_style(
			DuelPalette.ESSENCE_BACKGROUND,
			DuelPalette.ESSENCE_COLOR,
			DuelPalette.LINE_WIDTH,
			CHIP_PADDING
		)
	)
	for label: Label in [_essence_label, _essence_value]:
		label.add_theme_color_override("font_color", DuelPalette.ESSENCE_COLOR)


## Sources du joueur `player`, compteurs à `counter_placement` du bloc ; `slot_count` : Sources
## d'un joueur (203.5.7). Le compteur Essence part à 0.
func setup(
	player: DuelState.PlayerSide, counter_placement: CounterPlacement, slot_count: int
) -> void:
	_player = player
	move_child(_counters, 0 if counter_placement == CounterPlacement.ABOVE else 1)
	ViewNodes.free_children(_slot_grid)
	_slots.clear()
	for index: int in slot_count:
		var slot := _make_slot(index)
		_slots.append(slot)
		_slot_grid.add_child(slot.panel)
	show_essence(0)
	show_sources(0, 0, slot_count, 0)


## Les emplacements dans l'ordre : `upright` Sources redressées, `tilted` inclinées, `in_reserve`
## en réserve puis `in_fonte` dans la Fonte ; un emplacement au-delà de ce total reste en réserve.
func show_sources(upright: int, tilted: int, in_reserve: int, in_fonte: int) -> void:
	var limits := SlotLimits.new(upright, tilted, in_reserve, in_fonte)
	for index: int in _slots.size():
		_slots[index].state = _slot_state_at(index, limits)
		_refresh_slot(index, false)


## `essence` montrée dans le bloc : la réserve du joueur (203.6), ou, pendant le tour adverse, le
## paiement préparé de celui qui a l'appareil (décision 0032).
func show_essence(essence: int) -> void:
	_essence_value.text = str(essence)


## Sources pressables seulement quand le joueur devant l'écran peut s'en servir.
func set_interactive(is_interactive: bool) -> void:
	_is_interactive = is_interactive
	for index: int in _slots.size():
		_refresh_slot(index, false)


func _slot_state_at(index: int, limits: SlotLimits) -> SlotState:
	if index < limits.upright_end:
		return SlotState.UPRIGHT
	if index < limits.tilted_end:
		return SlotState.TILTED
	if index >= limits.fonte_start and index < limits.fonte_end:
		return SlotState.FONTE
	return SlotState.RESERVE


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
	panel.draw.connect(func() -> void: _draw_slot_marks(index))
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
	slot.icon.visible = slot.state == SlotState.UPRIGHT or slot.state == SlotState.TILTED
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
		SlotState.RESERVE:
			slot.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		SlotState.FONTE:
			slot.modulate.a = DuelPalette.DIMMED_ALPHA
			slot.add_theme_stylebox_override(
				"panel", _slot_style(DuelPalette.PANEL_COLOR, DuelPalette.CELL_LINE_COLOR)
			)


func _slot_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := DuelPalette.framed_style(background, border, SLOT_BORDER_WIDTH, 0.0)
	style.set_corner_radius_all(SLOT_RADIUS)
	return style


func _draw_slot_marks(index: int) -> void:
	var slot := _slots[index]
	match slot.state:
		SlotState.RESERVE:
			DashedOutline.draw(slot.panel, slot.panel.size)
		SlotState.FONTE:
			_draw_cross(slot.panel)


func _draw_cross(canvas: Control) -> void:
	var corner := Vector2.ONE * CROSS_MARGIN
	var far := canvas.size - corner
	canvas.draw_line(corner, far, DuelPalette.MUTED_COLOR, DuelPalette.BORDER_WIDTH, true)
	var other_start := Vector2(far.x, corner.y)
	var other_end := Vector2(corner.x, far.y)
	canvas.draw_line(
		other_start, other_end, DuelPalette.MUTED_COLOR, DuelPalette.BORDER_WIDTH, true
	)


func _player_border() -> Color:
	return DuelPalette.player_color(_player)


# Godot signale la sortie quand le pointeur passe sur le bouton enfant : rester survolé tant qu'il
# est dans l'emplacement.
func _is_pointer_inside(slot: Control) -> bool:
	return Rect2(Vector2.ZERO, slot.size).has_point(slot.get_local_mouse_position())
