class_name ScreenSides
extends RefCounted
## Décision 0050 : les vues nomment A ce qui est en bas, B ce qui est en haut ; vu du joueur B, ces
## places changent de joueur.


## Échange les entrées A et B de `nodes`, rangés par joueur.
static func swap(nodes: Dictionary) -> void:
	var node_a: Variant = nodes[DuelState.PlayerSide.A]
	nodes[DuelState.PlayerSide.A] = nodes[DuelState.PlayerSide.B]
	nodes[DuelState.PlayerSide.B] = node_a
