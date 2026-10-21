# 0040 — Raison de fin de partie portée par DuelEnded

- Statut : acceptée
- Date : 2026-10-21
- Décideur : créateur du projet
- Périmètre : fin de duel dans le moteur (`DuelEnded`, `StateCheckRules`), son texte dans la vue (`EndSummary`) et le relevé de playtest

## Contexte

`DuelEnded` (`rules/events/duel_ended.gd`) ne porte que le résultat (`DuelState.DuelResult` : A gagne, B gagne, nulle). La vue reconstruit la raison : `EndSummary.reason_text(events, state)` relit les événements du dernier lot (`PlayerConceded`, `TimeExpired`) puis les PV des Heroes (`hero.health == 0`). C'est une règle du chapitre 209 hors du moteur, relevée par l'audit du 20 octobre 2026 (lot A1). Le protocole de playtest (`docs/ruleset/70-playtest/protocole.md`, « Cause de fin », décision de design 0161 du ruleset) distingue « 0 PV par la fatigue » (209.5.3) de « 0 PV par une autre cause » (209.2.2), ce que la vue ne peut pas déduire. La roadmap notait cette décision à prendre avec l'étape 2.5 (`PlaytestRecorder`).

## Options envisagées

- Option A : raison sur `DuelEnded`. Nouvel enum `DuelState.EndReason` (NONE, HERO_HEALTH_ZERO, HERO_HEALTH_ZERO_BY_FATIGUE, CONCEDED, TIME_EXPIRED) porté par l'événement à côté du résultat ; la perte de PV transmet sa cause jusqu'à la vérification de victoire ; `EndSummary` ne fait que traduire. Coût : signatures de `StateCheckRules`, fixture de replay régénérée (0022), tests 209.2, 209.5 et `EndSummary`.
- Option B : comme A, plus un champ `end_reason` dans `DuelState` (avec `clone()` et son test), lisible après coup sans relire le journal. Coût : un champ d'état de plus, deux endroits qui disent la même chose.
- Option C : `DuelEnded` inchangé ; l'événement de perte de PV porte sa cause (combat, effet, fatigue) ; `EndSummary` reconstruit depuis les événements sans lire les PV. Le plus petit changement du moteur, mais la règle de lecture reste dans la vue et le relevé doit recouper deux événements.

## Décision

Option A, choisie par le créateur le 2026-10-21. Le ruleset ne change pas : aucune règle nouvelle, le moteur expose ce qu'il décidait déjà.

## Conséquences et vérification

- `DuelState.EndReason` ajouté parmi les enums de `DuelState` ; une cause nouvelle s'ajoute en fin d'enum. `DuelEnded.reason` ; `_end_duel` la porte.
- `StateCheckRules.check_victory(state, events, reason)` exige la raison, sans valeur par défaut : `lose_health` et la résolution de la pile passent `HERO_HEALTH_ZERO`, `apply_fatigue` passe `HERO_HEALTH_ZERO_BY_FATIGUE` ; les deux passent par la privée `_take_health` (retrait des PV et événement `HeroLostHealth`) puis `check_victory`. `lose_health` garde quatre paramètres.
- Une partie nulle porte la raison de la perte de PV qui la déclenche ; une nulle pendant la fatigue (`HERO_HEALTH_ZERO_BY_FATIGUE`) est inaccessible aujourd'hui, la fatigue ne touchant qu'un joueur à la fois, et `EndSummary` lui donne tout de même un texte.
- `DuelEngine.announces_with_target(card_id)` ne cherche la carte que dans les mains, seule zone d'où la vue annonce.
- `EndSummary.reason_text(events)` traduit (résultat, raison) sans lire l'état ; `EventText` inchangé.
- `tests/fixtures/replay_random_duel.journal.json` régénéré par `tools/record_replay_fixture.gd` : écart voulu, à dire dans le rapport. `PlaytestRecorder` (2.5) lira la raison dans le `DuelEnded` du journal.
- Vérification : tests nommés 209.2 et 209.5 pour chaque raison, test d'`EndSummary` sur (résultat, raison), suite de replay verte avec la fixture régénérée.
- À réexaminer : si une cause de fin nouvelle apparaît au chapitre 209, l'enum s'étend en fin ; si le relevé de playtest a besoin de la raison hors du journal, passer à l'option B.

## Références

Audit du 20 octobre 2026 (lot A1) ; décisions 0006, 0022 ; ruleset 209.2.2, 209.5.3, `docs/ruleset/70-playtest/protocole.md` (décision de design 0161) ; `rules/events/duel_ended.gd`, `ui/end_summary.gd`, `docs/roadmap.md` (étape 2.5).
