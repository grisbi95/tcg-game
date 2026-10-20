# Réglages Claude Code du projet

`settings.json` est partagé et versionné. `settings.local.json` et `CLAUDE.local.md` restent personnels et ignorés.

## MCP

Le serveur `godot-ai==4.3.0`, lancé par `uvx`, est inscrit dans Claude Code en scope local (`~/.claude.json`, propre à chaque machine) par le plugin `addons/godot_ai/` lui-même, à l'ouverture de l'éditeur ou par le bouton Configure de son dock (décision 0011). Rien n'est versionné : le plugin vide tout `.mcp.json` à la racine, ignoré par Git. Il ne répond que si l'éditeur Godot est ouvert sur le projet, et un seul projet à la fois (ports 8000 et 9500). Seul l'agent `ui-builder` en a les outils ; le désactiver dans les sessions de moteur, où il n'apporte que du contexte.

## Hooks

- **SessionStart** `hooks/session_start.sh` : édition courante du ruleset, « État actuel » de la roadmap, branche et nombre de fichiers modifiés. Trois lignes, rien d'autre.
- **PostToolUse** sur `Edit`, `Write`, `MultiEdit` : `hooks/post_edit_gdscript.sh` enchaîne `format_gdscript.py` (gdformat, ignoré si `.venv` absent) puis `check_gdscript.py` (`--headless --check-only`). Un diagnostic renvoie le code 2 : l'édition reste appliquée, Claude doit corriger ; un `.gd` hors du projet est ignoré par le hook (code 2 en ligne de commande). `--check-only` ne remonte pas tous les warnings de typage : vérifier aussi dans l'éditeur.
- Les éditions faites par terminal ou éditeur externe ne déclenchent pas le hook : lancer `bash .claude/hooks/check_changed_gdscript.sh` et `tools/lint.sh`.

## Permissions

Autorisés sans demande : `run_tests.sh`, `lint.sh`, `check_typing.sh`, le hook et ses tests, GdUnit4, gdlint et gdformat, Git en lecture plus `fetch` et `branch`, `gh pr` et `gh run` en lecture, le shell en lecture ; `rm -rf` et ses variantes refusés. Refusés aux outils d'édition : `addons/`, `.godot/`, `.venv/`, les `.uid` et `.import`. `docs/ruleset/` s'édite par l'agent `ruleset-editor` seulement (0014). Le chemin du binaire Godot est propre à chaque machine : il va dans `CLAUDE.local.md`.

## Vérifier les hooks

```bash
python3 -B -m unittest discover -s .claude/hooks -p 'test_*.py' -v
```
