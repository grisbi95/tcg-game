class_name InfoTooltips
extends VBoxContainer
## Pile de bulles d'information à droite de l'aperçu au survol (fiche de l'écran de duel, E27),
## dans la couche Informations : une par mot-clé de la carte survolée, plus « Endormie ». Elle
## s'affiche et se cache avec l'aperçu ; `DuelPreviewer` la pilote.

## Fiche de l'écran de duel, E27 : à droite de l'aperçu, alignée sur son haut (x 478, y 301 pour
## une carte seule ; x 597, y 356 avec un Gear), dans le repère 1920×1080. Comme l'aperçu, la pile
## est ancrée au centre vertical de l'écran (scène) : le décalage est compté depuis ce centre. La
## scène porte le décalage de la carte seule ; le code ne règle que celui de la carte avec Gear.
const SINGLE_OFFSET := Vector2(478, -239)
const PAIR_OFFSET := Vector2(597, -184)

const BUBBLE_SCENE: PackedScene = preload("res://ui/components/info_bubble_view.tscn")


func _ready() -> void:
	visible = false


## Montre `bubbles` ; `beside_pair` vrai quand l'aperçu montre une carte et son Gear. Sans bulle,
## la pile reste cachée.
func show_bubbles(bubbles: Array[InfoBubble], beside_pair: bool = false) -> void:
	hide_bubbles()
	_place(PAIR_OFFSET if beside_pair else SINGLE_OFFSET)
	for bubble: InfoBubble in bubbles:
		var view: InfoBubbleView = BUBBLE_SCENE.instantiate()
		add_child(view)
		view.show_bubble(bubble)
	visible = not bubbles.is_empty()


func _place(offset: Vector2) -> void:
	offset_left = offset.x
	offset_top = offset.y
	reset_size()


func hide_bubbles() -> void:
	visible = false
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
