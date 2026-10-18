class_name CardText
extends RefCounted
## Lignes de texte d'une carte à l'écran (composants CardView et HoverPreview, décision 0025).

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


static func cost_line(definition: CardDefinition) -> String:
	return "Coût %d" % definition.cost


## « Unit · Force 3 », « Spell · Réaction », « Gear ».
static func type_line(definition: CardDefinition) -> String:
	var parts := PackedStringArray([TYPE_NAMES[definition.card_type]])
	if definition.force != CardDefinition.NO_FORCE:
		parts.append(force_line(definition.force))
	if SPEED_NAMES.has(definition.speed):
		parts.append(SPEED_NAMES[definition.speed])
	return SEPARATOR.join(parts)


## « Force 3 », pour une carte ou une pièce (209.1).
static func force_line(force: int) -> String:
	return "Force %d" % force


## « Assaut 2 · Avant-poste » ; vide sans mot-clé.
static func keywords_line(definition: CardDefinition) -> String:
	var parts := PackedStringArray()
	for keyword: CardDefinition.Keyword in definition.keywords:
		var value := definition.keywords[keyword]
		var name := KEYWORD_NAMES[keyword]
		var has_value := value != CardDefinition.NO_KEYWORD_VALUE
		parts.append("%s %d" % [name, value] if has_value else name)
	return SEPARATOR.join(parts)
