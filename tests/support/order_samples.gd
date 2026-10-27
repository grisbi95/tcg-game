class_name OrderSamples
extends RefCounted
## Catalogue en mémoire des suites de l'Ordre du Hero (211, 202.3.19 à 202.3.22, décision 0055).
##
## Le Hero d'essai porte deux Ordres et un effet déclenché ; ce ne sont pas les cartes 1.9.

const HERO: StringName = &"order_hero"
## Comme HERO, avec la mention « une fois par tour » sur son effet déclenché.
const ONCE_HERO: StringName = &"order_once_hero"
const UNIT: StringName = &"order_unit"
## Spell de Réaction qui contrecarre un Spell de la pile.
const COUNTER_SPELL: StringName = &"order_counter_spell"
## Rang de l'Ordre d'Action sans coût : une Unit alliée ciblée a +2 Force jusqu'à la fin du tour.
const BOOST_ORDER: int = 0
## Rang de l'Ordre de Réaction : crée un jeton Unit sur une case libre de la première rangée.
const TOKEN_ORDER: int = 1
const ORDER_COUNT: int = 2
const UNIT_FORCE: int = 3
const BOOST: int = 2  # CatalogSamples.modify_force_resolve()
const TOKEN_ORDER_COST: int = 2
const COUNTER_COST: int = 2


## Dix Units d'essai (SetupSamples), le Hero d'essai, `UNIT` et le Spell `COUNTER_SPELL`.
static func catalog() -> Catalog:
	var result := SetupSamples.catalog()
	SetupSamples.add_unit(result, UNIT, UNIT_FORCE)
	var counter := CatalogSamples.with_field(CatalogSamples.spell(), "id", String(COUNTER_SPELL))
	counter = CatalogSamples.with_field(counter, "cost", COUNTER_COST)
	counter = CatalogSamples.with_effects(counter, [CatalogSamples.counter_spell_effect()])
	result.add_card(CardDefinition.from_dict(counter))
	result.add_hero(HeroDefinition.from_dict(hero_data(HERO, false)))
	result.add_hero(HeroDefinition.from_dict(hero_data(ONCE_HERO, true)))
	return result


## Objet JSON du Hero d'essai : deux Ordres, et un effet déclenché en fin de tour (une Unit
## alliée ciblée a +2 Force jusqu'à la fin du tour).
static func hero_data(id: StringName, once_per_turn: bool) -> Dictionary:
	var boost_data := {
		"speed": "action",
		"cost": 0,
		"texts": CatalogSamples.texts_of([CatalogSamples.modify_force_resolve()])
	}
	var token_data := {
		"speed": "reaction",
		"cost": TOKEN_ORDER_COST,
		"texts": CatalogSamples.texts_of([CatalogSamples.create_token_effect()])
	}
	var end_of_turn := CatalogSamples.triggered("end_of_turn", {"once_per_turn": once_per_turn})
	return {
		"id": String(id),
		"name": "Hero %s" % id,
		"health": 15,
		"text": "Deux Ordres et un effet déclenché.",
		"orders": [boost_data, token_data],
		"triggered": CatalogSamples.texts_of([end_of_turn]),
	}


## Annonce de l'Ordre d'Action sans coût de `side` sur la pièce `target_id`.
static func boost_order(side: DuelState.PlayerSide, target_id: int) -> AnnounceOrder:
	var intent := AnnounceOrder.new(side, BOOST_ORDER)
	intent.target_piece_ids.append(target_id)
	return intent


## Annonce de l'Ordre de Réaction de `side`, payé en inclinant, sur la case `cell`.
static func token_order(side: DuelState.PlayerSide, cell: Vector2i) -> AnnounceOrder:
	var intent := AnnounceOrder.new(side, TOKEN_ORDER, EssencePayment.new(TOKEN_ORDER_COST))
	intent.target_cells.append(cell)
	return intent


## Première Unit de `side` sur le plateau de `state`.
static func first_unit_id(state: DuelState, side: DuelState.PlayerSide) -> int:
	for piece: Piece in state.pieces:
		if piece.owner == side and piece.kind == Piece.PieceKind.UNIT:
			return piece.piece_id
	return DuelState.NO_ID


## Première case libre de la première rangée de `side`.
static func free_first_row_cell(state: DuelState, side: DuelState.PlayerSide) -> Vector2i:
	for cell: Vector2i in BoardGeometry.first_row_cells(side):
		if state.piece_at(cell) == null:
			return cell
	return BoardGeometry.NO_CELL
