class_name EffectContext
extends RefCounted
## Ce que partage l'application d'un effet à ses cibles (207.4, 207.5) : l'état, l'entrée de
## pile qui porte l'effet, l'effet et la liste d'événements. Construit par
## EffectRules.resolve_effect, jamais conservé ni cloné.

var state: DuelState
var entry: StackEntry
var effect: EffectDefinition
var events: Array[DuelEvent]
## 200.4.2, 207.7.6a : l'effet a eu lieu, au moins en partie ; posé par le module qui l'applique.
var took_place: bool = false


func _init(
	state_value: DuelState,
	entry_value: StackEntry,
	effect_value: EffectDefinition,
	events_value: Array[DuelEvent]
) -> void:
	state = state_value
	entry = entry_value
	effect = effect_value
	events = events_value
