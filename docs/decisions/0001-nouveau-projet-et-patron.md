# 0001 — Nouveau projet tcg-game, patron du prototype repris

- Statut : acceptée
- Date : 2026-10-16
- Décideur : créateur du projet
- Périmètre : fondation du projet et architecture générale

## Contexte

Le ruleset `tcg-ruleset` (édition 0.28) a profondément changé le jeu par rapport au prototype `tactical_tcg` : plateau 5×5, Hero sur le plateau, Essence et Sources, Gear, jetons, effets déclenchés, mots-clés, pendule liée aux décisions. Le code de règles du prototype et ses identifiants `R7.3` sont obsolètes ; son patron d'architecture et son outillage sont éprouvés.

## Options envisagées

- Option A : faire évoluer `tactical_tcg`. Garde l'historique, mais chaque module de règles et chaque test doivent être réécrits, avec un mélange durable d'identifiants R et 2xx.
- Option B : nouveau projet `GameDev/tcg/tcg-game/`, voisin du ruleset, dépôt Git propre ; outillage repris (hook, GdUnit4, support de tests, guide de code, patron de vue), moteur réécrit chapitre par chapitre.
- Option C : nouveau projet sans rien reprendre. Perd l'outillage.

## Décision

Option B, validée le 16 octobre 2026. Le patron repris : intentions → `DuelEngine` seul à modifier l'état → `Array[DuelEvent]` ; état en classes `RefCounted` typées avec `clone()` complet ; identifiants entiers jamais réutilisés ; refus par `IntentRejected` et `validate()` public ; RNG dans l'état ; vue resynchronisée depuis l'état après la file d'événements ; `DuelSelection` par `validate()`. Couches `data/` ← `rules/` ← `ai/` ← `app/` ← `ui/`. Godot 4.7.2, GDScript typé, GL Compatibility, export Web prioritaire sans thread.

## Conséquences et vérification

- `tactical_tcg` reste consultable, jamais importé.
- Vérification J0 : import headless, smoke test GdUnit4, tests du hook verts.
- À réexaminer si le ruleset se stabilise au point qu'une migration du prototype redevienne moins coûteuse, ce qui n'est pas attendu.

## Références

`../proposition-architecture-workflow.md` §1 et §2 ; décisions 0001, 0004, 0005, 0010 de `tactical_tcg`.
