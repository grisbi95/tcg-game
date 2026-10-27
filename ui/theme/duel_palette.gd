class_name DuelPalette
extends RefCounted
## Couleurs et cadres des composants, selon la bible « Vestiaire » (décisions 0070 et 0071,
## `docs/direction-artistique/bible.md`) : fond sombre et chaud, papier pour le plateau et les
## cartes, trait d'encre, coins coupés, ombres en aplat. Les teintes des cinq types de carte et les
## couleurs fixes des joueurs (décision 0027) y sont aussi, avec la fabrique de cadres. Survol,
## surlignage et choix sont des anneaux tracés par `DuelMarks`.

## Ajouter à la fin, sans réordonner.
enum Tint {
	UNIT,
	BUILDING,
	SPELL,
	GEAR,
	HERO,
}

## Ajouter à la fin, sans réordonner.
enum ButtonState {
	NORMAL,
	HOVER,
	PRESSED,
	DISABLED,
}

## Joueurs : franches, fixes (décision 0027) ; le rouge ne sert qu'au joueur B.
const PLAYER_A_COLOR := Color("2f6fd6")
const PLAYER_B_COLOR := Color("d43b2f")
## Texte aux couleurs du joueur, sur fond sombre : temps des joueurs, Sources.
const PLAYER_A_INK := Color("7fa8ee")
const PLAYER_B_INK := Color("ee8b82")
## Table, panneau, alvéole, et creux d'un emplacement vide avec son ombre intérieure.
const TABLE_COLOR := Color("1c1916")
const PANEL_COLOR := Color("26221d")
const SOCKET_COLOR := Color("2f2a24")
const HOLE_COLOR := Color("1f1b17")
const HOLE_SHADOW_COLOR := Color("0e0c0a")
## Sol de l'arène : plus clair au centre, plus sombre au bord.
const ARENA_CENTER_COLOR := Color("3d362e")
const ARENA_EDGE_COLOR := Color("2b2620")
## Lumière de l'arène qui tombe d'en haut de l'écran.
const ARENA_LIGHT_COLOR := Color(1.0, 0.886, 0.667, 0.07)
## Encre : trait et ombre de tout ce qui est dessiné, texte sur papier.
const INK_COLOR := Color("15120f")
## Papier, papier ombré (cases), papier sombre (arête des cases), papier éclairé (survol).
const PAPER_COLOR := Color("efe5cf")
const PAPER_SHADED_COLOR := Color("e0d3b6")
const PAPER_DARK_COLOR := Color("c7b896")
const PAPER_LIT_COLOR := Color("f7f0de")
## Gris chauds, et texte clair sur fond sombre.
const MUTED_COLOR := Color("8b8274")
const NEUTRAL_COLOR := Color("5c554b")
const TEXT_COLOR := Color("cdbfa6")
const BUTTON_TEXT_COLOR := Color("ffffff")
## Surlignage (peut être choisi), choix, et survol (`DuelMarks`) : franches.
const HIGHLIGHT_COLOR := Color("f4c542")
const SELECTED_COLOR := Color("57c77a")
const MARK_HOVER_COLOR := Color(1.0, 1.0, 1.0, 0.6)
const ESSENCE_COLOR := Color("f4c542")
## Barre de temps sous `TurnTimerBar.ALERT_SECONDS` secondes : signal visuel seul (décision 0053).
const ALERT_COLOR := Color("f2a33a")
const BAR_TRACK_COLOR := SOCKET_COLOR
## Voile posé sur le jeu figé : fin de partie, confirmation d'abandon.
const SCRIM_COLOR := Color(0.082, 0.071, 0.059, 0.72)
## Écart de luminosité du grand bouton survolé (plus clair) et pressé (plus sombre).
const BUTTON_HOVER_LIGHTEN: float = 0.12
const BUTTON_PRESSED_DARKEN: float = 0.12
## Décision 0028 : Source inclinée et temps qui ne s'écoule pas estompés.
const DIMMED_ALPHA: float = 0.55

## Teintes de type (bible) : fond du cadre d'une carte, d'une pièce ou d'une entrée de pile.
const TINT_BACKGROUNDS: Dictionary[Tint, Color] = {
	Tint.UNIT: Color("a8b88f"),
	Tint.BUILDING: Color("cfae74"),
	Tint.SPELL: Color("9ea6c4"),
	Tint.GEAR: Color("c98f72"),
	Tint.HERO: Color("c79aa3"),
}
## Encre sur une teinte de type : l'encre de la bible pour les cinq.
const TINT_INKS: Dictionary[Tint, Color] = {
	Tint.UNIT: INK_COLOR,
	Tint.BUILDING: INK_COLOR,
	Tint.SPELL: INK_COLOR,
	Tint.GEAR: INK_COLOR,
	Tint.HERO: INK_COLOR,
}
const CARD_TINTS: Dictionary[CardDefinition.CardType, Tint] = {
	CardDefinition.CardType.UNIT: Tint.UNIT,
	CardDefinition.CardType.BUILDING: Tint.BUILDING,
	CardDefinition.CardType.SPELL: Tint.SPELL,
	CardDefinition.CardType.GEAR: Tint.GEAR,
}
## Fond de l'illustration absente : un voile clair sur la teinte de la carte.
const ART_COLOR := Color(1.0, 1.0, 1.0, 0.28)
const CARD_FACE_COLOR := PAPER_COLOR
const CARD_TEXT_COLOR := INK_COLOR
## Goutte du coût : Essence jaune, trait et chiffre à l'encre.
const COST_FILL_COLOR := ESSENCE_COLOR
const COST_OUTLINE_COLOR := INK_COLOR
const COST_INK_COLOR := INK_COLOR
## Losange de la Force, toujours le même ; seule l'encre du chiffre change selon la Force actuelle
## (sur papier). Pas de rouge : joueur B.
const FORCE_FILL_COLOR := PAPER_COLOR
const FORCE_OUTLINE_COLOR := INK_COLOR
const FORCE_UP_INK := Color("2d7a2f")
const FORCE_DOWN_INK := Color("b0560f")
## Cœur des PV du Hero : brique, chiffre sur papier.
const HEALTH_FILL_COLOR := Color("b0644e")
const HEALTH_OUTLINE_COLOR := INK_COLOR
const HEALTH_INK_COLOR := PAPER_COLOR
## Décision 0027 : une seule couleur sombre pour tous les mots-clés.
const KEYWORD_BACKGROUND := INK_COLOR
const KEYWORD_INK := PAPER_COLOR
## Bulles d'information (E27) : papier, trait et ombre d'encre ; encre `CARD_TEXT_COLOR`.
const BUBBLE_BACKGROUND := PAPER_COLOR
const BUBBLE_BORDER_COLOR := INK_COLOR
const BUBBLE_SHADOW_COLOR := INK_COLOR
const CARD_BACK_COLOR := SOCKET_COLOR
const CARD_BACK_STRIPE_COLOR := Color(0.937, 0.898, 0.812, 0.1)
const CELL_COLOR := PAPER_SHADED_COLOR
const CELL_HOVER_COLOR := PAPER_COLOR

const BUTTON_COLOR_NAMES: Array[StringName] = [
	&"font_color",
	&"font_hover_color",
	&"font_pressed_color",
	&"font_hover_pressed_color",
	&"font_focus_color",
]
const BUTTON_STATE_STYLES: Dictionary[ButtonState, StringName] = {
	ButtonState.NORMAL: &"normal",
	ButtonState.HOVER: &"hover",
	ButtonState.PRESSED: &"pressed",
	ButtonState.DISABLED: &"disabled",
}

## Trait d'encre, de 2 à 4 px (bible) : fin, courant, épais ; liseré d'un joueur.
const LINE_WIDTH: int = 1
const BORDER_WIDTH: int = 2
const THICK_BORDER_WIDTH: int = 3
const PLAYER_BORDER_WIDTH: int = 4
## Coin coupé : un chanfrein, jamais un arrondi (bible) ; un seul segment par coin.
const CUT_SIZE: int = 8
const CUT_DETAIL: int = 1
## Ombre en aplat décalé, sans flou (bible) ; 1 px est le plus petit `shadow_size` qui se trace.
const SHADOW_SIZE: int = 1
const SHADOW_OFFSET: float = 3.0
const BUTTON_PRESSED_SHADOW_OFFSET: float = 0.0
const BUTTON_HOVER_SHADOW_OFFSET: float = 5.0
## Variation de Label déclarée dans ui/theme/duel_theme.tres (thème unique).
const SMALL_LABEL: StringName = &"SmallLabel"
const CONTENT_MARGIN: int = 8
## Marge intérieure d'un panneau centré (fin de partie, confirmation).
const MODAL_MARGIN: float = 32.0
## Décalage de l'ombre d'un panneau centré.
const MODAL_SHADOW_OFFSET: float = 6.0
const BUTTON_STATE_IMAGES: Dictionary[ButtonState, String] = {
	ButtonState.NORMAL: "normal",
	ButtonState.HOVER: "hover",
	ButtonState.PRESSED: "pressed",
	ButtonState.DISABLED: "disabled",
}


static func player_color(side: DuelState.PlayerSide) -> Color:
	return PLAYER_A_COLOR if side == DuelState.PlayerSide.A else PLAYER_B_COLOR


static func player_ink(side: DuelState.PlayerSide) -> Color:
	return PLAYER_A_INK if side == DuelState.PlayerSide.A else PLAYER_B_INK


## Couleur du vainqueur de `result` ; neutre pour une égalité ou sans résultat.
static func result_color(result: DuelState.DuelResult) -> Color:
	match result:
		DuelState.DuelResult.PLAYER_A_WINS:
			return PLAYER_A_COLOR
		DuelState.DuelResult.PLAYER_B_WINS:
			return PLAYER_B_COLOR
	return NEUTRAL_COLOR


## Encre du vainqueur de `result`, comme `result_color`.
static func result_ink(result: DuelState.DuelResult) -> Color:
	match result:
		DuelState.DuelResult.PLAYER_A_WINS:
			return PLAYER_A_INK
		DuelState.DuelResult.PLAYER_B_WINS:
			return PLAYER_B_INK
	return TEXT_COLOR


static func tint_of(card_type: CardDefinition.CardType) -> Tint:
	return CARD_TINTS[card_type]


## Nom de `tint` en minuscules (`unit`, `hero`…) : celui des fichiers de cadre de `assets/cards/`.
static func tint_name(tint: Tint) -> String:
	return str(Tint.find_key(tint)).to_lower()


## Cadre d'un composant, bordé de `border`.
static func panel_style(border: Color) -> StyleBoxFlat:
	return framed_style(PANEL_COLOR, border, BORDER_WIDTH, CONTENT_MARGIN)


## Fond `background` bordé de `border` sur `border_width`, coins coupés de `CUT_SIZE`, marge
## `margin`.
static func framed_style(
	background: Color, border: Color, border_width: int, margin: float
) -> StyleBoxFlat:
	var style := fill_style(background, CUT_SIZE, margin)
	style.border_color = border
	style.set_border_width_all(border_width)
	return style


## Contour vide de `color` sur `width` px, coins coupés de `cut` px, sans fond.
static func outline_style(color: Color, width: int, cut: int = CUT_SIZE) -> StyleBoxFlat:
	var style := fill_style(Color.TRANSPARENT, cut, 0.0)
	style.draw_center = false
	style.border_color = color
	style.set_border_width_all(width)
	return style


## Fond plein `background`, coins coupés de `cut` px, marge intérieure `margin`, sans bordure.
static func fill_style(background: Color, cut: int, margin: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.set_corner_radius_all(cut)
	style.corner_detail = CUT_DETAIL
	style.set_content_margin_all(margin)
	style.anti_aliasing = true
	return style


## Ajoute à `style` l'ombre d'encre en aplat, décalée de `offset` px vers le bas et la droite.
static func with_shadow(style: StyleBoxFlat, offset: float) -> StyleBoxFlat:
	if offset > 0.0:
		style.shadow_color = INK_COLOR
		style.shadow_size = SHADOW_SIZE
		style.shadow_offset = Vector2.ONE * offset
	return style


## Alvéole creusée (bible : un emplacement vide n'est jamais un pointillé) : creux sombre, ombre
## intérieure en haut et à gauche, marge `margin`.
static func hole_style(margin: float) -> StyleBoxFlat:
	var style := fill_style(HOLE_COLOR, CUT_SIZE, margin)
	style.border_color = HOLE_SHADOW_COLOR
	style.border_width_left = THICK_BORDER_WIDTH
	style.border_width_top = THICK_BORDER_WIDTH
	return style


## Carte ou pièce teintée par son type, bordée de `border` sur `border_width`.
static func tinted_style(
	tint: Tint, border: Color, border_width: int, margin: float
) -> StyleBoxFlat:
	return framed_style(TINT_BACKGROUNDS[tint], border, border_width, margin)


## Fond d'un grand bouton aux couleurs fixes de `side` (décision 0032) dans l'état `state` : trait
## d'encre et ombre en aplat, grisé quand il est désactivé (décision 0053, point 11). L'image
## `button_big_<état>.png` de la fiche, teintée à la couleur du camp, le remplace si elle existe.
static func player_button_style(side: DuelState.PlayerSide, state: ButtonState) -> StyleBox:
	var color := player_color(side)
	var shadow_offset := SHADOW_OFFSET
	var image_tint := color
	match state:
		ButtonState.HOVER:
			color = color.lightened(BUTTON_HOVER_LIGHTEN)
			shadow_offset = BUTTON_HOVER_SHADOW_OFFSET
		ButtonState.PRESSED:
			color = color.darkened(BUTTON_PRESSED_DARKEN)
			shadow_offset = BUTTON_PRESSED_SHADOW_OFFSET
		ButtonState.DISABLED:
			color = NEUTRAL_COLOR
			shadow_offset = BUTTON_PRESSED_SHADOW_OFFSET
			image_tint = Color.WHITE
	var flat := framed_style(color, INK_COLOR, THICK_BORDER_WIDTH, CONTENT_MARGIN)
	return DuelAssets.ui_style(
		DuelAssets.BUTTON_BIG_IMAGE_PREFIX + BUTTON_STATE_IMAGES[state],
		with_shadow(flat, shadow_offset),
		DuelAssets.BUTTON_BIG_IMAGE_MARGIN,
		image_tint
	)


## Cadre d'un panneau centré (fin de partie, confirmation, préparation) : fond `background`,
## bordure `accent`, ombre d'encre ; `modal_panel.png` de la fiche le remplace s'il existe.
static func modal_style(accent: Color, background: Color = PANEL_COLOR) -> StyleBox:
	var flat := framed_style(background, accent, PLAYER_BORDER_WIDTH, MODAL_MARGIN)
	return DuelAssets.ui_style(
		DuelAssets.MODAL_PANEL_IMAGE,
		with_shadow(flat, MODAL_SHADOW_OFFSET),
		DuelAssets.MODAL_PANEL_IMAGE_MARGIN
	)


## Habille `button` aux couleurs fixes de `side` : fonds de ses quatre états et texte.
static func apply_player_button(button: Button, side: DuelState.PlayerSide) -> void:
	for state: ButtonState in BUTTON_STATE_STYLES:
		button.add_theme_stylebox_override(
			BUTTON_STATE_STYLES[state], player_button_style(side, state)
		)
	for color_name: StringName in BUTTON_COLOR_NAMES:
		button.add_theme_color_override(color_name, BUTTON_TEXT_COLOR)
	button.add_theme_color_override("font_disabled_color", MUTED_COLOR)
