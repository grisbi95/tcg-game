# 0013 — Mulligans exécutés à la dernière réponse

- Statut : acceptée
- Date : 2026-10-16
- Décideur : créateur du projet
- Périmètre : mulligan simultané (204.2) ; complète la décision 0009

## Contexte

Les deux joueurs décident de leur mulligan en même temps (204.2.2), sans voir le choix de l'autre (204.2.3). La décision 0009 en fait une seule attente `MULLIGAN` dont les deux joueurs sont attendus ; un joueur sort de la liste quand il a décidé. Reste à fixer quand le moteur exécute le mulligan (204.2.9) : un joueur répond forcément avant l'autre.

## Options envisagées

- Option A : exécuter chaque mulligan dès sa réponse. Simple ; mais les événements du premier qui répond (cartes piochées, mélange) sortent avant que l'autre ait décidé, et les mélanges par `state.rng` dépendent de l'ordre des réponses.
- Option B : garder les choix dans un champ de `PendingDecision`, copié par `clone()` ; valider chaque réponse dès sa soumission ; émettre un événement public « X a décidé », sans contenu ; exécuter 204.2.9 à la dernière réponse, premier joueur d'abord. Un champ de plus ; l'issue ne dépend plus de l'ordre des réponses.

## Décision

Option B, validée le 16 octobre 2026. Garder sa main se soumet comme un mulligan avec une liste vide.

## Conséquences et vérification

- Une réponse invalide (joueur non attendu ou ayant déjà décidé, carte hors de sa main, carte en double) produit un unique `IntentRejected` à sa soumission, pas à l'exécution.
- Avant la dernière réponse, seul l'événement public sort ; aucune carte ne bouge, aucun tirage n'a lieu.
- À la dernière réponse : 204.2.9 pour le premier joueur, puis pour l'autre, puis fin de l'attente.
- « Premier joueur d'abord » suppose le premier joueur connu avant le mulligan : à confirmer par le ruleset (Q1).
- L'effet d'une liste vide sur le mélange de 204.2.7 reste à trancher par le ruleset (Q4).
- Tests nommés par identifiants (204.2.2, 204.2.3, 204.2.9), dont un qui soumet les réponses dans les deux ordres à graine fixe et compare les états finaux (`DeepCompare`).
- À réexaminer si le ruleset rend le mulligan séquentiel ou visible.

## Références

Ruleset 204.2.1 à 204.2.11, 209.4.4e ; décisions 0009 et 0012.
