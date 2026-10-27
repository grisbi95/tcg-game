# 0059 — Modules d'un chapitre long découpés par section

- Statut : acceptée
- Date : 2026-10-27
- Décideur : créateur du projet, en conversation
- Périmètre : découpage des modules de `rules/` pour un chapitre long ; complète 0007

## Contexte

0007 prévoit un module de règles par chapitre du ruleset, deux pour un chapitre long, découpés par section (`PreparationRules` et `TurnRules` pour 204, `SpellRules` et `EffectRules` pour 207). La limite de 400 lignes par fichier (`.gdlintrc`, `max-file-lines`) et la croissance du chapitre 207 au jalon J2c ont conduit, à l'étape c.5a (branche `feat/c.5a-cout-x-et-mots-cles`, décision 0058), à quatre modules pour 207, chacun limité à sa section : `SpellRules` (207.1), `StaticEffects` (207.2, effets statiques et portées, partagés par `ForceRules` et `KeywordRules`), `ModifierRules` (207.4, effets à durée) et `EffectRules` (207.5 et 207.6, cibles, application, Contrecarrer). La relecture a relevé l'écart avec 0007.

## Options envisagées

- Option A : un chapitre long se découpe en autant de modules que nécessaire, un par section ou groupe de sections, jamais hors du chapitre. Bénéfice : fichiers sous 400 lignes, une responsabilité par module, la carte de `rules/CLAUDE.md` dit quelle section va où. Coût : plus de fichiers à parcourir pour un chapitre.
- Option B : deux modules pour 207 et limite de lignes relevée pour ces fichiers (exemption `max-file-lines`). Bénéfice : la lettre de 0007. Coût : fichiers de plus de 600 lignes à plusieurs rôles, exemptions de lint que la relecture a déjà refusées ailleurs (c.3).

## Décision

Option A, B écartée. Choix du créateur, 2026-10-27.

## Conséquences et vérification

- Complète 0007 (sa ligne de statut porte « complétée par 0059 ») ; `CLAUDE.md` racine (§3) et l'en-tête de `rules/CLAUDE.md` renvoient à 0059.
- Règle qui demeure : un module ne dépasse jamais son chapitre ; chaque module dit ses sections dans la carte de `rules/CLAUDE.md`.
- Vérification : `tools/lint.sh` propre sans exemption de `max-file-lines` ; la carte couvre chaque module de `rules/`.
- Réexamen : si un chapitre dépasse cinq modules, ou si deux modules d'un même chapitre s'appellent en boucle.

## Références

- Décisions 0007, 0058.
- `.gdlintrc` (`max-file-lines`), `rules/CLAUDE.md`, branche `feat/c.5a-cout-x-et-mots-cles`.
