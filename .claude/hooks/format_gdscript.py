#!/usr/bin/env python3
"""Reformate avec gdformat le .gd que Claude vient d'éditer. Silencieux si gdformat est absent."""

import json
from pathlib import Path
import subprocess
import sys

EXCLUDED = {"addons", ".godot", ".venv", ".git"}


def main():
    root = Path(__file__).resolve().parents[2]
    try:
        event = json.load(sys.stdin)
    except (ValueError, OSError):
        return 0
    if not isinstance(event, dict) or event.get("hook_event_name") != "PostToolUse":
        return 0
    if event.get("tool_name") not in {"Edit", "Write", "MultiEdit"}:
        return 0
    tool_input = event.get("tool_input")
    raw = tool_input.get("file_path") if isinstance(tool_input, dict) else None
    if not isinstance(raw, str) or not raw:
        return 0
    path = root / raw[6:] if raw.startswith("res://") else Path(raw)
    if not path.is_absolute():
        path = Path(event.get("cwd", str(root))) / path
    path = path.resolve()
    if path.suffix.lower() != ".gd" or not path.is_file():
        return 0
    try:
        relative = path.relative_to(root)
    except ValueError:
        return 0
    if any(part in EXCLUDED for part in relative.parts):
        return 0
    gdformat = root / ".venv" / "bin" / "gdformat"
    if not gdformat.is_file():
        return 0
    try:
        result = subprocess.run([str(gdformat), str(path)], capture_output=True, text=True,
                                errors="replace", timeout=30, check=False)
    except (OSError, subprocess.TimeoutExpired) as exc:
        print(f"gdformat : impossible ({exc})", file=sys.stderr)
        return 2
    if result.returncode:
        print("gdformat : échec pour %s\n%s" % (relative.as_posix(),
              (result.stderr + result.stdout)[-2000:]), file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
