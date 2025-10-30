#!/usr/bin/env bash
# Universal AI Subagent Router for Omarchy OS
# Provider-agnostic workflow with #pln #imp #knw commands

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROVIDERS_CONFIG="${SCRIPT_DIR}/ai_providers.yml"

# Default settings
DEFAULT_PROVIDER="${AI_PROVIDER:-openrouter}"
DEFAULT_TIER="${AI_TIER:-x0}"
CURRENT_PROVIDER="$DEFAULT_PROVIDER"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
log() { echo -e "${GREEN}[AI]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }
info() { echo -e "${BLUE}[INFO]${NC} $*"; }

# Check dependencies
need() { command -v "$1" >/dev/null 2>&1 || { error "Missing: $1"; exit 1; }; }

need curl
need jq
need yq 2>/dev/null || {
  warn "yq not found, YAML parsing limited"
  # Simple YAML parser fallback
  yq() {
    local key="$1"
    local file="$2"
    grep "^\s*$key:" "$file" | sed 's/^[^:]*:\s*//'
  }
}

# Load provider configuration
load_provider_config() {
  local provider="$1"
  local cmd_var=""
  local env_vars=""

  if command -v yq >/dev/null 2>&1; then
    cmd_var=$(yq ".providers.${provider}.cmd" "$PROVIDERS_CONFIG" 2>/dev/null || echo "")
    env_vars=$(yq ".providers.${provider}.env[]" "$PROVIDERS_CONFIG" 2>/dev/null || echo "")
  else
    cmd_var=$(grep -A5 "^\s*${provider}:" "$PROVIDERS_CONFIG" | grep "cmd:" | sed 's/.*cmd:[[:space:]]*//' || echo "")
    env_vars=$(grep -A5 "^\s*${provider}:" "$PROVIDERS_CONFIG" | grep "env:" | sed 's/.*env:[[:space:]]*//' || echo "")
  fi

  if [[ -z "$cmd_var" ]]; then
    error "Provider '$provider' not found in configuration"
    return 1
  fi

  echo "$cmd_var"
}

# Get model for provider and tier
get_model() {
  local provider="$1"
  local tier="$2"

  if command -v yq >/dev/null 2>&1; then
    yq ".tiers.${tier}.${provider}" "$PROVIDERS_CONFIG" 2>/dev/null || echo "default"
  else
    grep -A10 "^tiers:" "$PROVIDERS_CONFIG" | grep -A5 "${tier}:" | grep "${provider}:" | sed 's/.*:[[:space:]]*//' || echo "default"
  fi
}

# Check if provider is available
check_provider() {
  local provider="$1"

  case "$provider" in
    openrouter)
      [[ -n "${OPENROUTER_API_KEY:-}" ]]
      ;;
    ollama)
      if command -v ollama >/dev/null 2>&1; then
        ollama list >/dev/null 2>&1
      else
        # Check if Ollama API is accessible
        curl -s "${OLLAMA_BASE_URL:-http://localhost:11434}/api/tags" >/dev/null 2>&1
      fi
      ;;
    lmstudio)
      # Check if LM Studio API is accessible
      curl -s "${LMSTUDIO_BASE_URL:-http://localhost:41343/v1}/models" >/dev/null 2>&1
      ;;
    openai)
      [[ -n "${OPENAI_API_KEY:-}" ]]
      ;;
    *)
      return 1
      ;;
  esac
}

# Switch provider (with fallback)
switch_provider() {
  local preferred="$1"

  if check_provider "$preferred"; then
    CURRENT_PROVIDER="$preferred"
    info "Switched to provider: $preferred"
    return 0
  fi

  warn "Provider '$preferred' not available, trying fallback chain"

  # Try fallback chain
  local fallbacks=("ollama" "openrouter" "lmstudio" "openai")
  for provider in "${fallbacks[@]}"; do
    if check_provider "$provider"; then
      CURRENT_PROVIDER="$provider"
      info "Fallback to provider: $provider"
      return 0
    fi
  done

  error "No AI providers available"
  return 1
}

# Build request payload
build_payload() {
  local subagent="$1"
  local prompt="$2"
  local provider="$3"
  local tier="$4"

  local model
  model=$(get_model "$provider" "$tier")

  # Get system prompt for subagent
  local system_prompt=""
  if command -v yq >/dev/null 2>&1; then
    system_prompt=$(yq ".subagents.${subagent}.system_prompt" "$PROVIDERS_CONFIG" 2>/dev/null || echo "")
  else
    system_prompt=$(grep -A20 "^\s*${subagent}:" "$PROVIDERS_CONFIG" | grep "system_prompt:" | sed 's/.*system_prompt:[[:space:]]*//' || echo "")
  fi

  case "$provider" in
    openrouter|openai|lmstudio)
      jq -n --arg model "$model" --arg system "$system_prompt" --arg user "$prompt" \
        '{model:$model, messages:[{role:"system",content:$system},{role:"user",content:$user}], max_tokens:4000, temperature:0.7}'
      ;;
    ollama)
      if [[ -n "$system_prompt" ]]; then
        jq -n --arg model "$model" --arg system "$system_prompt" --arg user "$prompt" \
          '{model:$model, system:$system, prompt:$user, stream:false}'
      else
        jq -n --arg model "$model" --arg user "$prompt" \
          '{model:$model, prompt:$user, stream:false}'
      fi
      ;;
    *)
      error "Unknown provider: $provider"
      return 1
      ;;
  esac
}

# Execute AI request
execute_request() {
  local subagent="$1"
  local prompt="$2"
  local tier="$3"

  if ! switch_provider "$CURRENT_PROVIDER"; then
    return 1
  fi

  local cmd
  cmd=$(load_provider_config "$CURRENT_PROVIDER")

  if [[ -z "$cmd" ]]; then
    error "Could not load provider command"
    return 1
  fi

  # Build and send request
  local payload
  payload=$(build_payload "$subagent" "$prompt" "$CURRENT_PROVIDER" "$tier")

  log "Querying ${CURRENT_PROVIDER} (${subagent}@${tier})..."

  # Execute the command
  if echo "$payload" | eval "$cmd" 2>/dev/null; then
    return 0
  else
    warn "Request failed, trying next provider"
    # Try next provider in fallback chain
    local current_index=-1
    local fallbacks=("ollama" "openrouter" "lmstudio" "openai")
    for i in "${!fallbacks[@]}"; do
      if [[ "${fallbacks[$i]}" == "$CURRENT_PROVIDER" ]]; then
        current_index=$i
        break
      fi
    done

    for ((i=current_index+1; i<${#fallbacks[@]}; i++)); do
      local next_provider="${fallbacks[$i]}"
      if check_provider "$next_provider"; then
        CURRENT_PROVIDER="$next_provider"
        log "Retrying with: $next_provider"
        if echo "$payload" | eval "$(load_provider_config "$next_provider")" 2>/dev/null; then
          return 0
        fi
      fi
    done

    error "All providers failed"
    return 1
  fi
}

# Main subagent commands
planner() {
  local prompt="$*"
  if [[ -z "$prompt" ]]; then
    error "Provide a planning task"
    return 1
  fi
  execute_request "planner" "$prompt" "$1"
}

implementor() {
  local prompt="$*"
  if [[ -z "$prompt" ]]; then
    error "Provide an implementation task"
    return 1
  fi
  execute_request "implementor" "$prompt" "$2"
}

knowledge() {
  local prompt="$*"
  if [[ -z "$prompt" ]]; then
    error "Provide a knowledge extraction task"
    return 1
  fi
  execute_request "knowledge" "$prompt" "free"
}

# Show status
status() {
  echo -e "${CYAN}🤖 Omarchy Universal AI Status${NC}"
  echo "================================"

  for provider in openrouter ollama lmstudio openai; do
    if check_provider "$provider"; then
      local model
      model=$(get_model "$provider" "$DEFAULT_TIER")
      echo -e "  ${GREEN}✅${NC} $provider: $model"
    else
      echo -e "  ${RED}❌${NC} $provider: unavailable"
    fi
  done

  echo ""
  echo "Current provider: $CURRENT_PROVIDER"
  echo "Default tier: $DEFAULT_TIER"
  echo ""
  echo "Environment variables:"
  env | grep -E "(OPENROUTER|OLLAMA|LMSTUDIO|OPENAI)_" | sort
}

# Usage information
usage() {
  cat <<'EOF'
🤖 Universal AI Subagent Router — Omarchy OS

Provider-agnostic AI workflow with automatic fallback

USAGE:
  # Subagent commands (supports #pln #imp #knw shortcuts)
  universal_ai.sh planner|pln [tier] "task description"
  universal_ai.sh implementor|imp [tier] "task description"
  universal_ai.sh knowledge|knw "task description"

  # Control commands
  universal_ai.sh status
  universal_ai.sh switch <provider>
  universal_ai.sh help

EXAMPLES:
  # Planning (uses x1 tier by default)
  universal_ai.sh planner x1 "Design a scalable microservices architecture"
  universal_ai.sh pln "Plan the implementation of a REST API"

  # Implementation (uses x0 tier by default)
  universal_ai.sh implementor x0 "Generate Go code for the API server"
  universal_ai.sh imp "Create a React component for the dashboard"

  # Knowledge extraction (uses free tier)
  universal_ai.sh knowledge "Extract patterns from the codebase"
  universal_ai.sh knw "Analyze the system architecture"

  # Provider management
  universal_ai.sh status
  universal_ai.sh switch ollama

ENVIRONMENT:
  AI_PROVIDER    - Preferred provider (openrouter, ollama, lmstudio, openai)
  AI_TIER        - Default tier (x1, x0, free)

ALIASES (add to ~/.bashrc):
  alias pln='universal_ai.sh planner'
  alias imp='universal_ai.sh implementor'
  alias knw='universal_ai.sh knowledge'
  alias ai='universal_ai.sh'
EOF
}

# Main execution
main() {
  local cmd="${1:-}"

  case "$cmd" in
    planner|pln)
      shift
      # Extract tier if specified (x1, x0, free)
      local tier="$DEFAULT_TIER"
      if [[ "$1" =~ ^(x1|x0|free)$ ]]; then
        tier="$1"
        shift
      fi
      planner "$tier" "$*"
      ;;
    implementor|imp)
      shift
      local tier="$DEFAULT_TIER"
      if [[ "$1" =~ ^(x1|x0|free)$ ]]; then
        tier="$1"
        shift
      fi
      implementor "$tier" "$*"
      ;;
    knowledge|knw)
      shift
      knowledge "$*"
      ;;
    status)
      status
      ;;
    switch)
      shift
      switch_provider "$1" || exit 1
      ;;
    ""|help|--help|-h)
      usage
      ;;
    *)
      error "Unknown command: $cmd"
      usage
      exit 1
      ;;
  esac
}

# Run main function with all arguments
main "$@"