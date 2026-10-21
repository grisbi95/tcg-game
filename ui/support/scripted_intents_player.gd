class_name ScriptedIntentsPlayer
extends RefCounted
## Outil de développement (essais de `_try/`, `DuelScenarios`) : soumet des intentions scriptées
## une à une, chacune quand l'hôte attend son joueur. Une intention d'un autre joueur que celui
## de l'écran, ou refusée par `DuelEngine.validate()`, arrête toute la suite. Aucune règle ici.

## L'intention suivante est valide : le parent la soumet comme un geste du joueur.
signal intent_chosen(intent: DuelIntent)

var _engine: DuelEngine
var _host: DuelHost
var _intents: Array[DuelIntent] = []


## `engine` valide chaque intention ; `host` dit quel joueur tient l'écran.
func setup(engine: DuelEngine, host: DuelHost) -> void:
	_engine = engine
	_host = host


## Ajoute `intents` à la suite.
func add_intents(intents: Array[DuelIntent]) -> void:
	_intents.append_array(intents)


## Vrai tant qu'il reste des intentions à jouer.
func has_pending() -> bool:
	return not _intents.is_empty()


## Émet `intent_chosen` pour la prochaine intention, si elle est valide.
func submit_next() -> void:
	if _intents.is_empty():
		return
	var intent: DuelIntent = _intents.pop_front()
	if intent.player != _host.get_screen_player():
		push_error("ScriptedIntentsPlayer : intention d'un autre joueur que celui de l'écran")
		_intents.clear()
		return
	if _engine.validate(intent) != IntentRejected.RejectReason.NONE:
		push_error("ScriptedIntentsPlayer : intention refusée, la suite est abandonnée")
		_intents.clear()
		return
	intent_chosen.emit(intent)
