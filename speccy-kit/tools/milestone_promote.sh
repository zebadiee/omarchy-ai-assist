#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C.UTF-8 LANG=C.UTF-8

LAB="${LAB:-$PWD/speccy-lab}"
MEM="$LAB/memory"
LOGS="$LAB/logs"
STATE="$MEM/state.json"
CHANGELOG="$LAB/CHANGELOG.md"

mkdir -p "$MEM" "$LOGS"

# Seed minimal state if missing/empty
if [ ! -s "$STATE" ]; then
  cat >"$STATE" <<'JSON'
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
fi

# Read metrics
stage="$(jq -r '.stage' "$STATE")"
vp="$(jq -r '.metrics.validate_pass' "$STATE")"
dr="$(jq -r '.metrics.dry_runs' "$STATE")"
rf="$(jq -r '.metrics.reflections' "$STATE")"
pr="$(jq -r '.metrics.proposals' "$STATE")"
gd="$(jq -r '.metrics.consecutive_green_days' "$STATE")"
sv="$(jq -r '.metrics.safeops_violations' "$STATE")"

# Readiness (same as ai-status.sh)
advisor_ready=$(( (dr>=3) && (rf>=3) && (pr>=3) && (vp>=2) && (sv<=0) ))
operator_ready=$(( (dr>=6) && (rf>=6) && (pr>=6) && (vp>=4) && (gd>=2) && (sv<=0) ))

# Target stage:
#  - If user passes an explicit target (advisor/operator), try that (and check readiness)
#  - Else auto: prefer operator if ready, else advisor if ready, else fail
target="${1:-auto}"
if [ "$target" = "auto" ]; then
  if [ $operator_ready -eq 1 ] && [ "$stage" != "operator" ]; then
    target="operator"
  elif [ $advisor_ready -eq 1 ] && [ "$stage" = "observer" ]; then
    target="advisor"
  else
    echo "[promote] Not ready yet."
    echo "  stage=$stage vp=$vp dr=$dr rf=$rf pr=$pr gd=$gd sv=$sv"
    echo "  needs: advisor( dr>=3, rf>=3, pr>=3, vp>=2, sv==0 )"
    echo "         operator( dr>=6, rf>=6, pr>=6, vp>=4, gd>=2, sv==0 )"
    exit 1
  fi
fi

# Validate requested target against readiness
case "$target" in
  advisor)
    if [ $advisor_ready -ne 1 ]; then
      echo "[promote] Advisor gate not met. Aborting."
      exit 2
    fi
    if [ "$stage" = "advisor" ] || [ "$stage" = "operator" ]; then
      echo "[promote] Already at $stage (>= advisor). No change."
      exit 0
    fi
    ;;
  operator)
    if [ $operator_ready -ne 1 ]; then
      echo "[promote] Operator gate not met. Aborting."
      exit 2
    fi
    if [ "$stage" = "operator" ]; then
      echo "[promote] Already operator. No change."
      exit 0
    fi
    ;;
  *)
    echo "Usage: milestone_promote.sh [advisor|operator|auto]"
    exit 2
    ;;
esac

ts="$(date -Iseconds)"
reason="${2:-"readiness gates satisfied"}"

# Append completed[] entry and update stage atomically
tmp="$(mktemp)"
jq --arg from "$stage" \
   --arg to "$target" \
   --arg ts "$ts" \
   --arg reason "$reason" '
  .completed += [{
    stage: $from,
    promoted_to: $to,
    ts: $ts,
    reason: $reason
  }] | .stage = $to
' "$STATE" > "$tmp" && mv "$tmp" "$STATE"

# Changelog & training signal
{
  echo "## $ts — Promotion"
  echo "- From: $stage → To: $target"
  echo "- Reason: $reason"
  echo "- Metrics: vp=$vp dr=$dr rf=$rf pr=$pr gd=$gd sv=$sv"
  echo
} >> "$CHANGELOG"

echo "REFLECT: promoted $stage -> $target @ $ts (reason: $reason)" >> "$MEM/training.log"

# Console frame
printf "\n"
echo "[PROMOTE] SUCCESS"
echo "  $stage  ->  $target @ $ts"
echo "  vp=$vp dr=$dr rf=$rf pr=$pr gd=$gd sv=$sv"