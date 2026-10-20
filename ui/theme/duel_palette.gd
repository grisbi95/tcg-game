class_name DuelPalette
extends RefCounted
## Couleurs et cadres des composants : teintes des cinq types de carte et couleurs fixes des
## joueurs (décision 0027), reprises de `docs/maquettes/ecran-de-partie-v1.html` (0028), et fabrique
## de cadres. Survol, surlignage et choix sont des anneaux tracés par `DuelMarks`.

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

const PLAYER_A_COLOR := Color("2f7fd8")
## Décision 0027 : le rouge ne sert qu'au joueur B.
const PLAYER_B_COLOR := Color("d23a3a")
## Fond et texte aux couleurs du joueur : pendules, Sources.
const PLAYER_A_SOFT := Color("2a3a52")
const PLAYER_B_SOFT := Color("4a2a2e")
const PLAYER_A_INK := Color("9cc6f2")
const PLAYER_B_INK := Color("f2b8b8")
const NEUTRAL_COLOR := Color("5a5f6b")
const TABLE_COLOR := Color("1d2127")
const PANEL_COLOR := Color("262b33")
const CELL_COLOR := Color("2c323b")
const CELL_LINE_COLOR := Color("3a414c")
const INK_COLOR := Color("eef0f3")
const MUTED_COLOR := Color("a3a9b3")
const HIGHLIGHT_COLOR := Color("f2c14e")
const SELECTED_COLOR := Color("4ecb71")
## Anneau de survol (`DuelMarks`).
const MARK_HOVER_COLOR := Color(1.0, 1.0, 1.0, 0.6)
const ESSENCE_COLOR := Color("ffd66b")
const ESSENCE_BACKGROUND := Color("3a3420")
const COUNTER_COLOR := Color("2a2f37")
const COUNTER_LINE_COLOR := Color("4a525e")
const SOURCE_COLOR := Color("3b424e")
const SOURCE_HOVER_COLOR := Color("46505e")
const SOURCE_TILTED_LINE_COLOR := Color("6b7380")
const BAR_TRACK_COLOR := Color("3a414c")
## Panneau de consigne de la colonne de duel.
const HINT_COLOR := Color("1f242b")
## Voile sombre posé sur le jeu figé : fin de partie, confirmation d'abandon.
const SCRIM_COLOR := Color(0.06, 0.07, 0.09, 0.72)
## Écart de luminosité du grand bouton survolé (plus clair) et pressé (plus sombre).
const BUTTON_HOVER_LIGHTEN: float = 0.12
const BUTTON_PRESSED_DARKEN: float = 0.12
## Décision 0028 : Source inclinée et pendule arrêtée estompées.
const DIMMED_ALPHA: float = 0.55

const TINT_BACKGROUNDS: Dictionary[Tint, Color] = {
	Tint.UNIT: Color("dff3ea"),
	Tint.BUILDING: Color("f8ecd6"),
	Tint.SPELL: Color("ecebfd"),
	Tint.GEAR: Color("fae9e2"),
	Tint.HERO: Color("fae7ef"),
}
const TINT_INKS: Dictionary[Tint, Color] = {
	Tint.UNIT: Color("0b5c47"),
	Tint.BUILDING: Color("7a4808"),
	Tint.SPELL: Color("463ca8"),
	Tint.GEAR: Color("8d3517"),
	Tint.HERO: Color("8a2c4c"),
}
const CARD_TINTS: Dictionary[CardDefinition.CardType, Tint] = {
	CardDefinition.CardType.UNIT: Tint.UNIT,
	CardDefinition.CardType.BUILDING: Tint.BUILDING,
	CardDefinition.CardType.SPELL: Tint.SPELL,
	CardDefinition.CardType.GEAR: Tint.GEAR,
}
## Fond de l'illustration absente, sur la teinte de la carte.
const ART_COLOR := Color(1.0, 1.0, 1.0, 0.75)
const CARD_FACE_COLOR := Color("ffffff")
const CARD_TEXT_COLOR := Color("1c1d20")
## Goutte du coût : bleu clair, contour bleu, chiffre bleu sombre (9:1 sur le remplissage).
const COST_FILL_COLOR := Color("c9e1f9")
const COST_OUTLINE_COLOR := Color("1e5fae")
const COST_INK_COLOR := Color("0c3566")
## Losange de la Force, toujours le même ; seule l'encre du chiffre change selon la Force actuelle
## (neutre 13,7:1 sur le remplissage, vert 5,4:1, orange foncé 4,8:1). Pas de rouge : joueur B.
const FORCE_FILL_COLOR := Color("e4e8ee")
const FORCE_OUTLINE_COLOR := Color("4a525e")
const FORCE_UP_INK := Color("1a6b1a")
const FORCE_DOWN_INK := Color("a34a00")
## Cœur des PV du Hero, aux teintes du Hero.
const HEALTH_FILL_COLOR := Color("f2a3bd")
const HEALTH_OUTLINE_COLOR := Color("8a2c4c")
const HEALTH_INK_COLOR := Color("4a0f26")
## Décision 0027 : une seule couleur sombre pour tous les mots-clés.
const KEYWORD_BACKGROUND := Color("24252a")
const KEYWORD_INK := Color("ffffff")
const CARD_BACK_COLOR := Color("343b46")
const CARD_BACK_STRIPE_COLOR := Color("2c323b")
const CELL_HOVER_COLOR := Color("333a44")

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

const LINE_WIDTH: int = 1
const BORDER_WIDTH: int = 2
const PLAYER_BORDER_WIDTH: int = 4
const CORNER_RADIUS: int = 8
## Variation de Label déclarée dans ui/theme/duel_theme.tres (thème unique).
const SMALL_LABEL: StringName = &"SmallLabel"
const CONTENT_MARGIN: int = 8
## Marge intérieure d'un panneau centré (fin de partie, confirmation, rideau de relais).
const MODAL_MARGIN: float = 32.0


static func player_color(side: DuelState.PlayerSide) -> Color:
	return PLAYER_A_COLOR if side == DuelState.PlayerSide.A else PLAYER_B_COLOR


static func player_soft(side: DuelState.PlayerSide) -> Color:
	return PLAYER_A_SOFT if side == DuelState.PlayerSide.A else PLAYER_B_SOFT


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
	return INK_COLOR


static func tint_of(card_type: CardDefinition.CardType) -> Tint:
	return CARD_TINTS[card_type]


## Cadre d'un composant, bordé de `border`.
static func panel_style(border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.border_color = border
	style.set_border_width_all(BORDER_WIDTH)
	style.set_corner_radius_all(CORNER_RADIUS)
	style.set_content_margin_all(CONTENT_MARGIN)
	return style


## Fond `background` bordé de `border` sur `border_width`, coins de `CORNER_RADIUS`, marge `margin`.
static func framed_style(
	background: Color, border: Color, border_width: int, margin: float
) -> StyleBoxFlat:
	var style := fill_style(background, CORNER_RADIUS, margin)
	style.border_color = border
	style.set_border_width_all(border_width)
	return style


## Fond plein `background`, coins arrondis de `radius`, marge intérieure `margin`, sans bordure.
static func fill_style(background: Color, radius: int, margin: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(margin)
	style.anti_aliasing = true
	return style


## Carte ou pièce teintée par son type, bordée de `border` sur `border_width`.
static func tinted_style(
	tint: Tint, border: Color, border_width: int, margin: float
) -> StyleBoxFlat:
	return framed_style(TINT_BACKGROUNDS[tint], border, border_width, margin)


## Fond d'un grand bouton aux couleurs fixes de `side` (décision 0032) dans l'état `state`.
static func player_button_style(side: DuelState.PlayerSide, state: ButtonState) -> StyleBoxFlat:
	var color := player_color(side)
	match state:
		ButtonState.HOVER:
			color = color.lightened(BUTTON_HOVER_LIGHTEN)
		ButtonState.PRESSED:
			color = color.darkened(BUTTON_PRESSED_DARKEN)
		ButtonState.DISABLED:
			color = player_soft(side)
	return fill_style(color, CORNER_RADIUS, CONTENT_MARGIN)


## Cadre d'un panneau centré (fin de partie, confirmation, rideau, préparation) : fond
## `background`, bordure `accent`.
static func modal_style(accent: Color, background: Color = PANEL_COLOR) -> StyleBoxFlat:
	return framed_style(background, accent, PLAYER_BORDER_WIDTH, MODAL_MARGIN)


## Habille `button` aux couleurs fixes de `side` : fonds de ses quatre états et texte.
static func apply_player_button(button: Button, side: DuelState.PlayerSide) -> void:
	for state: ButtonState in BUTTON_STATE_STYLES:
		button.add_theme_stylebox_override(
			BUTTON_STATE_STYLES[state], player_button_style(side, state)
		)
	for color_name: StringName in BUTTON_COLOR_NAMES:
		button.add_theme_color_override(color_name, INK_COLOR)
	button.add_theme_color_override("font_disabled_color", MUTED_COLOR)
