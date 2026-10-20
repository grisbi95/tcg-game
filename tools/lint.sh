#!/usr/bin/env bash
# gdformat --check puis gdlint sur les .gd du projet, tools/ compris, hors addons et .godot.
# Usage : tools/lint.sh [--fix]   (--fix : reformate au lieu de vérifier)
# Code de sortie : 0 propre ; 2 écart de format ou de lint, ou gdtoolkit absent.
set -u
cd "$(dirname "$0")/.."
files=$(find rules ai app ui tests tools -name '*.gd' 2>/dev/null)
[ -z "$files" ] && { echo "Aucun .gd à vérifier."; exit 0; }
if [ ! -x .venv/bin/gdformat ] || [ ! -x .venv/bin/gdlint ]; then
	echo "gdtoolkit absent : lancer tools/setup_gdtoolkit.sh." >&2
	exit 2
fi
status=0
if [ "${1:-}" = "--fix" ]; then
	.venv/bin/gdformat $files || status=2
else
	.venv/bin/gdformat --check $files || status=2
fi
.venv/bin/gdlint $files || status=2
exit $status
