# 0043 — Duel à distance entre deux navigateurs : relais WebSocket, hôte dans un navigateur, dépôt public

- Statut : acceptée
- Date : 2026-10-21
- Décideur : créateur du projet
- Périmètre : réseau entre deux joueurs humains (`app/`, `ui/`, hébergement ; étapes 2.6 et 2.7), correction de cap sur 0036 (point 1) et confirmation de 0005

## Contexte

La décision 0036 (2026-10-20) avait choisi « même appareil d'abord » : le réseau devenait un jalon à part après le premier playtest J3, et la roadmap le plaçait hors périmètre. Le 2026-10-21, le créateur demande que le premier playtest se joue à deux ordinateurs, chacun dans son navigateur. Deux contraintes sont levées le même jour : la fenêtre de réponse n'a plus d'échéance (ruleset 0.38, décision de design 0199 ; 208.6.2), donc le délai réseau ne pèse plus sur une règle ; l'architecture n'exige aucune main cachée, car on joue entre développeurs pour tester le jeu, non pour empêcher la triche (les mains restent privées dans les règles, 201.4 : chacun ne voit que la sienne sur son écran). Contraintes maintenues : GitHub Pages ne sert que des fichiers statiques (0005) ; aucun thread dans le gameplay Web ; déterminisme, journal et replay (0001, 0022) ; aucun fait de jeu par `AppEvents` (0006) ; `DuelHost` objet pur (0020). Le compte GitHub est gratuit, donc GitHub Pages exige un dépôt public (point laissé ouvert par 0039 et l'audit du 2026-10-20 (document de travail hors dépôt)).

## Options envisagées

- Option A : relais WebSocket, l'hôte dans un navigateur (recommandée). Le joueur qui crée la partie fait tourner `DuelEngine` et `DuelHost` comme aujourd'hui ; l'autre navigateur est un second écran : il envoie ses gestes (intentions) et reçoit les événements à afficher, par un petit serveur relais qui ne fait que transmettre des messages entre les deux navigateurs d'un même code de partie (aucune règle, aucun moteur, rien de stocké). Bénéfice : le plus léger ; hôte, journal, replay et fiche de playtest inchangés ; WebSocket est intégré à Godot sur toutes les plateformes (desktop pour développer, Web). Coût : un relais d'une centaine de lignes à écrire et héberger (offre gratuite, Fly.io ou Render par exemple) et un écran « Créer / Rejoindre une partie ». Limite : le navigateur du créateur tient les deux mains et la pendule ; si son onglet se ferme, la partie est perdue.
- Option B : pair à pair WebRTC. Bénéfice : aucun relais pour le trafic de jeu. Coût : un serveur de mise en relation reste nécessaire, le desktop exige l'extension `webrtc-native`, et certains réseaux domestiques bloquent la connexion sans serveur TURN. Limite : plus de pièces mobiles sans gain à cette échelle.
- Option C : serveur de jeu autoritaire. Le moteur et l'hôte tournent sur un serveur Godot sans affichage, les navigateurs n'envoient que des coups. Bénéfice : mains vraiment cachées, prêt pour un jeu public. Coût : héberger et déployer un second programme, déplacer l'hôte côté serveur (0029 l'envisageait), pendule côté serveur. Limite : inutile tant qu'on joue entre développeurs.
- Dépôt : public (GitHub Pages gratuit, 0005 inchangée, code visible) ou privé avec un hébergeur statique gratuit branché sur GitHub (Netlify, Cloudflare Pages), ce qui amenderait 0005.

## Décision

Option A et dépôt public, choisis par le créateur le 2026-10-21 (option A recommandée). Le mode « même appareil » de 0036 reste disponible (relais à l'écran, rideau) : il sert au développement et de repli ; le mode à distance s'y ajoute au choix, à la préparation.

## Conséquences et vérification

- Correction de cap : 0036 reçoit sur sa ligne de statut « point 1 modifié par 0043 » : le duel à distance entre deux navigateurs entre au jalon J2, avant J3 ; le même appareil reste le mode de développement et de repli. 0005 reste acceptée et confirmée : dépôt public, GitHub Pages ; le relais n'est pas hébergé par Pages.
- Roadmap, ajustée par la conversation : « Réseau » sort de la liste hors périmètre ; étape 2.6 = export Web, CI, GitHub Pages (sortie : deux joueurs terminent un duel sur un même appareil dans le navigateur, fiche CSV téléchargée) ; étape 2.7 nouvelle = duel à distance (relais WebSocket, code de partie, second écran ; sortie : deux joueurs sur deux ordinateurs terminent un duel, fiche produite chez le créateur de la partie) ; les deux avant J3.
- Architecture attendue en 2.7, à préciser par une décision si un système nouveau apparaît : couche réseau dans `app/` (connexion au relais, codage des intentions par `IntentCodec` de 0022 et des événements), aucune règle ; `DuelHost` inchangé dans le navigateur hôte ; le navigateur distant ne tient aucun état faisant autorité, il affiche les événements reçus et se recale sur l'état envoyé par l'hôte ; relais sans règle ni état, dans son propre dépôt ou dossier d'outillage, hors export du jeu.
- Vérification : en 2.7, une partie complète entre deux ordinateurs sur deux navigateurs, fiche CSV téléchargée ; tests sans réseau de la couche de codage des messages ; `tools/run_tests.sh` vert.
- À réexaminer : si le jeu devient public ou si la triche compte (option C), si le relais gratuit ne tient pas, si le réseau impose à nouveau une contrainte au ruleset (fenêtre de réponse, pendule), ou à la rétrospective de J2.

## Références

Décisions 0001, 0005, 0006, 0020, 0022, 0029, 0036, 0039, 0042 ; décision de design 0199 du ruleset ; ruleset 201.4, 208.6, 209.4 ; audit du 2026-10-20 (document de travail hors dépôt) ; roadmap 2.6, 2.7 et J3.
