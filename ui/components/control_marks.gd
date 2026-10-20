class_name ControlMarks
extends RefCounted
## Marques d'un Control survolable, surlignable et choisissable (décision 0027) : tient les trois
## états, suit le survol de son Control et le trace en anneaux (DuelMarks). Le Control l'appelle
## depuis son `_draw()` et réagit à `hover_changed` pour émettre ses propres signals.

signal hover_changed(is_hovered: bool)

var _control: Control
var _outset: float
var _is_hovered: bool = false
var _is_highlighted: bool = false
var _is_selected: bool = false


## Suit `control` ; le premier anneau est tracé à `outset` pixels hors de son bord (DuelMarks.draw).
func _init(control: Control, outset: float) -> void:
	_control = control
	_outset = outset
	control.mouse_entered.connect(_on_hover_changed.bind(true))
	control.mouse_exited.connect(_on_hover_changed.bind(false))


## Surligné : peut être choisi ; choisi : l'est.
func set_marks(is_highlighted: bool, is_selected: bool) -> void:
	_is_highlighted = is_highlighted
	_is_selected = is_selected
	_control.queue_redraw()


## À appeler depuis le `_draw()` du Control.
func draw() -> void:
	var mark := DuelMarks.mark_of(_is_hovered, _is_highlighted, _is_selected)
	DuelMarks.draw(_control, Rect2(Vector2.ZERO, _control.size), mark, _outset)


func _on_hover_changed(is_hovered: bool) -> void:
	_is_hovered = is_hovered
	_control.queue_redraw()
	hover_changed.emit(is_hovered)
