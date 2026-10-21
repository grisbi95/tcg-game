# 0041 — Bac à sable et LogView retirés

- Statut : acceptée
- Date : 2026-10-21
- Décideur : créateur du projet
- Périmètre : écrans d'essai de `ui/components/_try/` et composant `LogView`

## Contexte

Le bac à sable `ui/components/_try/try_duel_sandbox.gd` (395 lignes) est un écran de duel d'avant l'étape 2.3. Il fait doublon avec `ui/duel_screen.tscn` et avec `try_duel_screen_scenarios`, qui rejoue les situations rares (audit d'assainissement du 20 octobre 2026, lot A4). La décision 0028 dit : pas de journal à l'écran, `DuelJournal` (0022) reste pour le replay et les fiches de playtest, et `LogView` « ne reste que dans le bac à sable ».

## Options envisagées

- Option A : réduire le bac à sable à un lanceur, qui ne fait que lancer `duel_screen.tscn` avec un `LogView` à côté. Le doublon disparaît, 0028 reste vraie, aucune décision à écrire. Coût : un fichier et un composant de plus à maintenir pour un seul usage.
- Option B : tout supprimer, bac à sable, `LogView` et sa scène d'essai. Moins de code. Coût : 0028 est modifiée sur ce point, plus aucun journal à l'écran.
- Option C : ne rien toucher. Aucun effort, mais le doublon reste.

## Décision

Option B, choisie par le créateur le 2026-10-21 : tout supprimer. La décision 0028 est modifiée sur la seule phrase qui garde `LogView` dans le bac à sable ; le reste de 0028 est inchangé.

## Conséquences et vérification

- `try_duel_sandbox.gd`/`.tscn`, `ui/components/log_view.gd`/`.tscn` et `try_log_view.gd`/`.tscn` sont supprimés. Aucun journal à l'écran nulle part.
- `DuelJournal` (0022) et `EventText` restent. Les situations rares se rejouent par `try_duel_screen_scenarios`.
- Vérification : plus aucune référence aux fichiers supprimés dans le code, les scènes et les consignes, tests et lint verts.
- À réexaminer : un besoin de lire les événements pendant un playtest (J3) ou un débogage que le journal ne couvre pas.

## Références

Audit du 20 octobre 2026 (lot A4) ; décisions 0022, 0028 ; `ui/components/_try/try_duel_screen_scenarios`, `ui/duel_screen.tscn`.
