#!/usr/bin/env python3
"""Analyse un .gd après Edit/Write ; n'exécute pas le jeu et ne modifie pas le script."""

import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

TIMEOUT_SECONDS = 30
DIAGNOSTIC = re.compile(r"(?:^|\n)\s*(?:SCRIPT ERROR|ERROR|WARNING|Parse Error):", re.I)


def fail(message):
    print("Vérification GDScript : " + message, file=sys.stderr)
    return 2


def godot_binary():
    configured = os.environ.get("GODOT_BIN")
    if configured:
        return configured
    for name in ("godot", "godot4"):
        binary = shutil.which(name)
        if binary:
            return binary
    mac_app = Path("/Applications/Godot.app/Contents/MacOS/Godot")
    if sys.platform == "darwin" and mac_app.is_file():
        return str(mac_app)
    raise ValueError("Godot introuvable ; définir GODOT_BIN vers Godot 4.7.2.")


def main():
    # Le script installé détermine sa racine, sans accepter une racine externe.
    root = Path(__file__).resolve().parents[2]
    hook_mode = len(sys.argv) == 1
    if hook_mode:
        try:
            event = json.load(sys.stdin)
        except (ValueError, OSError) as exc:
            return fail(f"entrée JSON invalide : {exc}")
        if not isinstance(event, dict):
            return fail("l'entrée doit être un objet JSON.")
        if event.get("hook_event_name") != "PostToolUse":
            return 0
        if event.get("tool_name") not in {"Edit", "Write", "MultiEdit"}:
            return 0
        tool_input = event.get("tool_input")
        if not isinstance(tool_input, dict):
            return fail("tool_input manquant ou invalide.")
        raw_path = tool_input.get("file_path")
        if not isinstance(raw_path, str) or not raw_path:
            return fail("file_path manquant ou invalide.")
        cwd = event.get("cwd", str(root))
        if not isinstance(cwd, str) or not Path(cwd).is_absolute():
            return fail("cwd doit être un chemin absolu.")
        base = Path(cwd)
    elif len(sys.argv) == 2:
        raw_path, base = sys.argv[1], Path.cwd()
    else:
        return fail("usage : python3 .claude/hooks/check_gdscript.py chemin.gd")

    if raw_path.startswith("res://"):
        path = root / raw_path[6:]
    else:
        path = Path(raw_path)
        if not path.is_absolute():
            path = base / path
    if path.suffix.lower() != ".gd":
        return 0 if hook_mode else fail("le fichier doit être un .gd.")
    path = path.resolve()
    try:
        relative = path.relative_to(root)
    except ValueError:
        return fail("fichier extérieur au projet ; analyse non exécutée.")
    if any(part in {"addons", ".godot", ".git"} for part in relative.parts):
        return 0 if hook_mode else fail("dossier tiers ou généré exclu.")
    if not path.is_file():
        return fail(f"fichier introuvable : {relative.as_posix()}")
    if not (root / "project.godot").is_file():
        return fail("project.godot introuvable à la racine.")

    try:
        binary = godot_binary()
        version = subprocess.run(
            [binary, "--version"], capture_output=True, text=True, timeout=5,
            errors="replace", check=False,
        )
        if version.returncode or not version.stdout.strip().startswith("4.7.2.stable."):
            return fail("Godot 4.7.2 stable requis ; version détectée : " + version.stdout.strip())
        # Isoler les logs évite les collisions entre éditions simultanées.
        with tempfile.TemporaryDirectory(prefix="tactical-gd-check-") as temp:
            result = subprocess.run(
                [binary, "--headless", "--path", str(root), "--check-only",
                 "--script", "res://" + relative.as_posix(),
                 "--log-file", str(Path(temp) / "godot.log")],
                capture_output=True, text=True, errors="replace",
                timeout=TIMEOUT_SECONDS, check=False,
            )
        output = result.stdout + "\n" + result.stderr
        if result.returncode or DIAGNOSTIC.search(output):
            return fail(f"échec pour {relative.as_posix()}\n{output[-16000:]}\n"
                        "Corriger les diagnostics avant de poursuivre ; l'édition reste appliquée.")
    except (OSError, ValueError, subprocess.TimeoutExpired) as exc:
        return fail(f"analyse impossible : {exc}")

    message = f"Analyse --check-only réussie : {relative.as_posix()}. Les warnings de typage se contrôlent par tools/check_typing.sh."
    if hook_mode:
        print(json.dumps({"hookSpecificOutput": {
            "hookEventName": "PostToolUse", "additionalContext": message,
        }}, ensure_ascii=False))
    else:
        print(message)
    return 0


if __name__ == "__main__":
    sys.exit(main())
