#!/usr/bin/env bash
# SessionStart : rappelle l'état du projet en quelques lignes, sans rien charger de plus.
cd "$(dirname "$0")/../.." || exit 0
echo "Ruleset épinglé : édition $(cat docs/ruleset/RULESET_EDITION 2>/dev/null || echo '?')"
grep -m1 '^\*\*État actuel' docs/roadmap.md 2>/dev/null
echo "Git : $(git branch --show-current 2>/dev/null) ; $(git status --short 2>/dev/null | wc -l | tr -d ' ') fichier(s) modifié(s)"
