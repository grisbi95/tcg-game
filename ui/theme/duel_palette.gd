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
const COST_INK_COLOR := Color("1e5fae")
## Décision 0027 : une seule couleur sombre pour tous les mots-clés.
const KEYWORD_BACKGROUND := Color("24252a")
const KEYWORD_INK := Color("ffffff")
const FORCE_UP_BACKGROUND := Color("e3f1d3")
const FORCE_UP_INK := Color("2f5a0c")
const FORCE_DOWN_BACKGROUND := Color("ffe1c2")
const FORCE_DOWN_INK := Color("9a4700")
const CARD_BACK_COLOR := Color("343b46")
const CARD_BACK_STRIPE_COLOR := Color("2c323b")
const CELL_HOVER_COLOR := Color("333a44")
const PILL_BORDER_COLOR := Color(0.0, 0.0, 0.0, 0.18)

const LINE_WIDTH: int = 1
const BORDER_WIDTH: int = 2
const PLAYER_BORDER_WIDTH: int = 4
const CORNER_RADIUS: int = 8
## Pastille ronde : rayon d'au moins la moitié de sa taille.
const PILL_RADIUS: int = CORNER_RADIUS * 4
## Variation de Label déclarée dans ui/theme/duel_theme.tres (thème unique).
const SMALL_LABEL: StringName = &"SmallLabel"
const CONTENT_MARGIN: int = 8


static func player_color(side: DuelState.PlayerSide) -> Color:
	return PLAYER_A_COLOR if side == DuelState.PlayerSide.A else PLAYER_B_COLOR


static func player_soft(side: DuelState.PlayerSide) -> Color:
	return PLAYER_A_SOFT if side == DuelState.PlayerSide.A else PLAYER_B_SOFT


static func player_ink(side: DuelState.PlayerSide) -> Color:
	return PLAYER_A_INK if side == DuelState.PlayerSide.A else PLAYER_B_INK


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


## Pastille ronde d'un nombre (coût, Force, PV), de fond `background`.
static func pill_style(background: Color) -> StyleBoxFlat:
	var style := fill_style(background, PILL_RADIUS, 0.0)
	style.border_color = PILL_BORDER_COLOR
	style.set_border_width_all(LINE_WIDTH)
	return style
