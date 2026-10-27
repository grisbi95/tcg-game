class_name HandEffectSamples
extends RefCounted
## Catalogue en mémoire des suites des effets de main et de deck : piocher (201.3, 209.5),
## défausser (212), regarder le dessus du deck (217), réveiller (205.5), décision 0057. Reprend les
## cartes de TriggerSamples (Soldat, Martyr…) et leur ajoute les Spells et l'Unit d'essai de
## docs/ruleset/50-cartes/ (Étude, Inspiration, Charge, Éclaireur, Observatoire).

## Spell d'Action de coût 1 : piochez deux cartes, puis défaussez une carte de votre main.
const STUDY: StringName = &"hand_study"
## Spell d'Action de coût 1 : défaussez deux cartes de votre main.
const DISCARD_TWO: StringName = &"hand_discard_two"
## Spell d'Action de coût 1 : défaussez une carte de votre main.
const DISCARD_ONE: StringName = &"hand_discard_one"
## Spell de Réaction de coût 1 : piochez une carte.
const INSPIRATION: StringName = &"hand_inspiration"
## Spell d'Action de coût 1 : piochez une carte.
const DRAW_ONE: StringName = &"hand_draw_one"
## Spell d'Action de coût 1 : regardez la carte du dessus de votre deck.
const LOOK: StringName = &"hand_look"
## Spell d'Action de coût 1 : réveillez une Unit alliée ciblée.
const CHARGE: StringName = &"hand_charge"
## Spell d'Action de coût 1 : détruisez une Unit ennemie ciblée de Force 3 au plus.
const DESTROYER: StringName = &"hand_destroyer"
## Spell d'Action de coût 1 : réveillez une Unit ou un Hero allié ciblé.
const HERO_CHARGE: StringName = &"hand_hero_charge"
## Hero dont l'effet, à la fin du tour, réveille ce Hero.
const WAKING_HERO: StringName = &"hand_waking_hero"
## Arrivée : réveillez cette Unit.
const SCOUT: StringName = &"hand_scout"
## Arrivée : regardez la carte du dessus de votre deck.
const LOOKOUT: StringName = &"hand_lookout"
## Spell de Réaction de coût 1 : contrecarrez un Spell de la pile.
const COUNTER: StringName = &"hand_counter"
## Spell d'Action de coût 1 : renvoyez dans la main une Unit ennemie ciblée.
const RETURNER: StringName = &"hand_returner"
## Gear d'essai de CatalogSamples.gear().
const GEAR: StringName = &"sample_gear"
const SPELL_COST: int = 1
const UNIT_FORCE: int = 1
const SOURCES_IN_PLAY: int = 4


static func catalog() -> Catalog:
	var result := TriggerSamples.catalog()
	result.add_card(CardDefinition.from_dict(CatalogSamples.gear()))
	result.add_hero(HeroDefinition.from_dict(waking_hero_data()))
	for data: Dictionary in card_data():
		result.add_card(CardDefinition.from_dict(data))
	return result


## Objets JSON des cartes de ce catalogue, pour vérifier qu'elles sont valides.
static func card_data() -> Array[Dictionary]:
	var data: Array[Dictionary] = []
	data.append(_spell(STUDY, "action", [draw_effect(2), discard_effect(1)]))
	data.append(_spell(DISCARD_TWO, "action", [discard_effect(2)]))
	data.append(_spell(DISCARD_ONE, "action", [discard_effect(1)]))
	data.append(_spell(INSPIRATION, "reaction", [draw_effect(1)]))
	data.append(_spell(DRAW_ONE, "action", [draw_effect(1)]))
	data.append(_spell(LOOK, "action", [look_effect()]))
	data.append(_spell(HERO_CHARGE, "action", [wake_unit_or_hero_effect()]))
	data.append(_spell(CHARGE, "action", [wake_effect()]))
	data.append(_spell(COUNTER, "reaction", [CatalogSamples.counter_spell_effect()]))
	data.append(_spell(RETURNER, "action", [CatalogSamples.return_to_hand_effect()]))
	data.append(_spell(DESTROYER, "action", [CatalogSamples.destroy_effect()]))
	data.append(_arrival_unit(SCOUT, wake_source_effect()))
	data.append(_arrival_unit(LOOKOUT, triggered(look_effect())))
	return data


## Un effet valide par kind de la décision 0057.
static func effect_samples() -> Array[Dictionary]:
	return [draw_effect(1), discard_effect(1), look_effect(), wake_effect(), sleep_effect()]


static func draw_effect(amount: int) -> Dictionary:
	return {"kind": "draw_cards", "timing": "resolve", "subject": "owner_player", "amount": amount}


static func discard_effect(amount: int) -> Dictionary:
	return {
		"kind": "discard_cards", "timing": "resolve", "subject": "owner_player", "amount": amount
	}


static func look_effect() -> Dictionary:
	return {"kind": "look_at_top_card", "timing": "resolve", "subject": "owner_player"}


## 205.5 : réveille une Unit alliée ciblée.
static func wake_effect() -> Dictionary:
	return {"kind": "wake", "timing": "resolve", "target": CatalogSamples.ally_unit_target()}


## 205.5.7 : endort une Unit alliée ciblée.
static func sleep_effect() -> Dictionary:
	return {"kind": "sleep", "timing": "resolve", "target": CatalogSamples.ally_unit_target()}


## Réveille une Unit ou un Hero allié ciblé.
static func wake_unit_or_hero_effect() -> Dictionary:
	var target := CatalogSamples.ally_unit_target()
	target["filter"]["piece_kinds"] = ["unit", "hero"]
	return {"kind": "wake", "timing": "resolve", "target": target}


## Hero d'essai : à la fin du tour, réveillez ce Hero.
static func waking_hero_data() -> Dictionary:
	var effect := wake_source_effect()
	effect["trigger"] = "end_of_turn"
	var data := CatalogSamples.with_field(CatalogSamples.hero(), "id", String(WAKING_HERO))
	data = CatalogSamples.with_flats(data, "passive", [])
	return CatalogSamples.with_flats(data, "triggered", [effect])


## 205.5 : réveille la pièce qui porte l'effet, déclenché à l'arrivée.
static func wake_source_effect() -> Dictionary:
	return triggered({"kind": "wake", "timing": "resolve", "subject": "source_piece"})


## Variante déclenchée à l'arrivée de `effect`.
static func triggered(effect: Dictionary) -> Dictionary:
	var result := CatalogSamples.with_field(effect, "timing", "triggered")
	return CatalogSamples.with_field(result, "trigger", "arrival")


static func _spell(id: StringName, speed: String, effects: Array[Dictionary]) -> Dictionary:
	var data := CatalogSamples.with_field(CatalogSamples.spell(), "id", String(id))
	data = CatalogSamples.with_field(data, "name", "Spell %s" % id)
	data = CatalogSamples.with_field(data, "speed", speed)
	data = CatalogSamples.with_field(data, "cost", SPELL_COST)
	return CatalogSamples.with_effects(data, effects)


static func _arrival_unit(id: StringName, effect: Dictionary) -> Dictionary:
	var data := CatalogSamples.with_field(CatalogSamples.unit(), "id", String(id))
	data = CatalogSamples.with_field(data, "name", "Carte %s" % id)
	data = CatalogSamples.with_field(data, "force", UNIT_FORCE)
	data = CatalogSamples.with_effects(data, [effect])
	return CatalogSamples.with_field(data, "keywords", [{"keyword": "arrival"}])


## État de départ des suites : quatre Sources redressées pour chaque joueur.
static func builder(card_catalog: Catalog) -> DuelStateBuilder:
	var result := DuelStateBuilder.new(DuelConfig.new(), card_catalog)
	for side: DuelState.PlayerSide in DuelState.SIDES:
		result.with_sources_in_play(side, SOURCES_IN_PLAY, 0)
	return result


## Ajoute `count` cartes de `definition_id` à la main de `side` ; renvoie leurs identifiants.
static func fill_hand(
	builder_value: DuelStateBuilder,
	side: DuelState.PlayerSide,
	count: int,
	definition_id: StringName = TriggerSamples.SOLDIER
) -> Array[int]:
	var card_ids: Array[int] = []
	for index: int in count:
		card_ids.append(builder_value.add_to_hand(side, definition_id))
	return card_ids


## Annonce de `card_id` par `side`, avec les pièces ciblées.
static func cast(side: DuelState.PlayerSide, card_id: int, piece_ids: Array[int] = []) -> CastSpell:
	var intent := CastSpell.new(side, card_id, EssencePayment.new(SPELL_COST))
	intent.target_piece_ids.assign(piece_ids)
	return intent


## Réponse d'un joueur à l'attente CHOOSE_DISCARD.
static func discard(side: DuelState.PlayerSide, card_ids: Array[int]) -> ChooseDiscard:
	return ChooseDiscard.new(side, card_ids)


## Réponse d'un joueur à l'attente CHOOSE_TOP_CARD_PLACE : sous le deck ou au dessus.
static func place(side: DuelState.PlayerSide, below: bool) -> ChooseTopCardPlace:
	var chosen := ChooseTopCardPlace.TopCardPlace.ON_TOP
	if below:
		chosen = ChooseTopCardPlace.TopCardPlace.BELOW
	return ChooseTopCardPlace.new(side, chosen)


## Le joueur B passe : la pile se résout. Renvoie les événements.
static func resolve(engine: DuelEngine) -> Array[DuelEvent]:
	return DuelChecks.pass_once(engine, DuelState.PlayerSide.B)
