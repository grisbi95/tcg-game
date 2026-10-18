class_name HoverPreview
extends PanelContainer
## Aperçu agrandi d'une carte survolée (décision 0025), affiché par une CardView en grand.

@onready var _card_view: CardView = %CardView


func _ready() -> void:
	_card_view.set_large(true)
	visible = false


func show_definition(definition: CardDefinition, owner: DuelState.PlayerSide) -> void:
	_card_view.show_card(DuelState.NO_ID, definition, owner)
	visible = true


func hide_preview() -> void:
	visible = false
