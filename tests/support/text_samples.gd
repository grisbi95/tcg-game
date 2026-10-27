class_name TextSamples
extends RefCounted
## Catalogue en mémoire de l'étape c.5d (suite d'effets d'un texte et ensemble touché sans cible,
## décision 0064). Reprend FilterSamples (Apprenti, Spectre des archives, Porte-enseigne…) et
## ajoute, sous la forme des cartes de docs/ruleset/50-cartes/ sans en être les cartes (c.6) :
## Chantier, Grimoire, des Spells à condition « si », à « si vous le faites » et à « puis », des
## Spells sur un ensemble d'Units et un Ordre à condition « si ».

## Building : au début de votre tour, créez un jeton Unit de Force 4 sur une case libre ciblée
## adjacente à ce Building, puis détruisez ce Building.
const WORKSITE: StringName = &"text_worksite"
## Gear : quand l'Unit qui porte ce Gear détruit son défenseur, piochez une carte, puis défaussez
## une carte de votre main.
const GRIMOIRE: StringName = &"text_grimoire"
## Spell d'Action de coût 1 : si votre main compte 2 cartes ou moins, piochez deux cartes.
const IF_FEW: StringName = &"text_if_few"
## Spell d'Action de coût 1 : piochez une carte. Si votre main compte 2 cartes ou moins, piochez une
## carte. Piochez une carte.
const MIDDLE: StringName = &"text_middle"
## Spell d'Action de coût 1 : détruisez jusqu'à deux Units alliées ciblées. Si vous le faites,
## piochez une carte.
const SACRIFICE: StringName = &"text_sacrifice"
## Spell d'Action de coût 1 : défaussez une carte de votre main. Si vous le faites, piochez une
## carte.
const REPLACE: StringName = &"text_replace"
## Spell d'Action de coût 1 : endormez une Unit, un Hero ou un Building ciblé. Si vous le faites,
## piochez une carte.
const SLEEP_THEN_DRAW: StringName = &"text_sleep_then_draw"
## Spell d'Action de coût 1 : détruisez jusqu'à deux Units alliées ciblées, puis piochez une carte.
const THEN_DRAW: StringName = &"text_then_draw"
## Spell d'Action de coût 1 : les Units ennemies ont −1 Force jusqu'à la fin du tour.
const WEAKEN_ALL: StringName = &"text_weaken_all"
## Spell d'Action de coût 1 : les Units ennemies adjacentes à votre Hero ont −1 Force jusqu'à la fin
## du tour.
const WEAKEN_NEAR: StringName = &"text_weaken_near"
## Spell d'Action de coût 1 : détruisez les Units ennemies.
const PURGE: StringName = &"text_purge"
## Spell d'Action de coût 1 : endormez les Units ennemies.
const LULL: StringName = &"text_lull"
## Spell d'Action de coût 1 : les Units alliées ont Assaut 1 jusqu'à la fin du tour.
const ARM: StringName = &"text_arm"
## Unit : Arrivée, les Units ennemies adjacentes à cette Unit ont −1 Force jusqu'à la fin du tour.
const CHILL: StringName = &"text_chill"
## Hero : Ordre d'Action de coût 1 : si votre main compte 2 cartes ou moins, piochez une carte.
const HERO: StringName = &"text_hero"

const COST: int = 1
const UNIT_FORCE: int = 2
const WORKSITE_FORCE: int = 3
const TOKEN_FORCE: int = 4
const HAND_LIMIT: int = 2  # « si votre main compte 2 cartes ou moins »
const MALUS: int = -1
const ORDER_INDEX: int = 0


static func catalog() -> Catalog:
	var result := FilterSamples.catalog()
	for data: Dictionary in card_data():
		result.add_card(CardDefinition.from_dict(data))
	result.add_hero(HeroDefinition.from_dict(hero_data()))
	return result


## Objets JSON des cartes de ce catalogue, pour vérifier qu'elles sont valides.
static func card_data() -> Array[Dictionary]:
	return [
		_worksite(),
		_grimoire(),
		_spell(IF_FEW, [_text([_draw(2, true)])]),
		_spell(MIDDLE, [_text([_draw(1), _draw(1, true), _draw(1)])]),
		_spell(SACRIFICE, [_text([_destroy_allies(), _draw(1, false, true)])]),
		_spell(SLEEP_THEN_DRAW, [_text([_sleep_any(), _draw(1, false, true)])]),
		_spell(REPLACE, [_text([_discard(), _draw(1, false, true)])]),
		_spell(THEN_DRAW, [_text([_destroy_allies(), _draw(1)])]),
		_spell(WEAKEN_ALL, [_text([_weaken({})])]),
		_spell(
			WEAKEN_NEAR, [_text([_weaken({"relation": "adjacent", "relative_to": "own_hero"})])]
		),
		_spell(PURGE, [_text([_matching("destroy", "enemy", {})])]),
		_spell(LULL, [_text([_matching("sleep", "enemy", {})])]),
		_spell(ARM, [_text([_arm()])]),
		_chill(),
	]


## Hero d'essai : un Ordre d'Action de coût 1, « si votre main compte 2 cartes ou moins, piochez
## une carte ».
static func hero_data() -> Dictionary:
	var data := OrderSamples.hero_data(HERO, false)
	data = CatalogSamples.without_field(data, "triggered")
	var order := {"speed": "action", "cost": COST, "texts": [_text([_draw(1, true)])]}
	return CatalogSamples.with_field(data, "orders", [order])


## Un texte `timing` (par défaut RESOLVE) dont les effets sont `effects`.
static func text_of(
	effects: Array, timing: String = "resolve", extra: Dictionary = {}
) -> Dictionary:
	var text := {"timing": timing, "effects": effects}
	text.merge(extra, true)
	return text


static func _text(effects: Array) -> Dictionary:
	return text_of(effects)


static func _worksite() -> Dictionary:
	var token := {
		"kind": "create_token",
		"token_piece_kind": "unit",
		"token_force": TOKEN_FORCE,
		"target": {"what": "cell", "adjacent_to": "source_piece"},
	}
	var demolish := {"kind": "destroy", "subject": "source_piece"}
	var text := text_of([token, demolish], "triggered", {"trigger": "start_of_own_turn"})
	return _card(CatalogSamples.building(), WORKSITE, WORKSITE_FORCE, [text])


static func _grimoire() -> Dictionary:
	var effects := [
		CatalogSamples.plain_effect(HandEffectSamples.draw_effect(1)),
		CatalogSamples.plain_effect(HandEffectSamples.discard_effect(1)),
	]
	var text := text_of(effects, "triggered", {"trigger": "destroys_defender"})
	var data := CatalogSamples.with_field(CatalogSamples.gear(), "id", String(GRIMOIRE))
	data = CatalogSamples.with_field(data, "name", "Gear %s" % GRIMOIRE)
	return CatalogSamples.with_field(data, "texts", [text])


static func _chill() -> Dictionary:
	var effect := _weaken({"relation": "adjacent"})
	var text := text_of([effect], "triggered", {"trigger": "arrival"})
	var data := _card(CatalogSamples.unit(), CHILL, UNIT_FORCE, [text])
	return CatalogSamples.with_field(data, "keywords", [{"keyword": "arrival"}])


static func _draw(amount: int, if_few: bool = false, if_you_do: bool = false) -> Dictionary:
	var effect := CatalogSamples.plain_effect(HandEffectSamples.draw_effect(amount))
	if if_few:
		effect["condition"] = CatalogSamples.hand_size_condition("at_most", HAND_LIMIT)
	if if_you_do:
		effect["if_you_do"] = true
	return effect


static func _sleep_any() -> Dictionary:
	var target := {"what": "piece", "filter": {"piece_kinds": ["unit", "hero", "building"]}}
	return {"kind": "sleep", "target": target}


static func _discard() -> Dictionary:
	return CatalogSamples.plain_effect(HandEffectSamples.discard_effect(1))


static func _destroy_allies() -> Dictionary:
	var target := CatalogSamples.ally_unit_target()
	target["count_min"] = 1
	target["count_max"] = 2
	return {"kind": "destroy", "target": target}


static func _weaken(filter_extra: Dictionary) -> Dictionary:
	var effect := _matching("modify_force", "enemy", filter_extra)
	effect["amount"] = MALUS
	effect["duration"] = "until_end_of_turn"
	return effect


static func _arm() -> Dictionary:
	var effect := _matching("grant_keyword", "ally", {})
	effect["keyword"] = "assault"
	effect["amount"] = 1
	effect["duration"] = "until_end_of_turn"
	return effect


static func _matching(kind: String, side: String, filter_extra: Dictionary) -> Dictionary:
	var affected := {"side": side, "piece_kinds": ["unit"]}
	affected.merge(filter_extra, true)
	return {"kind": kind, "subject": "matching_pieces", "affected": affected}


static func _spell(id: StringName, texts: Array) -> Dictionary:
	var data := CatalogSamples.with_field(CatalogSamples.spell(), "id", String(id))
	data = CatalogSamples.with_field(data, "name", "Spell %s" % id)
	data = CatalogSamples.with_field(data, "speed", "action")
	data = CatalogSamples.with_field(data, "cost", COST)
	return CatalogSamples.with_field(data, "texts", texts)


static func _card(base: Dictionary, id: StringName, force: int, texts: Array) -> Dictionary:
	var data := CatalogSamples.with_field(base, "id", String(id))
	data = CatalogSamples.with_field(data, "name", "Carte %s" % id)
	data = CatalogSamples.with_field(data, "force", force)
	return CatalogSamples.with_field(data, "texts", texts)
