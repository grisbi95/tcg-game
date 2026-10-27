# 0067 — Case ciblée adjacente au Hero rétablie

- Statut : acceptée
- Date : 2026-10-27
- Décideur : créateur du projet, en conversation
- Périmètre : filtre d'adjacence d'une case ciblée (`TargetSpec.AdjacentTo`), étape c.6 du jalon J2c ; précise 0063

## Contexte

0063 (Conséquences) a supprimé `AdjacentTo.OWN_HERO` de `TargetSpec` en faisant passer l'adjacence au Hero des pièces dans `PieceFilter` (`relation: adjacent`, `relative_to: own_hero`, 0062). Pour une case ciblée, rien ne l'a remplacée. L'inventaire `docs/vocabulaire-des-effets.md` listait `OWN_HERO` parmi les filtres existants avant c.5c.

À c.6, le Hero Recruteuse (`docs/ruleset/50-cartes/heroes.md` : « Ordre (Action) — Endormez le Hero, payez 2 Essence : créez un jeton Unit de Force 1 sur une case libre ciblée adjacente au Hero ») ne pouvait plus s'écrire. 0061 veut qu'à c.6 une carte ne soit qu'une donnée et qu'un vocabulaire absent de l'inventaire ouvre une question : la relecture a demandé que le créateur acte ce retour.

## Options envisagées

- A. Acter le retour : perte involontaire de c.5c (0063), non un vocabulaire nouveau. `AdjacentTo.OWN_HERO` est rétabli pour une case seulement (ajouté à la fin de l'enum, 0047 ; lu par nom en JSON), jugé à l'ajout à la pile et à la résolution (207.5.6) par rapport au Hero du joueur à qui appartient l'effet, lu sur le plateau du moment ; refusé pour une cible pièce (qui passe par `PieceFilter`) ; inventaire mis à jour. Bénéfice : la Recruteuse s'écrit, le catalogue est complet. Coût : une valeur d'enum de plus et sa lecture dans `EffectRules`.
- B. Retirer le code et laisser la Recruteuse hors du catalogue en attendant. Bénéfice : aucun vocabulaire rétabli sans décision. Coût : le deck Phalange reste sans Hero, c.6 non terminée.

Recommandation présentée : A.

## Décision

Option A ; B écartée. Choix du créateur, en conversation, le 2026-10-27.

## Conséquences et vérification

- `TargetSpec.AdjacentTo.OWN_HERO` (case seulement) existe de nouveau, déjà codé à c.6 (`rules/catalog/target_spec.gd`, `rules/effect_rules.gd`), testé (`tests/test_207_5_6_cell_and_spell_filters.gd`, `tests/test_catalog_filters.gd`) ; la Recruteuse est dans `data/cards/heroes.json`.
- `docs/vocabulaire-des-effets.md`, axe F : la case adjacente au Hero redevient une ligne codée.
- Les identifiants de règle qui citent 205.2.5 pour cette adjacence sont faux (205.2.5 vise l'action normale d'une Unit) : à remplacer par 207.5.6 ou la règle exacte, travail induit de c.6.
- Réexamen : si une carte demande l'adjacence au Hero adverse, ou si les filtres de case et de pièce doivent se fondre en un seul (voir le réexamen de 0062).

## Références

- Décisions 0047, 0061, 0062, 0063 ; `docs/roadmap.md`, c.6.
- Ruleset 207.5.6, `docs/ruleset/50-cartes/heroes.md` (Recruteuse) ; `docs/vocabulaire-des-effets.md`.
