#!/usr/bin/env bash
# Copie les règles complètes et le glossaire du ruleset dans docs/ruleset/ et épingle l'édition.
# Le ruleset fait foi ; cette copie sert aux tests de couverture et aux agents, jamais à l'édition.
# Usage : tools/sync_ruleset.sh [chemin du dossier tcg-ruleset]   (défaut : ../tcg-ruleset)
set -eu
cd "$(dirname "$0")/.."
src="${1:-../tcg-ruleset}"
[ -f "$src/README.md" ] || { echo "Ruleset introuvable : $src" >&2; exit 2; }
edition=$(grep -oE 'Édition courante : \*\*[0-9.]+\*\*' "$src/README.md" | grep -oE '[0-9.]+' | head -1)
[ -n "$edition" ] || { echo "Édition introuvable dans $src/README.md" >&2; exit 2; }
rm -rf docs/ruleset
mkdir -p docs/ruleset/20-regles-completes docs/ruleset/70-playtest
cp "$src"/20-regles-completes/*.md docs/ruleset/20-regles-completes/
cp "$src"/01-glossaire.md "$src"/CHARTE.md docs/ruleset/
cp "$src"/70-playtest/*.md docs/ruleset/70-playtest/
printf '%s\n' "$edition" > docs/ruleset/RULESET_EDITION
cat > docs/ruleset/README.md <<README
# Copie synchronisée du ruleset

> Copie en lecture seule des règles complètes, du glossaire, de la charte et du protocole de playtest, prise dans \`$src\` à l'édition **$edition** le $(date +%Y-%m-%d). Ne pas éditer ici : toute modification passe par le dossier du ruleset et l'agent \`ruleset-editor\`, puis \`tools/sync_ruleset.sh\`.

- \`RULESET_EDITION\` : édition épinglée, lue par le test de couverture.
- \`20-regles-completes/\` : chapitres 200 à 210, identifiants cités par le code (\`# 206.3.6\`) et les tests (\`test_206_3_6_...\`).
- \`01-glossaire.md\` : vocabulaire des identifiants anglais du code (Hero, Unit, Building, Spell, Gear restent tels quels).
- \`70-playtest/\` : protocole et decks de test, sources de \`data/cards/\` et du \`PlaytestRecorder\`.
README
echo "Ruleset synchronisé : édition $edition"
