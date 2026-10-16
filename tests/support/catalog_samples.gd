class_name CatalogSamples
extends RefCounted
## Dictionnaires JSON minimaux et valides pour les tests du catalogue (décisions 0002 et 0010).
##
## Chaque fonction renvoie une copie neuve à modifier avec `with_field()` et `without_field()`.
## Ce ne sont pas les cartes de test de l'étape 1.9.


static func unit() -> Dictionary:
	return {
		"id": "sample_unit",
		"name": "Unit d'essai",
		"cost": 2,
		"type": "unit",
		"text": "",
		"force": 3
	}


static func building() -> Dictionary:
	return {
		"id": "sample_building",
		"name": "Building d'essai",
		"cost": 3,
		"type": "building",
		"text": "",
		"force": 5,
	}


static func spell() -> Dictionary:
	return {
		"id": "sample_spell",
		"name": "Spell d'essai",
		"cost": 1,
		"type": "spell",
		"speed": "reaction",
		"text": "Une Unit alliée ciblée a +2 Force jusqu'à la fin du tour.",
		"effects": [modify_force_resolve()],
	}


static func gear() -> Dictionary:
	return {
		"id": "sample_gear",
		"name": "Gear d'essai",
		"cost": 1,
		"type": "gear",
		"text": "La Unit qui porte ce Gear a +1 Force.",
		"effects": [modify_force_static()],
	}


static func hero() -> Dictionary:
	return {
		"id": "sample_hero",
		"name": "Hero d'essai",
		"health": 15,
		"text": "Passif et pouvoir.",
		"power_cost": 2,
		"passive": [modify_force_static({"scope": "adjacent_allied_units"})],
		"power": [modify_force_resolve({"amount": 1})],
	}


static func modify_force_resolve(overrides: Dictionary = {}) -> Dictionary:
	var effect := {
		"kind": "modify_force",
		"timing": "resolve",
		"amount": 2,
		"duration": "until_end_of_turn",
		"target": ally_unit_target(),
	}
	effect.merge(overrides, true)
	return effect


static func modify_force_static(overrides: Dictionary = {}) -> Dictionary:
	var effect := {"kind": "modify_force", "timing": "static", "scope": "bearer", "amount": 1}
	effect.merge(overrides, true)
	return effect


static func triggered(trigger: String, overrides: Dictionary = {}) -> Dictionary:
	var effect := modify_force_resolve({"timing": "triggered", "trigger": trigger})
	effect.merge(overrides, true)
	return effect


static func destroy_effect() -> Dictionary:
	var target := ally_unit_target()
	target["side"] = "enemy"
	target["max_force"] = 3
	return {"kind": "destroy", "timing": "resolve", "target": target}


static func counter_spell_effect() -> Dictionary:
	return {
		"kind": "counter_spell",
		"timing": "resolve",
		"target": {"what": "spell_on_stack"},
	}


static func create_token_effect() -> Dictionary:
	return {
		"kind": "create_token",
		"timing": "resolve",
		"token_piece_kind": "unit",
		"token_force": 2,
		"target": {"what": "cell", "row": "own_first"},
	}


static func ally_unit_target() -> Dictionary:
	return {"what": "piece", "side": "ally", "piece_kinds": ["unit"]}


## Copie de `data` avec `key` fixé à `value`.
static func with_field(data: Dictionary, key: String, value: Variant) -> Dictionary:
	var copy := data.duplicate(true)
	copy[key] = value
	return copy


## Copie de `data` sans `key`.
static func without_field(data: Dictionary, key: String) -> Dictionary:
	var copy := data.duplicate(true)
	copy.erase(key)
	return copy


## Vrai si l'une des erreurs contient `fragment`.
static func mentions(errors: PackedStringArray, fragment: String) -> bool:
	for error: String in errors:
		if error.contains(fragment):
			return true
	return false


## Fichier JSON de catalogue contenant ces entrées.
static func catalog_text(cards: Array, heroes: Array = [], edition: String = "0.28") -> String:
	return JSON.stringify({"edition": edition, "heroes": heroes, "cards": cards})
