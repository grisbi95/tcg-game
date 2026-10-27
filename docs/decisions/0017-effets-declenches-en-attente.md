# 0017 — Effets déclenchés en attente, une liste d'entrées de pile

- Statut : acceptée ; complétée par 0057
- Date : 2026-10-17
- Décideur : créateur du projet
- Périmètre : effets déclenchés (ruleset 207.3, 208.4, 204.5.3 à 204.5.7) ; complète les décisions 0004 et 0009

## Contexte

Un effet déclenché survient souvent pendant la résolution d'un bloc de la pile (Dernier souffle d'une pièce détruite en combat, Arrivée d'une pièce déployée). Il attend la fin de la résolution (208.4.2), puis s'ajoute au sommet de la pile (208.4.3), dans l'ordre de 208.4.6 et 208.4.7, ses cibles choisies à son ajout (207.5.1b). Il a lieu même si sa pièce a quitté le plateau (207.3.3). Il faut garder cet effet entre le moment de l'événement et son ajout, y compris quand le moteur attend un choix d'un joueur.

## Options envisagées

- Option A : liste d'attente d'entrées de pile. Dès l'événement, le moteur crée une `StackEntry` de genre TRIGGERED_EFFECT (joueur selon 207.3.4 et 207.3.4a, carte, pièce source, rang de l'effet) et la range dans `DuelState.waiting_triggers`. Simple ; la carte est connue au moment du fait, même si la pièce quitte le plateau ensuite.
- Option B : faits bruts (« telle pièce est détruite ») gardés dans l'état, convertis en effets plus tard. Plus souple pour de futurs déclencheurs, mais oblige à retrouver la carte d'une pièce déjà partie du plateau.
- Option C : relire le flux `Array[DuelEvent]` pour trouver les déclencheurs. Aucun champ d'état en plus, mais les règles dépendraient des événements destinés à la vue (0006), fragile, et les événements ne portent pas toutes les données utiles.

## Décision

Option A, validée le 17 octobre 2026 par le créateur.

## Conséquences et vérification

- Deux champs de `DuelState`, copiés par `clone()` : `waiting_triggers` (effets en attente, pas encore ordonnés) et `triggers_to_add` (effets ordonnés en cours d'ajout). Chaque entrée reçoit son identifiant d'entrée de pile dès sa création (jamais réutilisé), ce qui permet à `PendingDecision.candidate_ids` de les désigner.
- La liste se vide vers la pile : à la fin de la résolution d'un bloc, avant le retour au joueur actif (208.4.3, 208.5.1a) ; à la fin du tour (204.5.3) ; au début de la phase principale (208.4.11). Aucun vidage juste après une annonce (208.4.4) : aucun déclencheur ne réagit encore à une annonce.
- Ajout : d'abord les effets du joueur actif, puis ceux de son adversaire (208.4.6, 208.4.7). Dans chaque groupe, on écarte l'effet sans assez de cibles légales (207.5.9, 207.5.10) ou dont la mention « une fois par tour » a déjà servi ce tour (207.3.5). S'il en reste au moins deux, l'attente `ORDER_TRIGGERS` demande l'ordre complet par une intention `OrderTriggers` ; sinon le moteur l'applique seul (0004, événement `DecisionResolvedAutomatically`).
- Puis chaque effet, dans l'ordre : si le nombre de cibles légales égale le minimum exigé, le moteur les prend d'office (0004) ; sinon l'attente `CHOOSE_TARGETS` demande les cibles par une intention `ChooseTargets`. L'effet s'ajoute alors au sommet de la pile (207.5.1b) et la mention « une fois par tour » est décomptée à cet ajout (207.3.6).
- Une fois tout ajouté, la priorité suit 208.2.4. Si rien n'a été ajouté et que la pile est vide : retour au joueur actif (208.5.1), ou suite de la fin du tour (204.5.7 puis 204.5.2).
- Le décompte « une fois par tour » est tenu par carte (identifiant d'instance, qui la suit d'une zone à l'autre : 207.3.7, 207.3.10), remis à zéro au début de chaque tour (207.3.9). Aucun décompte par jeton (207.3.7a) : un jeton ne porte aucun effet (202.4.5) et aucun Gear ne lui donne d'effet déclenché. Le catalogue refuse une carte qui porte la mention et plusieurs effets déclenchés, que le ruleset ne règle pas.
- Tests nommés par identifiants : un déclencheur unique s'ajoute sans décision ; deux du même joueur produisent `ORDER_TRIGGERS` ; un effet du joueur actif et un de l'adversaire s'ajoutent sans décision, celui de l'adversaire au sommet (208.4.8) ; une cible unique est prise d'office ; deux cibles légales produisent `CHOOSE_TARGETS` ; `test_duel_state_clone.gd` renseigne les nouveaux champs.
- À réexaminer si un déclencheur doit réagir à une annonce (208.4.4, 208.2.4a) ou au début du tour (208.4.10), ou si un jeton reçoit un effet déclenché (202.4.5a, 207.3.7a).

## Références

Ruleset 204.5.3 à 204.5.7, 207.3, 207.5.1b, 207.5.9, 207.5.10, 208.2.4, 208.4.2 à 208.4.11, 208.5.1a ; décisions 0004, 0006, 0009.
