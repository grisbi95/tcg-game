# 0009 — PendingDecision, un objet porté par DuelState

- Statut : acceptée
- Date : 2026-10-16
- Décideur : créateur du projet
- Périmètre : représentation de l'attente d'un choix de joueur (204.2, 207.5, 208.4, 209.4.4)

## Contexte

Le moteur attend parfois le choix d'un joueur : mulligan simultané des deux joueurs (204.2.2, 204.2.3), ordre de ses effets déclenchés (208.4.6, 208.4.7), cibles d'une entrée de la pile (207.5.1b, 207.5.2). La pendule tourne pour ces attentes (209.4.4c, 209.4.4d, 209.4.4e). La décision 0004 fait prendre par le moteur les choix uniques.

## Options envisagées

- Option A : objet `RefCounted` `DuelState.pending_decision` (null si aucune attente), avec un enum `kind` (MULLIGAN, ORDER_TRIGGERS, CHOOSE_TARGETS, ajouts en fin), les joueurs attendus et les données du choix (identifiants d'entrées, cases candidates). `clone()` propre, une seule attente à la fois garantie par le type, la pendule lit les joueurs attendus.
- Option B : champs plats dans `DuelState`. Pas de classe en plus ; mais `DuelState` grossit à chaque genre, des champs restent inutilisés selon le genre, aucun type ne porte la cohérence.
- Option C : `Array[PendingDecision]`, un par joueur attendu. Modélise le mulligan simultané ; mais autorise des états incohérents (deux attentes de genres différents) à interdire par invariant, et alourdit « seule l'intention qui y répond est acceptée ».

## Décision

Option A, validée le 16 octobre 2026. Le mulligan simultané est une seule attente dont la liste des joueurs attendus contient les deux joueurs ; un joueur sort de la liste quand il a décidé.

## Conséquences et vérification

- `pending_decision` absent ⇒ aucune attente ; présent ⇒ seule l'intention qui y répond est acceptée (rules/CLAUDE.md).
- À l'étape 1.1 existent la classe, son enum `kind` (à compléter en fin) et ses champs de base ; les modules de 1.3 et 1.7 les emploient. `test_duel_state_clone.gd` renseigne chaque champ.
- À réexaminer si un genre d'attente exige en même temps des réponses de genres différents de plusieurs joueurs.

## Références

Ruleset 204.2.2, 207.5.1b, 208.4.6, 208.4.7, 209.4.4c à 209.4.4e ; décisions 0004 et 0007 ; `rules/CLAUDE.md`.
