# 0007 — Un module de règles par chapitre, couverture par identifiant

- Statut : acceptée ; précisée par 0014
- Date : 2026-10-16
- Décideur : créateur du projet
- Périmètre : découpage du moteur et traçabilité ruleset ↔ code

## Contexte

Le ruleset est numéroté par chapitre, section et règle (`206.3.6`), avec une charte qui garantit la stabilité des identifiants. Le prototype découpait déjà son moteur par section du livret et vérifiait la couverture des règles par un test qui lisait le livret.

## Options envisagées

- Option A : un module statique par chapitre du ruleset (`EssenceRules` 203, `ActionRules` 205, `StackRules` 208…), plus `ForceRules` et `BoardGeometry` transverses ; chaque fonction commentée par ses identifiants, chaque test nommé par le sien ; un test de couverture lit `docs/ruleset/20-regles-completes/` (copie épinglée par `tools/sync_ruleset.sh`) et exige un test ou une justification par règle.
- Option B : patron commande, chaque intention porte `validate` et `apply`. Pas d'aiguillage, mais règles dispersées par intention, hors de l'ordre du ruleset.
- Option C : moteur unique découpé au premier point de douleur. Découpage certain dès le chapitre 208.

## Décision

Option A, validée le 16 octobre 2026. Le ruleset se lit dans une copie locale épinglée (`docs/ruleset/RULESET_EDITION`) ; une nouvelle édition passe par `/sync-ruleset`, qui liste les identifiants touchés et le travail induit. Une règle PROVISOIRE devient un champ de `DuelConfig`.

## Conséquences et vérification

- Un identifiant mène en une recherche à sa fonction et à son test ; une édition du ruleset mène en une commande à la liste des tests à revoir.
- `test_rules_coverage.gd` (J1 étape 1.10) et sa liste `RULES_WITHOUT_OWN_TEST` justifiée.
- À réexaminer si un module dépasse 400 lignes (`.gdlintrc`) : scission par section, jamais hors du chapitre.

## Références

Ruleset `CHARTE.md` §3, §4, §9 ; `rules/CLAUDE.md` ; décisions 0005 et 0007 de `tactical_tcg` ; proposition §2.4.
