# 0047 — Retrait du pouvoir du Hero et valeurs d'enum non enregistrées supprimées

- Statut : acceptée
- Date : 2026-10-23
- Décideur : créateur du projet
- Périmètre : retrait du pouvoir du Hero du code ; sort des valeurs d'enum devenues inutiles (`StackEntry`, `IntentRejected`)

## Contexte

Le ruleset 0.42 (décision de design 0208, `docs/ruleset/40-decisions/0208-le-hero-n-a-pas-de-pouvoir.md`) retire le pouvoir du Hero. Le code a suivi : `UseHeroPower`, `HeroPowerAnnounced`, le compteur d'utilisation, le clic et la pastille de pouvoir sur la carte Hero ont disparu ; `HeroDefinition` refuse `power` et `power_cost`. Restent trois valeurs d'enum inutiles : `StackEntry.StackEntryKind.HERO_POWER`, `IntentRejected.RejectReason.HERO_POWER_ALREADY_USED` et `NORMAL_ACTION_ALREADY_USED` (gardée par la décision 0044 comme « journalisable »). La règle « ajouter en fin, jamais réordonner » protège les entiers d'un enum enregistré. Vérification faite, aucune de ces valeurs ne l'est : le journal (`app/duel_journal.gd`, `app/intent_codec.gd`) ne garde que les intentions et les temps, les JSON de `data/` écrivent les `kind` en chaînes, le CSV de playtest ne lit pas ces enums. Seule l'empreinte de rejeu (`ReplayFingerprint`) les hache, et elle se régénère (0022).

## Options envisagées

- Option A : garder les valeurs retirées, marquées « retiré », et la liste `RETIRED_REJECT_REASONS` du test de couverture. Pour : prudence, la lettre de la règle. Contre : du code mort qui grossit à chaque retrait, pour un risque inexistant.
- Option B : supprimer une valeur d'enum devenue inutile quand l'enum n'est enregistré dans aucun fichier conservé (journal, JSON, `.tres`, CSV) ; « ajouter en fin, jamais réordonner » ne vaut que pour un enum ainsi enregistré, comme le formule déjà `docs/code-guidelines.md` (« un enum sérialisé… »). Pour : pas de code mort. Contre : à revoir quand des journaux de playtest seront conservés (J3) : une valeur d'un enum alors enregistré ne se supprimera plus.

## Décision

Option B, choisie par le créateur en conversation le 2026-10-23. Les trois valeurs sont supprimées, `RETIRED_REJECT_REASONS` est retiré de `tests/test_rules_coverage.gd`, et `tests/CLAUDE.md` dit qu'une raison de refus que le moteur ne produit plus se supprime de l'enum.

## Conséquences et vérification

- Plus de code mort pour le pouvoir du Hero ; les fixtures de rejeu sont régénérées (graines 55 et 56).
- Modifie : 0044 (`NORMAL_ACTION_ALREADY_USED` ne reste plus dans l'enum) ; 0032 point 3 (carte Hero cliquable et anneau du pouvoir : caduc) ; 0027 (étiquette « Pouvoir · N » : caduque) ; 0010, 0003, 0019, 0030 et 0031 (mentions du pouvoir du Hero et de `UseHeroPower` : caduques).
- Vérification : `tools/run_tests.sh` vert, dont le test de couverture, et aucune occurrence de `HERO_POWER` ni de `NORMAL_ACTION_ALREADY_USED` dans le code.
- À réexaminer quand des journaux de playtest seront conservés (J3) ou si un enum est écrit dans un fichier conservé : la règle « ajouter en fin » s'applique alors à lui.

## Références

- `docs/ruleset/40-decisions/0208-le-hero-n-a-pas-de-pouvoir.md`
- Décisions 0003, 0010, 0019, 0022, 0027, 0030, 0031, 0032, 0044, 0046
- `docs/code-guidelines.md`, `tests/test_rules_coverage.gd`, `tests/CLAUDE.md`
- PR #37, branche `docs/hero-sans-pouvoir`
