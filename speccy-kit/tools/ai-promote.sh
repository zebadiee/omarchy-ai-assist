#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C.UTF-8 LANG=C.UTF-8

LAB="${LAB:-$PWD/speccy-lab}"
MEM="$LAB/memory"
STATE="$MEM/state.json"
mkdir -p "$MEM"

# seed if missing
[ -s "$STATE" ] || cat >"$STATE" <<'JSON'
{
  "stage": "observer",
  "metrics": {
    "validate_pass": 0,
    "consecutive_green_days": 0,
    "dry_runs": 0,
    "reflections": 0,
    "proposals": 0,
    "safeops_violations": 0
  },
  "completed": []
}
JSON

ts() { date -Iseconds; }

jq_get(){ jq -r "$1" "$STATE"; }

stage=$(jq_get '.stage')
vp=$(jq_get '.metrics.validate_pass')
dr=$(jq_get '.metrics.dry_runs')
rf=$(jq_get '.metrics.reflections')
pr=$(jq_get '.metrics.proposals')
gd=$(jq_get '.metrics.consecutive_green_days')
sv=$(jq_get '.metrics.safeops_violations')

promote_from="$stage"
promote_to=""

case "$stage" in
  observer)
    if [ "$sv" -le 0 ] && [ "$vp" -ge 2 ] && [ "$dr" -ge 3 ] && [ "$rf" -ge 3 ] && [ "$pr" -ge 3 ]; then
      promote_to="advisor"
    fi
    ;;
  advisor)
    if [ "$sv" -le 0 ] && [ "$vp" -ge 4 ] && [ "$dr" -ge 6 ] && [ "$rf" -ge 6 ] && [ "$pr" -ge 6 ] && [ "$gd" -ge 2 ]; then
      promote_to="operator"
    fi
    ;;
  operator)
    # Define your next gate here (e.g., autonomous)
    if [ "$sv" -le 0 ] && [ "$vp" -ge 8 ] && [ "$dr" -ge 10 ] && [ "$rf" -ge 10 ] && [ "$pr" -ge 10 ] && [ "$gd" -ge 4 ]; then
      promote_to="autonomous"
    fi
    ;;
  autonomous)
    echo "[INFO] Already at highest stage: autonomous"
    exit 0
    ;;
esac

if [ -z "$promote_to" ]; then
  echo "[INFO] Not ready for promotion from '$stage'."
  echo "       Need more: dry_runs/reflections/proposals/greens or validate_pass; and zero violations."
  exit 0
fi

tmp="$(mktemp)"
jq --arg from "$promote_from" \
   --arg to "$promote_to" \
   --arg ts "$(ts)" '
  .stage = $to |
  .completed += [ { "stage": $from, "promoted_to": $to, "ts": $ts } ]
' "$STATE" >"$tmp" && mv "$tmp" "$STATE"

echo "[SUCCESS] Promoted: $promote_from -> $promote_to @ $(ts)"
