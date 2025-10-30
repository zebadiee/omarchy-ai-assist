#!/usr/bin/env bash
# Omarchy AI Terminal Aliases
# Quick access to AI commands for VS Code terminal integration

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Set up environment
export AI_PROVIDER="${AI_PROVIDER:-ollama}"
export OLLAMA_BASE_URL="${OLLAMA_BASE_URL:-http://localhost:11434}"
export LMSTUDIO_BASE_URL="${LMSTUDIO_BASE_URL:-http://127.0.0.1:41343/v1}"
export LMSTUDIO_API_KEY="${LMSTUDIO_API_KEY:-lm-studio}"

# LM Studio CLI aliases
alias lms='./tools/lms_cli.sh'
alias lmsc='./tools/lms_cli.sh chat'
alias lmse='./tools/lms_cli.sh embed'
alias lmsm='./tools/lms_cli.sh models'
alias lmsp='./tools/lms_cli.sh ping'

# Universal AI aliases (works with any provider)
alias ai='./tools/universal_ai.sh'
alias uai='./tools/universal_ai.sh'
alias upln='./tools/universal_ai.sh planner'
alias uimp='./tools/universal_ai.sh implementor'
alias uknw='./tools/universal_ai.sh knowledge'
alias ustatus='./tools/universal_ai.sh status'

# Ollama AI aliases (immediate, works right now)
alias oai='./tools/ollama_ai.sh'
alias pln='./tools/ollama_ai.sh planner'
alias imp='./tools/ollama_ai.sh implementor'
alias knw='./tools/ollama_ai.sh knowledge'
alias ostatus='./tools/ollama_ai.sh status'

# Function aliases for immediate use (use in interactive shells)
# pln() { ./tools/ollama_ai.sh planner "$@"; }
# imp() { ./tools/ollama_ai.sh implementor "$@"; }
# knw() { ./tools/ollama_ai.sh knowledge "$@"; }
# oai() { ./tools/ollama_ai.sh "$@"; }

# Provider switching
ai_ollama() { export AI_PROVIDER=ollama; echo -e "${GREEN}Switched to Ollama${NC}"; }
ai_lmstudio() { export AI_PROVIDER=lmstudio; echo -e "${GREEN}Switched to LM Studio${NC}"; }
ai_openrouter() { export AI_PROVIDER=openrouter; echo -e "${GREEN}Switched to OpenRouter${NC}"; }

# Provider status
ai_check() {
  echo -e "${BLUE}🤖 AI Provider Status${NC}"
  echo "========================"

  # Check Ollama
  if curl -s "$OLLAMA_BASE_URL/api/tags" >/dev/null 2>&1; then
    echo -e "  ${GREEN}✅${NC} Ollama: Available"
  else
    echo -e "  ${YELLOW}⚠${NC}  Ollama: Not available"
  fi

  # Check LM Studio
  if curl -s "$LMSTUDIO_BASE_URL/models" >/dev/null 2>&1; then
    echo -e "  ${GREEN}✅${NC} LM Studio: Available"
  else
    echo -e "  ${YELLOW}⚠${NC}  LM Studio: Not available"
  fi

  # Check OpenRouter
  if [[ -n "${OPENROUTER_API_KEY:-}" ]]; then
    echo -e "  ${GREEN}✅${NC} OpenRouter: Configured"
  else
    echo -e "  ${YELLOW}⚠${NC}  OpenRouter: Not configured"
  fi

  echo ""
  echo "Current provider: ${AI_PROVIDER}"
}

# Help function
ai_help() {
  cat <<'EOF'
🤖 Omarchy AI Commands — Terminal Integration

LM STUDIO COMMANDS:
  lms        - LM Studio CLI main interface
  lmsc "msg" - Chat with LM Studio
  lmse "txt" - Generate embeddings
  lmsm       - List available models
  lmsp       - Ping LM Studio server

UNIVERSAL AI COMMANDS:
  pln [tier] "task"     - Planning subagent (x1, x0, free)
  imp [tier] "task"     - Implementation subagent
  knw "task"            - Knowledge extraction subagent
  aistatus              - Show AI system status

PROVIDER SWITCHING:
  ai_ollama             - Switch to Ollama
  ai_lmstudio           - Switch to LM Studio
  ai_openrouter         - Switch to OpenRouter
  ai_check              - Check provider availability

EXAMPLES:
  # Quick planning
  pln "Design a REST API structure"

  # Implementation with specific tier
  imp x0 "Generate Go code for the API server"

  # Knowledge extraction
  knw "Analyze the codebase for patterns"

  # Direct LM Studio chat
  lmsc -s "You are a Go expert" "Write a simple web server"

  # Check system status
  aistatus
  ai_check

ENVIRONMENT VARIABLES:
  AI_PROVIDER           - Current AI provider (default: ollama)
  OLLAMA_BASE_URL       - Ollama API endpoint
  LMSTUDIO_BASE_URL     - LM Studio API endpoint
  OPENROUTER_API_KEY    - OpenRouter API key

Add this to ~/.bashrc to enable globally:
  source /path/to/omarchy-ai-assist/tools/ai_aliases.sh
EOF
}

# Show welcome message on load
if [[ "${AI_ALIASES_WELCOME:-1}" == "1" ]]; then
  echo -e "${PURPLE}🤖 Omarchy AI aliases loaded${NC}"
  echo "Type 'ai_help' for commands, 'ai_check' for status"
fi