class_name EventText
extends RefCounted
## Phrase pour chaque événement du duel ; plus de journal à l'écran depuis la décision 0041. Aucune
## information cachée : une carte piochée ou écartée n'est jamais nommée (201.4).

## Une phrase par classe d'événement ; `%s` reçoit le joueur concerné d'un PlayerEvent.
const SENTENCES: Dictionary[StringName, String] = {
	&"ActiveEffectEnded": "Un effet prend fin.",
	&"CardDiscarded": "Le joueur %s défausse une carte.",
	&"CardDrawn": "Le joueur %s pioche une carte.",
	&"CardReturnedToDeck": "Le joueur %s remet une carte dans son deck.",
	&"CardReturnedToHand": "Une carte revient dans la main du joueur %s.",
	&"CardSetAside": "Le joueur %s écarte une carte.",
	&"CombatResolved": "Un combat est résolu.",
	&"DecisionRequested": "Le joueur %s doit faire un choix.",
	&"DecisionResolvedAutomatically": "Le seul choix possible du joueur %s est fait pour lui.",
	&"DeckShuffled": "Le joueur %s mélange son deck.",
	&"DeployAnnounced": "Le joueur %s annonce un déploiement.",
	&"DrawBlockedByHandLimit": "Le joueur %s ne pioche pas : sa main est pleine.",
	&"DuelEnded": "Le duel est terminé.",
	&"DuelSetupRejected": "La préparation du duel est refusée.",
	&"EffectLostAllTargets": "Un effet du joueur %s n'a plus de cible.",
	&"EffectTriggered": "Un effet du joueur %s se déclenche.",
	&"EssenceLost": "Le joueur %s perd son Essence non dépensée.",
	&"EssenceProduced": "Le joueur %s produit de l'Essence.",
	&"FatigueIncreased": "La fatigue du joueur %s augmente.",
	&"FirstPlayerChosen": "Le joueur %s commence.",
	&"ForceModified": "Une Force du joueur %s change.",
	&"GearAnnounced": "Le joueur %s annonce un Gear.",
	&"GearAttached": "Un Gear du joueur %s est attaché.",
	&"HeroAttacked": "Le Hero du joueur %s est attaqué.",
	&"HeroLostHealth": "Le Hero du joueur %s perd des PV.",
	&"HeroPlaced": "Le Hero du joueur %s est placé.",
	&"HeroPowerAnnounced": "Le joueur %s utilise le pouvoir de son Hero.",
	&"IdleDefeat": "Le joueur %s perd la partie par inactivité.",
	&"IntentRejected": "Action refusée.",
	&"MulliganDecided": "Le joueur %s a décidé de son mulligan.",
	&"NormalActionAnnounced": "Le joueur %s annonce une action normale.",
	&"NormalActionFailed": "L'action normale du joueur %s échoue.",
	&"PieceDeployed": "Une pièce du joueur %s est déployée.",
	&"PieceDestroyed": "Une pièce du joueur %s est détruite.",
	&"PieceEnteredAttacking": "Une pièce du joueur %s entre en attaquant.",
	&"PieceMoved": "Une pièce du joueur %s se déplace.",
	&"PiecesAwakened": "Les Units et le Hero du joueur %s se réveillent.",
	&"PlayerConceded": "Le joueur %s abandonne.",
	&"PriorityPassed": "Le joueur %s passe.",
	&"SourceInclined": "Le joueur %s incline une Source.",
	&"SourceReceived": "Le joueur %s reçoit une Source.",
	&"SourceRecycled": "Le joueur %s recycle une Source.",
	&"SourcesPutIntoPlay": "Les Sources du joueur %s entrent en jeu.",
	&"SourcesUntapped": "Les Sources du joueur %s se redressent.",
	&"SpellAnnounced": "Le joueur %s annonce un Spell.",
	&"SpellCountered": "Un Spell du joueur %s est contrecarré.",
	&"StackEntryAdded": "Une entrée du joueur %s rejoint la pile.",
	&"StackEntryResolved": "Une entrée du joueur %s se résout.",
	&"TargetsChosen": "Le joueur %s choisit ses cibles.",
	&"TimeExpired": "Le temps du joueur %s est écoulé.",
	&"TokenCreated": "Le joueur %s crée un jeton.",
	&"TriggerSkipped": "Un effet déclenché du joueur %s ne se produit pas.",
	&"TriggersOrdered": "Le joueur %s ordonne ses effets déclenchés.",
	&"TurnEnded": "Le joueur %s termine son tour.",
	&"TurnStarted": "Début du tour du joueur %s.",
}


## Phrase de `event` ; le nom de sa classe si aucune phrase ne lui est encore donnée.
static func describe(event: DuelEvent) -> String:
	var script: Script = event.get_script()
	var class_label := script.get_global_name()
	if not SENTENCES.has(class_label):
		return String(class_label)
	var sentence := SENTENCES[class_label]
	if event is PlayerEvent:
		return sentence % player_label((event as PlayerEvent).player)
	return sentence


static func player_label(side: DuelState.PlayerSide) -> String:
	return str(DuelState.PlayerSide.find_key(side))
