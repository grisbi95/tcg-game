class_name LabelFit
extends RefCounted
## Taille de police d'un Label d'une seule ligne, réduite jusqu'à un minimum pour que son texte
## tienne dans sa largeur : un nom long reste lisible en entier au lieu d'être coupé. Le thème
## donne la taille de départ et la police (condensée, pour les noms de cartes) ; aucune règle ici.


## Règle la taille de `label` : celle du thème fois `label_scale`, réduite au besoin jusqu'à
## `min_base_size` fois `label_scale`. Sans largeur encore (mise en page non faite), la taille
## de départ.
static func fit_to_width(label: Label, label_scale: float, min_base_size: int) -> void:
	label.remove_theme_font_size_override(&"font_size")
	var font := label.get_theme_font(&"font")
	var font_size := roundi(label.get_theme_font_size(&"font_size") * label_scale)
	var min_font_size := roundi(min_base_size * label_scale)
	if label.size.x > 0.0:
		while font_size > min_font_size and _text_width(font, label.text, font_size) > label.size.x:
			font_size -= 1
	label.add_theme_font_size_override(&"font_size", font_size)


static func _text_width(font: Font, text: String, font_size: int) -> float:
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
