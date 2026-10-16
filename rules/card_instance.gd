class_name CardInstance
extends RefCounted
## Exemplaire d'une carte dans un duel (décisions 0001, 0004, 0008).
##
## Une instance se trouve dans une seule zone à la fois : deck, main, défausse, Écart, pile
## ou pièce du plateau (201.3). Son identifiant la suit d'une zone à l'autre.

var card_instance_id: int = DuelState.NO_ID
## Identifiant de la définition de carte dans le catalogue (étape 1.2).
var definition_id: StringName = &""
## 201.5.1 : joueur dont le deck ou le Hero fournit la carte.
var owner: DuelState.PlayerSide = DuelState.PlayerSide.A


func clone() -> CardInstance:
	var copy := CardInstance.new()
	copy.card_instance_id = card_instance_id
	copy.definition_id = definition_id
	copy.owner = owner
	return copy
