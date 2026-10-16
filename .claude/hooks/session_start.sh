#!/usr/bin/env bash
# SessionStart : rappelle l'état du projet en quelques lignes, sans rien charger de plus.
# Avertit aussi si iCloud peut retirer des fichiers du disque (incident du 16 octobre 2026).
# Aucun avertissement ne bloque la session.

# Affiche un avertissement si le chemin donné est synchronisé par iCloud Drive.
warn_if_icloud_path() {
	case "$1/" in
	"$HOME/Documents/"* | "$HOME/Desktop/"* | "$HOME/Library/Mobile Documents/"*)
		echo "ATTENTION : le projet est sous un dossier synchronisé par iCloud ($1)." \
			"Le déplacer hors de ~/Documents, ~/Desktop et iCloud Drive (voir ~/Developer)."
		;;
	esac
}

# Affiche le nombre de fichiers du dossier courant retirés du disque par iCloud, et un exemple.
warn_if_dataless_files() {
	[ "$(uname)" = Darwin ] || return 0
	local dataless_paths
	dataless_paths="$(find . -flags +dataless 2>/dev/null)"
	[ -n "$dataless_paths" ] || return 0
	echo "ATTENTION : $(printf '%s\n' "$dataless_paths" | wc -l | tr -d ' ') fichier(s) du projet" \
		"retiré(s) du disque par iCloud, par exemple ${dataless_paths%%$'\n'*}." \
		"Git, Godot et les tests peuvent échouer."
}

main() {
	cd "$(dirname "$0")/../.." || exit 0
	warn_if_icloud_path "$(pwd -P)"
	warn_if_dataless_files
	echo "Ruleset épinglé : édition $(cat docs/ruleset/RULESET_EDITION 2>/dev/null || echo '?')"
	grep -m1 '^\*\*État actuel' docs/roadmap.md 2>/dev/null
	echo "Git : $(git branch --show-current 2>/dev/null) ;" \
		"$(git status --short 2>/dev/null | wc -l | tr -d ' ') fichier(s) modifié(s)"
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
	main
fi
