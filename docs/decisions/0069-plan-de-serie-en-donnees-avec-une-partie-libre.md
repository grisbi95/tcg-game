# 0069 — Plan de série en données, avec une partie libre

- Statut : acceptée
- Date : 2026-10-28
- Décideur : créateur du projet, en conversation
- Périmètre : écran de préparation (`SetupScreen`), `DuelSeries`, `GameLibrary`, fiche de relevé (`PlaytestSheet`, `PlaytestRecorder`), étape c.8 du jalon J2c

## Contexte

La décision 0066 fait choisir par l'hôte, à la préparation, le deck de A, le deck de B et le premier joueur. Pendant la série J3, l'hôte suit à la main le plan de série du protocole (`docs/ruleset/70-playtest/protocole.md`, « Plan de série » : 24 parties, decks et premier joueur fixés, décisions de design 0229, 0230, 0231). Le code ne vérifie rien ; 0066 acceptait ce risque et prévoyait son réexamen à c.8, quand la fiche de relevé porterait le plan.

Aujourd'hui le « Partie n° » de la fiche CSV (décision 0042) est un compteur de `DuelSeries` (1, 2, 3…), pas le numéro du plan, et la fiche ne dit pas quels decks ont joué. L'ordre de jeu des 24 parties n'est pas fixé par le ruleset (Q-142 ouverte) : le code ne doit pas l'imposer.

## Options envisagées

- A. Plan en données : les 24 parties dans un fichier de `data/`, lu par `GameLibrary` ; l'hôte choisit seulement le numéro de partie, decks et premier joueur en découlent ; la fiche reprend numéro et decks. Bénéfice : aucune erreur d'attribution, un seul choix, fiche juste. Coût : un fichier de données, un sélecteur modifié, des tests. Limite : sans sortie, impossible de jouer hors plan (essais, démo).
- B. Choix libre conservé (0066), la fiche ajoute les decks et l'hôte saisit le numéro de partie du plan. Bénéfice : le moins de travail, souplesse entière. Coût : l'hôte recopie le plan à la main. Limite : une erreur d'attribution ne se voit qu'au dépouillement.
- C. A plus une « partie libre » : le sélecteur propose « Partie 1 » à « Partie 24 » et « Partie libre » ; la partie libre garde le choix de 0066 ; sur la fiche, une partie libre est marquée « hors plan ». Bénéfice : plan garanti pendant la série, souplesse pour les essais. Coût : un peu plus que A, deux modes à l'écran.

Recommandation présentée : C.

## Décision

Option C. A et B écartées. Choix du créateur, en conversation, le 2026-10-28.

## Conséquences et vérification

- Fichier du plan dans `data/` (JSON avec champ `edition`, comme les decks, 0037) reprenant exactement le tableau du protocole ; lu et validé par `GameLibrary` (24 parties, decks existants). Un test contrôle les contraintes de 0229 à 0231.
- `DuelSeries` connaît la partie du plan choisie ou la partie libre ; `make_setup` en tire decks et premier joueur imposé (`DuelSetup.impose_first_player`).
- La fiche CSV porte le numéro de partie du plan (ou « hors plan »), le deck de A et le deck de B.
- L'hôte choisit librement le numéro de partie : aucun ordre de jeu imposé ; Q-142 reste ouverte, non tranchée en code.
- `ui/setup_screen.gd` : un sélecteur de partie (« Partie 1 » à « Partie 24 », « Partie libre ») ; les sélecteurs de decks et de premier joueur ne servent qu'à la partie libre.
- 0066 est modifiée par 0069 : son choix libre subsiste comme mode « partie libre ».
- Vérification : chaque partie du plan donne dans le `DuelSetup` les decks et le premier joueur du protocole ; la partie libre se comporte comme 0066 ; la fiche porte numéro et decks, ou « hors plan ».
- Réexamen : si le protocole change le plan de série (nombre de parties, decks) ou si Q-142 fixe un ordre de jeu.

## Références

- Décisions 0012, 0037, 0042, 0066 ; `docs/roadmap.md`, c.8.
- Ruleset : `docs/ruleset/70-playtest/protocole.md` (« Plan de série »), décisions de design 0229, 0230, 0231, Q-142.
