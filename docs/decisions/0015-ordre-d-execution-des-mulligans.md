# 0015 — Ordre d'exécution des mulligans

- Statut : acceptée
- Date : 2026-10-16
- Décideur : créateur du projet
- Périmètre : mulligan simultané (204.2) ; précise la décision 0013, qui reste acceptée : seule sa clause « premier joueur d'abord » est remplacée par celle-ci

## Contexte

La décision 0013 exécute les mulligans à la dernière réponse, « premier joueur d'abord », en supposant le premier joueur connu avant le mulligan (question Q1 du ruleset, devenue Q-075). Le créateur a tranché Q-075 en option B le 16 octobre 2026 : le premier joueur est tiré au sort après le mulligan. Ordre de la préparation : Heroes et PV, Sources, mélange, pioche de 5, mulligan, puis tirage du premier joueur. Au moment d'exécuter les mulligans, le premier joueur n'est donc pas connu.

Le moteur a pourtant besoin d'un ordre fixe : chaque mulligan mélange un deck par `state.rng` (204.2.7), et le même état, la même graine et les mêmes intentions doivent donner le même résultat. Le créateur a aussi tranché Q-078 en option A : un joueur qui n'écarte aucune carte garde sa main, ce n'est pas un mulligan, aucun mélange.

## Options envisagées

- Option A : ordre fixe, joueur A puis joueur B. Simple et déterministe ; invisible des joueurs, puisque chacun ne pioche et ne mélange que son propre deck. L'ordre ne change que la consommation de `state.rng`.
- Option B : ordre tiré par `state.rng`. Même effet visible ; un tirage de plus à coder et à tester, sans bénéfice de jeu.

## Décision

Option A, choix du créateur, validée le 16 octobre 2026.

## Conséquences et vérification

- À la dernière réponse : 204.2.9 pour le joueur A s'il écarte au moins une carte, puis pour le joueur B s'il en écarte au moins une, puis fin de l'attente. Un joueur qui garde sa main (liste vide) ne pioche ni ne mélange (Q-075 et Q-078 du ruleset, décisions de design correspondantes dans `docs/ruleset/40-decisions/`).
- Le tirage du premier joueur (204.1.14) a lieu après les mulligans, sauf si `DuelSetup` impose le premier joueur (0012) : dans ce cas aucun tirage.
- Le test de 0013 qui soumet les réponses dans les deux ordres à graine fixe et compare les états finaux reste exigé.
- À réexaminer si le ruleset fait connaître le premier joueur avant le mulligan.

## Références

Ruleset 204.1, 204.2.7, 204.2.9 ; questions Q-075 et Q-078 ; décisions 0012 et 0013.
