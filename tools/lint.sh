#!/usr/bin/env bash
# gdformat --check puis gdlint sur les .gd du projet, hors addons et dossiers générés.
# Usage : tools/lint.sh [--fix]   (--fix : reformate au lieu de vérifier)
set -u
cd "$(dirname "$0")/.."
files=$(find rules ai app ui tests -name '*.gd' 2>/dev/null)
[ -z "$files" ] && { echo "Aucun .gd à vérifier."; exit 0; }
status=0
if [ "${1:-}" = "--fix" ]; then
	.venv/bin/gdformat $files || status=2
else
	.venv/bin/gdformat --check $files || status=2
fi
.venv/bin/gdlint $files || status=2
exit $status
