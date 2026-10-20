# 0024 — DuelSelection pas à pas

- Statut : acceptée ; modifiée par 0031
- Date : 2026-10-18
- Décideur : créateur du projet
- Périmètre : traduction des gestes en intentions (`ui/`, étape 2.2)

## Contexte

Les vues émettent des gestes (carte, pièce, case, cible, Source) ; `DuelSelection` les traduit en intentions sans recopier aucune règle (`CLAUDE.md` §3). Il faut décider comment la sélection sait ce qui est jouable, y compris au mulligan à plusieurs cartes et pour l'ordre des déclencheurs.

## Options envisagées

- Option A : pas à pas (recommandée). Chaque geste réduit les choix ; à chaque étape, la sélection essaie les suites possibles auprès de `DuelEngine.validate()` et ne surligne que celles qu'il accepte. Coût : de nombreux appels à `validate()` par étape.
- Option B : liste de candidates partagée avec `RandomLegalAgent` (0019). Code commun ; mais limitée par construction (une carte au mulligan, deux ordres de déclencheurs, paiement simple).

## Décision

Option A, recommandée et choisie par le créateur le 18 octobre 2026.

## Conséquences et vérification

- Machine à états explicite (`enum` + `match`, `ui/CLAUDE.md`) : IDLE, CARD_CHOSEN, PIECE_CHOSEN, TARGET_PENDING, CONFIRM ; tout ajout en fin.
- `RefCounted`, testé sans scène ; aucune règle recopiée, `validate()` seul fait foi.
- Gère le mulligan à plusieurs cartes et tout ordre des déclencheurs (`PendingDecision`, 0009).
- Vérification : suite de `DuelSelection` sans scène, un test par étape et par type de geste.
- À réexaminer si le coût de `validate()` ralentit l'affichage des cases légales.

## Références

Décisions 0003, 0009, 0019, 0023 ; `ui/CLAUDE.md` ; roadmap étape 2.2.
