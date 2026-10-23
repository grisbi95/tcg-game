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
const SEPARATOR: String = " · "
const HERO_TYPE_NAME: String = "Hero"
## Décision 0027 : nom affiché d'un jeton, qui ne correspond à aucune carte (202.4.2).
const TOKEN_NAME: String = "Jeton"
const KEYWORD_SEPARATOR: String = ":"


## « Assaut 2 · Avant-poste » ; vide sans mot-clé.
static func keywords_line(definition: CardDefinition) -> String:
	var parts := PackedStringArray()
	for keyword: CardDefinition.Keyword in definition.keywords:
		parts.append(keyword_label(keyword, definition.keywords[keyword]))
	return SEPARATOR.join(parts)


## « Unit », « Building », « Spell », « Gear ».
static func type_name(card_type: CardDefinition.CardType) -> String:
	return TYPE_NAMES[card_type]


## 202.4.2, décision 0027 : « Unit · Jeton » ou « Building · Jeton ».
static func token_type_name(card_type: CardDefinition.CardType) -> String:
	return type_name(card_type) + SEPARATOR + TOKEN_NAME


## « Action » ou « Réaction » pour un Spell (207.1.2) ; vide sinon.
static func speed_name(definition: CardDefinition) -> String:
	return SPEED_NAMES.get(definition.speed, "")


## Décision 0027 : texte en BBCode, chaque mot-clé en étiquette en tête ; le nom du mot-clé déjà
## écrit au début du texte n'est pas répété.
static func body_bbcode(definition: CardDefinition) -> String:
	var chips := PackedStringArray()
	var text := definition.text.strip_edges()
	for keyword: CardDefinition.Keyword in definition.keywords:
		var label := keyword_label(keyword, definition.keywords[keyword])
		chips.append(chip(label))
		text = _without_prefix(text, label)
	return _joined(chips, text)


## Décision 0027, édition 0.42 (décision de design 0208) : le texte d'un Hero est son passif,
## rendu tel quel.
static func hero_body_bbcode(hero: HeroDefinition) -> String:
	return escaped(hero.text.strip_edges())


## « Assaut 2 », « Avant-poste ».
static func keyword_label(keyword: CardDefinition.Keyword, value: int) -> String:
	var name := KEYWORD_NAMES[keyword]
	return name if value == CardDefinition.NO_KEYWORD_VALUE else "%s %d" % [name, value]


## Étiquette sombre, la même pour tous les mots-clés (décision 0027).
static func chip(label: String) -> String:
	return (
		"[bgcolor=#%s][color=#%s] %s [/color][/bgcolor]"
		% [
			DuelPalette.KEYWORD_BACKGROUND.to_html(false),
			DuelPalette.KEYWORD_INK.to_html(false),
			escaped(label),
		]
	)


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


static func _joined(chips: PackedStringArray, text: String) -> String:
	var parts := chips.duplicate()
	if not text.is_empty():
		parts.append(escaped(text))
	return " ".join(parts)
