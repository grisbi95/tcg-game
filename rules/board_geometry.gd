class_name BoardGeometry
extends RefCounted
## Géométrie du plateau : notation, adjacence, rangées d'un joueur (201.2, 205).
##
## Une case est un `Vector2i` : `x` est l'indice de colonne (A = 0), `y` l'indice de rangée
## (rangée 1 = 0). Le joueur A a la rangée 1 pour première rangée, le joueur B la rangée 5
## (201.2.5 laisse l'attribution libre ; ce choix est une convention du moteur).

const NO_CELL: Vector2i = Vector2i(-1, -1)
const COLUMN_COUNT: int = 5  # 201.0.2
const ROW_COUNT: int = 5  # 201.0.2
const FIRST_COLUMN_LETTER: String = "A"  # 201.2.2
const CENTRAL_ROW_INDEX: int = 2  # 205.1.4 : rangée 3
const NEAR_ROW_COUNT: int = 2  # 205.1.3, 205.3.2
const HERO_START_COLUMN_INDEX: int = 2  # 204.1.1 : colonne C
const _FIRST_ROW_NUMBER: int = 1  # 201.2.3
const _NOTATION_LENGTH: int = 2  # 201.2.4 : une lettre, un chiffre
const _COLUMN_LETTER_INDEX: int = 0  # 201.2.4 : la lettre d'abord
const _ROW_DIGIT_INDEX: int = 1  # 201.2.4 : le chiffre ensuite


## 201.0.2 : les 25 cases, colonne par colonne, rangée 1 vers rangée 5.
static func all_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for column: int in COLUMN_COUNT:
		for row: int in ROW_COUNT:
			cells.append(Vector2i(column, row))
	return cells


# 201.0.2
static func is_on_board(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < COLUMN_COUNT and cell.y >= 0 and cell.y < ROW_COUNT


# 201.2.2, 201.2.3, 201.2.4
static func cell_name(cell: Vector2i) -> String:
	var column_letter := String.chr(FIRST_COLUMN_LETTER.unicode_at(0) + cell.x)
	return column_letter + str(cell.y + _FIRST_ROW_NUMBER)


# 201.2.4 : renvoie NO_CELL si `notation` n'est pas une case du plateau.
static func parse_cell(notation: String) -> Vector2i:
	if notation.length() != _NOTATION_LENGTH:
		return NO_CELL
	var column := notation.unicode_at(_COLUMN_LETTER_INDEX) - FIRST_COLUMN_LETTER.unicode_at(0)
	var row := notation.substr(_ROW_DIGIT_INDEX).to_int() - _FIRST_ROW_NUMBER
	var cell := Vector2i(column, row)
	if not is_on_board(cell) or cell_name(cell) != notation:
		return NO_CELL
	return cell


# 205.2.5 : deux cases partagent un côté, jamais en diagonale.
static func are_adjacent(first: Vector2i, second: Vector2i) -> bool:
	var offset := (first - second).abs()
	return offset.x + offset.y == 1


# 205.2.5
static func adjacent_cells(cell: Vector2i) -> Array[Vector2i]:
	var neighbours: Array[Vector2i] = []
	for step: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
		if is_on_board(cell + step):
			neighbours.append(cell + step)
	return neighbours


# 201.2.5 : indice de la première rangée de `side`.
static func first_row_index(side: DuelState.PlayerSide) -> int:
	return 0 if side == DuelState.PlayerSide.A else ROW_COUNT - 1


# 201.2.5 : 0 sur la première rangée de `side`, ROW_COUNT - 1 sur celle de l'adversaire.
static func distance_from_first_row(side: DuelState.PlayerSide, cell: Vector2i) -> int:
	return absi(cell.y - first_row_index(side))


# 205.1.2
static func is_in_first_row(side: DuelState.PlayerSide, cell: Vector2i) -> bool:
	return is_on_board(cell) and distance_from_first_row(side, cell) == 0


# 205.1.3, 205.3.2 : les deux rangées les plus proches de `side`.
static func is_in_near_rows(side: DuelState.PlayerSide, cell: Vector2i) -> bool:
	return is_on_board(cell) and distance_from_first_row(side, cell) < NEAR_ROW_COUNT


# 205.1.4
static func is_in_central_row(cell: Vector2i) -> bool:
	return is_on_board(cell) and cell.y == CENTRAL_ROW_INDEX


# 205.1.2
static func first_row_cells(side: DuelState.PlayerSide) -> Array[Vector2i]:
	return _cells_where(func(cell: Vector2i) -> bool: return is_in_first_row(side, cell))


# 205.1.3
static func near_rows_cells(side: DuelState.PlayerSide) -> Array[Vector2i]:
	return _cells_where(func(cell: Vector2i) -> bool: return is_in_near_rows(side, cell))


# 204.1.1 : case centrale de la première rangée, C1 ou C5.
static func hero_start_cell(side: DuelState.PlayerSide) -> Vector2i:
	return Vector2i(HERO_START_COLUMN_INDEX, first_row_index(side))


static func _cells_where(predicate: Callable) -> Array[Vector2i]:
	var matching: Array[Vector2i] = []
	for cell: Vector2i in all_cells():
		if predicate.call(cell):
			matching.append(cell)
	return matching
