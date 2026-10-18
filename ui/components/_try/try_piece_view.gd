extends Control
## Essai de PieceView (décision 0027) : chaque pièce dans une case de 143 px. Hero de A et de B ;
## Unit de Force imprimée, augmentée (avec un Gear) et diminuée ; Unit à mot-clé ; Building ;
## jetons Unit et Building ; une pièce surlignée et une choisie. Survoler une pièce l'entoure d'un
## anneau clair ; un clic passe à sa case.

const CELL_SCENE: PackedScene = preload("res://ui/components/cell_view.tscn")
const PIECE_SCENE: PackedScene = preload("res://ui/components/piece_view.tscn")
const A: DuelState.PlayerSide = DuelState.PlayerSide.A
const B: DuelState.PlayerSide = DuelState.PlayerSide.B
const DAMAGED_HEALTH: int = 12
const TOKEN_FORCE: int = 2

var _catalog: Catalog
var _row: HBoxContainer
var _next_piece_id: int = 0


func _ready() -> void:
	var column := VBoxContainer.new()
	TrySamples.frame(self, column)
	_catalog = TrySamples.catalog()
	_row = HBoxContainer.new()
	column.add_child(_row)
	var hero := _catalog.get_hero(TrySamples.HERO_ID)
	_add_hero(hero, A).show_health(DAMAGED_HEALTH)
	_add_hero(hero, B).show_health(hero.health)
	_add_card(&"soldat", A, 0)
	var armed := _add_card(&"soldat", A, 1)
	armed.show_gear(_catalog.get_card(&"lame").card_name)
	_add_card(&"heraut", B, -1)
	_add_card(&"gardien", B, 0)
	_add_card(&"palissade", A, 0)
	_row = HBoxContainer.new()
	column.add_child(_row)
	_add_token(CardDefinition.CardType.UNIT, A, 0)
	_add_token(CardDefinition.CardType.UNIT, B, -1)
	_add_token(CardDefinition.CardType.BUILDING, A, 0)
	_add_card(&"campement", B, 0).set_marks(true, false)
	_add_card(&"pillard", A, 0).set_marks(false, true)


func _add_hero(hero: HeroDefinition, owner: DuelState.PlayerSide) -> PieceView:
	var piece := _add_piece()
	piece.show_hero(_next_piece_id, hero, owner)
	return piece


# `change` : écart entre la Force montrée et la Force imprimée.
func _add_card(card_id: StringName, owner: DuelState.PlayerSide, change: int) -> PieceView:
	var definition := _catalog.get_card(card_id)
	var piece := _add_piece()
	piece.show_card_piece(_next_piece_id, definition, owner)
	piece.show_force(definition.force + change, definition.force)
	return piece


func _add_token(
	card_type: CardDefinition.CardType, owner: DuelState.PlayerSide, change: int
) -> PieceView:
	var piece := _add_piece()
	piece.show_token(_next_piece_id, card_type, owner)
	piece.show_force(TOKEN_FORCE + change, TOKEN_FORCE)
	return piece


func _add_piece() -> PieceView:
	_next_piece_id += 1
	var cell: CellView = CELL_SCENE.instantiate()
	_row.add_child(cell)
	var piece: PieceView = PIECE_SCENE.instantiate()
	cell.put_piece(piece)
	cell.cell_pressed.connect(func(pressed: Vector2i) -> void: print("case pressée ", pressed))
	piece.piece_hovered.connect(func(piece_id: int) -> void: print("survol ", piece_id))
	return piece
