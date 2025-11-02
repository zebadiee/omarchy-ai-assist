#!/usr/bin/env bash
# Export env vars used by Token Steward from the vault into current shell.
set -euo pipefail
export OPENROUTER_KEYS="$(bin/token-vault get OPENROUTER_KEYS || true)"
export GEMINI_KEYS="$(bin/token-vault get GEMINI_KEYS || true)"
export ANTHROPIC_KEYS="$(bin/token-vault get ANTHROPIC_KEYS || true)"
export OPENAI_KEYS="$(bin/token-vault get OPENAI_KEYS || true)"
echo "Loaded keys into environment (empty if not present)."