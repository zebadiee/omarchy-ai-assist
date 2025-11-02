#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C.UTF-8 LANG=C.UTF-8

ROOT="${ROOT:-$PWD}"
LAB="${LAB:-$PWD/speccy-lab}"
MEM="$LAB/memory"; LOGS="$LAB/logs"
STATE="$MEM/state.json"

mkdir -p "$MEM" "$LOGS"
[ -s "$STATE" ] || bash speccy-kit/tools/ai-status.sh show >/dev/null

# Compute readiness by re-harvesting
bash speccy-kit/tools/ai-status.sh harvest >/dev/null

stage="$(jq -r '.stage' "$STATE")"
vp="$(jq -r '.metrics.validate_pass' "$STATE")"
dr="$(jq -r '.metrics.dry_runs' "$STATE")"
rf="$(jq -r '.metrics.reflections' "$STATE")"
pr="$(jq -r '.metrics.proposals' "$STATE")"
gd="$(jq -r '.metrics.consecutive_green_days' "$STATE")"
sv="$(jq -r '.metrics.safeops_violations' "$STATE")"

advisor_ready=$(( (dr>=3) && (rf>=3) && (pr>=3) && (vp>=2) && (sv<=0) ))
operator_ready=$(( (dr>=6) && (rf>=6) && (pr>=6) && (vp>=4) && (gd>=2) && (sv<=0) ))

target="${1:-auto}"
case "$target" in
  advisor|operator) ;; # explicit
  auto)
    if [ "$stage" = "observer" ] && [ $advisor_ready -eq 1 ]; then target="advisor"
    elif [ "$stage" = "advisor" ] && [ $operator_ready -eq 1 ]; then target="operator"
    else target=""; fi
    ;;
  *) echo "Usage: milestone.sh [advisor|operator|auto]"; exit 2;;
esac

if [ -z "$target" ]; then
  echo "[INFO] Not eligible for next promotion yet. Stage=$stage"; exit 0
fi

ts="$(date -Iseconds)"
tmp="$(mktemp)"

jq --arg from "$stage" --arg to "$target" --arg ts "$ts" '
  .completed += [{stage:$from, promoted_to:$to, ts:$ts}] |
  .stage = $to
' "$STATE" >"$tmp" && mv "$tmp" "$STATE"

echo "✅ Promoted: $stage → $target @ $ts"
bash speccy-kit/tools/ai-status.sh show >/dev/null