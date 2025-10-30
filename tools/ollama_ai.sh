#!/usr/bin/env bash
# Simplified Ollama AI Subagent Router
# Direct integration with Ollama for immediate use

set -euo pipefail

# Configuration
OLLAMA_BASE_URL="${OLLAMA_BASE_URL:-http://localhost:11434}"
DEFAULT_MODEL="${OLLAMA_MODEL:-mistral}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[AI]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Check Ollama availability
check_ollama() {
  if curl -s "$OLLAMA_BASE_URL/api/tags" >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# List available models
list_models() {
  echo -e "${BLUE}📋 Available Ollama Models:${NC}"
  curl -s "$OLLAMA_BASE_URL/api/tags" | jq -r '.models[].name' 2>/dev/null | while read -r model; do
    echo "  • $model"
  done || {
    echo "  • $DEFAULT_MODEL (default)"
  }
}

# Execute Ollama request
ollama_request() {
  local model="$1"
  local prompt="$2"
  local system_prompt="$3"

  local payload
  if [[ -n "$system_prompt" ]]; then
    payload=$(jq -n --arg model "$model" --arg system "$system_prompt" --arg prompt "$prompt" \
      '{model:$model, system:$system, prompt:$prompt, stream:false}')
  else
    payload=$(jq -n --arg model "$model" --arg prompt "$prompt" \
      '{model:$model, prompt:$prompt, stream:false}')
  fi

  log "Querying Ollama ($model)..."
  echo "$payload" | curl -s -X POST "$OLLAMA_BASE_URL/api/generate" -H "Content-Type: application/json" -d @- | jq -r '.response'
}

# Planner subagent
planner() {
  local prompt="$*"
  if [[ -z "$prompt" ]]; then
    error "Provide a planning task"
    return 1
  fi

  local system_prompt="You are an expert software architect and strategic planner for Omarchy OS. Focus on system design, architectural patterns, and implementation strategies. Provide detailed, actionable plans with clear technical specifications."

  ollama_request "$DEFAULT_MODEL" "$prompt" "$system_prompt"
}

# Implementor subagent
implementor() {
  local prompt="$*"
  if [[ -z "$prompt" ]]; then
    error "Provide an implementation task"
    return 1
  fi

  local system_prompt="You are a master implementor and code generator for Omarchy OS. Generate clean, efficient, and well-documented code. Focus on Go, JavaScript, and shell scripting for system integration."

  ollama_request "$DEFAULT_MODEL" "$prompt" "$system_prompt"
}

# Knowledge subagent
knowledge() {
  local prompt="$*"
  if [[ -z "$prompt" ]]; then
    error "Provide a knowledge extraction task"
    return 1
  fi

  local system_prompt="You are a knowledge extraction and pattern analysis specialist. Identify patterns, extract insights, and synthesize information. Focus on learning and cross-agent knowledge sharing."

  ollama_request "$DEFAULT_MODEL" "$prompt" "$system_prompt"
}

# Chat with any model
chat() {
  local model="$1"
  shift
  local prompt="$*"

  if [[ -z "$prompt" ]]; then
    error "Provide a message"
    return 1
  fi

  ollama_request "$model" "$prompt" ""
}

# Status
status() {
  echo -e "${BLUE}🤖 Ollama AI Status${NC}"
  echo "========================"

  if check_ollama; then
    echo -e "  ${GREEN}✅${NC} Ollama Server: Running"
    echo "  Endpoint: $OLLAMA_BASE_URL"
    echo ""
    list_models
  else
    echo -e "  ${RED}❌${NC} Ollama Server: Not available"
    echo "  Expected endpoint: $OLLAMA_BASE_URL"
    echo ""
    echo "💡 Start Ollama with: ollama serve"
  fi
}

# Usage
usage() {
  cat <<'EOF'
🤖 Ollama AI Subagent Router — Omarchy OS

Direct Ollama integration for AI-powered development

USAGE:
  ollama_ai.sh planner|pln "task description"
  ollama_ai.sh implementor|imp "task description"
  ollama_ai.sh knowledge|knw "task description"
  ollama_ai.sh chat <model> "message"
  ollama_ai.sh status

EXAMPLES:
  # Planning
  ollama_ai.sh pln "Design a scalable microservices architecture"
  ollama_ai.sh planner "Plan the implementation of a REST API"

  # Implementation
  ollama_ai.sh imp "Generate Go code for a web server"
  ollama_ai.sh implementor "Create a shell script for system monitoring"

  # Knowledge extraction
  ollama_ai.sh knw "Extract patterns from this codebase"
  ollama_ai.sh knowledge "Analyze the system architecture"

  # Direct chat
  ollama_ai.sh chat mistral "Explain container orchestration"
  ollama_ai.sh chat llama3.1 "What are the best practices for API design?"

  # Status
  ollama_ai.sh status

ENVIRONMENT:
  OLLAMA_BASE_URL  - Ollama API endpoint (default: http://localhost:11434)
  OLLAMA_MODEL     - Default model (default: mistral)

ALIASES (add to ~/.bashrc):
  alias pln='ollama_ai.sh planner'
  alias imp='ollama_ai.sh implementor'
  alias knw='ollama_ai.sh knowledge'
  alias oai='ollama_ai.sh'
EOF
}

# Main execution
main() {
  local cmd="${1:-}"

  case "$cmd" in
    planner|pln)
      shift
      planner "$*"
      ;;
    implementor|imp)
      shift
      implementor "$*"
      ;;
    knowledge|knw)
      shift
      knowledge "$*"
      ;;
    chat)
      shift
      if [[ $# -lt 2 ]]; then
        error "Usage: chat <model> <message>"
        exit 1
      fi
      local model="$1"
      shift
      chat "$model" "$*"
      ;;
    status)
      status
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

main "$@"