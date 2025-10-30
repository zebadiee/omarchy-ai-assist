#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
HS="${ROOT}/HANDSHAKE.md"

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing: $1" >&2; exit 1; }; }
need jq; need curl

# Use yq if available, otherwise use simple fallback
if command -v yq >/dev/null 2>&1; then
    YQ_CMD="yq"
else
    YQ_SCRIPT="$(dirname "$0")/simple_yq"
    if [[ -f "$YQ_SCRIPT" ]]; then
        YQ_CMD="$YQ_SCRIPT"
    else
        echo "Missing: yq and fallback script" >&2
        exit 1
    fi
fi

AGENT="${1:-}"; shift || true
TEXT="${*:-}"
[ -n "$AGENT" ] && [ -n "$TEXT" ] || { echo "usage: handshake_chat.sh <#pln|#imp|#knw|#mem> \"message\""; exit 1; }

tier_default() { echo "x0"; }

TIER="${TIER:-x0}"
CTRL="$($YQ_CMD '.entrypoint.control' "$HS")"
CONSTRAINTS="$($YQ_CMD '.entrypoint.constraints' "$HS")"

# Map subagent names to paths
case "${AGENT#\#}" in
    "pln") SUBAGENT_PATH="$($YQ_CMD '.entrypoint.subagents.pln' "$HS")" ;;
    "imp") SUBAGENT_PATH="$($YQ_CMD '.entrypoint.subagents.imp' "$HS")" ;;
    "knw") SUBAGENT_PATH="$($YQ_CMD '.entrypoint.subagents.knw' "$HS")" ;;
    "mem") SUBAGENT_PATH="$($YQ_CMD '.entrypoint.subagents.mem' "$HS")" ;;
    *) echo "Unknown subagent: $AGENT" >&2; exit 1 ;;
esac

[ -f "$ROOT/$CTRL" ] || { echo "Missing $CTRL"; exit 1; }
[ -f "$ROOT/$CONSTRAINTS" ] || { echo "Missing $CONSTRAINTS"; exit 1; }
[ -f "$ROOT/$SUBAGENT_PATH" ] || { echo "Missing $SUBAGENT_PATH"; exit 1; }

PROMPT="$(cat "$ROOT/$CONSTRAINTS")"\n\n---\n\n'"$(cat "$ROOT/$SUBAGENT_PATH")"\n\n---\n\n'"USER:\n$TEXT\n"

# provider order from handshake
case "$TIER" in
    "x1") PROVIDERS=("openai" "anthropic" "gemini" "lmstudio" "ollama") ;;
    "x0") PROVIDERS=("lmstudio" "ollama" "openai" "gemini" "anthropic") ;;
    "free") PROVIDERS=("ollama" "lmstudio" "gemini" "anthropic" "openai") ;;
    *) PROVIDERS=("ollama" "lmstudio" "openai") ;;
esac

# try providers in order: lmstudio/ollama/openai/gemini/anthropic
for P in "${PROVIDERS[@]}"; do
  case "$P" in
    lmstudio)
      base="${LMSTUDIO_BASE_URL:-http://127.0.0.1:1234/v1}"
      key="${LMSTUDIO_API_KEY:-lm-studio}"
      model="$($YQ_CMD ".routing.models.lmstudio.\"$TIER\"" "$HS" 2>/dev/null || echo default)"
      jq -n --arg m "$model" --arg t "$PROMPT" \
        '{model:$m, messages:[{role:"user",content:$t}]}' \
      | curl -fsS "$base/chat/completions" -H "authorization: Bearer '"$key"'" -H "content-type: application/json" -d @- \
      | jq -r '.choices[0].message.content' && exit 0 || true
      ;;
    ollama)
      host="${OLLAMA_HOST:-http://127.0.0.1:11434}"
      model="$($YQ_CMD ".routing.models.ollama.\"$TIER\"" "$HS" 2>/dev/null || echo "mistral:latest")"
      jq -n --arg m "$model" --arg t "$PROMPT" \
        '{model:$m, prompt:$t, stream:false}' \
      | curl -fsS "$host/api/generate" -H "content-type: application/json" -d @- \
      | jq -r '.response' && exit 0 || true
      ;;
    openai)
      [ -n "${OPENAI_API_KEY:-}" ] || continue
      model="$($YQ_CMD ".routing.models.openai.\"$TIER\"" "$HS" 2>/dev/null || echo "gpt-4o-mini")"
      jq -n --arg m "$model" --arg t "$PROMPT" \
        '{model:$m, messages:[{role:"user",content:$t}]}' \
      | curl -fsS https://api.openai.com/v1/chat/completions \
        -H "authorization: Bearer $OPENAI_API_KEY" -H "content-type: application/json" -d @- \
      | jq -r '.choices[0].message.content' && exit 0 || true
      ;;
    gemini)
      [ -n "${GEMINI_API_KEY:-}" ] || continue
      model="$($YQ_CMD ".routing.models.gemini.\"$TIER\"" "$HS" 2>/dev/null || echo "gemini-1.5-flash")"
      jq -n --arg t "$PROMPT" '{contents:[{role:"user",parts:[{text:$t}]}]}' \
      | curl -fsS "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$GEMINI_API_KEY" \
        -H "content-type: application/json" -d @- \
      | jq -r '.candidates[0].content.parts[0].text' && exit 0 || true
      ;;
    anthropic)
      [ -n "${ANTHROPIC_API_KEY:-}" ] || continue
      model="$($YQ_CMD ".routing.models.anthropic.\"$TIER\"" "$HS" 2>/dev/null || echo "claude-3-haiku")"
      jq -n --arg m "$model" --arg t "$PROMPT" \
        '{model:$m,max_tokens:4096,messages:[{role:"user",content:$t}]}' \
      | curl -fsS https://api.anthropic.com/v1/messages \
        -H "x-api-key: $ANTHROPIC_API_KEY" -H "anthropic-version: 2023-06-01" \
        -H "content-type: application/json" -d @- \
      | jq -r '.content[0].text' && exit 0 || true
      ;;
  esac
done

echo "[handshake] no provider responded for tier=$TIER" >&2
exit 2