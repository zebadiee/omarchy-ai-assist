#!/usr/bin/env bash
set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

MEMORY_DIR="speccy-lab/memory"
MEMORY_LOG="$MEMORY_DIR/training.log"

# Ensure memory directory exists
mkdir -p "$MEMORY_DIR"

if [[ $# -eq 0 ]]; then
    echo "${BLUE}📝 AI Memory System${NC}"
    echo "=================="
    echo "Usage: $0 \"<memory entry>\""
    echo ""
    echo "Recent entries:"
    tail -n 10 "$MEMORY_LOG" 2>/dev/null || echo "No memory entries yet"
    exit 0
fi

# Add timestamp and memory entry
ENTRY="$(date '+%Y-%m-%d %H:%M:%S') | $*"
echo "$ENTRY" >> "$MEMORY_LOG"
echo "${GREEN}✅ Memory stored:${NC} $*"

# Also store in structured format
JSON_ENTRY=$(cat <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "stage": "$(grep 'training_stage:' speccy-lab/config.yml | cut -d' ' -f2 || echo 'unknown')",
  "entry": "$*",
  "context": "manual_memory"
}
EOF
)
echo "$JSON_ENTRY" >> "$MEMORY_DIR/mem.jsonl"
