# 0014 — Le ruleset est fusionné dans le dépôt tcg-game, dans docs/ruleset/

- Statut : acceptée ; point ouvert réglé le 2026-10-20 : l'édition se lit dans `docs/ruleset/README.md` (`test_catalog_loader.gd`, hook de session), le test de couverture ne la lit pas, `RULESET_EDITION` n'existe pas
- Date : 2026-10-16
- Décideur : créateur du projet
- Périmètre : emplacement et édition du ruleset ; précise les décisions 0001 et 0007 pour la partie « copie épinglée et synchronisée »

## Contexte

Le ruleset vit dans un dépôt séparé (`../tcg-ruleset`, distant GitHub `grisbi95/tcg-ruleset`). `tcg-game` n'en garde qu'une copie partielle en lecture seule dans `docs/ruleset/` (règles complètes, glossaire, charte, playtest), épinglée par `docs/ruleset/RULESET_EDITION` et mise à jour par `tools/sync_ruleset.sh`.

En développant le moteur, des questions de règles apparaissent (Q-075 à Q-079). Les trancher oblige à changer de dossier, consigner dans l'autre dépôt, resynchroniser, puis revenir. Le créateur veut modifier règles et code ensemble.

Contraintes inchangées : le ruleset fait foi ; un point non tranché va dans les questions ouvertes ; on ne renumérote jamais une règle ; la conversation tranche, l'agent `ruleset-editor` rédige.

## Options envisagées

- Option A : fusion complète dans `docs/ruleset/`, avec l'historique Git du ruleset. Bénéfice : une seule source, règle et code dans le même commit, plus de copie ni de synchronisation, chemins de `docs/ruleset/` conservés pour le code, les tests et les agents. Coût : une quinzaine de documents de consignes à retoucher (mentions de « copie » et de synchronisation), suppression de `tools/sync_ruleset.sh` et de la skill `sync-ruleset`, agent `ruleset-editor` rapatrié dans `.claude/agents/`, ancien dépôt GitHub archivé par le créateur. Limite : le code voit toujours la dernière version des règles ; une règle peut changer avant que le code suive, avec pour garde-fous le test de couverture et le numéro d'édition.
- Option B : sous-module Git dans `docs/ruleset/`. Bénéfice : projets indépendants, édition dans la même session. Coût : deux commits et deux envois par changement, sous-modules fragiles, CI à configurer. Limite : ne règle qu'à moitié le besoin.

## Décision

Option A, choix du créateur, validé le 16 octobre 2026.

## Conséquences et vérification

- `docs/ruleset/` contient le ruleset entier : vision, glossaire, questions ouvertes, règles de base, règles complètes 200 à 210, décisions de design `40-decisions/`, playtest, changelog, charte, README et `CLAUDE.md` local. Il s'édite en place, toujours par l'agent `ruleset-editor`, selon sa `CHARTE.md`.
- L'édition reste le numéro porté par `docs/ruleset/README.md` et `90-changelog.md`. `RULESET_EDITION` est soit conservé et tenu à jour par `ruleset-editor`, soit remplacé par une lecture du README dans le test de couverture : ce point se règle à la fusion, sans changer le rôle du test de couverture (0007).
- Une modification de règle et le code qui l'applique peuvent partir dans le même commit ou la même PR. Une règle modifiée sans code correspondant est signalée dans « État actuel » de la roadmap.
- Fin de la copie : `tools/sync_ruleset.sh`, la skill `/sync-ruleset` et l'interdiction d'éditer `docs/ruleset/` dans `.claude/settings.json` disparaissent à la fusion.
- Le dépôt séparé `tcg-ruleset` est archivé par le créateur après la fusion.
- Vérification : après la fusion, plus aucune mention de copie ou de synchronisation dans les consignes, et le test de couverture lit l'édition au bon endroit.
- À réexaminer si le ruleset doit être partagé seul (autre projet, publication du livret) ou si son historique gêne celui du code.

## Références

Décisions 0001 et 0007 (précisées, non modifiées) ; `docs/ruleset/README.md`, `docs/ruleset/RULESET_EDITION`, `tools/sync_ruleset.sh` ; questions Q-075 à Q-079.
