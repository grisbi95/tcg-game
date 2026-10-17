# 0018 — Pendule avancée par l'hôte, lue par le moteur

- Statut : acceptée
- Date : 2026-10-17
- Décideur : créateur du projet
- Périmètre : pendule (ruleset 209.4, 209.2.8, 209.2.8a, 209.2.9)

## Contexte

Chaque joueur a une pendule de 10 minutes pour toute la partie (209.4.1, 209.4.3), qui ne tourne que quand les règles attendent une décision de lui (209.4.2, 209.4.4a à 209.4.4e). Pendant le mulligan, les deux pendules tournent en même temps. Le moteur de `rules/` ne lit jamais l'heure et doit rester déterministe (décision 0001) ; la cible Web impose une pendule indépendante des images rendues.

## Options envisagées

- Option A : moteur averti. `DuelEngine.advance_clock(elapsed_msec)` retire le temps écoulé aux pendules qui tournent ; `DuelEngine.clock_owners()` dit, en lecture pure, quelles pendules tournent (aucune, une, ou les deux pendant le mulligan). L'hôte (`DuelHost`, jalon J2) mesure le temps réel et appelle `advance_clock`. Le moteur reste sans heure et rejouable ; le temps écoulé peut se journaliser pour le replay.
- Option B : heure portée par chaque intention, décomptée à la soumission. Moins d'appels ; mais sans intention le temps ne s'écoule jamais, ce qui exige une intention « tic » et mêle le temps aux intentions.
- Option C : pendules tenues par l'application seule, qui prévient le moteur quand un temps est écoulé. Moteur plus simple ; mais `DuelState` ne contient plus le temps (IA et `clone()` l'ignorent) et il y a deux sources de vérité.

## Décision

Option A, validée le 17 octobre 2026 par le créateur.

## Conséquences et vérification

- `StateCheckRules` calcule les pendules qui tournent à partir de l'état seul : aucune hors duel, pendant le début du tour ou une fin du tour sans décision (209.4.2b, 209.4.2c) ; les joueurs attendus par `pending_decision` (209.4.4c à 209.4.4e) ; sinon, pile non vide, le joueur qui peut répondre ou passer (209.4.4b) ; sinon, en phase principale pile vide, le joueur actif (209.4.4a). La résolution de la pile a lieu dans un `submit()` : aucune pendule n'y tourne (209.4.2a).
- `advance_clock` ne bouge les pendules que hors `submit()` (invariant de `rules/CLAUDE.md`) ; un temps nul ou négatif ne change rien ; une pendule ne descend jamais sous 0.
- Si une pendule atteint 0 (209.4.5) pendant l'avance, la partie s'arrête à cet instant (209.2.9) : seul le temps jusqu'à cet instant est retiré aux autres pendules qui tournent ; le joueur perd (209.2.8), ou la partie est nulle si les deux pendules atteignent 0 au même instant (209.2.8a). Un événement `TimeExpired` par pendule à 0, puis `DuelEnded`.
- 209.4.3a : `DuelConfig.clock_bonus_msec` reste à 0 ; `find_errors()` refuse une autre valeur, aucune règle ne disant quand un ajout aurait lieu.
- Tests nommés par identifiants (209.4.x, 209.2.8, 209.2.8a, 209.2.9), dont le mulligan qui fait tourner les deux pendules et une avance qui dépasse le temps d'un seul joueur.
- À réexaminer si le ruleset ajoute du temps pendant la partie ou si le jeu passe en réseau.

## Références

Ruleset 209.4.1 à 209.4.5, 209.2.8, 209.2.8a, 209.2.9, 201.1.3c ; décisions 0001, 0009, 0012.
