# 0039 — Rituels du cycle de développement en skills locales

- Statut : acceptée
- Date : 2026-10-21
- Décideur : créateur du projet
- Périmètre : skills de `.claude/skills/` couvrant le cycle d'une étape de la roadmap, du début à la rétrospective

## Contexte

L'audit d'assainissement du 20 octobre 2026 relève six skills (`implement`, `tests`, `check`, `decision`, `close-step`, `cards`) et aucune pour : le commit et la PR (`close-step` ne fait que proposer le message), l'ouverture d'une étape, la propagation d'une règle changée du ruleset vers le moteur et les tests (aucune skill depuis la décision 0014), la rétrospective d'un jalon, la correction de cap quand une décision en remplace une autre. Le créateur veut emprunter ces rituels à la méthode BMAD sans l'installer.

## Options envisagées

- Option A : trois skills. `/pr` (branche, commit, push, PR selon `.github/PULL_REQUEST_TEMPLATE.md`, lire la CI une fois, jamais de fusion sans demande), `/open-step N.M` (lire roadmap, décisions et chapitre du ruleset, créer la branche, poser la définition de terminé), `/sync-rule <id>` (`ruleset-editor`, puis `test_rules_coverage`, `grep` des identifiants dans `rules` et `tests`, puis `/implement`). Rétrospective et correction de cap restent en conversation. Bénéfice : le plus léger. Limite : aucune trace écrite des leçons d'un jalon.
- Option B : quatre skills. A plus `/retro <jalon>`, qui écrit `docs/retros/<jalon>.md` (ce qui a marché, dettes portées au backlog, décisions à réexaminer) ; la correction de cap devient un paragraphe de `/decision` (décision remplacée avec statut « remplacée par » posé par `adr-writer`, périmètre de la roadmap ajusté, questions ouvertes touchées). Bénéfice : une trace écrite par jalon, sans skill en doublon. Limite : un dossier `docs/retros/` de plus à tenir.
- Option C : cinq skills, telles que l'audit les proposait : B plus `/correct-course` séparée. Bénéfice : chaque rituel a sa recette. Limite : recoupe `/decision` et les statuts d'`adr-writer`, et servirait rarement.

## Décision

Option B, validée par le créateur le 2026-10-21. Aucun outil BMAD n'est installé.

## Conséquences et vérification

- Quatre skills nouvelles : `/pr`, `/open-step`, `/sync-rule`, `/retro`. `/decision` gagne un paragraphe « correction de cap ».
- `docs/retros/` est créé au premier jalon clos (J2). `docs/README.md` « Où écrire » gagne la ligne « Leçons d'un jalon → `docs/retros/<jalon>.md` par `/retro` » ; `.claude/README.md` liste les skills ; `CLAUDE.md` §9 renvoie aux skills du cycle en une ligne.
- `/pr` ne fusionne jamais sans demande explicite et exige la CI verte, ce qui tient lieu de protection de `main` tant que le dépôt est privé (l'audit du 20 octobre 2026 envisage un dépôt public à l'étape 2.6, point non décidé). `/pr` est verrouillée contre un appel par le modèle (`disable-model-invocation`) : seul le créateur la lance.
- Vérification : chaque skill existe dans `.claude/skills/` et figure dans `.claude/README.md` ; à la clôture de J2, `docs/retros/J2.md` existe.
- À réexaminer : un rituel non joué pendant un jalon entier est retiré ; si le dépôt devient public ou si une équipe rejoint le projet, réexaminer le besoin d'installer BMAD ou un outil équivalent.

## Références

Audit du 20 octobre 2026 ; décisions 0014, 0038 ; `.claude/skills/`, `.claude/README.md`, `docs/README.md`, `docs/roadmap.md`.
