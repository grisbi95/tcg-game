class_name DuelPalette
extends RefCounted
## Couleurs et cadres des composants (décision 0025) : un cadre coloré par joueur, et des bordures
## qui signalent ce qui peut être choisi ou ce qui est choisi.

const PLAYER_A_COLOR := Color("3a7bd5")
const PLAYER_B_COLOR := Color("d5523a")
const NEUTRAL_COLOR := Color("5a5f6b")
const PANEL_COLOR := Color("1f2229")
const HIGHLIGHT_COLOR := Color("f2c14e")
const SELECTED_COLOR := Color("4ecb71")
const RUNNING_COLOR := Color("f2c14e")
const BORDER_WIDTH: int = 2
const MARKED_BORDER_WIDTH: int = 5
const CORNER_RADIUS: int = 8
const SOURCE_CORNER_RADIUS: int = 4
## Variations de Label déclarées dans ui/theme/duel_theme.tres (décision 0025, thème unique).
const SMALL_LABEL: StringName = &"SmallLabel"
const LARGE_LABEL: StringName = &"LargeLabel"
const CARD_TEXT_LABEL: StringName = &"CardTextLabel"
const LARGE_CARD_TEXT_LABEL: StringName = &"LargeCardTextLabel"
const CONTENT_MARGIN: int = 8
## Décision 0025 : une Source inclinée est plus sombre que sa couleur de joueur.
const TILTED_DARKENING: float = 0.45
const HOVER_LIGHTENING: float = 0.25


static func player_color(side: DuelState.PlayerSide) -> Color:
	return PLAYER_A_COLOR if side == DuelState.PlayerSide.A else PLAYER_B_COLOR


## Cadre d'un composant : bordure `border`, plus épaisse s'il est surligné ou choisi.
static func panel_style(border: Color, is_marked: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.border_color = border
	style.set_border_width_all(MARKED_BORDER_WIDTH if is_marked else BORDER_WIDTH)
	style.set_corner_radius_all(CORNER_RADIUS)
	style.set_content_margin_all(CONTENT_MARGIN)
	return style


## Fond plein d'une Source du joueur de couleur `color`, plus sombre si elle est inclinée.
static func source_style(color: Color, is_tilted: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color.darkened(TILTED_DARKENING) if is_tilted else color
	style.set_corner_radius_all(SOURCE_CORNER_RADIUS)
	return style


## Bordure d'un élément selon qu'il est choisi, surligné, ou ni l'un ni l'autre.
static func marked_border(base: Color, is_highlighted: bool, is_selected: bool) -> Color:
	if is_selected:
		return SELECTED_COLOR
	if is_highlighted:
		return HIGHLIGHT_COLOR
	return base
