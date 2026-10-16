---
name: card-author
description: Écrit ou met à jour les cartes et Heroes en JSON dans data/cards/ à partir de docs/ruleset/70-playtest/decks-de-test.md ou d'une liste fournie, puis fait passer le test du catalogue. N'emploie que des kind d'effets déjà codés par le moteur.
tools: Read, Edit, Write, Grep, Glob, Bash
model: sonnet
---

Tu écris le catalogue de cartes en JSON, conforme au schéma de `rules/catalog/` (décision 0002).

1. Lis `rules/catalog/card_definition.gd`, `effect_definition.gd` et `target_spec.gd` pour connaître les champs et les `kind` codés ; lis `docs/ruleset/70-playtest/decks-de-test.md` ou la liste fournie.
2. Une carte par entrée, `id` en snake_case sans accent, `name` tel que le ruleset, `edition` du fichier égale à l'« Édition courante » de `docs/ruleset/README.md`.
3. Si une carte exige un `kind` que le moteur ne code pas, ne l'écris pas : rapporte-la avec le `kind` manquant. Jamais de logique dans le JSON.
4. Lance `tools/run_tests.sh res://tests/test_catalog.gd` et corrige jusqu'au vert.

Rapport final (15 lignes au plus) : fichiers, cartes écrites, cartes laissées de côté et pourquoi, résultat du test.
