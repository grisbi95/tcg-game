class_name CardText
extends RefCounted
## Textes d'une carte à l'écran (CardView, PieceView, HoverPreview ; décisions 0025 et 0027).

const KEYWORD_NAMES: Dictionary[CardDefinition.Keyword, String] = {
	CardDefinition.Keyword.OUTPOST: "Avant-poste",  # 210.2.1
	CardDefinition.Keyword.ARRIVAL: "Arrivée",  # 210.3.1
	CardDefinition.Keyword.LAST_BREATH: "Dernier souffle",  # 210.3.2
	CardDefinition.Keyword.ASSAULT: "Assaut",  # 210.4.1
	CardDefinition.Keyword.RAMPART: "Rempart",  # 210.4.2
}
## 210.2.1, 210.2.1a : la rangée centrale n'est jamais permise.
# gdlint: ignore=max-line-length
const OUTPOST_REMINDER: String = "Tu peux déployer une Unit sur une case libre adjacente à ce Building, hors de la rangée centrale."
## 210.3.1
const ARRIVAL_REMINDER: String = "Son effet se déclenche quand la pièce arrive sur le plateau."
## 210.3.2
const LAST_BREATH_REMINDER: String = "Son effet se déclenche quand la pièce est détruite."
## Rappels des mots-clés pour les bulles d'information ; `{X}` est remplacé par la valeur.
const KEYWORD_REMINDERS: Dictionary[CardDefinition.Keyword, String] = {
	CardDefinition.Keyword.OUTPOST: OUTPOST_REMINDER,
	CardDefinition.Keyword.ARRIVAL: ARRIVAL_REMINDER,
	CardDefinition.Keyword.LAST_BREATH: LAST_BREATH_REMINDER,
	CardDefinition.Keyword.ASSAULT: "+{X} Force quand la pièce attaque.",  # 210.4.1
	CardDefinition.Keyword.RAMPART: "+{X} Force quand la pièce défend.",  # 210.4.2
}
const VALUE_PLACEHOLDER: String = "{X}"
const ASLEEP_NAME: String = "Endormie"
## 205.5.3, 205.5.5
const ASLEEP_REMINDER: String = "Ne peut pas faire d'action normale avant son prochain réveil."
const TYPE_NAMES: Dictionary[CardDefinition.CardType, String] = {
	CardDefinition.CardType.UNIT: "Unit",
	CardDefinition.CardType.BUILDING: "Building",
	CardDefinition.CardType.SPELL: "Spell",
	CardDefinition.CardType.GEAR: "Gear",
}
const SPEED_NAMES: Dictionary[CardDefinition.SpellSpeed, String] = {
	CardDefinition.SpellSpeed.ACTION: "Action",  # 207.1.2
	CardDefinition.SpellSpeed.REACTION: "Réaction",  # 207.1.2
}
const TOP_CARD_PLACE_LABELS: Dictionary[ChooseTopCardPlace.TopCardPlace, String] = {
	ChooseTopCardPlace.TopCardPlace.ON_TOP: "Garder dessus",
	ChooseTopCardPlace.TopCardPlace.BELOW: "Mettre dessous",
}
const ORDER_BUTTON_FORMAT: String = "Ordre %d · %s · coût %d"
const SEPARATOR: String = " · "
const HERO_TYPE_NAME: String = "Hero"
## Décision 0027 : nom affiché d'un jeton, qui ne correspond à aucune carte (202.4.2).
const TOKEN_NAME: String = "Jeton"
const KEYWORD_SEPARATOR: String = ":"


## « Unit », « Building », « Spell », « Gear ».
static func type_name(card_type: CardDefinition.CardType) -> String:
	return TYPE_NAMES[card_type]


## « Action » ou « Réaction » pour un Spell (207.1.2) ; vide sinon.
static func speed_name(definition: CardDefinition) -> String:
	return SPEED_NAMES.get(definition.speed, "")


## Texte du bouton « dessus » ou « dessous » de la carte regardée (217.1.2, 217.1.3).
static func top_card_place_label(place: ChooseTopCardPlace.TopCardPlace) -> String:
	return TOP_CARD_PLACE_LABELS[place]


## Décision 0068 : « Ordre 1 · Réaction · coût 0 », le bouton de l'Ordre de rang `order_index`.
static func order_button_text(order_index: int, order: HeroOrder) -> String:
	var speed: String = SPEED_NAMES.get(order.speed, "")
	return ORDER_BUTTON_FORMAT % [order_index + 1, speed, order.cost]


## Mots-clés de `piece` d'une carte `definition` (null : jeton, Hero), Assaut et Rempart accordés
## compris (210.4, décision 0058) : les valeurs viennent de `KeywordRules`, un jeton n'en porte que
## s'il en reçoit (202.4.13a). Montrés au survol, la pièce épurée n'en porte pas (décision 0073).
static func piece_keywords(
	state: DuelState, piece: Piece, definition: CardDefinition
) -> Dictionary[CardDefinition.Keyword, int]:
	var totals: Dictionary[CardDefinition.Keyword, int] = {
		CardDefinition.Keyword.ASSAULT: KeywordRules.assault_value(state, piece),
		CardDefinition.Keyword.RAMPART: KeywordRules.rampart_value(state, piece),
	}
	var result: Dictionary[CardDefinition.Keyword, int] = {}
	if definition != null:
		for keyword: CardDefinition.Keyword in definition.keywords:
			result[keyword] = totals.get(keyword, definition.keywords[keyword])
	for keyword: CardDefinition.Keyword in totals:
		if totals[keyword] > 0 and not result.has(keyword):
			result[keyword] = totals[keyword]
	return result


## Étiquette en tête du texte d'une carte (décision 0027) : un mot-clé, avec son icône, ou la
## vitesse d'un Spell (207.1.2), sans icône ; la vitesse n'est pas un mot-clé de règle.
class Chip:
	extends RefCounted
	var label: String
	var has_icon: bool
	var icon: DuelIcons.Icon

	func _init(chip_label: String, chip_icon: int = -1) -> void:
		label = chip_label
		has_icon = chip_icon >= 0
		if has_icon:
			icon = chip_icon as DuelIcons.Icon


## Les étiquettes en tête du texte de `definition` : sa vitesse s'il s'agit d'un Spell, puis chaque
## mot-clé, en capitales.
static func chips(definition: CardDefinition) -> Array[Chip]:
	var result: Array[Chip] = []
	var speed := speed_name(definition)
	if not speed.is_empty():
		result.append(Chip.new(speed.to_upper()))
	for keyword: CardDefinition.Keyword in definition.keywords:
		var label := keyword_label(keyword, definition.keywords[keyword])
		result.append(Chip.new(label.to_upper(), DuelIcons.keyword_icon(keyword)))
	return result


## Décision 0027 : texte en BBCode, sans les étiquettes (`chips`) ; le nom du mot-clé déjà écrit
## au début du texte n'est pas répété.
static func body_bbcode(definition: CardDefinition) -> String:
	var text := definition.text.strip_edges()
	for keyword: CardDefinition.Keyword in definition.keywords:
		text = _without_prefix(text, keyword_label(keyword, definition.keywords[keyword]))
	return escaped(text)


## Décision 0027, édition 0.42 (décision de design 0208) : le texte d'un Hero est son passif,
## rendu tel quel.
static func hero_body_bbcode(hero: HeroDefinition) -> String:
	return escaped(hero.text.strip_edges())


## « Assaut 2 », « Avant-poste ».
static func keyword_label(keyword: CardDefinition.Keyword, value: int) -> String:
	var name := KEYWORD_NAMES[keyword]
	return name if value == CardDefinition.NO_KEYWORD_VALUE else "%s %d" % [name, value]


## Rappel de règle d'un mot-clé de valeur `value`, pour sa bulle d'information.
static func keyword_reminder(keyword: CardDefinition.Keyword, value: int) -> String:
	return KEYWORD_REMINDERS[keyword].replace(VALUE_PLACEHOLDER, str(value))


## Texte affiché tel quel par un RichTextLabel en BBCode.
static func escaped(text: String) -> String:
	return text.replace("[", "[lb]")


static func _without_prefix(text: String, label: String) -> String:
	if not text.begins_with(label):
		return text
	var rest := text.substr(label.length()).strip_edges()
	if rest.begins_with(KEYWORD_SEPARATOR):
		rest = rest.substr(KEYWORD_SEPARATOR.length()).strip_edges()
	return rest
