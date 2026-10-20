class_name DeckList
extends RefCounted
## Deck lu dans `data/decks/` (décision 0037) : un Hero et le nombre d'exemplaires de chaque carte.
##
## Sa validité est celle du catalogue (`Catalog.find_deck_errors`, 201.6.1, 201.6.2) et de
## `DuelSetup.find_errors`, contrôlée au démarrage du duel.

var deck_id: StringName = &""
var deck_name: String = ""
var hero_id: StringName = &""
## Identifiant de carte du catalogue → nombre d'exemplaires, dans l'ordre du fichier.
var copies: Dictionary[StringName, int] = {}


## Cartes groupées par définition, dans l'ordre de `copies` ; la dernière est le sommet du deck
## avant le mélange (`DuelSetup`).
func card_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for card_id: StringName in copies:
		for copy: int in copies[card_id]:
			ids.append(card_id)
	return ids
