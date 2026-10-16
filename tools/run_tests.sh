#!/usr/bin/env bash
# Lance les suites GdUnit4 en headless et n'affiche que les échecs et le résumé.
# Usage : tools/run_tests.sh [res://tests/test_suite.gd]   (défaut : res://tests)
# Code de sortie : 0 tout passe ; 100 au moins un échec ; autre : erreur d'exécution.
set -u
cd "$(dirname "$0")/.."
: "${GODOT_BIN:=/Applications/Godot.app/Contents/MacOS/Godot}"
target="${1:-res://tests}"
GODOT_BIN="$GODOT_BIN" bash addons/gdUnit4/runtest.sh --headless -a "$target" --ignoreHeadlessMode 2>&1 \
	| grep -E 'FAILED|ERROR|Overall Summary|Executed|Total' | grep -v 'remote port'
exit "${PIPESTATUS[0]}"
