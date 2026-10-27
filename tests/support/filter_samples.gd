class_name FilterSamples
extends RefCounted
## Catalogue en mémoire des suites de l'étape c.5c (sujets, portées et filtres, décision 0062).
## Reprend NamedTriggerSamples (Apprenti, Spectre des archives, Trophée…) et ajoute, sous la forme
## des cartes de docs/ruleset/50-cartes/ sans en être les cartes (c.6) : Endormir, Porte-enseigne,
## Ancien du bosquet, Obélisque, Bannière, une démolition et deux cartes à plusieurs effets
## déclenchés.

## Spell d'Action de coût 1 : endormez une Unit, un Hero ou un Building ciblé (de tout côté).
const SLEEPER: StringName = &"filter_sleeper"
## Unit : à la fin de votre tour, endormez cette Unit.
const DROWSY: StringName = &"filter_drowsy"
## Unit : les autres Units alliées adjacentes à cette Unit ont +1 Force.
const STANDARD_BEARER: StringName = &"filter_standard_bearer"
## Unit : les autres Units alliées situées dans la même rangée que cette Unit ont +1 Force.
const ELDER: StringName = &"filter_elder"
## Building : les Units ennemies adjacentes à ce Building ont −1 Force.
const OBELISK: StringName = &"filter_obelisk"
## Gear : les Units alliées adjacentes à l'Unit qui porte ce Gear ont +1 Force.
const BANNER: StringName = &"filter_banner"
## Building : au début de votre tour, détruisez ce Building (seconde moitié de Chantier ; la carte
## complète attend l'ordre du texte, 207.7.4, étape c.5d).
const DEMOLITION: StringName = &"filter_demolition"
## Unit : à l'annonce d'un Spell de votre joueur, deux effets : une fois par tour, cette Unit a +1
## Force ; sans limite, cette Unit a +2 Force (jusqu'à la fin du tour).
const MIXED: StringName = &"filter_mixed"
## Unit : à l'annonce d'un Spell de votre joueur, deux effets chacun « une fois par tour » : +1 et
## +2 Force à cette Unit jusqu'à la fin du tour.
const TWICE_ONCE: StringName = &"filter_twice_once"

const UNIT_FORCE: int = 2
const BUILDING_FORCE: int = 3
const BONUS: int = 1
const BIG_BONUS: int = 2
const MALUS: int = -1
const SLEEPER_COST: int = 1


static func catalog() -> Catalog:
	var result := NamedTriggerSamples.catalog()
	for data: Dictionary in card_data():
		result.add_card(CardDefinition.from_dict(data))
	return result


## Objets JSON des cartes de ce catalogue, pour vérifier qu'elles sont valides.
static func card_data() -> Array[Dictionary]:
	return [
		_sleeper(),
		_unit(DROWSY, [_drowsy_effect()]),
		_unit(STANDARD_BEARER, [_aura(_scope("adjacent", "ally", false), BONUS)]),
		_unit(ELDER, [_aura(_scope("same_row", "ally", false), BONUS)]),
		_building(OBELISK, [_aura(_scope("adjacent", "enemy", true), MALUS)]),
		_gear(BANNER, [_aura(_scope("adjacent", "ally", true), BONUS)]),
		_building(DEMOLITION, [_demolition_effect()]),
		_unit(MIXED, [_self_boost(BONUS, true), _self_boost(BIG_BONUS, false)]),
		_unit(TWICE_ONCE, [_self_boost(BONUS, true), _self_boost(BIG_BONUS, true)]),
	]


## Portée « relation » des pièces du côté `side`, genre Unit ; « autres » : la pièce qui porte
## l'effet est exclue si `include_reference` est faux.
static func _scope(relation: String, side: String, include_reference: bool) -> Dictionary:
	return {
		"side": side,
		"piece_kinds": ["unit"],
		"relation": relation,
		"include_reference": include_reference,
	}


static func _aura(scope: Dictionary, amount: int) -> Dictionary:
	return CatalogSamples.modify_force_static({"scope": scope, "amount": amount})


static func _self_boost(amount: int, once_per_turn: bool) -> Dictionary:
	return {
		"kind": "modify_force",
		"timing": "triggered",
		"trigger": "own_spell_announced",
		"subject": "source_piece",
		"amount": amount,
		"duration": "until_end_of_turn",
		"once_per_turn": once_per_turn,
	}


static func _drowsy_effect() -> Dictionary:
	return {
		"kind": "sleep",
		"timing": "triggered",
		"trigger": "end_of_turn",
		"subject": "source_piece",
	}


static func _demolition_effect() -> Dictionary:
	return {
		"kind": "destroy",
		"timing": "triggered",
		"trigger": "start_of_own_turn",
		"subject": "source_piece",
	}


static func _sleeper() -> Dictionary:
	var target := {
		"what": "piece",
		"filter": {"piece_kinds": ["unit", "hero", "building"]},
	}
	var effect := {"kind": "sleep", "timing": "resolve", "target": target}
	var data := CatalogSamples.with_field(CatalogSamples.spell(), "id", String(SLEEPER))
	data = CatalogSamples.with_field(data, "name", "Spell %s" % SLEEPER)
	data = CatalogSamples.with_field(data, "speed", "action")
	data = CatalogSamples.with_field(data, "cost", SLEEPER_COST)
	return CatalogSamples.with_field(data, "effects", [effect])


static func _unit(id: StringName, effects: Array) -> Dictionary:
	return _card(CatalogSamples.unit(), id, UNIT_FORCE, effects)


static func _building(id: StringName, effects: Array) -> Dictionary:
	return _card(CatalogSamples.building(), id, BUILDING_FORCE, effects)


static func _gear(id: StringName, effects: Array) -> Dictionary:
	var data := CatalogSamples.with_field(CatalogSamples.gear(), "id", String(id))
	data = CatalogSamples.with_field(data, "name", "Gear %s" % id)
	return CatalogSamples.with_field(data, "effects", effects)


static func _card(base: Dictionary, id: StringName, force: int, effects: Array) -> Dictionary:
	var data := CatalogSamples.with_field(base, "id", String(id))
	data = CatalogSamples.with_field(data, "name", "Carte %s" % id)
	data = CatalogSamples.with_field(data, "force", force)
	return CatalogSamples.with_field(data, "effects", effects)
