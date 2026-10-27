class_name InfoBubble
extends RefCounted
## Une bulle d'information du survol (décision 0053, fiche de l'écran de duel, E27) : un titre et
## un texte de rappel. `list_for` dresse celles d'une carte survolée, sans scène.

var title: String
var text: String


func _init(bubble_title: String, bubble_text: String) -> void:
	title = bubble_title
	text = bubble_text


## Une bulle par mot-clé de `definition`, puis de son `gear` (null sans Gear), puis « Endormie »
## (201.4.11, 205.5) si la pièce survolée l'est. `definition` est null pour un Hero ou un jeton.
static func list_for(
	definition: CardDefinition, gear: CardDefinition, is_asleep: bool
) -> Array[InfoBubble]:
	var bubbles: Array[InfoBubble] = []
	for card: CardDefinition in [definition, gear]:
		if card != null:
			bubbles.append_array(_keyword_bubbles(card.keywords))
	return _with_asleep(bubbles, is_asleep)


## Comme `list_for`, avec les mots-clés que porte la pièce survolée, reçus compris (210.4,
## décision 0073) ; un mot-clé déjà montré n'est pas répété pour son Gear.
static func list_for_piece(
	keywords: Dictionary[CardDefinition.Keyword, int], gear: CardDefinition, is_asleep: bool
) -> Array[InfoBubble]:
	var bubbles := _keyword_bubbles(keywords)
	if gear != null:
		for keyword: CardDefinition.Keyword in gear.keywords:
			if not keywords.has(keyword):
				bubbles.append(_keyword_bubble(keyword, gear.keywords[keyword]))
	return _with_asleep(bubbles, is_asleep)


static func _with_asleep(bubbles: Array[InfoBubble], is_asleep: bool) -> Array[InfoBubble]:
	if is_asleep:
		bubbles.append(InfoBubble.new(CardText.ASLEEP_NAME, CardText.ASLEEP_REMINDER))
	return bubbles


static func _keyword_bubbles(
	keywords: Dictionary[CardDefinition.Keyword, int]
) -> Array[InfoBubble]:
	var bubbles: Array[InfoBubble] = []
	for keyword: CardDefinition.Keyword in keywords:
		bubbles.append(_keyword_bubble(keyword, keywords[keyword]))
	return bubbles


static func _keyword_bubble(keyword: CardDefinition.Keyword, value: int) -> InfoBubble:
	return InfoBubble.new(
		CardText.keyword_label(keyword, value), CardText.keyword_reminder(keyword, value)
	)
