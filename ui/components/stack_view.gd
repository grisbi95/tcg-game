class_name StackView
extends VBoxContainer
## Pile (208 ; décision 0028) : une ligne par entrée, la dernière en haut, à la teinte de sa carte
## et liserée de la couleur de son joueur. Une entrée se presse quand la sélection la propose
## (cible d'un Contrecarrer, ordre des effets déclenchés), marquée d'un anneau jaune (DuelMarks) ;
## son survol montre sa carte dans l'aperçu. L'écran ne la montre que non vide.

signal stack_entry_pressed(stack_entry_id: int)
signal stack_entry_hovered(stack_entry_id: int)
signal stack_entry_unhovered(stack_entry_id: int)

const ICON_SIZE: float = 16.0
const PADDING: float = 8.0


## Une entrée de la pile telle que l'écran la montre.
class StackLine:
	extends RefCounted
	var stack_entry_id: int = DuelState.NO_ID
	var label: String = ""
	var tint: DuelPalette.Tint = DuelPalette.Tint.SPELL
	var owner: DuelState.PlayerSide = DuelState.PlayerSide.A

	func _init(
		entry_id: int, entry_label: String, entry_tint: DuelPalette.Tint, side: DuelState.PlayerSide
	) -> void:
		stack_entry_id = entry_id
		label = entry_label
		tint = entry_tint
		owner = side


## `lines` vont de la base au sommet de la pile ; `highlighted_ids` peuvent se presser.
func show_entries(lines: Array[StackLine], highlighted_ids: Array[int]) -> void:
	ViewNodes.free_children(self)
	for index: int in range(lines.size() - 1, -1, -1):
		var line := lines[index]
		add_child(_make_entry(line, highlighted_ids.has(line.stack_entry_id)))


func _make_entry(line: StackLine, is_highlighted: bool) -> PanelContainer:
	var entry := _make_frame(line)
	entry.add_child(_make_row(line))
	_connect_hover(entry, line.stack_entry_id)
	if is_highlighted:
		_connect_highlight(entry, line.stack_entry_id)
	return entry


func _make_frame(line: StackLine) -> PanelContainer:
	var entry := PanelContainer.new()
	var border := DuelPalette.player_color(line.owner)
	entry.add_theme_stylebox_override(
		"panel",
		DuelPalette.tinted_style(line.tint, border, DuelPalette.PLAYER_BORDER_WIDTH, PADDING)
	)
	return entry


func _make_row(line: StackLine) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.theme_type_variation = &"CardRow"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ink := DuelPalette.TINT_INKS[line.tint]
	row.add_child(_make_icon(line.tint, ink))
	row.add_child(_make_label(line.label, ink))
	return row


func _make_icon(tint: DuelPalette.Tint, ink: Color) -> Control:
	var icon := Control.new()
	icon.custom_minimum_size = Vector2.ONE * ICON_SIZE
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	DuelIcons.bind(
		icon,
		func() -> DuelIcons.Icon: return DuelIcons.TINT_ICONS[tint],
		func() -> Color: return ink
	)
	return icon


func _make_label(text: String, ink: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"StackEntryLabel"
	label.add_theme_color_override("font_color", ink)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.clip_text = true
	return label


func _connect_hover(entry: PanelContainer, stack_entry_id: int) -> void:
	entry.mouse_entered.connect(func() -> void: stack_entry_hovered.emit(stack_entry_id))
	entry.mouse_exited.connect(func() -> void: stack_entry_unhovered.emit(stack_entry_id))


func _connect_highlight(entry: PanelContainer, stack_entry_id: int) -> void:
	entry.draw.connect(
		func() -> void:
			var rect := Rect2(Vector2.ZERO, entry.size)
			DuelMarks.draw(entry, rect, DuelMarks.Mark.HIGHLIGHTED, 0.0)
	)
	entry.gui_input.connect(
		func(event: InputEvent) -> void:
			if ViewInput.is_left_click(event):
				stack_entry_pressed.emit(stack_entry_id)
	)
