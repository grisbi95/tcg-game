class_name ViewNodes
extends RefCounted
## Gestion des nœuds enfants commune aux composants.


## Retire et libère chaque enfant de `parent`, avant d'en ajouter d'autres.
static func free_children(parent: Node) -> void:
	for child: Node in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
