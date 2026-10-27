# 0066 — Choix des decks et du premier joueur par l'hôte à la préparation

- Statut : acceptée
- Date : 2026-10-27
- Décideur : créateur du projet, en conversation
- Périmètre : écran de préparation (`SetupScreen`), `DuelSeries`, `GameLibrary` et fabrication du `DuelSetup`, étape c.6 du jalon J2c

## Contexte

`ui/main_screen.gd` charge un seul deck (`GameLibrary.load_deck`, deck de test, 0037) et le donne aux deux joueurs (`DuelSeries.new(deck, deck)`) ; `DuelSeries.get_first_player()` fait alterner le premier joueur selon les décisions de design 0158 et 0168 du ruleset. L'étape c.6 écrit les 4 decks du catalogue de playtest (`docs/ruleset/50-cartes/decks.md` : Percée, Phalange, Échiquier, Grimoire) et demande qu'ils se choisissent à l'écran de préparation.

Pour la série J3, le protocole (`docs/ruleset/70-playtest/protocole.md`, « Plan de série ») fixe pour chacune des 24 parties le deck de A, le deck de B et le premier joueur (décisions de design 0230 : decks attribués par le plan, choix par chaque joueur écarté ; 0231 : premier joueur fixé par le plan, remplace en partie 0158 et 0168). L'ordre de jeu des parties n'est pas fixé (Q-142, ouverte).

Contraintes : `DuelSetup` porte déjà decks, Heroes, graine et premier joueur imposé (`impose_first_player`, 0012) ; en duel à distance l'hôte fabrique le setup et l'envoie à l'invité (rien de nouveau par le relais, 0049, 0050) ; aucune règle dans `ui/`.

## Options envisagées

- A. Plan de série en données : les 24 parties en JSON dans `data/`, lues par `GameLibrary` ; l'hôte choisit le numéro de partie (ordre libre, Q-142) ; decks et premier joueur en découlent (0230, 0231). Bénéfice : fidèle à 0230 et 0231, aucune erreur d'attribution, un seul sélecteur, prépare c.8. Coût : un fichier de données recopié du protocole et son test de contraintes. Limite : aucune partie hors plan sans revenir au code.
- B. Choix libre des deux decks par l'hôte, dans deux listes ; le premier joueur suit l'alternance ou devient un troisième choix. Bénéfice : le plus souple. Coût : pendant la série, l'hôte recopie le plan à la main, avec un risque d'erreur. Limite : le code ne garantit plus le plan de 0230.
- C. A plus une « partie libre » (deux listes de decks, premier joueur tiré au sort). Bénéfice : plan garanti et souplesse. Coût : un peu plus d'écran.

Recommandation présentée : A.

## Décision

Option B. A et C écartées. Choix du créateur, en conversation, le 2026-10-27.

Précision du créateur sur le premier joueur : il est choisi par l'hôte à la préparation, par un troisième sélecteur (joueur A, joueur B, ou tirage au sort par le moteur selon 0012). Les autres possibilités présentées étaient l'alternance actuelle (0158, 0168) et le tirage au sort systématique.

## Conséquences et vérification

- `SetupScreen` propose à l'hôte trois choix : deck du joueur A, deck du joueur B (parmi les decks de `data/decks/`, deck de test compris), premier joueur (A, B ou tirage). La vue émet ces choix comme gestes ; `app/` (`DuelSeries` ou `main_screen.gd`, `GameLibrary` qui liste les decks) en fabrique le `DuelSetup` ; aucune règle dans `ui/`.
- `DuelSeries` ne fait plus alterner le premier joueur (0158 et 0168, remplacées en partie par 0231 au ruleset) : le premier joueur est celui que choisit l'hôte, imposé par `DuelSetup.impose_first_player`, ou tiré par le moteur (0012).
- Pendant la série J3, l'hôte suit à la main le plan de série du protocole (decks et premier joueur de chaque partie, 0230, 0231) ; le code ne vérifie pas le plan. Risque d'erreur d'attribution accepté ; à surveiller à c.8 (le plan dans la fiche de relevé) et au premier playtest.
- En duel à distance, l'hôte fait ces choix ; l'invité reçoit le setup comme aujourd'hui.
- Vérification : les quatre decks et le deck de test se choisissent pour A et pour B ; chaque valeur du troisième sélecteur donne le premier joueur attendu dans le `DuelSetup`.
- Réexamen : si une partie de la série J3 se joue avec une attribution qui ne suit pas le plan, ou quand c.8 fait porter le plan à la fiche de relevé (l'option A ou C redevient alors candidate).

## Références

- Décisions 0012, 0037, 0049, 0050 ; `docs/roadmap.md`, c.6 ; `docs/ruleset/50-cartes/decks.md`.
- Ruleset : `docs/ruleset/70-playtest/protocole.md` (« Plan de série »), décisions de design 0158, 0168, 0230, 0231, Q-142.
