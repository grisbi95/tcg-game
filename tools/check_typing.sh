#!/usr/bin/env bash
# Contrôle du typage : analyse Godot --check-only de chaque .gd du projet, les warnings de
# typage (untyped_declaration, unsafe_*) traités comme des erreurs par un override.cfg
# temporaire ; project.godot n'est pas modifié. À lancer après un import du projet.
# Usage : tools/check_typing.sh   (GODOT_BIN : binaire Godot, sinon `godot` du PATH, sinon
# l'application macOS)
# Code de sortie : 0 aucun problème ; 1 au moins un problème ; 2 contrôle impossible.
set -u
cd "$(dirname "$0")/.."
macos_godot=/Applications/Godot.app/Contents/MacOS/Godot
: "${GODOT_BIN:=$(command -v godot || echo "$macos_godot")}"
if ! "$GODOT_BIN" --headless --version >/dev/null 2>&1; then
	echo "Godot introuvable ou inutilisable : « $GODOT_BIN ». Contrôle impossible."
	exit 2
fi
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
count=0
problems=""
while IFS= read -r file; do
	count=$((count + 1))
	output=$("$GODOT_BIN" --headless --path . --check-only --script "res://$file" 2>&1)
	status=$?
	# Chaque « SCRIPT ERROR » est suivi de sa ligne « at: » : on les joint en une ligne.
	errors=$(echo "$output" | grep -A1 'SCRIPT ERROR' | grep -v '^--$' | paste - -)
	if [ -n "$errors" ]; then
		problems+="$errors"$'\n'
	elif [ "$status" -ne 0 ]; then
		problems+="Godot s'est arrêté avec le code $status sur $file"$'\n'
	fi
done < <(find rules ai app ui tests tools -name '*.gd' 2>/dev/null | sort)
if [ "$count" -eq 0 ]; then
	echo "Aucun .gd trouvé : contrôle impossible."
	exit 2
fi
# Une erreur d'un script chargé par d'autres remonte plusieurs fois : une seule fois suffit.
report=$(printf '%s' "$problems" | sort -u | grep .)
if [ -z "$report" ]; then
	echo "Typage : aucun problème sur $count fichiers."
	exit 0
fi
echo "$report" | sed -E 's/[[:space:]]+at: GDScript::reload \((.*)\)$/\n    \1/'
echo "Typage : $(echo "$report" | grep -c .) problème(s) sur $count fichiers."
exit 1
