class_name StackView
extends VBoxContainer
## Pile (208 ; décisions 0028 et 0053) : une ligne par entrée, la dernière en haut, à la teinte
## de sa carte et liserée de la couleur de son joueur. Une entrée se presse quand la sélection la
## propose (cible d'un Contrecarrer, ordre des effets déclenchés), marquée d'un anneau jaune
## (DuelMarks) ; son survol montre sa carte dans l'aperçu. Une entrée peut porter le rang que le
## joueur lui a donné (décision 0032, ordre des effets déclenchés). La colonne de duel montre
## « Pile vide » à sa place quand elle n'a aucune entrée.

signal stack_entry_pressed(stack_entry_id: int)
signal stack_entry_hovered(stack_entry_id: int)
signal stack_entry_unhovered(stack_entry_id: int)

## Entrée de 200 × 52 (fiche E19) : liseré de camp de 5 px, vignette 30 × 38 à la teinte du type,
## nom en gras et ligne d'aide.
const ENTRY_HEIGHT: float = 52.0
const EDGE_WIDTH: float = 5.0
const THUMBNAIL_SIZE := Vector2(30.0, 38.0)
const THUMBNAIL_ICON_SIZE: float = 18.0
const THUMBNAIL_CUT: int = 4
## Pastille du rang choisi pour un effet déclenché (208.4.6) : un carré à coins coupés de 22 px à
## l'encre de la teinte, le chiffre à la couleur du fond de la teinte.
const ORDER_BADGE_SIZE: float = 22.0
const ORDER_BADGE_CUT: int = 5
const NO_ORDER: int = 0
const ENTRY_BORDER_WIDTH: int = 2


## Une entrée de la pile telle que l'écran la montre.
class StackLine:
	extends RefCounted
	var stack_entry_id: int = DuelState.NO_ID
	var label: String = ""
	var tint: DuelPalette.Tint = DuelPalette.Tint.SPELL
	var owner: DuelState.PlayerSide = DuelState.PlayerSide.A
	## Rang choisi par le joueur pendant l'ordre des effets déclenchés ; NO_ORDER sans pastille.
	var order_number: int = NO_ORDER
	## Ligne d'aide sous le nom : le type et le camp, ou le coup.
	var help: String = ""

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

	## Écrit la ligne d'aide et rend la ligne.
	func with_help(text: String) -> StackLine:
		help = text
		return self


## `lines` vont de la base au sommet de la pile ; `highlighted_ids` peuvent se presser.
func show_entries(lines: Array[StackLine], highlighted_ids: Array[int]) -> void:
	ViewNodes.free_children(self)
	for index: int in range(lines.size() - 1, -1, -1):
		var line := lines[index]
		add_child(_make_entry(line, highlighted_ids.has(line.stack_entry_id)))


func _make_entry(line: StackLine, is_highlighted: bool) -> PanelContainer:
	var entry := PanelContainer.new()
	entry.custom_minimum_size.y = ENTRY_HEIGHT
	var fill := DuelPalette.TINT_BACKGROUNDS[line.tint]
	var drawn := DuelPalette.framed_style(
		fill, DuelPalette.INK_COLOR, ENTRY_BORDER_WIDTH, float(ENTRY_BORDER_WIDTH)
	)
	entry.add_theme_stylebox_override(
		"panel",
		DuelAssets.ui_style(
			DuelAssets.STACK_ENTRY_IMAGE, drawn, DuelAssets.STACK_ENTRY_IMAGE_MARGIN, fill
		)
	)
	entry.add_child(_make_row(line))
	_connect_hover(entry, line.stack_entry_id)
	if is_highlighted:
		_connect_highlight(entry, line.stack_entry_id)
	return entry


func _make_row(line: StackLine) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.theme_type_variation = &"StackRow"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ink := DuelPalette.TINT_INKS[line.tint]
	row.add_child(_make_edge(DuelPalette.player_color(line.owner)))
	row.add_child(_make_thumbnail(line.tint))
	row.add_child(_make_texts(line, ink))
	if line.order_number != NO_ORDER:
		row.add_child(_make_order_badge(line.order_number, line.tint))
	return row


# Le liseré suit le coin coupé gauche de l'entrée.
func _make_edge(color: Color) -> PanelContainer:
	var edge := PanelContainer.new()
	edge.custom_minimum_size.x = EDGE_WIDTH
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := DuelPalette.fill_style(color, DuelPalette.CUT_SIZE, 0.0)
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_right = 0
	edge.add_theme_stylebox_override("panel", style)
	return edge


func _make_thumbnail(tint: DuelPalette.Tint) -> Control:
	var thumbnail := PanelContainer.new()
	thumbnail.custom_minimum_size = THUMBNAIL_SIZE
	thumbnail.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	thumbnail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	thumbnail.add_theme_stylebox_override(
		"panel", DuelPalette.fill_style(DuelPalette.TINT_INKS[tint], THUMBNAIL_CUT, 0.0)
	)
	thumbnail.add_child(_make_icon(tint, DuelPalette.TINT_BACKGROUNDS[tint]))
	return thumbnail


func _make_texts(line: StackLine, ink: Color) -> VBoxContainer:
	var texts := VBoxContainer.new()
	texts.theme_type_variation = &"StackTexts"
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.add_child(_make_label(line.label, ink, &"StackEntryLabel"))
	if not line.help.is_empty():
		texts.add_child(_make_label(line.help, ink, &"StackEntryHelpLabel"))
	return texts


func _make_order_badge(number: int, tint: DuelPalette.Tint) -> PanelContainer:
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2.ONE * ORDER_BADGE_SIZE
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.size_flags_horizontal = Control.SIZE_SHRINK_END
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_theme_stylebox_override(
		"panel", DuelPalette.fill_style(DuelPalette.TINT_INKS[tint], ORDER_BADGE_CUT, 0.0)
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
	icon.custom_minimum_size = Vector2.ONE * THUMBNAIL_ICON_SIZE
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	DuelIcons.bind(
		icon,
		func() -> DuelIcons.Icon: return DuelIcons.TINT_ICONS[tint],
		func() -> Color: return ink
	)
	return icon


func _make_label(text: String, ink: Color, look: StringName) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = look
	label.add_theme_color_override("font_color", ink)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
