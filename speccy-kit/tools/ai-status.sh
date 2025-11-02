#!/usr/bin/env bash
set -euo pipefail

# Locale safety
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

LAB="${LAB:-$PWD/speccy-lab}"
MEM_DIR="$LAB/memory"
LOG_DIR="$LAB/logs"
STATE_JSON="$MEM_DIR/state.json"
STATUS_MD="$LAB/STATUS.md"

mkdir -p "$MEM_DIR" "$LOG_DIR"

# Seed minimal state if empty
if [ ! -s "$STATE_JSON" ]; then
  cat >"$STATE_JSON" <<'JSON'
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

# Harvest (non-destructive): pull counts from logs/memory if available
harvest() {
  local m="$STATE_JSON"
  # Count simple signals if the files exist; tolerate absence
  local vpasses=$(grep -hFc "[SUCCESS] Validation OK" "$LOG_DIR"/validation-history.log 2>/dev/null || true)
  local reflections=$(grep -hEc '^REFLECT:' "$MEM_DIR"/training.log 2>/dev/null || true)
  local proposals=$(grep -hEc '^PROPOSAL:' "$MEM_DIR"/training.log 2>/dev/null || true)
  local dry=$(grep -hEc 'DRY-RUN:OK' "$LOG_DIR"/*.log 2>/dev/null || true)
  local greens=$(grep -hEc '^GREEN_DAY$' "$MEM_DIR"/training.log 2>/dev/null || true)
  local viols=$(grep -hEc '^SAFEOPS:VIOLATION' "$LOG_DIR"/*.log 2>/dev/null || true)

  # Merge into metrics (max with current to avoid regress)
  tmp="$(mktemp)"
  jq --argjson v "${vpasses:-0}" \
     --argjson r "${reflections:-0}" \
     --argjson p "${proposals:-0}" \
     --argjson d "${dry:-0}" \
     --argjson g "${greens:-0}" \
     --argjson sv "${viols:-0}" '
    .metrics.validate_pass = ([$v, .metrics.validate_pass] | max) |
    .metrics.reflections = ([$r, .metrics.reflections] | max) |
    .metrics.proposals = ([$p, .metrics.proposals] | max) |
    .metrics.dry_runs = ([$d, .metrics.dry_runs] | max) |
    .metrics.consecutive_green_days = ([$g, .metrics.consecutive_green_days] | max) |
    .metrics.safeops_violations = ([$sv, .metrics.safeops_violations] | max)
  ' "$m" >"$tmp" && mv "$tmp" "$m"

  # Update stage from state.json
  stage=$(jq -r '.stage' "$m")

  # Update stage from state.json
  stage=$(jq -r '.stage' "$m")
}

render() {
  local s="$STATE_JSON"
  local stage=$(jq -r '.stage' "$s")
  local m=$(jq -r '.metrics' "$s")

  # Build checklist safely (no inner escaped quotes)
  mapfile -t completed < <(jq -r ' \
    .completed[]? | "- " + .stage + (if has("promoted_to") then " -> " + .promoted_to else "" end) + " @ " + .ts \
  ' "$s" 2>/dev/null || true)

  # Extract metrics
  vp=$(jq -r '.metrics.validate_pass' "$s")
  dr=$(jq -r '.metrics.dry_runs' "$s")
  rf=$(jq -r '.metrics.reflections' "$s")
  pr=$(jq -r '.metrics.proposals' "$s")
  gd=$(jq -r '.metrics.consecutive_green_days' "$s")
  sv=$(jq -r '.metrics.safeops_violations' "$s")

  # Simple readiness gates (adjust as desired)
  need_advisor=$(( (dr>=3) && (rf>=3) && (pr>=3) && (vp>=2) && (sv<=0) ))
  need_operator=$(( (dr>=6) && (rf>=6) && (pr>=6) && (vp>=4) && (gd>=2) && (sv<=0) ))

  {
    echo "# AI Milestone Status"
    echo
    echo "**Stage:** \`$stage\`"
    echo
    echo "## Progress"
    printf "| Metric | Value |\n|---|---:|"
    printf "| validate_pass | %s |\n" "$vp"
    printf "| dry_runs | %s |\n" "$dr"
    printf "| reflections | %s |\n" "$rf"
    printf "| proposals | %s |\n" "$pr"
    printf "| consecutive_green_days | %s |\n" "$gd"
    printf "| safeops_violations | %s |\n" "$sv"
    echo
    echo "## Completed Promotions"
    if [ "${#completed[@]}" -eq 0 ]; then
      echo "_(none yet)_"
    else
      printf "%s\n" "${completed[@]}"
    fi
    echo
    echo "## Readiness Signals"
    echo "- Advisor ready: $([ $need_advisor -eq 1 ] && echo '✅' || echo '❌')"
    echo "- Operator ready: $([ $need_operator -eq 1 ] && echo '✅' || echo '❌')"
    echo
    echo "_Updated: $(date -Iseconds)_"
  } > "$STATUS_MD"

  # Pretty console frame
  echo "[SUCCESS] Metrics harvested successfully"
  awk 'BEGIN{print "╔"gensub(/./,"═","g",sprintf("%"60"s",""))"╗"}
       {printf "║ %-58s ║\n", $0}
       END{print "╚"gensub(/./,"═","g",sprintf("%"60"s",""))"╝"}' \
       < <(printf "AI MILESTONE STATUS\nStage: %s\nvalidate_pass:%s dry_runs:%s reflections:%s proposals:%s green_days:%s violations:%s\n" \
               "$stage" "$vp" "$dr" "$rf" "$pr" "$gd" "$sv")
}

case "${1:-show}" in
  harvest) harvest; render;;
  show)    harvest; render;;
  *) echo "Usage: ai-status.sh [show|harvest]"; exit 2;; 
esac
