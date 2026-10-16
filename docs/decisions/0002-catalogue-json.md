# 0002 — Catalogue de cartes en JSON

- Statut : acceptée
- Date : 2026-10-16
- Décideur : créateur du projet
- Périmètre : format des données de cartes et de Heroes

## Contexte

Le prototype stockait les cartes en Resources `.tres`. Pour un développement assisté par Claude, les `.tres` coûtent des allers-retours (uid, sous-ressources, diffs illisibles). Le ruleset prévoit un catalogue `50-cartes/` en Markdown.

## Options envisagées

- Option A : `.tres`. Édition confortable dans l'éditeur Godot ; diffs et écriture par Claude pénibles.
- Option B : JSON dans `data/cards/`, chargé au démarrage dans des `CardDefinition` typés (`RefCounted`), validé par `find_errors()` et par un test du catalogue. Diff lisible, écriture fiable, format d'échange avec le ruleset.
- Option C : JSON source et export `.tres` par script d'éditeur, si l'éditeur devient nécessaire.

## Décision

Option B, validée le 16 octobre 2026 ; C reste possible. Chaque fichier porte l'`edition` du ruleset (charte §9). Le vocabulaire d'effets est fermé : enums `EffectKind`, `Duration`, `TriggerEvent`, `Keyword`, `TargetWhat`, interprétés par le moteur seul. Aucune logique dans les données. Un nouveau `kind` se code et se teste avant toute carte qui l'emploie.

## Conséquences et vérification

- `rules/catalog/` : `CardDefinition`, `HeroDefinition`, `EffectDefinition`, `TargetSpec`, `CatalogLoader`.
- Test du catalogue : `kind` connus, champs exigés présents, 30 cartes, 3 exemplaires au plus (201.6.1, 201.6.2), édition cohérente.
- À réexaminer si un éditeur visuel de cartes devient nécessaire (option C) ou si le JSON dépasse ce qu'un vocabulaire fermé exprime.

## Références

Ruleset 201.6, 202.1, 202.2, 210 ; `docs/ruleset/70-playtest/decks-de-test.md` ; proposition §2.2.
