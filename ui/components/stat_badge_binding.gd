class_name StatBadgeBinding
extends RefCounted
## Forme et chiffre de la statistique d'une carte ou d'une pièce (décision 0027) : losange de la
## Force, cœur des PV. Tient la forme et l'aspect courants, trace le Control vide `badge` et pose
## le chiffre dans `label`. Le Control qui la possède règle le reste (visibilité, taille).

var _badge: Control
var _label: Label
var _shape: DuelIcons.Badge = DuelIcons.Badge.DIAMOND
var _look: BadgeLook = BadgeLook.force(0, 0)


func _init(badge: Control, label: Label) -> void:
	_badge = badge
	_label = label
	DuelIcons.bind_badge(
		badge, func() -> DuelIcons.Badge: return _shape, func() -> BadgeLook: return _look
	)


## Force `force` sur un losange, comparée à `printed_force` (209.1).
func show_force(force: int, printed_force: int) -> void:
	show_stat(DuelIcons.Badge.DIAMOND, BadgeLook.force(force, printed_force), force)


## PV du Hero (202.3.7) sur un cœur.
func show_health(health: int) -> void:
	show_stat(DuelIcons.Badge.HEART, BadgeLook.health(), health)


## Forme `shape` aux couleurs de `look`, portant `value`.
func show_stat(shape: DuelIcons.Badge, look: BadgeLook, value: int) -> void:
	_shape = shape
	_look = look
	_label.text = str(value)
	_label.add_theme_color_override("font_color", look.ink)
	DuelIcons.fit_label(_label, shape)
	_badge.queue_redraw()
