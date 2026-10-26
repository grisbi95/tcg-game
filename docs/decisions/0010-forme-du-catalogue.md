# 0010 — Forme du catalogue : effets atomiques, cibles à champs fixes, mots-clés déclarés

- Statut : acceptée ; modifiée par 0047 ; modifiée par 0055 ; complétée par 0056
- Date : 2026-10-16
- Décideur : créateur du projet
- Périmètre : schéma JSON de `data/cards/` et classes de `rules/catalog/` (précise la décision 0002)

## Contexte

Le ruleset fixe ce qu'une carte porte (202.1 à 202.3), les timings d'un effet (207.2 statique, 207.3 déclenché, 207.1 Spell), les durées (207.4), les cibles (207.5) et les mots-clés (210), pas la forme des données. Le vocabulaire fermé de la décision 0002 (`EffectKind`, `Duration`, `TriggerEvent`, `Keyword`, `TargetWhat`) restait à dessiner pour les 17 cartes et le Hero de `decks-de-test.md`.

## Options envisagées

- Effet. A : une action atomique par effet, champs plats `kind`, `timing`, `trigger`, `scope`, `target`, `duration`, `amount`. B : un effet porte des cibles puis une liste d'actions (aucune des 17 cartes n'en a besoin, interpréteur plus lourd). C : un `kind` par motif de carte (vocabulaire qui grossit à chaque carte).
- Cibles. A : `TargetSpec` à champs fixes (`what`, `side`, `piece_kinds`, `max_force`, `row`, `count_min`, `count_max`), portée d'un effet statique en enum à part. B : conditions génériques `{field, op, value}` (interpréteur de conditions, données proches d'un langage). C : enum de ciblages nommés composites (une valeur par nouvelle carte).
- Mots-clés. A : les cinq mots-clés déclarés dans `keywords` avec leur valeur X, Arrivée et Dernier souffle liés à un effet déclenché de même événement. B : seuls Avant-poste, Assaut et Rempart déclarés, Arrivée et Dernier souffle déduits du `trigger`.

## Décision

Effet A, cibles A, mots-clés A, validés le 16 octobre 2026.

- `EffectDefinition` : `kind` (`MODIFY_FORCE`, `DESTROY`, `COUNTER_SPELL`, `CREATE_TOKEN`, ajouts en fin), `timing` (`RESOLVE`, `STATIC`, `TRIGGERED`), `trigger` (`ARRIVAL`, `DESTROYED`), `scope` d'un effet statique (`BEARER`, `ADJACENT_ALLIED_UNITS`), `duration` (`ActiveEffect.EffectDuration`), `amount`, `token_piece_kind`, `token_force`. Un effet statique ne cible pas (207.2.1, 207.5.1) et n'a pas de durée (207.4.10).
- `TargetSpec` : `what` (`PIECE`, `CELL`, `SPELL_ON_STACK`, 207.5.11 et 207.5.14), `side`, `piece_kinds`, `max_force`, `row` (`OWN_FIRST`), nombre de cibles (207.5.10).
- Timings admis par type de carte, pour ne rien laisser d'implicite : Spell `RESOLVE` (202.2.20) ; Unit et Building `STATIC` ou `TRIGGERED` (207.2.2, 207.3) ; Gear `STATIC` (207.2.8) ; passif du Hero `STATIC` (202.3.18), pouvoir `RESOLVE` (208.1.4). Un autre emploi est une question pour `tcg-ruleset`, pas un cas à tolérer.
- Ajouts structurels sans règle propre : `Catalog` (résolution de `definition_id`, un seul espace d'identifiants pour cartes et Heroes, 202.3.4), `CatalogReader` (lecture typée, champ inconnu refusé), contrôle de deck 201.6.1, 201.6.2 et 202.3.5 par `Catalog.find_deck_errors()`. Bornes de bon sens non écrites au ruleset : coût et coût du pouvoir au moins 0, Hero d'au moins 1 PV, `amount` non nul, X d'un mot-clé à valeur au moins 1.

## Conséquences et vérification

- Un nouveau `kind` s'ajoute en fin de `EffectKind`, avec ses champs dans `find_errors()`, son code et ses tests avant toute carte (0002).
- `tests/test_catalog.gd`, `test_catalog_effects.gd` et `test_catalog_loader.gd` refusent chaque définition incohérente avec le message de la règle.
- À réexaminer si une carte exige deux actions sur une même cible (option B de l'effet) ou une condition de cible que les champs fixes n'expriment pas (option B des cibles).

## Références

Ruleset 201.6, 202.1 à 202.4, 207.1 à 207.6, 210 ; `docs/ruleset/70-playtest/decks-de-test.md` ; décisions 0002, 0007 et 0008 ; `rules/CLAUDE.md`.
