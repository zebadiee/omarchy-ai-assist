#!/bin/bash
# Omarchy AI Subagent Router
# Routes subagent commands (#pln, #imp, #knw, #mem) to appropriate AI providers

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPTS_DIR="$(dirname "$SCRIPT_DIR")/prompts/subagents"
MEMORY_DIR="$(dirname "$SCRIPT_DIR")/memory"
LTM_STORE="$MEMORY_DIR/ltm_store.jsonl"

# Provider priorities
TIER_X1_PROVIDERS="lmstudio:ollama:openrouter:openai"
TIER_X0_PROVIDERS="ollama:lmstudio:openrouter:openai"
TIER_FREE_PROVIDERS="ollama:lmstudio:openrouter:openai"

# Models for each provider
declare -A PROVIDER_MODELS=(
    ["lmstudio"]="deepseek-r1-distill-llama-70b"
    ["ollama"]="mistral:latest"
    ["openrouter"]="deepseek/deepseek-chat"
    ["openai"]="gpt-4o-mini"
)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging
log_info() { echo -e "${BLUE}[INFO]${NC} $1" >&2; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1" >&2; }

# Usage
usage() {
    cat << USAGE_EOF
Omarchy AI Subagent Router

USAGE:
    ai_subagent.sh <SUBAGENT> <TIER> [PROMPT]

SUBAGENTS:
    pln     Planner (#pln) - Creates minimal, ordered plans
    imp     Implementor (#imp) - Implements exact tasks from plans
    knw     Knowledge Extractor (#knw) - Extracts concepts from files
    mem     Memory Librarian (#mem) - Manages long-term memory

TIERS:
    x1      Premium tier (best models)
    x0      Mid-tier (balanced models)
    free    Free tier (cost-effective models)

EXAMPLES:
    ai_subagent.sh pln x1 "Create a REST API for user management"
    ai_subagent.sh imp x0 "Implement tsk1 from plan"
    ai_subagent.sh knw free "Extract concepts from src/main.py"
    ai_subagent.sh mem x1 "Store user preference for dark mode"

ALIases (add to ~/.bashrc):
    alias pln="ai_subagent.sh pln x1"
    alias imp="ai_subagent.sh imp x0"
    alias knw="ai_subagent.sh knw free"
    alias mem="ai_subagent.sh mem x1"
USAGE_EOF
}

# Detect available providers
detect_providers() {
    local available=()

    # Check LM Studio
    if curl -s http://localhost:41343/health >/dev/null 2>&1; then
        available+=("lmstudio")
    fi

    # Check Ollama
    if curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
        available+=("ollama")
    fi

    # Check OpenRouter (requires OPENROUTER_API_KEY)
    if [[ -n "$OPENROUTER_API_KEY" ]]; then
        available+=("openrouter")
    fi

    # Check OpenAI (requires OPENAI_API_KEY)
    if [[ -n "$OPENAI_API_KEY" ]]; then
        available+=("openai")
    fi

    echo "${available[@]}"
}

# Get provider order based on tier
get_provider_order() {
    local tier="$1"
    case "$tier" in
        "x1") echo "$TIER_X1_PROVIDERS" ;;
        "x0") echo "$TIER_X0_PROVIDERS" ;;
        "free") echo "$TIER_FREE_PROVIDERS" ;;
        *)
            log_error "Unknown tier: $tier"
            echo "x1"  # Default fallback
            ;;
    esac
}

# Find first available provider
find_available_provider() {
    local provider_order="$1"
    local available_providers
    available_providers=($(detect_providers))

    IFS=':' read -ra providers <<< "$provider_order"
    for provider in "${providers[@]}"; do
        if [[ " ${available_providers[@]} " =~ " ${provider} " ]]; then
            echo "$provider"
            return 0
        fi
    done

    log_error "No available providers found"
    return 1
}

# Call Ollama API (simplified for immediate use)
call_ollama() {
    local prompt="$1"
    local model="$2"

    # Escape the prompt for JSON
    local prompt_escaped
    prompt_escaped=$(echo "$prompt" | jq -Rs .)

    local response
    response=$(curl -s -X POST http://localhost:11434/api/generate \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$model\",
            \"prompt\": $prompt_escaped,
            \"stream\": false
        }")

    if [[ $? -eq 0 && -n "$response" ]]; then
        echo "$response" | jq -r '.response' 2>/dev/null || echo "Error: Failed to parse Ollama response"
    else
        echo "Error: Ollama API call failed"
    fi
}

# Call LM Studio API
call_lmstudio() {
    local prompt="$1"
    local model="$2"

    curl -s -X POST http://localhost:41343/v1/chat/completions \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$model\",
            \"messages\": [
                {\"role\": \"user\", \"content\": \"$prompt\"}
            ],
            \"temperature\": 0.7,
            \"max_tokens\": 2048
        }" | jq -r '.choices[0].message.content' 2>/dev/null || echo "Error: LM Studio API call failed"
}

# Make AI call (simplified)
call_ai() {
    local prompt="$1"
    local provider="$2"
    local model="$3"

    log_info "Calling $provider with model: $model"

    case "$provider" in
        "lmstudio") call_lmstudio "$prompt" "$model" ;;
        "ollama") call_ollama "$prompt" "$model" ;;
        *)
            log_error "Provider $provider not yet implemented"
            return 1
            ;;
    esac
}

# Load subagent prompt
load_subagent_prompt() {
    local subagent="$1"
    local prompt_file="$PROMPTS_DIR/${subagent}.md"

    if [[ ! -f "$prompt_file" ]]; then
        log_error "Subagent prompt file not found: $prompt_file"
        return 1
    fi

    cat "$prompt_file"
}

# Handle memory operations
handle_memory() {
    local tier="$1"
    local memory_data="$2"

    # Initialize memory store if it doesn't exist
    [[ ! -f "$LTM_STORE" ]] && echo "" > "$LTM_STORE"

    # Add timestamp and metadata
    local timestamp=$(date -Iseconds)

    # Parse the memory_data JSON and add timestamp
    local entry
    entry=$(echo "$memory_data" | jq ". + {\"ts\": \"$timestamp\"}")

    # Validate the final JSON
    if ! echo "$entry" | jq . >/dev/null 2>&1; then
        log_error "Invalid memory entry format"
        return 1
    fi

    # Append to memory store
    echo "$entry" >> "$LTM_STORE"
    log_success "Memory entry stored"
}

# Main function
main() {
    # Check arguments
    if [[ $# -lt 2 ]]; then
        usage
        exit 1
    fi

    local subagent="$1"
    local tier="$2"
    local user_prompt="${3:-}"

    # Validate subagent
    if [[ ! "$subagent" =~ ^(pln|imp|knw|mem)$ ]]; then
        log_error "Invalid subagent: $subagent"
        usage
        exit 1
    fi

    # Validate tier
    if [[ ! "$tier" =~ ^(x1|x0|free)$ ]]; then
        log_error "Invalid tier: $tier"
        usage
        exit 1
    fi

    # Load subagent prompt
    local subagent_prompt
    subagent_prompt=$(load_subagent_prompt "$subagent") || exit 1

    # Find available provider
    local provider_order
    provider_order=$(get_provider_order "$tier")

    local provider
    provider=$(find_available_provider "$provider_order") || exit 1

    local model="${PROVIDER_MODELS[$provider]}"

    # Build full prompt
    local full_prompt
    if [[ -n "$user_prompt" ]]; then
        full_prompt="$subagent_prompt

USER INPUT: $user_prompt

Respond according to your role and output format."
    else
        full_prompt="$subagent_prompt

Respond according to your role and output format."
    fi

    log_info "Processing #$subagent request with $provider ($tier tier)"

    # Make AI call
    local response
    response=$(call_ai "$full_prompt" "$provider" "$model")

    if [[ $? -eq 0 && -n "$response" && "$response" != *"Error:"* && "$response" != "null" ]]; then
        echo "$response"

        # Special handling for memory subagent
        if [[ "$subagent" == "mem" ]]; then
            handle_memory "$tier" "$response"
        fi

        log_success "Subagent #$subagent completed successfully"
    else
        log_error "AI call failed or returned null response"
        echo "Error: Failed to get valid response from $provider"
        if [[ "$VERBOSE" == "true" ]]; then
            echo "Debug response: $response"
        fi
        exit 1
    fi
}

# Run main function with all arguments
main "$@"
