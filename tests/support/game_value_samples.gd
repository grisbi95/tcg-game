class_name GameValueSamples
extends RefCounted
## Catalogue en mémoire de l'étape c.5e (valeur du jeu partagée et déclencheurs à objet, décision
## 0065). Reprend TextSamples (Purge, Contre de HandEffectSamples…) et ajoute, sous la forme des
## cartes de docs/ruleset/50-cartes/ sans en être les cartes (c.6) : des Units et un
## Building qui réagissent à la destruction d'une autre pièce ou au contrecarrage d'un Spell, des
## textes à condition sur une valeur du jeu et des Spells dont X se lit sur une valeur du jeu.

## Unit : quand une autre Unit alliée est détruite, piochez une carte.
const WITNESS: StringName = &"gv_witness"
## Unit : quand une Unit ennemie est détruite, piochez une carte.
const AVENGER: StringName = &"gv_avenger"
## Unit : quand une autre pièce est détruite, piochez une carte.
const VULTURE: StringName = &"gv_vulture"
## Unit : quand un Building allié est détruit, piochez une carte.
const MOURNER: StringName = &"gv_mourner"
## Unit : quand une autre Unit alliée adjacente est détruite, piochez une carte.
const NEIGHBOR: StringName = &"gv_neighbor"
## Unit : quand un Spell adverse est contrecarré, piochez une carte.
const HUNTER: StringName = &"gv_hunter"
## Unit : quand un Spell allié est contrecarré, piochez une carte.
const GUARDIAN: StringName = &"gv_guardian"
## Unit : quand un Spell est contrecarré, piochez une carte.
const ONLOOKER: StringName = &"gv_onlooker"
## Unit : quand un Spell est contrecarré, si son coût est 3 ou plus, piochez une carte.
const MOURNING_MERCHANT: StringName = &"gv_mourning_merchant"
## Unit : quand vous annoncez un Spell, si son coût est 3 ou plus, piochez une carte.
const HAGGLER: StringName = &"gv_haggler"
## Building : au début de votre tour, si vous avez 3 Units alliées ou plus, piochez une carte.
const CROWD: StringName = &"gv_crowd"
## Spell d'Action de coût 3 : piochez une carte.
const BIG_SPELL: StringName = &"gv_big_spell"
## Spell d'Action de coût 1 : si vous avez 2 Units alliées ou moins, piochez une carte.
const ROLLCALL: StringName = &"gv_rollcall"
## Spell d'Action de coût 1 : si vous avez 2 Units alliées ou plus, piochez une carte.
const GATHER: StringName = &"gv_gather"
## Spell d'Action de coût 1 : piochez autant de cartes que d'Units alliées.
const CENSUS: StringName = &"gv_census"
## Spell d'Action de coût 1 : piochez autant de cartes que vous en avez en main.
const GREED: StringName = &"gv_greed"
## Spell d'Action de coût 1 : défaussez deux cartes de votre main, puis piochez autant de cartes.
const RENEW: StringName = &"gv_renew"
## Spell d'Action de coût 1 : défaussez une carte de votre main, puis défaussez-en autant.
const ECHOING_DISCARD: StringName = &"gv_echoing_discard"
## Spell d'Action de coût X : piochez X cartes.
const SURGE: StringName = &"gv_surge"
## Spell d'Action de coût X : piochez X cartes, puis défaussez X cartes de votre main.
const RESERVE: StringName = &"gv_reserve"
## Spell d'Action de coût X : défaussez X cartes de votre main.
const SHED: StringName = &"gv_shed"
## Spell d'Action de coût 1 : défaussez autant de cartes que d'Units ennemies.
const TITHE: StringName = &"gv_tithe"
## Spell d'Action de coût X : si X vaut 2 ou plus, piochez une carte.
const BIG_X: StringName = &"gv_big_x"

const UNIT_FORCE: int = 2
const BIG_COST: int = 3
const CROWD_SIZE: int = 3
const ROLLCALL_LIMIT: int = 2
const RENEW_DISCARDED: int = 2


static func catalog() -> Catalog:
	var result := TextSamples.catalog()
	for data: Dictionary in card_data():
		result.add_card(CardDefinition.from_dict(data))
	return result


## Objets JSON des cartes de ce catalogue, pour vérifier qu'elles sont valides.
static func card_data() -> Array[Dictionary]:
	var data: Array[Dictionary] = []
	data.append_array(_destruction_cards())
	data.append_array(_countering_cards())
	data.append_array(_condition_cards())
	data.append_array(_x_cards())
	return data


## Un effet « piochez `amount` cartes » dans un texte ; `x_from` fait de `amount` un « X ».
static func draw(amount: Variant = 1, x_from: Dictionary = {}) -> Dictionary:
	return _amount_effect("draw_cards", amount, x_from)


## Un effet « défaussez `amount` cartes de votre main » dans un texte.
static func discard(amount: Variant = 1, x_from: Dictionary = {}) -> Dictionary:
	return _amount_effect("discard_cards", amount, x_from)


## Un texte déclenché par `trigger` : `extra` porte `object` et `condition`.
static func triggered_text(trigger: String, effects: Array, extra: Dictionary = {}) -> Dictionary:
	var details := {"trigger": trigger}
	details.merge(extra, true)
	return TextSamples.text_of(effects, "triggered", details)


## Une condition sur une valeur du jeu.
static func condition(value: Dictionary, comparison: String, amount: int) -> Dictionary:
	return CatalogSamples.condition(value, comparison, amount)


## Valeur du jeu : nombre d'Units alliées en jeu.
static func allied_units() -> Dictionary:
	return {"kind": "piece_count", "filter": {"side": "ally", "piece_kinds": ["unit"]}}


## Valeur du jeu : nombre d'Units ennemies en jeu.
static func enemy_units() -> Dictionary:
	return {"kind": "piece_count", "filter": {"side": "enemy", "piece_kinds": ["unit"]}}


static func _amount_effect(kind: String, amount: Variant, x_from: Dictionary) -> Dictionary:
	var effect := {"kind": kind, "subject": "owner_player", "amount": amount}
	if not x_from.is_empty():
		effect["amount"] = "X"
		effect["x_from"] = x_from
	return effect


static func _destruction_cards() -> Array[Dictionary]:
	var ally_unit := {"side": "ally", "piece_kinds": ["unit"]}
	var adjacent := {"side": "ally", "piece_kinds": ["unit"], "relation": "adjacent"}
	return [
		_unit(WITNESS, [_destroyed_text(ally_unit)]),
		_unit(AVENGER, [_destroyed_text({"side": "enemy", "piece_kinds": ["unit"]})]),
		_unit(VULTURE, [_destroyed_text({})]),
		_unit(MOURNER, [_destroyed_text({"side": "ally", "piece_kinds": ["building"]})]),
		_unit(NEIGHBOR, [_destroyed_text(adjacent)]),
	]


static func _countering_cards() -> Array[Dictionary]:
	return [
		_unit(HUNTER, [_countered_text({"side": "enemy"}, {})]),
		_unit(GUARDIAN, [_countered_text({"side": "ally"}, {})]),
		_unit(ONLOOKER, [_countered_text({}, {})]),
		_unit(MOURNING_MERCHANT, [_countered_text({}, _spell_cost_condition())]),
		_unit(HAGGLER, [_announced_text(_spell_cost_condition())]),
	]


static func _condition_cards() -> Array[Dictionary]:
	var crowd := condition(allied_units(), "at_least", CROWD_SIZE)
	var few := condition(allied_units(), "at_most", ROLLCALL_LIMIT)
	var many := condition(allied_units(), "at_least", ROLLCALL_LIMIT)
	var big_x := condition({"kind": "chosen_x"}, "at_least", ROLLCALL_LIMIT)
	var crowd_text := triggered_text("start_of_own_turn", [draw()], {"condition": crowd})
	var data: Array[Dictionary] = [
		_card(CatalogSamples.building(), CROWD, UNIT_FORCE, [crowd_text]),
		_spell(ROLLCALL, 1, [_text([conditioned(draw(), few)])]),
		_spell(GATHER, 1, [_text([conditioned(draw(), many)])]),
		_spell(BIG_SPELL, BIG_COST, [_text([draw()])]),
		_spell(BIG_X, "X", [_text([conditioned(draw(), big_x)])]),
	]
	return data


static func _x_cards() -> Array[Dictionary]:
	var chosen := {"kind": "chosen_x"}
	var previous := {"kind": "discarded_by_previous_effect"}
	return [
		_spell(CENSUS, 1, [_text([draw(1, allied_units())])]),
		_spell(GREED, 1, [_text([draw(1, {"kind": "hand_size"})])]),
		_spell(RENEW, 1, [_text([discard(RENEW_DISCARDED), draw(1, previous)])]),
		_spell(ECHOING_DISCARD, 1, [_text([discard(1), discard(1, previous)])]),
		_spell(SURGE, "X", [_text([draw(1, chosen)])]),
		_spell(RESERVE, "X", [_text([draw(1, chosen), discard(1, chosen)])]),
		_spell(SHED, "X", [_text([discard(1, chosen)])]),
		_spell(TITHE, 1, [_text([discard(1, enemy_units())])]),
	]


static func _destroyed_text(object: Dictionary) -> Dictionary:
	var extra := {}
	if not object.is_empty():
		extra["object"] = object
	return triggered_text("other_piece_destroyed", [draw()], extra)


static func _countered_text(object: Dictionary, event_condition: Dictionary) -> Dictionary:
	var extra := {}
	if not object.is_empty():
		extra["object"] = object
	if not event_condition.is_empty():
		extra["condition"] = event_condition
	return triggered_text("spell_countered", [draw()], extra)


static func _announced_text(event_condition: Dictionary) -> Dictionary:
	return triggered_text("own_spell_announced", [draw()], {"condition": event_condition})


static func _spell_cost_condition() -> Dictionary:
	return condition({"kind": "event_spell_cost"}, "at_least", BIG_COST)


static func conditioned(effect: Dictionary, effect_condition: Dictionary) -> Dictionary:
	return CatalogSamples.with_field(effect, "condition", effect_condition)


static func _text(effects: Array) -> Dictionary:
	return TextSamples.text_of(effects)


static func _unit(id: StringName, texts: Array) -> Dictionary:
	return _card(CatalogSamples.unit(), id, UNIT_FORCE, texts)


static func _spell(id: StringName, cost: Variant, texts: Array) -> Dictionary:
	var data := CatalogSamples.with_field(CatalogSamples.spell(), "id", String(id))
	data = CatalogSamples.with_field(data, "name", "Spell %s" % id)
	data = CatalogSamples.with_field(data, "speed", "action")
	data = CatalogSamples.with_field(data, "cost", cost)
	return CatalogSamples.with_field(data, "texts", texts)


static func _card(base: Dictionary, id: StringName, force: int, texts: Array) -> Dictionary:
	var data := CatalogSamples.with_field(base, "id", String(id))
	data = CatalogSamples.with_field(data, "name", "Carte %s" % id)
	if base.has("force"):
		data = CatalogSamples.with_field(data, "force", force)
	return CatalogSamples.with_field(data, "texts", texts)
