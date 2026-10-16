#!/usr/bin/env bash
# PostToolUse sur Edit/Write : reformate (gdformat) puis analyse (--check-only), dans cet ordre.
# L'événement JSON reçu sur stdin est transmis aux deux scripts.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
input="$(cat)"
printf '%s' "$input" | python3 "$here/format_gdscript.py" || exit 2
printf '%s' "$input" | python3 "$here/check_gdscript.py"
