class_name DuelAssets
extends RefCounted
## Assets du jeu (décisions 0051 et 0071) : rangés par sorte dans `res://assets/`, retrouvés par
## leur nom. Un asset absent rend `null` et l'appelant garde son repli : l'icône du type pour une
## illustration (0027), le dessin de `DuelIcons` pour une icône, le style dessiné du thème pour un
## cadre ou un fond. Un seul mécanisme pour les images de l'écran de duel (fiche § 7) : `ui_style`
## pour un cadre, `skin_theme` pour les cadres du thème, `show_table` pour la table. Le moteur et
## `data/` ne connaissent aucune image.

const ROOT_DIRECTORY: String = "res://assets/"
const CARD_ART_DIRECTORY: String = ROOT_DIRECTORY + "cards/art/"
const ICON_DIRECTORY: String = ROOT_DIRECTORY + "icons/"
const UI_DIRECTORY: String = ROOT_DIRECTORY + "ui/"
const CARD_ART_EXTENSION: String = ".webp"
const ICON_EXTENSION: String = ".svg"
const UI_EXTENSION: String = ".png"
const TABLE_EXTENSION: String = ".webp"
const TABLE_NAME: String = "table"
## Images de `assets/ui/` de la fiche § 7 : leur nom et la marge de leur 9-patch, en pixels.
const COLUMN_PANEL_IMAGE: String = "column_panel"
const COLUMN_PANEL_IMAGE_MARGIN: int = 16
const STACK_EMPTY_IMAGE: String = "stack_empty"
const STACK_EMPTY_IMAGE_MARGIN: int = 12
const STACK_ENTRY_IMAGE: String = "stack_entry"
const STACK_ENTRY_IMAGE_MARGIN: int = 8
const COUNTER_IMAGE: String = "counter"
const COUNTER_IMAGE_MARGIN: int = 8
const BOARD_FRAME_IMAGE: String = "board_frame"
const BOARD_FRAME_IMAGE_MARGIN: int = 20
const TOOLTIP_PANEL_IMAGE: String = "tooltip_panel"
const TOOLTIP_PANEL_IMAGE_MARGIN: int = 12
const TIME_BAR_FILL_IMAGE: String = "time_bar_fill"
const TIME_BAR_TRACK_IMAGE: String = "time_bar_track"
const TIME_BAR_IMAGE_MARGIN: int = 3
## Les images à plusieurs états : préfixe, puis `normal`, `hover`, `pressed` (et `disabled`).
const BUTTON_ICON_IMAGE_PREFIX: String = "button_icon_"
const BUTTON_ICON_IMAGE_MARGIN: int = 6
const BUTTON_MODAL_IMAGE_PREFIX: String = "button_modal_"
const BUTTON_MODAL_IMAGE_MARGIN: int = 16
const BUTTON_BIG_IMAGE_PREFIX: String = "button_big_"
const BUTTON_BIG_IMAGE_MARGIN: int = 16
const MODAL_PANEL_IMAGE: String = "modal_panel"
const MODAL_PANEL_IMAGE_MARGIN: int = 32
## Métadonnée du thème : le dessin d'origine d'un cadre, gardé avant qu'une image le remplace.
const DRAWN_META_PREFIX: String = "drawn_style_"

## Chemin cherché → texture, `null` compris : un asset absent ne se recherche qu'une fois.
static var _textures: Dictionary[String, Texture2D] = {}
## Cadres du thème remplaçables par une image (fiche § 7), avec leur marge de 9-patch.
static var _theme_slots: Array[ThemeSlot] = _make_theme_slots()


## Un cadre du thème et l'image qui peut le remplacer.
class ThemeSlot:
	extends RefCounted
	var theme_type: StringName
	var style_name: StringName
	var file_name: String
	var margin: int
	var is_tinted_by_fill: bool

	func _init(type_name: StringName, style: StringName, file: String) -> void:
		theme_type = type_name
		style_name = style
		file_name = file

	## Marge du 9-patch, en pixels.
	func with_margin(image_margin: int) -> ThemeSlot:
		margin = image_margin
		return self

	## L'image est en blanc : elle prend la couleur du fond du dessin qu'elle remplace.
	func tinted() -> ThemeSlot:
		is_tinted_by_fill = true
		return self


## Illustration de la carte ou du Hero d'identifiant `definition_id`, ou `null` sans fichier.
static func card_art(definition_id: StringName) -> Texture2D:
	if definition_id.is_empty():
		return null
	return _texture(card_art_path(definition_id))


## Chemin de l'illustration de `definition_id` : son identifiant dans `data/cards/`.
static func card_art_path(definition_id: StringName) -> String:
	return CARD_ART_DIRECTORY + String(definition_id) + CARD_ART_EXTENSION


## Icône `icon_name`, nom rendu par `DuelIcons.asset_name`, dessinée en blanc et teintée au
## dessin, ou `null` sans fichier.
static func icon(icon_name: String) -> Texture2D:
	return _texture(ICON_DIRECTORY + icon_name + ICON_EXTENSION)


## Image `ui/<image_name>.png` de la fiche § 7, ou `null` sans fichier.
static func ui_image(image_name: String) -> Texture2D:
	return _texture(UI_DIRECTORY + image_name + UI_EXTENSION)


## Chemin de l'image de la table (E01).
static func table_path() -> String:
	return UI_DIRECTORY + TABLE_NAME + TABLE_EXTENSION


## Le cadre `ui/<image_name>.png` en 9-patch de marge `margin`, teinté de `tint`, s'il existe ;
## sinon `fallback`, le dessin du thème. Les marges de contenu restent celles de `fallback`, pour
## que la mise en page ne change pas.
static func ui_style(
	image_name: String, fallback: StyleBox, margin: int = 0, tint: Color = Color.WHITE
) -> StyleBox:
	var texture := ui_image(image_name)
	if texture == null:
		return fallback
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.modulate_color = tint
	for side: Side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_texture_margin(side, margin)
		style.set_content_margin(side, fallback.get_margin(side))
	return style


## Cadres du thème qu'une image peut remplacer (fiche § 7).
static func theme_slots() -> Array[ThemeSlot]:
	return _theme_slots


## Remplace dans `theme` chaque cadre dont l'image existe (décision 0071) ; les autres gardent
## leur dessin. Sûr à rappeler sur un même thème (ressource en cache) : le dessin d'origine est
## gardé dans ses métadonnées et sert de repli et de teinte à chaque appel.
static func skin_theme(theme: Theme) -> void:
	for slot: ThemeSlot in _theme_slots:
		if not theme.has_stylebox(slot.style_name, slot.theme_type):
			continue
		var drawn := _drawn_style(theme, slot)
		var tint := Color.WHITE
		var flat := drawn as StyleBoxFlat
		if slot.is_tinted_by_fill and flat != null:
			tint = flat.bg_color
		var skinned := ui_style(slot.file_name, drawn, slot.margin, tint)
		if skinned != drawn:
			theme.set_stylebox(slot.style_name, slot.theme_type, skinned)


## Montre dans `image` la table `ui/table.webp` ; sans elle, `fallback` (la couleur de table).
static func show_table(image: TextureRect, fallback: Control) -> void:
	var texture := _texture(table_path())
	image.texture = texture
	image.visible = texture != null
	fallback.visible = texture == null


## Montre dans `image` l'illustration de `definition_id` ; sans elle, l'icône `fallback_icon`.
static func show_card_art(
	image: TextureRect, fallback_icon: Control, definition_id: StringName
) -> void:
	_show_art(image, fallback_icon, card_art(definition_id))


## Un jeton n'a pas d'illustration : `image` est vidée, `fallback_icon` montrée.
static func show_no_art(image: TextureRect, fallback_icon: Control) -> void:
	_show_art(image, fallback_icon, null)


## Pour les essais : fait trouver `texture` (ou rien, si `null`) au chemin `path`, sans fichier.
static func use_texture(path: String, texture: Texture2D) -> void:
	_textures[path] = texture


## Pour les essais : oublie les textures cherchées ou imposées, pour relire les fichiers.
static func forget_textures() -> void:
	_textures.clear()


static func _drawn_style(theme: Theme, slot: ThemeSlot) -> StyleBox:
	var key := DRAWN_META_PREFIX + String(slot.theme_type) + "_" + String(slot.style_name)
	if not theme.has_meta(key):
		theme.set_meta(key, theme.get_stylebox(slot.style_name, slot.theme_type))
	var drawn: StyleBox = theme.get_meta(key)
	return drawn


static func _make_theme_slots() -> Array[ThemeSlot]:
	var slots: Array[ThemeSlot] = [
		ThemeSlot.new(&"ColumnPanel", &"panel", COLUMN_PANEL_IMAGE).with_margin(
			COLUMN_PANEL_IMAGE_MARGIN
		),
		ThemeSlot.new(&"StackArea", &"panel", STACK_EMPTY_IMAGE).with_margin(
			STACK_EMPTY_IMAGE_MARGIN
		),
		ThemeSlot.new(&"EssenceChip", &"panel", COUNTER_IMAGE).with_margin(COUNTER_IMAGE_MARGIN),
		ThemeSlot.new(&"BoardGrid", &"panel", BOARD_FRAME_IMAGE).with_margin(
			BOARD_FRAME_IMAGE_MARGIN
		),
		ThemeSlot.new(&"InfoBubblePanel", &"panel", TOOLTIP_PANEL_IMAGE).with_margin(
			TOOLTIP_PANEL_IMAGE_MARGIN
		),
	]
	for bar: StringName in [&"TimerBarA", &"TimerBarB", &"TimerBarAlert"]:
		var fill := ThemeSlot.new(bar, &"fill", TIME_BAR_FILL_IMAGE)
		var track := ThemeSlot.new(bar, &"background", TIME_BAR_TRACK_IMAGE)
		slots.append(fill.with_margin(TIME_BAR_IMAGE_MARGIN).tinted())
		slots.append(track.with_margin(TIME_BAR_IMAGE_MARGIN).tinted())
	for state: String in ["normal", "hover", "pressed"]:
		var icon_slot := ThemeSlot.new(
			&"ConcedeButton", StringName(state), BUTTON_ICON_IMAGE_PREFIX + state
		)
		slots.append(icon_slot.with_margin(BUTTON_ICON_IMAGE_MARGIN))
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		var modal_slot := ThemeSlot.new(
			&"ModalButton", StringName(state), BUTTON_MODAL_IMAGE_PREFIX + state
		)
		slots.append(modal_slot.with_margin(BUTTON_MODAL_IMAGE_MARGIN))
	return slots


static func _show_art(image: TextureRect, fallback_icon: Control, texture: Texture2D) -> void:
	image.texture = texture
	image.visible = texture != null
	fallback_icon.visible = texture == null


static func _texture(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(path) as Texture2D if ResourceLoader.exists(path) else null
	return _textures[path]
