#!/usr/bin/env bash
# Wrapper for prompt_annealer.py with convenient defaults.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PY="$SCRIPT_DIR/prompt_annealer.py"

if [[ ! -f "$PY" ]]; then
  echo "[prompt-annealer] python script missing at $PY" >&2
  exit 2
fi

python3 "$PY" "$@"
