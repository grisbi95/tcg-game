# Copie synchronisée du ruleset

> Copie en lecture seule des règles complètes, du glossaire, de la charte et du protocole de playtest, prise dans `../tcg-ruleset` à l'édition **0.28** le 2026-10-16. Ne pas éditer ici : toute modification passe par le dossier du ruleset et l'agent `ruleset-editor`, puis `tools/sync_ruleset.sh`.

- `RULESET_EDITION` : édition épinglée, lue par le test de couverture.
- `20-regles-completes/` : chapitres 200 à 210, identifiants cités par le code (`# 206.3.6`) et les tests (`test_206_3_6_...`).
- `01-glossaire.md` : vocabulaire des identifiants anglais du code (Hero, Unit, Building, Spell, Gear restent tels quels).
- `70-playtest/` : protocole et decks de test, sources de `data/cards/` et du `PlaytestRecorder`.
