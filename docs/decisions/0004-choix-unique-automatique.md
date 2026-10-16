# 0004 — Décision à choix unique prise par le moteur

- Statut : acceptée
- Date : 2026-10-16
- Décideur : créateur du projet
- Périmètre : points d'interruption PendingDecision (208.4, 207.5)

## Contexte

Le moteur attend parfois une décision d'un joueur en pleine résolution : ordre de ses effets déclenchés simultanés (208.4.6, 208.4.7), cibles d'un effet déclenché à son ajout à la pile (207.5.1b). Ces attentes sont modélisées par `DuelState.pending_decision`. Souvent, un seul choix est légal : un seul déclencheur, une seule cible possible.

## Options envisagées

- Option A : quand une seule option est légale, le moteur l'applique sans émettre `DecisionRequested`. Moins d'allers-retours pour la vue et l'IA ; la pendule ne tourne pas pour un faux choix.
- Option B : toujours demander. Flux uniforme, mais des intentions triviales à produire et un temps de pendule consommé pour rien.

## Décision

Option A, validée le 16 octobre 2026. Commodité d'implémentation : aucune règle n'est modifiée, l'issue est identique à celle de l'option B. L'événement `DecisionResolvedAutomatically` garde la trace dans le journal.

## Conséquences et vérification

- Tests : un déclencheur unique s'ajoute sans décision ; deux déclencheurs du même joueur produisent `ORDER_TRIGGERS` ; une cible unique est choisie d'office ; deux cibles légales produisent `CHOOSE_TARGETS`.
- À réexaminer si une carte rend le choix d'une cible unique significatif (par exemple cibler ou non).

## Références

Ruleset 207.5.1b, 207.5.9, 208.4.6 à 208.4.8, 209.4.4c, 209.4.4d ; proposition §2.5.
