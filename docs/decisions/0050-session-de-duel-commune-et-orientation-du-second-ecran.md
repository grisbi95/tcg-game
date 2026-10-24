# 0050 — Session de duel commune et orientation du joueur qui rejoint

- Statut : acceptée ; modifiée par 0053
- Date : 2026-10-23
- Décideur : créateur du projet
- Périmètre : écran de duel et préparation pour le duel à distance, étape 2.8 (`app/`, `ui/`) ; complète 0043 et 0049 ; touche 0020 (DuelHost), 0036 (préparation, scène principale) et 0030 (joueur A en bas)

## Contexte

`DuelScreen` est câblé directement sur `DuelHost` (tick, submit_human, concede, begin_response, confirm_events_played, confirm_relay, get_screen_player, host_state_changed, journal) ; `DuelCenterPresenter` et `ScriptedIntentsPlayer` lisent aussi l'hôte. Le duel à distance (0049) ajoute deux cas : l'hôte à distance (DuelHost + RemoteHostLink + RelayConnection, joueur local fixe, l'autre joué depuis le second navigateur) et le second écran (RemoteGuestLink + RelayConnection, copie locale du moteur, aucun DuelHost). Par ailleurs 0030 pose le joueur A en bas ; le joueur qui rejoint joue B.

## Options envisagées

Question 1, comment l'écran de duel sert les trois cas :

- A : une « session » commune. Classe de base `DuelSession` dans `app/` (RefCounted, sans Node, sans règle), seule connue de l'écran de duel : démarrage, tick à chaque image, intention du joueur de l'écran, abandon, réponse commencée, confirmation d'affichage, état de session (lecture des événements, joueur de l'écran attendu, autre joueur attendu, fin, connexion perdue), joueur de l'écran, fenêtre de réponse ouverte, moteur, préparation, journal. Trois variantes : locale (DuelHost, relais confirmé aussitôt comme en 0048), hôte à distance, second écran. Bénéfice : un seul écran à maintenir. Coût : remanier une fois les branchements de l'écran. Limite : l'interface doit couvrir les trois cas sans fuite de l'un dans l'autre.
- B : un second écran à part, copie de l'écran de duel. Plus rapide au début ; tout changement est à faire deux fois.
- C : des tests du mode partout dans l'écran de duel. Peu de fichiers ; code vite confus.

Question 2, orientation pour le joueur qui rejoint :

- A : plateau retourné, chaque joueur voit son camp en bas, comme à une vraie table. Coût : le plateau et les zones se posent selon le joueur de l'écran.
- B : pas de retournement pour l'instant, le joueur qui rejoint se voit en haut ; retournement au backlog.

## Décision

Question 1 : option A. Question 2 : option A. Choix du créateur le 2026-10-23.

## Conséquences et vérification

- 0030 devient « le joueur de l'écran en bas » pour le second écran ; A en bas inchangé en même appareil et chez l'hôte.
- « Créer / Rejoindre » s'ajoute à la préparation (0043) : commencer sur cet appareil, créer une partie à distance (code affiché, attente de l'autre joueur), rejoindre par un code. Le créateur joue A, celui qui rejoint joue B ; la graine reste choisie par le créateur.
- Une connexion perdue ou une version incompatible ramène à la préparation avec un message. En duel à distance, « Nouvelle partie » du panneau de fin ramène à la préparation (pas de revanche enchaînée en 2.8).
- La fiche CSV se produit chez l'hôte comme chez le second écran, leurs journaux étant identiques.
- Vérification : suites existantes vertes après le remaniement ; tests sans scène de la session de second écran (états, intentions envoyées, refus) ; une partie entre deux fenêtres par le relais local.
- À réexaminer : revanche à distance demandée en playtest ; apparition d'un quatrième cas (IA à distance, spectateur).

## Références

Décisions 0020, 0030, 0036, 0043, 0048, 0049. Roadmap, étape 2.8.
