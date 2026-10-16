#!/usr/bin/env bash
# Contrôle du typage : analyse Godot --check-only de chaque .gd du projet, les warnings de
# typage (untyped_declaration, unsafe_*) traités comme des erreurs par un override.cfg
# temporaire ; project.godot n'est pas modifié. À lancer après un import du projet.
# Usage : tools/check_typing.sh   Code de sortie : 0 aucun problème ; 1 au moins un ; 2 refus.
set -u
cd "$(dirname "$0")/.."
: "${GODOT_BIN:=/Applications/Godot.app/Contents/MacOS/Godot}"
if [ -e override.cfg ]; then
	echo "override.cfg existe déjà : contrôle annulé pour ne pas l'écraser."
	exit 2
fi
trap 'rm -f override.cfg' EXIT
cat > override.cfg <<'CFG'
[debug]

gdscript/warnings/untyped_declaration=2
gdscript/warnings/unsafe_property_access=2
gdscript/warnings/unsafe_method_access=2
gdscript/warnings/unsafe_cast=2
gdscript/warnings/unsafe_call_argument=2
CFG
files=$(find rules ai app ui tests -name '*.gd' 2>/dev/null | sort)
count=$(echo "$files" | grep -c .)
# Une erreur d'un script chargé par d'autres remonte plusieurs fois : on garde chaque couple
# (message, emplacement) une seule fois.
report=$(for file in $files; do
	"$GODOT_BIN" --headless --path . --check-only --script "res://$file" 2>&1 \
		| grep -A1 'SCRIPT ERROR' | grep -v '^--$' | paste - -
done | sort -u)
if [ -z "$report" ]; then
	echo "Typage : aucun problème sur $count fichiers."
	exit 0
fi
echo "$report" | sed -E 's/[[:space:]]+at: GDScript::reload \((.*)\)$/\n    \1/'
echo "Typage : $(echo "$report" | grep -c .) problème(s) sur $count fichiers."
exit 1
