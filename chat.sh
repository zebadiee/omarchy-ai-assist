#!/usr/bin/env bash
# Simple conversational AI interface for Omarchy

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
OLLAMA_BASE_URL="${OLLAMA_BASE_URL:-http://localhost:11434}"
MODEL="${OLLAMA_MODEL:-mistral}"

echo -e "${CYAN}🤖 Omarchy AI Chat${NC}"
echo "=================="
echo "Type 'exit' or 'quit' to end conversation"
echo "Type 'help' for commands"
echo ""

# Check if Ollama is running
if ! curl -s "$OLLAMA_BASE_URL/api/tags" >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Ollama not running. Start it with: ollama serve${NC}"
    exit 1
fi

# Conversation loop
while true; do
    echo -en "${GREEN}You:${NC} "
    read -r user_input

    # Check for exit commands
    case "$user_input" in
        exit|quit|q)
            echo -e "${BLUE}👋 Goodbye!${NC}"
            break
            ;;
        help|h)
            echo -e "${CYAN}Available commands:${NC}"
            echo "  help, h      - Show this help"
            echo "  status, s    - Show AI status"
            echo "  clear, c     - Clear conversation context"
            echo "  exit, quit, q - End conversation"
            echo "  Just type any message to chat!"
            continue
            ;;
        status|s)
            echo -e "${BLUE}📊 AI Status:${NC}"
            echo "  Provider: Ollama"
            echo "  Model: $MODEL"
            echo "  Endpoint: $OLLAMA_BASE_URL"
            continue
            ;;
        clear|c)
            echo -e "${YELLOW}🧹 Context cleared${NC}"
            continue
            ;;
        "")
            continue
            ;;
    esac

    # Send to AI
    echo -en "${BLUE}AI:${NC} "

    # Create JSON payload
    payload=$(jq -n --arg model "$MODEL" --arg prompt "$user_input" \
        '{model:$model, prompt:$prompt, stream:false}')

    # Get response
    response=$(echo "$payload" | curl -s -X POST "$OLLAMA_BASE_URL/api/generate" \
        -H "Content-Type: application/json" \
        -d @- | jq -r '.response')

    echo "$response"
    echo ""
done