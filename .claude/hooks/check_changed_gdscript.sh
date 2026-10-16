#!/usr/bin/env bash
# Vérifie avec check_gdscript.py chaque .gd modifié, ajouté ou non suivi selon Git.
# Usage : bash .claude/hooks/check_changed_gdscript.sh [--staged]
# Complète le hook PostToolUse, qui ne voit pas les éditions par terminal, MCP ou éditeur externe.
set -u
cd "$(git rev-parse --show-toplevel)" || exit 2
if [ "${1:-}" = "--staged" ]; then
	files=$(git diff --cached --name-only --diff-filter=ACMR -- '*.gd')
else
	files=$( { git diff HEAD --name-only --diff-filter=ACMR -- '*.gd'
	           git ls-files --others --exclude-standard -- '*.gd'; } | sort -u)
fi
files=$(printf '%s\n' "$files" | grep -vE '^(addons|\.godot)/' | grep -v '^$' || true)
if [ -z "$files" ]; then
	echo "Aucun .gd modifié."
	exit 0
fi
status=0
while IFS= read -r file; do
	[ -f "$file" ] || continue
	python3 .claude/hooks/check_gdscript.py "$file" || status=2
done <<< "$files"
exit $status
