#!/usr/bin/env bash
set -euo pipefail
BASE_URL="${LOCAL_BASE_URL:-http://localhost:11434/v1}"
MODEL="${LOCAL_MODEL:-llama3.1:8b}"
PROMPT="$(cat)"
curl -sS -X POST "$BASE_URL/chat/completions" \
  -H "content-type: application/json" \
  -d "$(jq -n --arg m "$MODEL" --arg p "$PROMPT" \
        '{model:$m, messages:[{role:"user", content:$p}], temperature:0.6, max_tokens:512}')" |
jq -r '.choices[0].message.content'
