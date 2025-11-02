#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C.UTF-8 LANG=C.UTF-8

# Colors and Unicode
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'
PURPLE='\033[0;35m'; CYAN='\033[0;36m'; WHITE='\033[1m'; NC='\033[0m'

# Configuration
LAB="${LAB:-$PWD/speccy-lab}"
MEM="$LAB/memory"
LOGS="$LAB/logs"
STATE="$MEM/state.json"
CHANGELOG="$LAB/CHANGELOG.md"
GATES_CONFIG="$LAB/config/gates.yaml"
AUDIT_LOG="$LOGS/audit.jsonl"

mkdir -p "$MEM" "$LOGS" "$(dirname "$GATES_CONFIG")"

# Helper functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Initialize gates config if missing
if [ ! -f "$GATES_CONFIG" ]; then
  log_warning "Gates config missing, creating default..."
  mkdir -p "$(dirname "$GATES_CONFIG")"
  cat >"$GATES_CONFIG" <<'YAML'
# AI Milestone Gates Configuration
roles:
  observer:
    description: "Default entry level"
    color: "🔵"
  advisor:
    description: "Ideas and planning, no execution"
    color: "🟡"
    gates:
      dry_runs: 3
      reflections: 3
      proposals: 3
      validate_pass: 2
      safeops_violations: 0
  operator:
    description: "Full action authority"
    color: "🟢"
    gates:
      dry_runs: 6
      reflections: 6
      proposals: 6
      validate_pass: 4
      consecutive_green_days: 2
      safeops_violations: 0
audit:
  retention_days: 365
  log_path: "logs/audit.jsonl"
safety:
  max_promotions_per_day: 1
  require_justification: true
YAML
fi

# Seed minimal state if missing/empty
if [ ! -s "$STATE" ]; then
  log_info "Initializing milestone state..."
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
  "completed": [],
  "created_at": "2025-01-01T00:00:00Z"
}
JSON
fi

# Read current metrics
read_metrics() {
  stage="$(jq -r '.stage' "$STATE")"
  vp="$(jq -r '.metrics.validate_pass' "$STATE")"
  dr="$(jq -r '.metrics.dry_runs' "$STATE")"
  rf="$(jq -r '.metrics.reflections' "$STATE")"
  pr="$(jq -r '.metrics.proposals' "$STATE")"
  gd="$(jq -r '.metrics.consecutive_green_days' "$STATE")"
  sv="$(jq -r '.metrics.safeops_violations' "$STATE")"
}

# Parse YAML gates (simple parsing for our specific structure)
parse_gates() {
  local role="$1"
  python3 -c "
import yaml, sys, json
with open('$GATES_CONFIG') as f:
    config = yaml.safe_load(f)
gates = config.get('roles', {}).get('$role', {}).get('gates', {})
print(json.dumps(gates))
" 2>/dev/null || echo "{}"
}

# Check readiness for a role
check_readiness() {
  local target_role="$1"
  local gates
  gates="$(parse_gates "$target_role")"

  local ready=1
  local reasons=()

  # Check each gate
  local required_dry_runs="$(echo "$gates" | jq -r '.dry_runs // 0')"
  if [ "$required_dry_runs" -gt 0 ] && [ "$dr" -lt "$required_dry_runs" ]; then
    ready=0; reasons+=("dry_runs: $dr/$required_dry_runs")
  fi

  local required_reflections="$(echo "$gates" | jq -r '.reflections // 0')"
  if [ "$required_reflections" -gt 0 ] && [ "$rf" -lt "$required_reflections" ]; then
    ready=0; reasons+=("reflections: $rf/$required_reflections")
  fi

  local required_proposals="$(echo "$gates" | jq -r '.proposals // 0')"
  if [ "$required_proposals" -gt 0 ] && [ "$pr" -lt "$required_proposals" ]; then
    ready=0; reasons+=("proposals: $pr/$required_proposals")
  fi

  local required_validate_pass="$(echo "$gates" | jq -r '.validate_pass // 0')"
  if [ "$required_validate_pass" -gt 0 ] && [ "$vp" -lt "$required_validate_pass" ]; then
    ready=0; reasons+=("validate_pass: $vp/$required_validate_pass")
  fi

  local required_green_days="$(echo "$gates" | jq -r '.consecutive_green_days // 0')"
  if [ "$required_green_days" -gt 0 ] && [ "$gd" -lt "$required_green_days" ]; then
    ready=0; reasons+=("green_days: $gd/$required_green_days")
  fi

  local max_violations="$(echo "$gates" | jq -r '.safeops_violations // 0')"
  if [ "$sv" -gt "$max_violations" ]; then
    ready=0; reasons+=("violations: $sv (max: $max_violations)")
  fi

  echo "$ready"
  printf '%s\n' "${reasons[@]}"
}

# Write audit log entry
write_audit() {
  local action="$1"
  local from_role="$2"
  local to_role="$3"
  local reason="$4"
  local result="$5"

  local timestamp
  timestamp="$(date -Iseconds)"

  local user="${USER:-system}"

  local audit_entry
  audit_entry="$(cat <<EOF
{
  "timestamp": "$timestamp",
  "user": "$user",
  "action": "$action",
  "from": "$from_role",
  "to": "$to_role",
  "reason": "$reason",
  "metrics": {
    "dry_runs": $dr,
    "reflections": $rf,
    "proposals": $pr,
    "validate_pass": $vp,
    "consecutive_green_days": $gd,
    "safeops_violations": $sv
  },
  "result": "$result"
}
EOF
)"

  echo "$audit_entry" >> "$AUDIT_LOG"
  log_info "Audit entry written to $AUDIT_LOG"
}

# Display readiness status with progress bars
show_readiness() {
  read_metrics

  echo -e "\n${WHITE}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${WHITE}║${NC} ${CYAN}AI MILESTONE READINESS STATUS${NC}                              ${WHITE}║${NC}"
  echo -e "${WHITE}╚════════════════════════════════════════════════════════════╝${NC}"

  echo -e "\n${WHITE}Current Role:${NC} ${YELLOW}$stage${NC}"
  echo -e "${WHITE}Current Metrics:${NC}"

  # Display metrics with progress bars
  printf "  Dry Runs:        %3d/%-3d %s\n" "$dr" "6" "$(bar $dr 6)"
  printf "  Reflections:     %3d/%-3d %s\n" "$rf" "6" "$(bar $rf 6)"
  printf "  Proposals:       %3d/%-3d %s\n" "$pr" "6" "$(bar $pr 6)"
  printf "  Validate Pass:   %3d/%-3d %s\n" "$vp" "4" "$(bar $vp 4)"
  printf "  Green Days:      %3d/%-3d %s\n" "$gd" "2" "$(bar $gd 2)"
  printf "  Safety Violations: %3d (must be 0)\n" "$sv"

  echo -e "\n${WHITE}Readiness Gates:${NC}"

  # Check advisor readiness
  local advisor_ready
  local advisor_reasons=()
  read -r advisor_ready advisor_reasons <<< "$(check_readiness advisor)"
  if [ "$advisor_ready" = "1" ]; then
    echo -e "  ${GREEN}✅ Advisor${NC} - Gates satisfied"
  else
    echo -e "  ${RED}❌ Advisor${NC} - Missing: ${advisor_reasons[*]}"
  fi

  # Check operator readiness
  local operator_ready
  local operator_reasons=()
  read -r operator_ready operator_reasons <<< "$(check_readiness operator)"
  if [ "$operator_ready" = "1" ]; then
    echo -e "  ${GREEN}✅ Operator${NC} - Gates satisfied"
  else
    echo -e "  ${RED}❌ Operator${NC} - Missing: ${operator_reasons[*]}"
  fi

  echo -e "\n${WHITE}Next Action:${NC}"
  if [ "$stage" = "observer" ] && [ "$advisor_ready" = "1" ]; then
    echo -e "  Ready for: ${YELLOW}./speccy milestone promote advisor${NC}"
  elif [ "$stage" = "advisor" ] && [ "$operator_ready" = "1" ]; then
    echo -e "  Ready for: ${GREEN}./speccy milestone promote operator${NC}"
  elif [ "$operator_ready" = "1" ] && [ "$stage" != "operator" ]; then
    echo -e "  Ready for: ${GREEN}./speccy milestone promote operator${NC}"
  else
    echo -e "  Continue training to meet requirements"
  fi
}

# Simple progress bar
bar() {
  local value="$1"
  local max="$2"
  local filled=$((value * 10 / max))
  local empty=$((10 - filled))
  printf "["
  printf "%*s" "$filled" | tr ' ' '█'
  printf "%*s" "$empty" | tr ' ' '░'
  printf "]"
}

# Reset metrics (for testing)
reset_metrics() {
  local force="${1:-false}"
  if [ "$force" != "--force" ]; then
    echo -e "${YELLOW}⚠️  This will reset all milestone metrics.${NC}"
    echo -e "Use ${WHITE}./speccy milestone reset --force${NC} to confirm."
    return 1
  fi

  log_warning "Resetting all milestone metrics..."
  local tmp
  tmp="$(mktemp)"
  jq '
    .metrics = {
      "validate_pass": 0,
      "consecutive_green_days": 0,
      "dry_runs": 0,
      "reflections": 0,
      "proposals": 0,
      "safeops_violations": 0
    }
  ' "$STATE" > "$tmp" && mv "$tmp" "$STATE"

  write_audit "reset" "$stage" "$stage" "Testing/sandbox reset" "success"
  log_success "Metrics reset complete"
}

# Main promotion logic
promote_milestone() {
  local target="${1:-auto}"
  local reason="${2:-readiness gates satisfied}"

  read_metrics

  # Check advisor readiness
  local advisor_ready
  local advisor_reasons=()
  read -r advisor_ready advisor_reasons <<< "$(check_readiness advisor)"

  # Check operator readiness
  local operator_ready
  local operator_reasons=()
  read -r operator_ready operator_reasons <<< "$(check_readiness operator)"

  # Determine target
  local final_target="$target"
  if [ "$target" = "auto" ]; then
    if [ "$operator_ready" = "1" ] && [ "$stage" != "operator" ]; then
      final_target="operator"
    elif [ "$advisor_ready" = "1" ] && [ "$stage" = "observer" ]; then
      final_target="advisor"
    else
      log_error "Not ready for promotion"
      echo -e "  ${WHITE}Current stage:${NC} $stage"
      echo -e "  ${WHITE}Current metrics:${NC} dr=$dr rf=$rf pr=$pr vp=$vp gd=$gd sv=$sv"
      echo -e "  ${WHITE}Advisor needs:${NC} dr≥3, rf≥3, pr≥3, vp≥2, sv=0"
      echo -e "  ${WHITE}Operator needs:${NC} dr≥6, rf≥6, pr≥6, vp≥4, gd≥2, sv=0"
      write_audit "promotion_attempt" "$stage" "none" "$reason" "failed_gates"
      exit 1
    fi
  fi

  # Validate target against readiness
  case "$final_target" in
    advisor)
      if [ "$advisor_ready" != "1" ]; then
        log_error "Advisor gate not met. Missing: ${advisor_reasons[*]}"
        write_audit "promotion_attempt" "$stage" "advisor" "$reason" "failed_gates"
        exit 2
      fi
      if [ "$stage" = "advisor" ] || [ "$stage" = "operator" ]; then
        log_info "Already at $stage (≥ advisor). No change needed."
        write_audit "promotion_attempt" "$stage" "$stage" "$reason" "no_change"
        exit 0
      fi
      ;;
    operator)
      if [ "$operator_ready" != "1" ]; then
        log_error "Operator gate not met. Missing: ${operator_reasons[*]}"
        write_audit "promotion_attempt" "$stage" "operator" "$reason" "failed_gates"
        exit 2
      fi
      if [ "$stage" = "operator" ]; then
        log_info "Already operator. No change needed."
        write_audit "promotion_attempt" "$stage" "$stage" "$reason" "no_change"
        exit 0
      fi
      ;;
    *)
      log_error "Usage: milestone_cli.sh promote [advisor|operator|auto] [reason]"
      exit 2
      ;;
  esac

  # Perform promotion
  local ts
  ts="$(date -Iseconds)"

  local tmp
  tmp="$(mktemp)"
  jq --arg from "$stage" \
     --arg to "$final_target" \
     --arg ts "$ts" \
     --arg reason "$reason" '
    .completed += [{
      stage: $from,
      promoted_to: $to,
      ts: $ts,
      reason: $reason
    }] | .stage = $to
  ' "$STATE" > "$tmp" && mv "$tmp" "$STATE"

  # Update changelog
  {
    echo "## $ts — Promotion"
    echo "- From: $stage → To: $final_target"
    echo "- Reason: $reason"
    echo "- Metrics: dr=$dr rf=$rf pr=$pr vp=$vp gd=$gd sv=$sv"
    echo
  } >> "$CHANGELOG"

  # Log training signal
  echo "REFLECT: promoted $stage -> $final_target @ $ts (reason: $reason)" >> "$MEM/training.log"

  # Write audit
  write_audit "promotion" "$stage" "$final_target" "$reason" "success"

  # Success message
  printf "\n"
  echo -e "${GREEN}[PROMOTE] SUCCESS${NC}"
  echo -e "  ${stage}  →  $final_target @ $ts"
  echo -e "  ${WHITE}Metrics:${NC} dr=$dr rf=$rf pr=$pr vp=$vp gd=$gd sv=$sv"
  echo -e "  ${WHITE}Reason:${NC} $reason"
}

# Main command dispatcher
case "${1:-help}" in
  show)
    show_readiness
    ;;
  promote)
    shift
    promote_milestone "$@"
    ;;
  reset)
    shift
    reset_metrics "$@"
    ;;
  status)
    show_readiness
    ;;
  help|*)
    echo -e "${WHITE}AI Milestone Management System${NC}"
    echo ""
    echo -e "${CYAN}Commands:${NC}"
    echo -e "  ${WHITE}show${NC}     Show current readiness status and metrics"
    echo -e "  ${WHITE}promote${NC}  Promote to next available role"
    echo -e "  ${WHITE}reset${NC}    Reset all metrics (use --force to confirm)"
    echo -e "  ${WHITE}status${NC}   Alias for 'show'"
    echo ""
    echo -e "${CYAN}Usage:${NC}"
    echo -e "  $0 show"
    echo -e "  $0 promote [advisor|operator|auto] [reason]"
    echo -e "  $0 reset --force"
    echo ""
    echo -e "${CYAN}Examples:${NC}"
    echo -e "  $0 promote auto"
    echo -e "  $0 promote advisor \"Completed training requirements\""
    echo -e "  $0 promote operator \"Ready for full operational authority\""
    exit 0
    ;;
esac