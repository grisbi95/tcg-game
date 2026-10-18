class_name ViewInput
extends RefCounted
## Lecture des gestes communs aux composants : un clic gauche appuyé sur le composant.


static func is_left_click(event: InputEvent) -> bool:
	if not event is InputEventMouseButton:
		return false
	var button := event as InputEventMouseButton
	return button.button_index == MOUSE_BUTTON_LEFT and button.pressed
