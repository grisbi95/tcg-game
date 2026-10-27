class_name NamedTriggerSamples
extends RefCounted
## Catalogue en mémoire des déclencheurs nommés avec leur auteur et de la condition « si »
## (204.3.12, 206.3.7, 207.3.12, 207.3.13, 207.3.14, 212.2.5, décision 0060). Reprend le catalogue
## des effets de main (Soldat, Géant, Étude, « piochez », Gear d'essai) et lui ajoute des cartes de
## la forme de celles de docs/ruleset/50-cartes/ : Apprenti, Lame-sort, Spectre des archives,
## Bibliothèque, Forge, Grimoire, Trophée, Poudrière et le Hero Pilleuse.

## Unit : chaque fois que vous annoncez un Spell, cette Unit a +1 Force jusqu'à la fin du tour.
const APPRENTICE: StringName = &"named_apprentice"
## Unit : une fois par tour, quand vous annoncez un Spell, une Unit alliée ciblée a +1 Force.
const SPELLBLADE: StringName = &"named_spellblade"
## Unit : une fois par tour, quand vous défaussez une carte de votre main, cette Unit a +2 Force
## jusqu'à la fin du tour.
const SPECTRE: StringName = &"named_spectre"
## Building : au début de votre tour, piochez une carte.
const LIBRARY: StringName = &"named_library"
## Building : au début de votre tour, une Unit alliée ciblée a +2 Force jusqu'à la fin du tour.
const FORGE: StringName = &"named_forge"
## Gear : quand l'Unit qui porte ce Gear détruit son défenseur, piochez une carte.
const GRIMOIRE: StringName = &"named_grimoire"
## Gear : quand l'Unit qui porte ce Gear détruit son défenseur, elle a +1 Force tant que la pièce
## est en jeu.
const TROPHY: StringName = &"named_trophy"
## Gear : une fois par tour, à la fin du tour, piochez une carte.
const LANTERN: StringName = &"named_lantern"
## Building à Dernier souffle : détruisez une Unit ennemie ciblée de Force 4 ou moins adjacente à
## la case de ce Building.
const POWDER_KEG: StringName = &"named_powder_keg"
## Comme PILLEUSE, avec la mention « une fois par tour ».
const ONCE_PILLEUSE: StringName = &"named_once_pilleuse"
## Unit : quand elle détruit son défenseur, piochez une carte.
const CONQUEROR: StringName = &"named_conqueror"
## Unit : chaque fois que vous défaussez une carte, une Unit alliée ciblée a +1 Force (sans « une
## fois par tour »).
const GHOST: StringName = &"named_ghost"
## Hero : au début de votre tour, si vous avez une carte ou moins en main, piochez deux cartes.
const PILLEUSE: StringName = &"named_pilleuse"

const APPRENTICE_FORCE: int = 2
const SPELLBLADE_FORCE: int = 3
const SPECTRE_FORCE: int = 2
const CONQUEROR_FORCE: int = 4
const GHOST_FORCE: int = 1
const BUILDING_FORCE: int = 2
const POWDER_KEG_FORCE: int = 3
const POWDER_KEG_MAX_FORCE: int = 4
const SPECTRE_BONUS: int = 2
const SPELLBLADE_BONUS: int = 1
const FORGE_BONUS: int = 2
const TROPHY_BONUS: int = 1
const PILLEUSE_HAND_LIMIT: int = 1
const PILLEUSE_DRAWN: int = 2


static func catalog() -> Catalog:
	var result := HandEffectSamples.catalog()
	for data: Dictionary in card_data():
		result.add_card(CardDefinition.from_dict(data))
	result.add_hero(HeroDefinition.from_dict(hero_data(PILLEUSE, false)))
	result.add_hero(HeroDefinition.from_dict(hero_data(ONCE_PILLEUSE, true)))
	return result


## Objets JSON des cartes de ce catalogue, pour vérifier qu'elles sont valides.
static func card_data() -> Array[Dictionary]:
	var data: Array[Dictionary] = []
	data.append(_unit(APPRENTICE, APPRENTICE_FORCE, _self_boost("own_spell_announced", 1, false)))
	data.append(_unit(SPELLBLADE, SPELLBLADE_FORCE, _boost("own_spell_announced", 1, true)))
	var spectre_effect := _self_boost("own_card_discarded", SPECTRE_BONUS, true)
	data.append(_unit(SPECTRE, SPECTRE_FORCE, spectre_effect))
	data.append(_unit(CONQUEROR, CONQUEROR_FORCE, _draw("destroys_defender")))
	data.append(_unit(GHOST, GHOST_FORCE, _boost("own_card_discarded", 1, false)))
	data.append(_building(LIBRARY, BUILDING_FORCE, _draw("start_of_own_turn")))
	data.append(_building(FORGE, BUILDING_FORCE, _boost("start_of_own_turn", FORGE_BONUS, false)))
	data.append(_gear(GRIMOIRE, _draw("destroys_defender")))
	var lantern_effect := _draw("end_of_turn")
	lantern_effect["once_per_turn"] = true
	data.append(_gear(LANTERN, lantern_effect))
	var trophy_effect := _self_boost("destroys_defender", TROPHY_BONUS, false)
	trophy_effect["duration"] = "while_piece_in_play"
	data.append(_gear(TROPHY, trophy_effect))
	var keg := _building(POWDER_KEG, POWDER_KEG_FORCE, _powder_effect())
	keg["keywords"] = [{"keyword": "last_breath"}]
	data.append(keg)
	return data


## Hero d'essai : au début de votre tour, si la main compte une carte ou moins, piochez deux cartes.
static func hero_data(id: StringName, once_per_turn: bool) -> Dictionary:
	var effect := HandEffectSamples.draw_effect(PILLEUSE_DRAWN)
	effect["timing"] = "triggered"
	effect["trigger"] = "start_of_own_turn"
	effect["once_per_turn"] = once_per_turn
	effect["condition"] = CatalogSamples.hand_size_condition("at_most", PILLEUSE_HAND_LIMIT)
	var data := CatalogSamples.with_field(CatalogSamples.hero(), "id", String(id))
	data = CatalogSamples.with_flats(data, "passive", [])
	return CatalogSamples.with_flats(data, "triggered", [effect])


## Effet « cette Unit a +`amount` Force jusqu'à la fin du tour » déclenché par `trigger`, sujet : la
## pièce source (décision 0062).
static func _self_boost(trigger: String, amount: int, once_per_turn: bool) -> Dictionary:
	var effect := _boost(trigger, amount, once_per_turn)
	effect.erase("target")
	effect["subject"] = "source_piece"
	return effect


## Effet « piochez une carte » déclenché par `trigger`.
static func _draw(trigger: String) -> Dictionary:
	var effect := HandEffectSamples.draw_effect(1)
	effect["timing"] = "triggered"
	effect["trigger"] = trigger
	return effect


## Effet « une Unit alliée ciblée a +`amount` Force jusqu'à la fin du tour » déclenché par
## `trigger`.
static func _boost(trigger: String, amount: int, once_per_turn: bool) -> Dictionary:
	return CatalogSamples.triggered(trigger, {"amount": amount, "once_per_turn": once_per_turn})


static func _powder_effect() -> Dictionary:
	var target := {
		"what": "piece",
		"filter": {"side": "enemy", "piece_kinds": ["unit"], "relation": "adjacent"},
		"max_force": POWDER_KEG_MAX_FORCE,
	}
	return {"kind": "destroy", "timing": "triggered", "trigger": "destroyed", "target": target}


static func _unit(id: StringName, force: int, effect: Dictionary) -> Dictionary:
	return _card(CatalogSamples.unit(), id, force, effect)


static func _building(id: StringName, force: int, effect: Dictionary) -> Dictionary:
	return _card(CatalogSamples.building(), id, force, effect)


static func _gear(id: StringName, effect: Dictionary) -> Dictionary:
	var data := CatalogSamples.with_field(CatalogSamples.gear(), "id", String(id))
	return CatalogSamples.with_effects(data, [effect])


static func _card(base: Dictionary, id: StringName, force: int, effect: Dictionary) -> Dictionary:
	var data := CatalogSamples.with_field(base, "id", String(id))
	data = CatalogSamples.with_field(data, "name", "Carte %s" % id)
	data = CatalogSamples.with_field(data, "force", force)
	return CatalogSamples.with_effects(data, [effect])


## Pièce de `definition_id` posée sur `cell_name` pour `side` ; renvoie son `piece_id`.
static func place(
	builder: DuelStateBuilder,
	side: DuelState.PlayerSide,
	piece_kind: Piece.PieceKind,
	definition_id: StringName,
	cell_name: String
) -> int:
	return builder.place_piece(side, piece_kind, DuelStateBuilder.cell(cell_name), definition_id)
