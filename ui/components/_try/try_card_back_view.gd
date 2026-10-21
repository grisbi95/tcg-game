extends Control
## Essai de CardBackView (décisions 0027 et 0028) : le deck de B (19 cartes) et celui de A
## (16 cartes), puis cinq dos réduits de la main de B.

const BACK_SCENE: PackedScene = preload("res://ui/components/card_back_view.tscn")
const B_DECK_COUNT: int = 19
const A_DECK_COUNT: int = 16
const HAND_COUNT: int = 5


func _ready() -> void:
	var column := VBoxContainer.new()
	TrySamples.frame(self, column)
	var decks := HBoxContainer.new()
	column.add_child(decks)
	_add_back(decks, DuelState.PlayerSide.B, CardBackView.DECK_SIZE).show_count(B_DECK_COUNT)
	_add_back(decks, DuelState.PlayerSide.A, CardBackView.DECK_SIZE).show_count(A_DECK_COUNT)
	var hand := HBoxContainer.new()
	column.add_child(hand)
	for index: int in HAND_COUNT:
		_add_back(hand, DuelState.PlayerSide.B, CardBackView.HAND_SIZE)


func _add_back(row: HBoxContainer, side: DuelState.PlayerSide, back_size: Vector2) -> CardBackView:
	var back: CardBackView = BACK_SCENE.instantiate()
	row.add_child(back)
	back.show_back(side, back_size)
	return back
