class_name InfoBubbleView
extends PanelContainer
## Une bulle d'information (fiche de l'écran de duel, E27) : titre en gras et texte de rappel, sur
## un fond clair à ombre portée.

@onready var _title_label: Label = %TitleLabel
@onready var _text_label: Label = %TextLabel


func show_bubble(bubble: InfoBubble) -> void:
	_title_label.text = bubble.title
	_text_label.text = bubble.text
