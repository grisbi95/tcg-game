#!/usr/bin/env bash
# Installe gdlint et gdformat (gdtoolkit 4) dans un venv local au projet, hors Git.
set -eu
cd "$(dirname "$0")/.."
[ -d .venv ] || python3 -m venv .venv
.venv/bin/pip install -q "gdtoolkit==4.*"
.venv/bin/gdlint --version
.venv/bin/gdformat --version
