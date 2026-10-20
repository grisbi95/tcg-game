# 0038 — Backlog des dettes techniques

- Statut : acceptée
- Date : 2026-10-20
- Décideur : créateur du projet
- Périmètre : documentation du projet, propriétaire des dettes techniques et forme de la ligne « État actuel » de `docs/roadmap.md`

## Contexte

« État actuel » de `docs/roadmap.md` (ligne 5) porte 34 sujets sur une ligne de 5 065 caractères : une douzaine de dettes techniques sans document propriétaire, 7 questions de règles non ouvertes dans le ruleset, des mesures de playtest déjà au protocole, et des redites de ce que les décisions et les `CLAUDE.md` disent déjà. Le hook `session_start.sh` l'affiche entière, alors que `.claude/README.md` promet trois lignes. `docs/README.md` impose un propriétaire par information ; `roadmap.md` est le seul plan ; les questions de règles appartiennent à `docs/ruleset/02-questions-ouvertes.md` et les mesures à `docs/ruleset/70-playtest/protocole.md`. Audit du 20 octobre 2026 (fichier de travail, non commité).

## Options envisagées

- Option A : `docs/backlog.md`, une ligne par dette avec identifiant de règle, priorité et étape cible ; « État actuel » redevient cinq lignes au plus et renvoie au backlog. Bénéfice : lisible hors ligne, lu par les agents et le hook, versionné avec le code. Coût : un document de plus à tenir. Limite : pas de lien avec les PR.
- Option B : section « Backlog » dans `roadmap.md`, même contenu sous les jalons. Bénéfice : aucun fichier nouveau, « seul plan » reste vrai à la lettre. Coût : la roadmap grossit et mélange plan et dettes. Limite : le hook et les agents lisent tout le fichier.
- Option C : issues GitHub, une par dette, label `dette`, liée depuis les PR. Bénéfice : fermeture par PR, filtres. Coût : hors du dépôt, invisible aux agents sans `gh`, dépôt privé. Limite : les identifiants de règle sont inconnus de GitHub.

## Décision

Option A, validée par le créateur le 2026-10-20. Le backlog est lu par les agents et par le hook comme le reste de la documentation ; les issues GitHub pourront venir quand le dépôt sera public.

## Conséquences et vérification

- `docs/backlog.md` est le seul propriétaire des dettes techniques : une ligne par dette, avec identifiant de règle ou décision, priorité (haute si écart au ruleset), étape ou jalon cible ; une dette réglée est supprimée, pas barrée.
- « État actuel » de `docs/roadmap.md` tient en cinq lignes au plus : état du jalon, dernière PR fusionnée, prochaine action, décisions à prendre avec la prochaine étape, renvoi au backlog. Les questions de règles vont à `02-questions-ouvertes.md` par `ruleset-editor`, les mesures de playtest au protocole.
- `docs/README.md` ajoute `backlog.md` à « Où trouver quoi » et « Où écrire » ; la skill `/close-step` met le backlog à jour à chaque clôture d'étape.
- Vérification : `bash .claude/hooks/session_start.sh` tient en trois lignes courtes ; aucune dette n'apparaît dans « État actuel ».
- À réexaminer si le dépôt devient public et que les PR ferment des dettes (passer aux issues GitHub, option C), ou si le backlog dépasse une cinquantaine de lignes (le scinder par couche).

## Références

`docs/README.md`, `docs/roadmap.md`, `.claude/README.md` ; audit du 20 octobre 2026.
