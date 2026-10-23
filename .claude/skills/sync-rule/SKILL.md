---
name: sync-rule
description: Propage une règle du ruleset nouvelle ou modifiée vers le moteur, les tests et les cartes : lecture du changement, consignation par ruleset-editor, couverture, travail induit, puis /implement. Usage : /sync-rule 206.3.6 ou /sync-rule 208.3
---

# Synchroniser une règle

Arguments : un identifiant (`206.3.6`), une section (`208.3`) ou une liste.

Moment : entre deux étapes, à la clôture de l'une ou à l'ouverture de la suivante par `/open-step`, ou hors étape ; jamais pendant une étape ouverte (rétro J2). Si une règle change pendant une étape, elle se note dans « État actuel » de `docs/roadmap.md` et attend la clôture de l'étape.

1. Lis la règle (texte, statut), sa ligne dans `docs/ruleset/90-changelog.md`, les règles qui y renvoient (`grep -rnw "<identifiant>" docs/ruleset`) et le code qui la cite (`grep -rnw "<identifiant>" rules tests data app ui`). Si le code est déjà conforme au texte courant, dis-le et arrête-toi.
2. Si le point tranché n'est pas encore consigné, lance `ruleset-editor` avec ce qui a été décidé : identifiants, texte, décision de design, édition. Rien n'entre dans `docs/ruleset/` autrement.
3. Lance `verifier` sur `res://tests/test_rules_coverage.gd`. Une règle nouvelle sans test fait échouer la couverture : c'est attendu, le test attendu se nomme par l'identifiant.
4. Liste le travail induit avant de coder : identifiants à implémenter, règles qui y renvoient, cartes de `data/cards/` touchées, valeur de `DuelConfig` pour une règle PROVISOIRE nouvelle.
5. Si le champ `edition` des JSON de `data/` diffère de l'« Édition courante » de `docs/ruleset/README.md` : `card-author` met à jour `data/cards/` et `data/decks/`, `ui-builder` la balise d'essai de `ui/components/_try/duel_scenarios.gd` ; le test du catalogue l'exige.
6. `/implement <identifiants>` pour le moteur et les tests ; `/cards` si une carte change ; puis `verifier` complet. Un écart voulu du replay de non-régression (décision 0022) se régénère par `tools/record_replay_fixture.gd` et se dit dans le rapport.
7. Rapport : identifiants, fichiers touchés, replay régénéré ou non et pourquoi, points restés à arbitrer. Si le code ne suit pas dans la même PR, signale la règle modifiée sans son code dans « État actuel » de `docs/roadmap.md` et porte la dette dans `docs/backlog.md`.
