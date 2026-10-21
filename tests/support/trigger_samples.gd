class_name TriggerSamples
extends RefCounted
## Catalogue en mémoire pour les suites des effets déclenchés (207.3, 208.4, 210.3, 204.5.3).
##
## Inspiré du Héraut et du Martyr des decks de test ; ce ne sont pas les cartes de l'étape 1.9.

const SOLDIER: StringName = &"trigger_soldier"
const GIANT: StringName = &"trigger_giant"
## Arrivée : une Unit ennemie ciblée a −1 Force jusqu'à la fin du tour.
const HERALD: StringName = &"trigger_herald"
## Dernier souffle : une Unit alliée ciblée a +1 Force tant que la pièce est en jeu.
const MARTYR: StringName = &"trigger_martyr"
## Arrivée : deux Units ennemies ciblées ont −1 Force jusqu'à la fin du tour.
const DOUBLE_HERALD: StringName = &"trigger_double_herald"
## Building, fin du tour : une Unit alliée ciblée a +1 Force jusqu'à la fin du tour.
const BEACON: StringName = &"trigger_beacon"
## Comme BEACON, avec la mention « une fois par tour ».
const ONCE_BEACON: StringName = &"trigger_once_beacon"
const SOLDIER_FORCE: int = 2
const GIANT_FORCE: int = 5
const HERALD_FORCE: int = 3
const MARTYR_FORCE: int = 3
const BEACON_FORCE: int = 4
const HERALD_MALUS: int = -1
const MARTYR_BONUS: int = 1
const BEACON_BONUS: int = 1


static func catalog() -> Catalog:
	var result := Catalog.new()
	SetupSamples.add_unit(result, SOLDIER, SOLDIER_FORCE)
	SetupSamples.add_unit(result, GIANT, GIANT_FORCE)
	for data: Dictionary in card_data():
		result.add_card(CardDefinition.from_dict(data))
	return result


## Objets JSON des cartes à effet déclenché, pour vérifier qu'elles sont valides.
static func card_data() -> Array[Dictionary]:
	var enemy_unit := CatalogSamples.ally_unit_target()
	enemy_unit["side"] = "enemy"
	var herald_effect := CatalogSamples.triggered(
		"arrival", {"amount": HERALD_MALUS, "target": enemy_unit}
	)
	var martyr_effect := CatalogSamples.triggered(
		"destroyed", {"amount": MARTYR_BONUS, "duration": "while_piece_in_play"}
	)
	var two_enemy_units := enemy_unit.duplicate(true)
	two_enemy_units["count_min"] = 2
	two_enemy_units["count_max"] = 2
	var double_effect := herald_effect.duplicate(true)
	double_effect["target"] = two_enemy_units
	var beacon_effect := CatalogSamples.triggered("end_of_turn", {"amount": BEACON_BONUS})
	var once_effect := beacon_effect.duplicate(true)
	once_effect["once_per_turn"] = true
	return [
		_card(CatalogSamples.unit(), HERALD, HERALD_FORCE, herald_effect, "arrival"),
		_card(CatalogSamples.unit(), DOUBLE_HERALD, HERALD_FORCE, double_effect, "arrival"),
		_card(CatalogSamples.unit(), MARTYR, MARTYR_FORCE, martyr_effect, "last_breath"),
		_card(CatalogSamples.building(), BEACON, BEACON_FORCE, beacon_effect, ""),
		_card(CatalogSamples.building(), ONCE_BEACON, BEACON_FORCE, once_effect, ""),
	]


static func _card(
	base: Dictionary, id: StringName, force: int, effect: Dictionary, keyword: String
) -> Dictionary:
	var data := CatalogSamples.with_field(base, "id", String(id))
	data = CatalogSamples.with_field(data, "name", "Carte %s" % id)
	data = CatalogSamples.with_field(data, "force", force)
	data = CatalogSamples.with_field(data, "effects", [effect])
	if not keyword.is_empty():
		data = CatalogSamples.with_field(data, "keywords", [{"keyword": keyword}])
	return data
