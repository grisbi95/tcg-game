class_name StackView
extends VBoxContainer
## Pile (208 ; décision 0028) : une ligne par entrée, la dernière en haut, à la teinte de sa carte
## et liserée de la couleur de son joueur. Une entrée se presse quand la sélection la propose
## (cible d'un Contrecarrer, ordre des effets déclenchés), marquée d'un anneau jaune (DuelMarks) ;
## son survol montre sa carte dans l'aperçu. Une entrée peut porter le rang que le joueur lui
## a donné (décision 0032, ordre des effets déclenchés). L'écran ne la montre que non vide.

signal stack_entry_pressed(stack_entry_id: int)
signal stack_entry_hovered(stack_entry_id: int)
signal stack_entry_unhovered(stack_entry_id: int)

const ICON_SIZE: float = 16.0
const PADDING: float = 8.0
## Pastille du rang choisi pour un effet déclenché (208.4.6) : un cercle de 22 px à l'encre de la
## teinte, le chiffre à la couleur du fond de la teinte.
const ORDER_BADGE_SIZE: float = 22.0
const ORDER_BADGE_RADIUS: int = 11
const NO_ORDER: int = 0


## Une entrée de la pile telle que l'écran la montre.
class StackLine:
	extends RefCounted
	var stack_entry_id: int = DuelState.NO_ID
	var label: String = ""
	var tint: DuelPalette.Tint = DuelPalette.Tint.SPELL
	var owner: DuelState.PlayerSide = DuelState.PlayerSide.A
	## Rang choisi par le joueur pendant l'ordre des effets déclenchés ; NO_ORDER sans pastille.
	var order_number: int = NO_ORDER

	func _init(
		entry_id: int, entry_label: String, entry_tint: DuelPalette.Tint, side: DuelState.PlayerSide
	) -> void:
		stack_entry_id = entry_id
		label = entry_label
		tint = entry_tint
		owner = side

	## Numérote la ligne et la rend (écriture en chaîne : `StackLine.new(...).with_order(1)`).
	func with_order(number: int) -> StackLine:
		order_number = number
		return self


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
	if line.order_number != NO_ORDER:
		row.add_child(_make_order_badge(line.order_number, line.tint))
	return row


func _make_order_badge(number: int, tint: DuelPalette.Tint) -> PanelContainer:
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2.ONE * ORDER_BADGE_SIZE
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_theme_stylebox_override(
		"panel", DuelPalette.fill_style(DuelPalette.TINT_INKS[tint], ORDER_BADGE_RADIUS, 0.0)
	)
	var label := Label.new()
	label.text = str(number)
	label.theme_type_variation = &"StackEntryLabel"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", DuelPalette.TINT_BACKGROUNDS[tint])
	badge.add_child(label)
	return badge


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
