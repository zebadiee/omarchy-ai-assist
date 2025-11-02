#!/usr/bin/env bash
set -euo pipefail

# AI Milestone Progress Tracker
# Automatically tracks AI learning progress and manages stage promotions

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
LAB="${ROOT}/speccy-lab"
STATE="${LAB}/state"
LOGS="${LAB}/logs"
MEM="${LAB}/memory"
SPEC="${LAB}/milestones.yml"
STATUS_MD="${LAB}/STATUS.md"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Helper functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check dependencies
need() {
  command -v "$1" >/dev/null 2>&1 || {
    log_error "Missing required dependency: $1"
    log_info "Install with: apt install $1 (or equivalent)"
    exit 1
  }
}

# Ensure required tools are available
need yq || {
  log_warning "yq not found, checking local installation..."
  if [ -f ~/bin/yq ]; then
    export PATH="$PATH:~/bin"
  else
    log_error "yq required but not found. Please install with:"
    log_error "  wget -qO /tmp/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64"
    log_error "  chmod +x /tmp/yq && mkdir -p ~/bin && mv /tmp/yq ~/bin/yq"
    exit 1
  fi
}
need jq

# Create directories
mkdir -p "$STATE" "$LOGS" "$MEM"

# State management
STATE_JSON="${STATE}/progress.json"

init_state() {
  if [ ! -f "$STATE_JSON" ]; then
    log_info "Initializing milestone tracking state..."
    cat > "$STATE_JSON" <<'EOF'
{
  "version": 1,
  "current_stage": "observer",
  "completed": [],
  "metrics": {},
  "started_at": "$(date -Is)",
  "last_updated": "$(date -Is)"
}
EOF
  fi
}

# Metric management functions
metric_set() {
  local key="$1" val="$2"
  jq --arg k "$key" --argjson v "$val" '.metrics[$k]=$v | .last_updated=now' "$STATE_JSON" > "${STATE_JSON}.tmp" && mv "${STATE_JSON}.tmp" "$STATE_JSON"
}

metric_inc() {
  local key="$1"; local add="${2:-1}"
  local cur; cur="$(jq -r --arg k "$key" '.metrics[$k]//0' "$STATE_JSON")"
  metric_set "$key" "$((cur+add))"
}

metric_get() {
  jq -r --arg k "$1" '.metrics[$k]//0' "$STATE_JSON"
}

# Record cycle completion (green/red)
record_cycle() {
  local ok="$1" # 1 for green, 0 for red
  local today="$(date +%F)"

  # consecutive green days calculation
  local prev_day="$(jq -r '.metrics.last_cycle_day // ""' "$STATE_JSON")"
  local streak="$(metric_get consecutive_green_days)"

  if [ "$ok" = "1" ]; then
    if [ "$prev_day" = "$today" ]; then
      : # same day, keep current streak
    else
      streak=$((streak+1))
      metric_set consecutive_green_days "$streak"
    fi
  else
    metric_set consecutive_green_days 0
  fi

  jq --arg d "$today" '.metrics.last_cycle_day=$d' "$STATE_JSON" > "${STATE_JSON}.tmp" && mv "${STATE_JSON}.tmp" "$STATE_JSON"
}

# Harvest metrics from logs and memory
harvest_metrics() {
  log_info "Harvesting metrics from logs and memory..."

  # Dry-run passes (count lines tagged as DRY PASS)
  local dry_pass=$(grep -Rsc '\[DRY\] PASS' "$LOGS" 2>/dev/null | awk -F: '{s+=$2} END{print s+0}')
  metric_set min_dry_runs "$dry_pass"

  # SafeOps violations (look for [SAFE] die or "blocked")
  local vio=$(grep -Rsci '\[SAFE\].*blocked\|die.*violat\|policy.*violation' "$LOGS" 2>/dev/null | awk -F: '{s+=$2} END{print s+0}')
  metric_set safeops_violations "$vio"

  # Reflections count
  local refl=$(grep -Rsc 'REFLECTION:' "$MEM" 2>/dev/null | awk -F: '{s+=$2} END{print s+0}')
  metric_set reflections "$refl"

  # Proposals count (look for PROPOSAL:)
  local props=$(grep -Rsc 'PROPOSAL:' "$MEM" "$LOGS" 2>/dev/null | awk -F: '{s+=$2} END{print s+0}')
  metric_set proposals "$props"

  # Validate passes (look for 'Registry OK; CLI OK; CI-ready.')
  local valp=$(grep -Rsc 'Registry OK; CLI OK; CI-ready\.' "$LOGS" 2>/dev/null | awk -F: '{s+=$2} END{print s+0}')
  metric_set validate_pass "$valp"

  # SafeOps exec OK (look for '[SAFE] Sandbox run succeeded.')
  local execok=$(grep -Rsc '\[SAFE\].*succeeded\|SAFE.*OK' "$LOGS" 2>/dev/null | awk -F: '{s+=$2} END{print s+0}')
  metric_set safeops_exec_ok "$execok"

  # Daily cycles (look for AI_LEARNING_CYCLE)
  local dcycles=$(grep -Rsc 'AI_LEARNING_CYCLE|daily_learning_cycle' "$LOGS" 2>/dev/null | awk -F: '{s+=$2} END{print s+0}')
  metric_set daily_cycles "$dcycles"

  # Lesson completions
  local lessons=$(grep -Rsc 'lesson_completed:|LESSON.*COMPLETE' "$MEM" "$LOGS" 2>/dev/null | awk -F: '{s+=$2} END{print s+0}')
  metric_set lessons_completed "$lessons"

  log_success "Metrics harvested successfully"
}

# Check if current stage meets promotion criteria
meets() {
  local stage="$1"
  echo -e "${CYAN}Stage: $stage${NC}"
  echo "Criteria check:"

  # Get requirements from YAML (simple grep approach)
  local need_dry=$(grep -A 20 "id: $stage" "$SPEC" | grep "min_dry_runs:" | awk '{print $2}' || echo "0")
  local need_ref=$(grep -A 20 "id: $stage" "$SPEC" | grep "min_reflections:" | awk '{print $2}' || echo "0")
  local need_props=$(grep -A 20 "id: $stage" "$SPEC" | grep "min_proposals:" | awk '{print $2}' || echo "0")
  local need_val=$(grep -A 20 "id: $stage" "$SPEC" | grep "min_validate_pass:" | awk '{print $2}' || echo "0")
  local need_exec=$(grep -A 20 "id: $stage" "$SPEC" | grep "min_safeops_exec_ok:" | awk '{print $2}' || echo "0")
  local need_cycles=$(grep -A 20 "id: $stage" "$SPEC" | grep "min_daily_cycles:" | awk '{print $2}' || echo "0")
  local need_days=$(grep -A 20 "id: $stage" "$SPEC" | grep "min_consecutive_green_days:" | awk '{print $2}' || echo "0")
  local need_lessons=$(grep -A 20 "id: $stage" "$SPEC" | grep "min_lessons_completed:" | awk '{print $2}' || echo "0")
  local max_vio=$(grep -A 20 "id: $stage" "$SPEC" | grep "max_safeops_violations:" | awk '{print $2}' || echo "0")

  # Get current values
  local have_dry=$(metric_get min_dry_runs)
  local have_ref=$(metric_get reflections)
  local have_props=$(metric_get proposals)
  local have_val=$(metric_get validate_pass)
  local have_exec=$(metric_get safeops_exec_ok)
  local have_cycles=$(metric_get daily_cycles)
  local have_days=$(metric_get consecutive_green_days)
  local have_lessons=$(metric_get lessons_completed)
  local have_vio=$(metric_get safeops_violations)

  # Print detailed criteria check
  printf "  %-28s %s/%s %s\n" "dry_runs:" "$have_dry" "$need_dry" "$([ "$have_dry" -ge "$need_dry" ] && echo "✅" || echo "❌")"
  printf "  %-28s %s/%s %s\n" "reflections:" "$have_ref" "$need_ref" "$([ "$have_ref" -ge "$need_ref" ] && echo "✅" || echo "❌")"
  printf "  %-28s %s/%s %s\n" "proposals:" "$have_props" "$need_props" "$([ "$have_props" -ge "$need_props" ] && echo "✅" || echo "❌")"
  printf "  %-28s %s/%s %s\n" "validate_pass:" "$have_val" "$need_val" "$([ "$have_val" -ge "$need_val" ] && echo "✅" || echo "❌")"
  printf "  %-28s %s/%s %s\n" "safeops_exec_ok:" "$have_exec" "$need_exec" "$([ "$have_exec" -ge "$need_exec" ] && echo "✅" || echo "❌")"
  printf "  %-28s %s/%s %s\n" "daily_cycles:" "$have_cycles" "$need_cycles" "$([ "$have_cycles" -ge "$need_cycles" ] && echo "✅" || echo "❌")"
  printf "  %-28s %s/%s %s\n" "consecutive_green_days:" "$have_days" "$need_days" "$([ "$have_days" -ge "$need_days" ] && echo "✅" || echo "❌")"
  printf "  %-28s %s/%s %s\n" "lessons_completed:" "$have_lessons" "$need_lessons" "$([ "$have_lessons" -ge "$need_lessons" ] && echo "✅" || echo "❌")"
  printf "  %-28s %s<=%s %s\n" "safeops_violations:" "$have_vio" "$max_vio" "$([ "$have_vio" -le "$max_vio" ] && echo "✅" || echo "❌")"

  # Final boolean check
  local meets_all=true
  [ "$have_dry" -ge "$need_dry" ] || meets_all=false
  [ "$have_ref" -ge "$need_ref" ] || meets_all=false
  [ "$have_props" -ge "$need_props" ] || meets_all=false
  [ "$have_val" -ge "$need_val" ] || meets_all=false
  [ "$have_exec" -ge "$need_exec" ] || meets_all=false
  [ "$have_cycles" -ge "$need_cycles" ] || meets_all=false
  [ "$have_days" -ge "$need_days" ] || meets_all=false
  [ "$have_lessons" -ge "$need_lessons" ] || meets_all=false
  [ "$have_vio" -le "$max_vio" ] || meets_all=false

  if $meets_all; then
    echo -e "\n${GREEN}✅ All criteria met for stage: $stage${NC}"
    return 0
  else
    echo -e "\n${YELLOW}❌ Some criteria not yet met for stage: $stage${NC}"
    return 1
  fi
}

# Promote to next stage if ready
promote_if_ready() {
  local stage="$1"
  echo -e "${CYAN}Checking promotion eligibility for stage: $stage${NC}"

  if meets "$stage"; then
    local next=$(yq -r ".stages[] | select(.id==\"$stage\").on_complete.promote_to" "$SPEC")
    [ -z "$next" ] && next="$stage"

    # Record completion and promotion
    local promotion_json=$(jq --arg s "$stage" --arg n "$next" --arg t "$(date -Is)" \
      '.completed += [{"stage":$s,"ts":$t,"promoted_to":$n}] | .current_stage=$n | .last_updated=now' \
      "$STATE_JSON")

    echo "$promotion_json" > "${STATE_JSON}.tmp" && mv "${STATE_JSON}.tmp" "$STATE_JSON"

    log_success "🎉 PROMOTED to stage: $next"

    # Show unlocked rewards
    echo -e "${GREEN}🎓 Unlocked capabilities for $next:${NC}"
    yq -r ".rewards.$next[]? // \"No new rewards\"" "$SPEC" 2>/dev/null | while read reward; do
      echo "  • $reward"
    done

    # Show unlocked lessons
    echo -e "${GREEN}📚 New lessons available:${NC}"
    yq -r ".lessons[] | select(.from_stage==\"$next\") | \"  • \(.title): \(.description)\"" "$SPEC" 2>/dev/null || echo "  • No new lessons"

    return 0
  else
    log_warning "Not ready to promote yet. Continue working on stage: $stage"
    return 1
  fi
}

# Show current status
status() {
  init_state
  harvest_metrics

  local cur=$(jq -r '.current_stage' "$STATE_JSON")
  local started=$(jq -r '.started_at' "$STATE_JSON")
  local updated=$(jq -r '.last_updated' "$STATE_JSON")

  echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║                    AI MILESTONE STATUS                        ║${NC}"
  echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "Current Stage: ${GREEN}$cur${NC}"
  echo "Started: $started"
  echo "Last Updated: $updated"
  echo ""

  echo -e "${CYAN}📊 Current Metrics:${NC}"
  jq -r '.metrics | to_entries[] | "  \(.key): \(.value)"' "$STATE_JSON" 2>/dev/null || echo "  No metrics yet"
  echo ""

  echo -e "${CYAN}🏆 Completed Milestones:${NC}"
  if jq -e '.completed | length > 0' "$STATE_JSON" >/dev/null; then
    jq -r '.completed[]? | "  ✅ \(.stage) promoted to \(.promoted_to // \"unknown\") @ \(.ts)"' "$STATE_JSON"
  else
    echo "  No milestones completed yet"
  fi
  echo ""

  echo -e "${CYAN}🎯 Stage Requirements:${NC}"
  meets "$cur" || true

  # Ensure UTF-8 locale for jq
  export LC_ALL=C.UTF-8
  export LANG=C.UTF-8

  # Write markdown status
  {
    echo "# AI Status Report"
    echo ""
    echo "## Current Stage: $cur"
    echo "**Started:** $started"
    echo "**Last Updated:** $updated"
    echo ""
    echo "## Metrics"
    echo "| Metric | Value |"
    echo "|--------|-------|"
    jq -r '.metrics | to_entries[] | "| \(.key) | \(.value) |"' "$STATE_JSON" 2>/dev/null || echo "| No metrics | - |"
    echo ""
    echo "## Completed Milestones"
    if jq -e '.completed | length > 0' "$STATE_JSON" >/dev/null; then
      jq -r '.completed[]? | "- " + .stage + (if has("promoted_to") then " → " + .promoted_to else "" end) + " @ " + .ts' "$STATE_JSON" 2>/dev/null || echo "No milestones completed yet"
    else
      echo "No milestones completed yet"
    fi
    echo ""
    echo "---"
    echo "*Generated: $(date -Is)*"
  } > "$STATUS_MD"

  log_info "Status report written to: $STATUS_MD"
}

# Main command routing
case "${1:-}" in
  status)
    status
    ;;
  harvest)
    init_state
    harvest_metrics
    echo "Metrics harvested successfully."
    ;;
  check)
    init_state
    harvest_metrics
    if meets "$(jq -r '.current_stage' "$STATE_JSON")"; then
      echo "READY_FOR_PROMOTION"
      exit 0
    else
      echo "NOT_READY"
      exit 1
    fi
    ;;
  promote)
    init_state
    harvest_metrics
    promote_if_ready "$(jq -r '.current_stage' "$STATE_JSON")"
    ;;
  record)
    shift || true
    record_cycle "${1:-1}"
    echo "Cycle recorded: ${1:-1} (1=green, 0=red)"
    ;;
  report)
    status
    echo ""
    echo "Full status report:"
    cat "$STATUS_MD"
    ;;
  reset)
    log_warning "Resetting all milestone progress..."
    init_state
    echo '{"version":1,"current_stage":"observer","completed":[],"metrics":{},"started_at":"'$date -Is'","last_updated":"'$(date -Is)'"}' > "$STATE_JSON"
    log_success "Milestone progress reset to observer stage"
    ;;
  *)
    echo "AI Milestone Progress Tracker"
    echo ""
    echo "Usage: $0 {status|harvest|check|promote|record [1|0]|report|reset}"
    echo ""
    echo "Commands:"
    echo "  status     - Show current milestone status and metrics"
    echo "  harvest    - Collect metrics from logs and memory"
    echo "  check      - Check if ready for promotion (exit code 0=ready)"
    echo "  promote    - Attempt promotion to next stage if criteria met"
    echo "  record N   - Record cycle completion (1=green, 0=red)"
    echo "  report     - Generate full status report"
    echo "  reset      - Reset all progress (dangerous!)"
    echo ""
    echo "Examples:"
    echo "  $0 status                    # Show current status"
    echo "  $0 promote                   # Try to promote"
    echo "  $0 record 1                  # Record successful cycle"
    echo "  ./speccy milestone status    # Via CLI"
    exit 2
    ;;
esac