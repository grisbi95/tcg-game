---
name: sync-ruleset
description: Resynchronise la copie docs/ruleset/ depuis ../tcg-ruleset et liste ce que la nouvelle édition change pour le code. Usage : /sync-ruleset
---

# Synchroniser le ruleset

1. `tools/sync_ruleset.sh` (chemin par défaut `../tcg-ruleset`).
2. `git diff --stat docs/ruleset/` puis `git diff docs/ruleset/20-regles-completes/` : relève les identifiants ajoutés, modifiés ou supprimés et les valeurs PROVISOIRE changées.
3. Pour chaque identifiant touché, cherche les tests et le code qui le citent (`grep -rn "206.3.6" rules tests`). Liste le travail induit ; ne modifie pas le code dans cette étape.
4. Lance `tools/run_tests.sh res://tests/test_rules_coverage.gd` si la suite existe : les règles nouvelles sans test apparaissent.
