class_name MovementSamples
extends RefCounted
## Catalogue en mémoire des suites des effets de mouvement : échanger (214), déplacer (215),
## renvoyer dans la main (216), décision 0056. Reprend les cartes de TriggerSamples (Héraut,
## Martyr, Soldat) et leur ajoute un Spell par kind et une Unit à Arrivée par kind.

## Spell d'Action de coût 1 : échange les cases de deux Units alliées ciblées.
const SWAP_SPELL: StringName = &"movement_swap_spell"
## Comme SWAP_SPELL, les Units ciblées sont adjacentes au Hero du lanceur.
const NEAR_HERO_SWAP_SPELL: StringName = &"movement_near_hero_swap_spell"
## Spell d'Action de coût 1 : déplace une Unit ennemie ciblée sur une case libre adjacente ciblée.
const MOVE_SPELL: StringName = &"movement_move_spell"
## Spell d'Action de coût 1 : renvoie dans la main une Unit ennemie ciblée.
const RETURN_SPELL: StringName = &"movement_return_spell"
## Arrivée : déplace une Unit ennemie ciblée sur une case libre ciblée adjacente.
const SHIFTER: StringName = &"movement_shifter"
## Arrivée : échange les cases de deux Units alliées ciblées.
const SWAPPER: StringName = &"movement_swapper"
## Arrivée : renvoie dans la main une Unit ennemie ciblée.
const RETURNER: StringName = &"movement_returner"
const SPELL_COST: int = 1
const ARRIVAL_UNIT_FORCE: int = 3


static func catalog() -> Catalog:
	var result := TriggerSamples.catalog()
	result.add_card(CardDefinition.from_dict(CatalogSamples.gear()))
	for data: Dictionary in card_data():
		result.add_card(CardDefinition.from_dict(data))
	return result


## Objets JSON des cartes de ce catalogue, pour vérifier qu'elles sont valides.
static func card_data() -> Array[Dictionary]:
	var data: Array[Dictionary] = []
	var near_hero := CatalogSamples.swap_cells_effect()
	near_hero["target"]["filter"]["relation"] = "adjacent"
	near_hero["target"]["filter"]["relative_to"] = "own_hero"
	data.append(_spell(SWAP_SPELL, CatalogSamples.swap_cells_effect()))
	data.append(_spell(NEAR_HERO_SWAP_SPELL, near_hero))
	data.append(_spell(MOVE_SPELL, CatalogSamples.move_unit_effect()))
	data.append(_spell(RETURN_SPELL, CatalogSamples.return_to_hand_effect()))
	data.append(_arrival_unit(SHIFTER, CatalogSamples.move_unit_effect()))
	data.append(_arrival_unit(SWAPPER, CatalogSamples.swap_cells_effect()))
	data.append(_arrival_unit(RETURNER, CatalogSamples.return_to_hand_effect()))
	return data


static func _spell(id: StringName, effect: Dictionary) -> Dictionary:
	var data := CatalogSamples.with_field(CatalogSamples.spell(), "id", String(id))
	data = CatalogSamples.with_field(data, "name", "Spell %s" % id)
	data = CatalogSamples.with_field(data, "speed", "action")
	data = CatalogSamples.with_field(data, "cost", SPELL_COST)
	return CatalogSamples.with_effects(data, [effect])


static func _arrival_unit(id: StringName, effect: Dictionary) -> Dictionary:
	var triggered := CatalogSamples.with_field(effect, "timing", "triggered")
	triggered = CatalogSamples.with_field(triggered, "trigger", "arrival")
	var data := CatalogSamples.with_field(CatalogSamples.unit(), "id", String(id))
	data = CatalogSamples.with_field(data, "name", "Carte %s" % id)
	data = CatalogSamples.with_field(data, "force", ARRIVAL_UNIT_FORCE)
	data = CatalogSamples.with_effects(data, [triggered])
	return CatalogSamples.with_field(data, "keywords", [{"keyword": "arrival"}])


## Annonce de `card_id` par `side` avec ses cibles : pièces, puis cases.
static func cast(
	side: DuelState.PlayerSide, card_id: int, piece_ids: Array[int], cells: Array[Vector2i] = []
) -> CastSpell:
	var intent := CastSpell.new(side, card_id, EssencePayment.new(SPELL_COST))
	intent.target_piece_ids.assign(piece_ids)
	intent.target_cells.assign(cells)
	return intent


## Réponse d'un joueur à l'attente CHOOSE_TARGETS.
static func choose(
	side: DuelState.PlayerSide, piece_ids: Array[int], cells: Array[Vector2i] = []
) -> ChooseTargets:
	var intent := ChooseTargets.new(side)
	intent.target_piece_ids.assign(piece_ids)
	intent.target_cells.assign(cells)
	return intent


## Erreurs de `find_errors()` de l'effet décrit par `data`.
static func effect_errors(data: Dictionary) -> PackedStringArray:
	return CatalogSamples.effect_errors(data)


## Erreurs de `find_errors()` de la cible décrite par `data`.
static func target_errors(data: Dictionary) -> PackedStringArray:
	return TargetSpec.from_dict(data).find_errors()


## Démarre `engine` sur l'état construit par `builder`.
static func start(engine: DuelEngine, builder: DuelStateBuilder) -> void:
	engine.start_from_state(builder.build())


static func cell_of(engine: DuelEngine, piece_id: int) -> Vector2i:
	return engine.get_state().find_piece(piece_id).cell


## Le joueur B passe : la pile se résout. Renvoie les événements décrits.
static func resolve(engine: DuelEngine) -> Array[String]:
	return EventLog.describe(DuelChecks.pass_once(engine, DuelState.PlayerSide.B))
