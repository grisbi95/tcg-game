# 0049 — Duel à distance : second écran par journal rejoué, relais Node.js minimal

- Statut : acceptée
- Date : 2026-10-23
- Décideur : créateur du projet
- Périmètre : duel à distance, étape 2.8 (`app/`, `ui/`, `tools/relay/`) ; précise la décision 0043

## Contexte

La décision 0043 a choisi un relais WebSocket, l'hôte (`DuelEngine` et `DuelHost`) dans le navigateur du créateur de la partie, l'autre navigateur étant un second écran sans état faisant autorité, « à préciser par une décision si un système nouveau apparaît ». Deux questions restent : comment le second navigateur reste à jour, et sous quelle forme écrire le relais. Contraintes : déterminisme (0001) ; journal et replay (0022 : `DuelJournal` enregistre le setup, les intentions acceptées, le temps écoulé, le temps de fenêtre de réponse et les réponses commencées ; `IntentCodec` encode les intentions) ; `DuelHost` objet pur (0020) ; aucun fait de jeu par `AppEvents` (0006) ; GitHub Pages statique (0005) ; aucun thread en Web.

## Options envisagées

Question 1, synchronisation du second écran.

- Option A : journal rejoué. L'hôte envoie le setup puis chaque entrée du journal au fil de l'eau ; le second navigateur les rejoue dans sa propre copie de `DuelEngine` (comme le replay) et ses vues lisent cette copie. Bénéfice : réutilise journal, `IntentCodec` et replay, très peu de code, messages petits. Coût : écrire l'envoi et la réception des entrées. Limite : les deux navigateurs doivent avoir la même version du jeu et la même édition du ruleset, vérifiées à la connexion ; la copie locale n'est jamais autoritaire.
- Option B : état complet envoyé après chaque action. Bénéfice : robuste aux écarts de version. Coût : codage de tout `DuelState` en messages, gros travail et beaucoup de tests, messages lourds.
- Option C : événements seuls, second écran sans état. Coût : les vues se recalent aujourd'hui sur `get_state()`, il faudrait les réécrire. Déconseillée.

Question 2, forme du relais.

- Option A : petit serveur Node.js (environ 80 lignes) dans `tools/relay/`, hors export du jeu, sans règle ni état durable, qui apparie deux connexions par code de partie et transmet les messages. Se lance en local pour développer sans Internet ; hébergé sur une offre gratuite (Render ou équivalent). Limite : l'offre gratuite met le serveur en veille après une quinzaine de minutes sans usage, d'où 30 s à 1 min d'attente à la première connexion d'une séance ; rien pendant une partie.
- Option B : relais en Godot sans affichage. Bénéfice : une seule langue. Coût : héberger un binaire Godot, plus lourd, moins d'hébergeurs gratuits.
- Option C : Cloudflare Worker. Bénéfice : jamais en veille, gratuit. Coût : API propre, test local difficile, compte à créer.

## Décision

Option A pour les deux questions, choisies par le créateur le 2026-10-23 (A recommandée dans les deux cas). Le joueur distant envoie ses intentions à l'hôte, qui seul valide et soumet ; la copie du second écran ne fait jamais autorité.

## Conséquences et vérification

- Couche réseau dans `app/` : connexion au relais et messages (setup, entrées de journal, intentions du joueur distant, réponse commencée), testée sans réseau. `DuelHost` inchangé côté hôte. Édition du ruleset et version du jeu vérifiées à la connexion. Écran « Créer / Rejoindre » avec code de partie ; mode même appareil conservé ; fiche CSV produite chez l'hôte.
- Premier fichier JavaScript du dépôt : exception à « GDScript seul » (CLAUDE.md §2), limitée à `tools/relay/`, hors export.
- Vérification : tests de codage des messages ; test d'un second écran alimenté par un journal, états identiques à ceux de l'hôte ; une partie complète entre deux navigateurs.
- À réexaminer : si un écart de version ou de déterminisme désynchronise les écrans (option B) ; si la veille de l'hébergeur gêne les playtests (option C ou offre payante) ; si le jeu devient public (0043 option C).

## Références

Décisions 0001, 0005, 0006, 0020, 0022, 0043 ; roadmap 2.8 ; ruleset 201.4.
