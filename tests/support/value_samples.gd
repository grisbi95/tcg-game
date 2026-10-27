class_name ValueSamples
extends RefCounted
## Catalogue en mémoire des suites de la valeur X et des mots-clés accordés (213, 210.4, décision
## 0058). Reprend la forme de Exécution, Furie, Sève, Hache de guerre, Cape d'ombre et Tambour de
## guerre de docs/ruleset/50-cartes/ sans en être les cartes (c.6).

## Unit de Force 3, sans mot-clé.
const SOLDIER: StringName = &"value_soldier"
## Unit de Force 3 à Assaut 2.
const RAIDER: StringName = &"value_raider"
## Unit de Force 3 à Rempart 1.
const GUARD: StringName = &"value_guard"
## Spell d'Action à coût X : détruisez une Unit ennemie ciblée de Force X ou moins.
const EXECUTION: StringName = &"value_execution"
## Spell d'Action à coût X : une Unit alliée ciblée a +X Force jusqu'à la fin du tour.
const BLESSING: StringName = &"value_blessing"
## Spell d'Action de coût 3 : une Unit alliée ciblée a Assaut X jusqu'à la fin du tour, X étant sa
## Force à la résolution.
const FURY: StringName = &"value_fury"
## Spell de Réaction de coût 2 : comme FURY avec Rempart.
const SAP: StringName = &"value_sap"
## Spell d'Action de coût 1 : une Unit alliée ciblée a Assaut 1 tant que la pièce est en jeu.
const WATCH: StringName = &"value_watch"
## Gear de coût 1 : la Unit qui porte ce Gear a Assaut 2.
const WAR_AXE: StringName = &"value_war_axe"
## Gear de coût 1 : la Unit qui porte ce Gear a Rempart 2.
const SHADOW_CLOAK: StringName = &"value_shadow_cloak"
## Building de Force 3 : les Units alliées adjacentes à ce Building ont Assaut 1.
const WAR_DRUM: StringName = &"value_war_drum"
## Gear d'essai de CatalogSamples.gear() : +1 Force à la Unit porteuse.
const FORCE_GEAR: StringName = &"sample_gear"

const UNIT_FORCE: int = 3
const RAIDER_ASSAULT: int = 2
const GUARD_RAMPART: int = 1
const FURY_COST: int = 3
const SAP_COST: int = 2
const WATCH_COST: int = 1
const AXE_ASSAULT: int = 2
const CLOAK_RAMPART: int = 2
const DRUM_ASSAULT: int = 1
const GEAR_FORCE_BONUS: int = 1  # CatalogSamples.modify_force_static()
const SOURCES_IN_PLAY: int = 6


static func catalog() -> Catalog:
	var result := Catalog.new()
	for data: Dictionary in card_data():
		result.add_card(CardDefinition.from_dict(data))
	return result


## Objets JSON des cartes de ce catalogue, pour vérifier qu'elles sont valides.
static func card_data() -> Array[Dictionary]:
	var cards: Array[Dictionary] = [
		CatalogSamples.gear(),
		_unit(SOLDIER, []),
		_unit(RAIDER, [{"keyword": "assault", "value": RAIDER_ASSAULT}]),
		_unit(GUARD, [{"keyword": "rampart", "value": GUARD_RAMPART}]),
		_spell(EXECUTION, "X", "action", [execution_effect()]),
		_spell(BLESSING, "X", "action", [blessing_effect()]),
		_spell(FURY, FURY_COST, "action", [fury_effect("assault")]),
		_spell(SAP, SAP_COST, "reaction", [fury_effect("rampart")]),
		_spell(WATCH, WATCH_COST, "action", [watch_effect()]),
		_gear(WAR_AXE, static_grant("assault", AXE_ASSAULT, CatalogSamples.bearer_scope())),
		_gear(SHADOW_CLOAK, static_grant("rampart", CLOAK_RAMPART, CatalogSamples.bearer_scope())),
		_war_drum(),
	]
	return cards


## Détruisez une Unit ennemie ciblée de Force X ou moins, X choisi à l'annonce.
static func execution_effect() -> Dictionary:
	var target := CatalogSamples.ally_unit_target()
	target["filter"]["side"] = "enemy"
	target["max_force"] = "X"
	return {"kind": "destroy", "timing": "resolve", "x_source": "chosen", "target": target}


## Une Unit alliée ciblée a +X Force jusqu'à la fin du tour, X choisi à l'annonce.
static func blessing_effect() -> Dictionary:
	return CatalogSamples.modify_force_resolve({"amount": "X", "x_source": "chosen"})


## Une Unit alliée ciblée a `keyword` X jusqu'à la fin du tour, X étant sa Force à la résolution.
static func fury_effect(keyword: String) -> Dictionary:
	return {
		"kind": "grant_keyword",
		"timing": "resolve",
		"keyword": keyword,
		"amount": "X",
		"x_source": "target_force",
		"duration": "until_end_of_turn",
		"target": CatalogSamples.ally_unit_target(),
	}


## Une Unit alliée ciblée a Assaut 1 tant que la pièce est en jeu.
static func watch_effect() -> Dictionary:
	return {
		"kind": "grant_keyword",
		"timing": "resolve",
		"keyword": "assault",
		"amount": 1,
		"duration": "while_piece_in_play",
		"target": CatalogSamples.ally_unit_target(),
	}


## Effet statique qui accorde `keyword` `amount` aux pièces de `scope`.
static func static_grant(keyword: String, amount: int, scope: Dictionary) -> Dictionary:
	return {
		"kind": "grant_keyword",
		"timing": "static",
		"scope": scope,
		"keyword": keyword,
		"amount": amount,
	}


## Annonce de `card_id` par `side` : X choisi, X Essence ou `cost` payés, pièces ciblées.
static func cast(
	side: DuelState.PlayerSide, card_id: int, x_value: int, piece_ids: Array[int] = []
) -> CastSpell:
	var intent := CastSpell.new(side, card_id, EssencePayment.new(x_value))
	intent.x_value = x_value
	intent.target_piece_ids.assign(piece_ids)
	return intent


## Annonce d'un Spell à coût fixe `cost`.
static func cast_fixed(
	side: DuelState.PlayerSide, card_id: int, cost: int, piece_ids: Array[int] = []
) -> CastSpell:
	var intent := CastSpell.new(side, card_id, EssencePayment.new(cost))
	intent.target_piece_ids.assign(piece_ids)
	return intent


## État de départ des suites : six Sources redressées pour chaque joueur.
static func builder(card_catalog: Catalog) -> DuelStateBuilder:
	var result := DuelStateBuilder.new(DuelConfig.new(), card_catalog)
	for side: DuelState.PlayerSide in DuelState.SIDES:
		result.with_sources_in_play(side, SOURCES_IN_PLAY, 0)
	return result


static func _unit(id: StringName, keywords: Array) -> Dictionary:
	var data := CatalogSamples.with_field(CatalogSamples.unit(), "id", String(id))
	data = CatalogSamples.with_field(data, "name", "Unit %s" % id)
	data = CatalogSamples.with_field(data, "force", UNIT_FORCE)
	return CatalogSamples.with_field(data, "keywords", keywords)


static func _spell(id: StringName, cost: Variant, speed: String, effects: Array) -> Dictionary:
	var data := CatalogSamples.with_field(CatalogSamples.spell(), "id", String(id))
	data = CatalogSamples.with_field(data, "name", "Spell %s" % id)
	data = CatalogSamples.with_field(data, "speed", speed)
	data = CatalogSamples.with_field(data, "cost", cost)
	return CatalogSamples.with_field(data, "effects", effects)


static func _gear(id: StringName, effect: Dictionary) -> Dictionary:
	var data := CatalogSamples.with_field(CatalogSamples.gear(), "id", String(id))
	data = CatalogSamples.with_field(data, "name", "Gear %s" % id)
	return CatalogSamples.with_field(data, "effects", [effect])


static func _war_drum() -> Dictionary:
	var data := CatalogSamples.with_field(CatalogSamples.building(), "id", String(WAR_DRUM))
	data = CatalogSamples.with_field(data, "name", "Building %s" % WAR_DRUM)
	var effect := static_grant("assault", DRUM_ASSAULT, CatalogSamples.adjacent_allied_scope())
	return CatalogSamples.with_field(data, "effects", [effect])
