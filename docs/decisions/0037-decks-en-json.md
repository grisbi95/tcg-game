# 0037 — Decks en JSON

- Statut : acceptée
- Date : 2026-10-20
- Décideur : créateur du projet
- Périmètre : données des decks (`data/decks/`, `rules/catalog/`, étape 2.4)

## Contexte

La liste du deck de test (30 cartes, Hero Capitaine, `docs/ruleset/70-playtest/decks-de-test.md`, décision 0171 du ruleset) n'existe que dans le code des tests (`tests/support/test_catalog.gd`, `DECK_COPIES`). L'écran fabrique un faux deck. La préparation de partie (0036) a besoin d'un vrai deck.

## Options envisagées

- Option A : un fichier JSON de deck, `data/decks/deck_de_test.json` (édition, identifiant, nom affiché, Hero, nombre d'exemplaires par carte), lu par un petit lecteur dans `rules/catalog/` à côté de `CatalogLoader`, avec le même contrôle d'édition. Un deck est une donnée comme une carte (0002) : en ajouter un ne touche pas au code. Coût : un lecteur et son test, un dossier `data/decks/` nouveau.
- Option B : la liste dans le code, déplacée des tests vers une classe du jeu que les tests réutilisent. Plus rapide, mais chaque nouveau deck modifie le code.

## Décision

Option A, choisie par le créateur le 2026-10-20 (recommandée).

## Conséquences et vérification

- La validité d'un deck reste celle du catalogue (`Catalog.find_deck_errors`, 201.6.1, 201.6.2) et de `DuelSetup.find_errors`.
- `TestCatalog.deck()` lit le fichier au lieu de sa constante. La préparation et les tests utilisent le même lecteur.
- `CLAUDE.md` §5 gagne la ligne « data/decks/ JSON des decks (0037) ».
- Vérification : test du lecteur, et deck de test valide selon `Catalog.find_deck_errors`.
- À réexaminer à l'intégration de `50-cartes/` (J4) ou à l'arrivée d'un éditeur de decks.

## Références

Ruleset 201.6.1, 201.6.2, `70-playtest/decks-de-test.md`, décision 0171 du ruleset ; décisions 0002, 0010, 0036 ; roadmap 2.4.
