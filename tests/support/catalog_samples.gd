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
		"text": "Passif.",
		"passive": [modify_force_static({"scope": "adjacent_allied_units"})],
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


## Un effet valide par kind des décisions 0002, 0056 et 0058 (ceux des effets de main :
## HandEffectSamples.effect_samples()).
static func effect_samples() -> Array[Dictionary]:
	return [
		modify_force_resolve(),
		destroy_effect(),
		counter_spell_effect(),
		create_token_effect(),
		swap_cells_effect(),
		move_unit_effect(),
		return_to_hand_effect(),
		grant_keyword_effect(),
	]


## 210.4, décision 0058 : une Unit alliée ciblée a Assaut 2 jusqu'à la fin du tour.
static func grant_keyword_effect() -> Dictionary:
	return {
		"kind": "grant_keyword",
		"timing": "resolve",
		"keyword": "assault",
		"amount": 2,
		"duration": "until_end_of_turn",
		"target": ally_unit_target(),
	}


## 214 : échange les cases de deux Units alliées ciblées.
static func swap_cells_effect() -> Dictionary:
	var target := ally_unit_target()
	target["count_min"] = 2
	target["count_max"] = 2
	return {"kind": "swap_cells", "timing": "resolve", "target": target}


## 215, décision 0056 : déplace une Unit ennemie ciblée sur une case libre ciblée adjacente.
static func move_unit_effect() -> Dictionary:
	var target := ally_unit_target()
	target["side"] = "enemy"
	return {
		"kind": "move_unit",
		"timing": "resolve",
		"target": target,
		"destination": {"what": "cell", "adjacent_to": "target_piece"},
	}


## 216 : renvoie dans la main une Unit ennemie ciblée.
static func return_to_hand_effect() -> Dictionary:
	var target := ally_unit_target()
	target["side"] = "enemy"
	return {"kind": "return_to_hand", "timing": "resolve", "target": target}


## Spell d'Action qui crée un jeton Unit sur une case ciblée.
static func token_spell(id: StringName, cost: int) -> CardDefinition:
	var data := with_field(spell(), "id", String(id))
	data = with_field(data, "speed", "action")
	data = with_field(data, "cost", cost)
	data = with_field(data, "effects", [create_token_effect()])
	return CardDefinition.from_dict(data)


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
