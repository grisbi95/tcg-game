class_name ChoiceButtonsView
extends VBoxContainer
## Une pile de boutons de choix (décision 0068) : les Ordres du Hero qu'on peut annoncer, ou
## « Garder dessus » / « Mettre dessous » pour la carte regardée. Le parent donne les textes et
## reçoit le rang du bouton pressé ; rien n'est décidé ici.

signal choice_pressed(index: int)


## Remplace les boutons par un par texte de `labels`, dans l'ordre.
func show_choices(labels: Array[String]) -> void:
	ViewNodes.free_children(self)
	for index: int in labels.size():
		var button := Button.new()
		button.text = labels[index]
		button.focus_mode = Control.FOCUS_NONE
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(choice_pressed.emit.bind(index))
		add_child(button)
