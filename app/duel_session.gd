class_name DuelSession
extends RefCounted
## Ce que l'écran de duel connaît d'un duel (décision 0050) : démarrage, temps réel, gestes du
## joueur de l'écran, événements à afficher et état d'attente. Trois variantes : sur un même
## appareil (`HostedDuelSession`), hôte d'un duel à distance (`RemoteHostSession`) et second écran
## (`RemoteGuestSession`). Base sans comportement, à redéfinir ; aucune règle ici.

signal session_state_changed(session_state: SessionState)

enum SessionState {
	NOT_STARTED,
	PLAYING_EVENTS,
	## Le joueur de l'écran peut agir.
	AWAITING_VIEWER,
	## Un autre joueur, agent ou joueur distant, doit agir.
	AWAITING_OTHER,
	ENDED,
	## Duel à distance : connexion perdue ou navigateurs incompatibles (`get_disconnection()`).
	DISCONNECTED,
}


## Démarre le duel ; renvoie ses premiers événements, à afficher.
func start() -> Array[DuelEvent]:
	return []


## À chaque image : temps réel écoulé, coups des autres joueurs ; renvoie un lot d'événements à
## afficher, ou rien.
func tick() -> Array[DuelEvent]:
	return []


## Intention du joueur de l'écran, choisie par `DuelSelection` ; renvoie les événements à afficher.
func submit(_intent: DuelIntent) -> Array[DuelEvent]:
	return []


## 209.2.5 : le joueur de l'écran abandonne ; renvoie les événements à afficher.
func concede() -> Array[DuelEvent]:
	return []


## Décision 0042 : le joueur de l'écran commence une réponse pendant sa fenêtre (208.6.2).
func begin_response() -> void:
	pass


## L'écran a fini d'afficher le plus ancien lot d'événements qu'il n'avait pas confirmé.
func confirm_events_played() -> void:
	pass


func get_session_state() -> SessionState:
	return SessionState.NOT_STARTED


## Joueur de l'écran, dont la vue montre ce qu'il peut voir (201.4) et dont les gestes comptent.
func get_viewer() -> DuelState.PlayerSide:
	return DuelState.PlayerSide.A


## Décisions 0030 et 0050 : joueur dont le camp est en bas de l'écran.
func get_bottom_side() -> DuelState.PlayerSide:
	return DuelState.PlayerSide.A


## Décision 0029 : vrai tant que la fenêtre de réponse est montrée au joueur de l'écran (208.6.1).
func is_response_window_open() -> bool:
	return false


## Moteur que lisent les vues et `DuelSelection`, faisant autorité ou copie (décision 0049).
func get_engine() -> DuelEngine:
	return null


func get_setup() -> DuelSetup:
	return null


## Journal du duel, d'où se lit la fiche de relevé (décision 0042).
func get_journal() -> DuelJournal:
	return null


## Raison, à afficher, de l'état DISCONNECTED ; vide sinon.
func get_disconnection() -> String:
	return ""


## Vrai pour un duel à distance : pas de revanche enchaînée (décision 0050).
func is_remote() -> bool:
	return false


## Ferme la connexion d'un duel à distance ; sans effet sinon.
func close() -> void:
	pass
