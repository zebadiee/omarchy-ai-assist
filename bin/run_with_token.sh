#!/usr/bin/env bash
set -euo pipefail

PROVIDER="${1:?provider required}"
CLI_BIN="${2:?cli binary required}"
shift 2

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# --- 0) Local provider shortcut (no keys) --------------------
if [ "$PROVIDER" = "local" ]; then
  # Ensure local wrapper exists
  [ -x "$SCRIPT_DIR/local_ai.sh" ] || { echo "missing $SCRIPT_DIR/local_ai.sh"; exit 2; }
  exec "$SCRIPT_DIR/local_ai.sh" session
fi

# --- 1) Select key from Token Steward (optional: skip if no pool) ---
KEY=""
if [ -x "$SCRIPT_DIR/../tokens/select_key.py" ]; then
  # ask steward to pick a key for this provider (prints just the key)
  KEY="$(python3 "$SCRIPT_DIR/../tokens/select_key.py" "$PROVIDER" 2>/dev/null || true)"
fi

# --- 2) Map to provider-specific env var ----------------------
case "$PROVIDER" in
  openrouter) [ -n "${KEY:-}" ] && export OPENROUTER_API_KEY="$KEY" ;;
  anthropic)  [ -n "${KEY:-}" ] && export ANTHROPIC_API_KEY="$KEY" ;;
  openai)     [ -n "${KEY:-}" ] && export OPENAI_API_KEY="$KEY" ;;
  gemini)     [ -n "${KEY:-}" ] && export GEMINI_API_KEY="$KEY" ;;
esac

# --- 3) Execute underlying CLI -------------------------------
if [ "$CLI_BIN" = "goose" ]; then
  exec goose session
elif [ "$CLI_BIN" = "gemini" ]; then
  exec gemini chat
elif [ "$CLI_BIN" = "anthropic" ]; then
  exec anthropic messages create
elif [ "$CLI_BIN" = "openai" ]; then
  exec openai chat.completions.create
else
  # custom wrapper path
  exec "$CLI_BIN" "$@"
fi
