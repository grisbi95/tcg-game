extends Control
## Essai de ColumnLettersView (décision 0050), dans la largeur des colonnes d'une grille (711 px) :
## en haut l'ordre de A (A à E), en dessous celui de B (E à A).

const LETTERS_SCENE: PackedScene = preload("res://ui/components/column_letters_view.tscn")
const GRID_WIDTH: float = 711.0
const ROW_SPACING: int = 30


func _ready() -> void:
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = GRID_WIDTH
	column.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	column.add_theme_constant_override("separation", ROW_SPACING)
	TrySamples.frame(self, column)
	for side: DuelState.PlayerSide in DuelState.SIDES:
		var letters: ColumnLettersView = LETTERS_SCENE.instantiate()
		column.add_child(letters)
		letters.show_from_side(side)
