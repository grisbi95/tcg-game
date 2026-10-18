extends Control
## Essai de PieceView : le Hero de A, une Unit de B avec un Gear, une Unit surlignée et une
## choisie.

const PIECE_SCENE: PackedScene = preload("res://ui/components/piece_view.tscn")
const HERO_HEALTH: int = 15
const UNIT_FORCE: int = 3
const GEAR_NAME: String = "Lame"


func _ready() -> void:
	var row := HBoxContainer.new()
	TrySamples.frame(self, row)
	var hero_name := TrySamples.catalog().get_hero(TrySamples.HERO_ID).hero_name
	_add_piece(row).show_hero(0, hero_name, DuelState.PlayerSide.A, HERO_HEALTH)
	var armed := _add_piece(row)
	armed.show_unit(1, "Soldat", DuelState.PlayerSide.B, UNIT_FORCE)
	armed.show_gear(GEAR_NAME)
	var highlighted := _add_piece(row)
	highlighted.show_unit(2, "Recrue", DuelState.PlayerSide.A, 1)
	highlighted.set_marks(true, false)
	var selected := _add_piece(row)
	selected.show_unit(3, "Colosse", DuelState.PlayerSide.B, UNIT_FORCE + 2)
	selected.set_marks(false, true)


func _add_piece(row: HBoxContainer) -> PieceView:
	var piece: PieceView = PIECE_SCENE.instantiate()
	row.add_child(piece)
	piece.piece_pressed.connect(func(piece_id: int) -> void: print("pièce pressée ", piece_id))
	return piece
