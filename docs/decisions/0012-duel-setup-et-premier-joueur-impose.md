# 0012 — Préparation du duel par DuelSetup et premier joueur imposé

- Statut : acceptée
- Date : 2026-10-16
- Décideur : créateur du projet
- Périmètre : démarrage d'un duel (`DuelEngine.start_new_duel`), désignation du premier joueur (204.1.14)

## Contexte

204.1.14 désigne le premier joueur par tirage au sort pendant la préparation. Le protocole de playtest (`docs/ruleset/70-playtest/protocole.md`, décisions 0158 et 0168 du ruleset) le fait au contraire alterner d'une partie à l'autre, le joueur A commençant la partie 1, sans modifier 204.1.14. Le moteur doit donc accepter les deux : tirage par défaut, premier joueur imposé pour une série. Le démarrage reçoit aussi les decks, les Heroes et la graine.

## Options envisagées

- Option A : un objet `DuelSetup` passé à `start_new_duel`, avec les deux decks, les deux Heroes, la graine et un premier joueur optionnel ; s'il est absent, tirage par `state.rng`. Un seul objet à journaliser ; la règle 204.1.14 reste le comportement par défaut.
- Option B : un champ « premier joueur » dans `DuelConfig`. Pas de classe en plus ; mais `DuelConfig` porte une valeur par règle PROVISOIRE, et 204.1.14 est ACTÉ : le champ casserait ce principe.
- Option C : l'hôte cherche une graine qui donne le bon premier joueur. Aucun changement du moteur ; mais fragile, car tout changement de l'ordre des tirages déplace le résultat, et la graine n'est plus libre.

## Décision

Option A, validée le 16 octobre 2026.

## Conséquences et vérification

- Premier joueur imposé ⇒ aucun tirage pour 204.1.14 ; absent ⇒ un tirage par `state.rng`, déterministe à graine fixe.
- Deck invalide (201.6, contrôle de `Catalog`) ⇒ le duel ne démarre pas.
- `start_new_duel` garde au plus 4 paramètres : le `DuelSetup` les regroupe.
- Le journal et le replay (J2) enregistrent le `DuelSetup` en tête de partie.
- Tests : tirage déterministe à graine fixe ; premier joueur imposé pour A et pour B ; deck invalide refusé.
- À réexaminer si le ruleset change 204.1.14, ou si une autre donnée de préparation doit être imposée hors règle.

## Références

Ruleset 201.6, 204.1.9 à 204.1.15 ; protocole de playtest, décisions 0158 et 0168 du ruleset ; décisions 0001 et 0009 ; question ouverte sur l'ordre de la préparation (Q1).
