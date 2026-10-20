class_name EventPlayer
extends Node
## Joue les événements du duel (décision 0006) : reçoit chaque lot renvoyé par DuelHost, le joue
## événement par événement, dans l'ordre des lots, puis annonce `batch_played`. L'écran confirme
## alors à l'hôte que le lot est affiché (`DuelHost.confirm_events_played`) et recale ses vues
## sur `get_state()`, qui fait foi. Pendant la lecture, `is_playing()` est vrai : les commandes
## sont bloquées (ui/CLAUDE.md).
##
## Sans rendu, et sans animation pour l'instant : un événement est « joué » aussitôt, et un lot
## attend une image avant son annonce pour que l'appelant ait fini sa pile d'appels. Plus tard
## (animations), `_play_event` deviendra asynchrone et `_play_queue` l'attendra (`await`) ;
## `event_played` laisse déjà une vue s'y accrocher.

## Un événement vient d'être joué ; les vues animées s'y raccrocheront.
signal event_played(event: DuelEvent)
## Tous les événements d'un lot sont joués.
signal batch_played(events: Array[DuelEvent])

var _queue: Array[EventBatch] = []
var _is_playing: bool = false


## Un lot d'événements en attente de lecture.
class EventBatch:
	extends RefCounted
	var events: Array[DuelEvent] = []

	func _init(batch_events: Array[DuelEvent]) -> void:
		events = batch_events


## Met `events` en file et lance la lecture si elle n'est pas en cours. Un lot vide est ignoré.
func play(events: Array[DuelEvent]) -> void:
	if events.is_empty():
		return
	_queue.append(EventBatch.new(events))
	if not _is_playing:
		_play_queue()


## Vrai tant qu'un lot est en cours de lecture ou en attente : les commandes sont bloquées.
func is_playing() -> bool:
	return _is_playing


func _play_queue() -> void:
	_is_playing = true
	while not _queue.is_empty():
		var batch: EventBatch = _queue.pop_front()
		for event: DuelEvent in batch.events:
			_play_event(event)
		await get_tree().process_frame
		batch_played.emit(batch.events)
	_is_playing = false


func _play_event(event: DuelEvent) -> void:
	event_played.emit(event)
