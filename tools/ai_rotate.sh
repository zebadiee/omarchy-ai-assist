#!/usr/bin/env bash
set -euo pipefail

# Rotation policy per tier: ordered preference (edit as you like)
# Providers must exist in tools/ai_providers.yml
declare -A ORDER=(
  [x1]="openai anthropic gemini lmstudio ollama"
  [x0]="lmstudio ollama openai gemini anthropic"
  [free]="ollama lmstudio gemini anthropic openai"
)

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ai-rotate"
mkdir -p "$STATE_DIR"

tier="${1:-x0}"; shift || true
agent="${1:-}"; shift || true
msg="${*:-}"

[ -n "$agent" ] || { echo "Usage: $0 <x1|x0|free> <agent> \"message...\""; exit 1; }
[ -n "$msg" ] || { echo "Provide a message."; exit 1; }

state_file="$STATE_DIR/${agent}_${tier}.json"
touch "$state_file"

# cooldowns (seconds)
FAIL_COOLDOWN=120
HEALTH_TIMEOUT=3

# provider-specific health probes (adjust as needed)
health_check() {
  local provider="$1"
  case "$provider" in
    openai)
      [ -n "${OPENAI_API_KEY:-}" ] || return 1
      timeout $HEALTH_TIMEOUT bash -lc 'printf " " | openai api chat.completions.create -m gpt-4o -g user:- --input-file - >/dev/null 2>&1' || return 1
      ;;
    anthropic)
      [ -n "${ANTHROPIC_API_KEY:-}" ] || return 1
      timeout $HEALTH_TIMEOUT bash -lc 'curl -fsS https://api.anthropic.com/v1/models -H "x-api-key: $ANTHROPIC_API_KEY" -H "anthropic-version: 2023-06-01" >/dev/null' || return 1
      ;;
    gemini)
      [ -n "${GEMINI_API_KEY:-}" ] || return 1
      timeout $HEALTH_TIMEOUT bash -lc 'curl -fsS "https://generativelanguage.googleapis.com/v1beta/models?key=$GEMINI_API_KEY" >/dev/null' || return 1
      ;;
    lmstudio)
      local base="${LMSTUDIO_BASE_URL:-http://127.0.0.1:1234/v1}"
      timeout $HEALTH_TIMEOUT bash -lc "curl -fsS \"$base/models\" >/dev/null" || return 1
      ;;
    ollama)
      timeout $HEALTH_TIMEOUT bash -lc 'curl -fsS http://127.0.0.1:11434/api/tags >/dev/null' || return 1
      ;;
    *)
      return 1;;
  esac
}

now() { date +%s; }

can_use() {
  local provider="$1"
  local last_fail ts
  last_fail=$(jq -r --arg p "$provider" '.failures[$p] // 0' "$state_file" 2>/dev/null || echo 0)
  ts=$(now)
  (( ts - last_fail >= FAIL_COOLDOWN )) || return 1
  health_check "$provider"
}

mark_failure() {
  local provider="$1"
  local ts=$(now)
  tmp=$(mktemp)
  jq --arg p "$provider" --argjson ts "$ts" \
     '.failures[$p]=$ts' "$state_file" 2>/dev/null >"$tmp" || echo "{\"failures\":{}}" >"$tmp"
  mv "$tmp" "$state_file"
}

# Try providers in order for the tier
for prov in ${ORDER[$tier]}; do
  if can_use "$prov"; then
    echo "[ai-rotate] Using provider=$prov tier=$tier agent=$agent"
    AI_PROVIDER="$prov" tools/ai_subagent.sh "$agent" "$tier" "$msg" && exit 0 || {
      echo "[ai-rotate] provider=$prov failed; marking cooldown"
      mark_failure "$prov"
      continue
    }
  else
    echo "[ai-rotate] Skipping provider=$prov (health/cooldown)"
  fi
done

echo "[ai-rotate] All providers unavailable for tier=$tier" >&2
exit 2
