extends Control
## Essai de ArenaFloor (décision 0071) : le sol de l'arène autour d'un plateau factice.

const BOARD_SIZE := Vector2(711.0, 711.0)
const BOARD_POSITION := Vector2(400.0, 190.0)
const ARENA_SCENE: PackedScene = preload("res://ui/components/arena_floor.tscn")


func _ready() -> void:
	var table := ColorRect.new()
	table.color = DuelPalette.TABLE_COLOR
	table.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(table)
	var arena: ArenaFloor = ARENA_SCENE.instantiate()
	add_child(arena)
	var board := Panel.new()
	board.position = BOARD_POSITION
	board.size = BOARD_SIZE
	add_child(board)
	arena.setup(board)
