class_name TooltipsSpy
extends InfoTooltips
## Bulles d'essai : enregistrent ce qu'on leur demande de montrer, sans scène ni arbre. Sert aux
## suites de `DuelPreviewer`.

var calls: Array[String] = []
var shown_titles: Array[String] = []
var shown_beside_pair: bool = false


func show_bubbles(bubbles: Array[InfoBubble], beside_pair: bool = false) -> void:
	calls.append("show_bubbles")
	shown_beside_pair = beside_pair
	shown_titles.clear()
	for bubble: InfoBubble in bubbles:
		shown_titles.append(bubble.title)


func hide_bubbles() -> void:
	calls.append("hide_bubbles")
