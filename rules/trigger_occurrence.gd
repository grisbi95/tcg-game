class_name TriggerOccurrence
extends RefCounted
## Événement qui déclenche des textes (207.3.1, décision 0065) et son objet : la pièce détruite
## (207.3.15) ou le Spell annoncé ou contrecarré. Construit à
## chaque événement par TriggerRules, jamais conservé ni cloné.

var event: EffectDefinition.TriggerEvent = EffectDefinition.TriggerEvent.NONE
## OTHER_PIECE_DESTROYED : la pièce détruite.
var destroyed_piece: Piece
## OWN_SPELL_ANNOUNCED, SPELL_COUNTERED : le Spell de l'événement.
var spell: StackEntry


## Événement sans objet.
static func of_event(trigger_event: EffectDefinition.TriggerEvent) -> TriggerOccurrence:
	var occurrence := TriggerOccurrence.new()
	occurrence.event = trigger_event
	return occurrence


## 207.3.15 : `piece` est détruite.
static func of_destruction(piece: Piece) -> TriggerOccurrence:
	var occurrence := of_event(EffectDefinition.TriggerEvent.OTHER_PIECE_DESTROYED)
	occurrence.destroyed_piece = piece
	return occurrence


## Annonce ou contrecarrage de `spell`.
static func of_spell(
	trigger_event: EffectDefinition.TriggerEvent, spell_entry: StackEntry
) -> TriggerOccurrence:
	var occurrence := of_event(trigger_event)
	occurrence.spell = spell_entry
	return occurrence
